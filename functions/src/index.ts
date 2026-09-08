/**
 * Cloud Functions de Racha Tribu (proyecto Firebase "rachatribu").
 *
 * Espejo, trigger por trigger, del diseño que se había hecho para
 * Postgres/Supabase (triggers SECURITY DEFINER + pg_cron): el feed de
 * actividad, el otorgamiento de Escudos de Racha y el job diario que
 * aplica escudos pendientes se generan aquí, en el servidor, nunca desde
 * el cliente Flutter — así ningún dispositivo puede falsear un evento ni
 * duplicar un escudo. Ver ../../firebase/FIRESTORE_SCHEMA.md para el
 * mapeo completo de colecciones.
 */
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentWritten,
} from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { SHIELD_MILESTONES, computeDropsEarned, computeLongestStreakDays, computeStreakDays, todayStr } from './streakLogic';

initializeApp();
const db = getFirestore();

function addDaysToToday(days: number): string {
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

async function fetchCircleName(circleId: string): Promise<string> {
  const snap = await db.doc(`circles/${circleId}`).get();
  return (snap.data()?.name as string | undefined) ?? 'tu círculo';
}

async function fetchUsername(uid: string): Promise<string> {
  const snap = await db.doc(`users/${uid}`).get();
  return (snap.data()?.username as string | undefined) ?? 'Alguien';
}

interface ActivityEventInput {
  circleId?: string;
  /** Para eventos sin círculo (ej. "ally_accepted"): a quién le aparece. */
  personalUid?: string;
  actorId?: string | null;
  type: string;
  emoji: string;
  message: string;
  payload?: Record<string, unknown>;
}

async function pushActivityEvent(input: ActivityEventInput): Promise<void> {
  const doc = {
    actorId: input.actorId ?? null,
    type: input.type,
    emoji: input.emoji,
    message: input.message,
    payload: input.payload ?? {},
    createdAt: FieldValue.serverTimestamp(),
  };
  if (input.circleId) {
    await db.collection(`circles/${input.circleId}/activityEvents`).add(doc);
  } else if (input.personalUid) {
    await db.collection(`users/${input.personalUid}/activityEvents`).add(doc);
  }
}

interface MemberStats {
  streakDays: number;
  longestStreakDays: number;
  dropsEarned: number;
  freezesAvailable: number;
}

/** Espejo de circle_member_stats (vista Postgres): recalcula y persiste. */
async function recomputeMemberStats(circleId: string, uid: string): Promise<MemberStats> {
  const [checkInsSnap, usesSnap, grantsSnap] = await Promise.all([
    db.collection(`circles/${circleId}/checkIns`).where('userId', '==', uid).get(),
    db.collection(`circles/${circleId}/streakShieldUses`).where('userId', '==', uid).get(),
    db.collection(`circles/${circleId}/streakShieldGrants`).where('userId', '==', uid).get(),
  ]);
  const realDates = checkInsSnap.docs.map((d) => d.data().date as string);
  const frozenDates = usesSnap.docs.map((d) => d.data().coveredDate as string);

  const stats: MemberStats = {
    streakDays: computeStreakDays(realDates, frozenDates),
    longestStreakDays: computeLongestStreakDays(realDates),
    dropsEarned: computeDropsEarned(realDates, frozenDates),
    freezesAvailable: grantsSnap.size - usesSnap.size,
  };

  await db.doc(`circles/${circleId}/memberStats/${uid}`).set({
    ...stats,
    checkedInToday: realDates.includes(todayStr()),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return stats;
}

/** Espejo de fn_maybe_grant_shield (Postgres). */
async function maybeGrantShields(
  circleId: string,
  uid: string,
  streakDays: number,
  circleName: string,
): Promise<void> {
  for (const milestone of SHIELD_MILESTONES) {
    if (streakDays < milestone) continue;
    const grantRef = db.doc(`circles/${circleId}/streakShieldGrants/${uid}_${milestone}`);
    if ((await grantRef.get()).exists) continue;

    await grantRef.set({
      userId: uid,
      milestoneDays: milestone,
      grantedAt: FieldValue.serverTimestamp(),
    });
    await pushActivityEvent({
      circleId,
      actorId: uid,
      type: 'milestone',
      emoji: '🏆',
      message: `${circleName} alcanzó ${milestone} días de racha — ¡ganaste un Escudo de Racha! 🛡️`,
      payload: { milestoneDays: milestone },
    });
  }
}

/**
 * Espejo de trg_check_in_activity + on_circle_insert (owner-membership no
 * aplica aquí: en Firestore la membresía del dueño se crea junto con el
 * círculo en la propia app, ver FIRESTORE_SCHEMA.md). Al crear un
 * check-in: recalcula memberStats, publica el evento, evalúa escudos y
 * detecta Círculo Perfecto. Al borrar (deshacer): solo recalcula stats.
 */
export const onCheckInWrite = onDocumentWritten(
  'circles/{circleId}/checkIns/{checkInId}',
  async (event) => {
    const circleId = event.params.circleId;
    const before = event.data?.before;
    const after = event.data?.after;
    const isCreate = !before?.exists && !!after?.exists;
    const uid = (after?.exists ? after.data()?.userId : before?.data()?.userId) as
      | string
      | undefined;
    if (!uid) return;

    const stats = await recomputeMemberStats(circleId, uid);
    if (!isCreate || !after) return; // deshacer un check-in no genera actividad nueva

    const [circleName, username] = await Promise.all([fetchCircleName(circleId), fetchUsername(uid)]);

    await pushActivityEvent({
      circleId,
      actorId: uid,
      type: 'check_in',
      emoji: '🔥',
      message: `${username} completó "${circleName}" — racha de ${stats.streakDays} días.`,
      payload: { streakDays: stats.streakDays },
    });

    await maybeGrantShields(circleId, uid, stats.streakDays, circleName);

    const checkInDate = after.data()?.date as string;
    const [membersSnap, todaySnap] = await Promise.all([
      db.collection(`circles/${circleId}/members`).get(),
      db.collection(`circles/${circleId}/checkIns`).where('date', '==', checkInDate).get(),
    ]);
    const distinctToday = new Set(todaySnap.docs.map((d) => d.data().userId as string));
    if (membersSnap.size > 1 && distinctToday.size === membersSnap.size) {
      await pushActivityEvent({
        circleId,
        actorId: null,
        type: 'perfect_circle',
        emoji: '✨',
        message: `¡"${circleName}" logró el Círculo Perfecto de hoy!`,
      });
    }
  },
);

/** Espejo de trg_member_joined_activity (Postgres). Omite al propio dueño. */
export const onMemberCreate = onDocumentCreated(
  'circles/{circleId}/members/{uid}',
  async (event) => {
    const { circleId, uid } = event.params;
    const circleSnap = await db.doc(`circles/${circleId}`).get();
    if (circleSnap.data()?.ownerId === uid) return;

    const [circleName, username] = await Promise.all([fetchCircleName(circleId), fetchUsername(uid)]);
    await pushActivityEvent({
      circleId,
      actorId: uid,
      type: 'member_joined',
      emoji: '🎉',
      message: `${username} se unió a "${circleName}".`,
    });
  },
);

/** Espejo de trg_shield_used_activity (Postgres). */
export const onShieldUseCreate = onDocumentCreated(
  'circles/{circleId}/streakShieldUses/{useId}',
  async (event) => {
    const circleId = event.params.circleId;
    const uid = event.data?.data().userId as string | undefined;
    if (!uid) return;

    const circleName = await fetchCircleName(circleId);
    await pushActivityEvent({
      circleId,
      actorId: uid,
      type: 'shield_used',
      emoji: '🛡️',
      message: `${circleName} usó un Escudo de Racha para no perder la cadena.`,
    });
    await recomputeMemberStats(circleId, uid);
  },
);

/** Espejo de trg_ally_status_activity (Postgres). Solo dispara al aceptar. */
export const onAllyRequestUpdate = onDocumentUpdated('allyRequests/{requestId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!after || after.status !== 'accepted' || before?.status === 'accepted') return;

  const fromUsername = await fetchUsername(after.fromUserId as string);
  await pushActivityEvent({
    personalUid: after.toUserId as string,
    actorId: after.fromUserId as string,
    type: 'ally_accepted',
    emoji: '🕊️',
    message: `Ahora eres aliado de ${fromUsername}.`,
  });
});

/**
 * Espejo de fn_apply_pending_shields (Postgres, vía pg_cron): job diario
 * que consume un escudo automáticamente cuando se dejó pasar un día sin
 * check-in tras traer racha activa, para que la cadena no se rompa.
 * `onShieldUseCreate` se encarga del evento de actividad resultante.
 */
export const applyPendingShields = onSchedule('5 0 * * *', async () => {
  const yesterday = addDaysToToday(-1);
  const dayBefore = addDaysToToday(-2);

  const membersSnap = await db.collectionGroup('members').get();
  for (const memberDoc of membersSnap.docs) {
    const circleRef = memberDoc.ref.parent.parent;
    if (!circleRef) continue;
    const circleId = circleRef.id;
    const uid = memberDoc.id;

    const [yesterdayCheckIn, yesterdayUse, dayBeforeCheckIn, dayBeforeUse] = await Promise.all([
      db.doc(`circles/${circleId}/checkIns/${uid}_${yesterday}`).get(),
      db.doc(`circles/${circleId}/streakShieldUses/${uid}_${yesterday}`).get(),
      db.doc(`circles/${circleId}/checkIns/${uid}_${dayBefore}`).get(),
      db.doc(`circles/${circleId}/streakShieldUses/${uid}_${dayBefore}`).get(),
    ]);
    if (yesterdayCheckIn.exists || yesterdayUse.exists) continue;
    if (!dayBeforeCheckIn.exists && !dayBeforeUse.exists) continue;

    const [grantsSnap, usesSnap] = await Promise.all([
      db.collection(`circles/${circleId}/streakShieldGrants`).where('userId', '==', uid).get(),
      db.collection(`circles/${circleId}/streakShieldUses`).where('userId', '==', uid).get(),
    ]);
    if (grantsSnap.size - usesSnap.size <= 0) continue;

    await db.doc(`circles/${circleId}/streakShieldUses/${uid}_${yesterday}`).set({
      userId: uid,
      coveredDate: yesterday,
      usedAt: FieldValue.serverTimestamp(),
    });
  }
});

/**
 * Callable: canjea un invite_code por membresía real. El cliente no puede
 * leer `circles` para buscar por código (las reglas exigen ya ser
 * miembro), así que esta función usa el Admin SDK para encontrar el
 * círculo dueño del código y crear la membresía por el usuario.
 */
export const redeemInviteCode = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Debes iniciar sesión.');

  const inviteCode = (request.data?.inviteCode as string | undefined)?.trim();
  if (!inviteCode) throw new HttpsError('invalid-argument', 'Falta inviteCode.');

  const circlesSnap = await db.collection('circles').where('inviteCode', '==', inviteCode).limit(1).get();
  if (circlesSnap.empty) throw new HttpsError('not-found', 'Código de invitación inválido.');

  const circleDoc = circlesSnap.docs[0];
  const memberRef = db.doc(`circles/${circleDoc.id}/members/${uid}`);
  if ((await memberRef.get()).exists) {
    return { circleId: circleDoc.id, alreadyMember: true };
  }
  await memberRef.set({ role: 'member', joinedAt: FieldValue.serverTimestamp() });
  return { circleId: circleDoc.id, alreadyMember: false };
});
