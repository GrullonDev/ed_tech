# Esquema de Firestore — Racha Tribu (proyecto `rachatribu`)

Reemplaza el diseño previo en Postgres/Supabase (ver el PR cerrado
GrullonDev/ed_tech#2) por el equivalente en Firestore, sobre el proyecto
Firebase **`rachatribu`** ya creado y vinculado a GitHub. Mismo objetivo:
mapear los modelos Dart actuales (`lib/core/model/*`, hoy 100% locales vía
Hive) a una base de datos real, sin cambiar el contrato de `HomeLogic`
hacia la UI. Ver `MIGRATION_PLAN.md` para el plan de reemplazo de
`LocalStorageService`.

## Por qué Firestore es distinto a diseñar (vs. lo que se había hecho en SQL)

Postgres tenía funciones/vistas que recalculaban `streakDays`,
`longestStreakDays`, etc. al vuelo en cada lectura. Firestore no tiene
ese tipo de cómputo del lado del servidor en las lecturas — la
alternativa idiomática es **denormalizar**: una Cloud Function recalcula
las estadísticas cada vez que cambian los datos de origen (`checkIns`,
escudos) y las guarda en un documento aparte (`memberStats`) que el
cliente sí puede leer barato. El cálculo en sí (`functions/src/streakLogic.ts`)
es una traducción línea por línea de la lógica que ya vivía en
`HabitCircle` (Dart) y en las funciones SQL del intento con Supabase.

## Colecciones

```
users/{uid}
  username: string
  memberSince: Timestamp
  createdAt: Timestamp

  users/{uid}/activityEvents/{eventId}   -- eventos sin círculo (ej. "ally_accepted")
    actorId, type, emoji, message, payload, createdAt

circles/{circleId}
  name: string
  category: string
  ownerId: string (uid)
  inviteCode: string
  createdAt: Timestamp

  circles/{circleId}/members/{uid}
    role: 'owner' | 'member'
    joinedAt: Timestamp

  circles/{circleId}/checkIns/{uid_yyyy-mm-dd}   -- doc ID = unicidad
    userId: string
    date: string ("yyyy-mm-dd")
    createdAt: Timestamp

  circles/{circleId}/streakShieldGrants/{uid_milestoneDays}
    userId: string
    milestoneDays: 7 | 21 | 30 | 50 | 100
    grantedAt: Timestamp

  circles/{circleId}/streakShieldUses/{uid_yyyy-mm-dd}
    userId: string
    coveredDate: string ("yyyy-mm-dd")
    usedAt: Timestamp

  circles/{circleId}/memberStats/{uid}        -- denormalizado, solo Cloud Functions escribe
    streakDays, longestStreakDays, dropsEarned, freezesAvailable: number
    checkedInToday: boolean
    updatedAt: Timestamp

  circles/{circleId}/activityEvents/{eventId}  -- escrito directo por el cliente (Fase 4, ruta Spark)
    actorId, emoji, message, createdAt

allyRequests/{fromUid_toUid}     -- escrito directo por el cliente (Fase 3), sin Cloud Function
  fromUserId, toUserId: string
  fromUsername, toUsername: string  -- denormalizados para no tener que leer users/{uid} aparte
  status: 'pending' | 'accepted' | 'rejected'
  sentAt: Timestamp
```

## Mapeo modelo Dart → colección Firestore

| Modelo Dart | Colección/documento Firestore | Notas |
|---|---|---|
| `AppUser` | `users/{uid}` | `uid` viene de Firebase Auth; ya no hace falta `playerId` propio. |
| `HabitCircle` (name, category) | `circles/{circleId}` | Suma `inviteCode`, canjeable vía la Cloud Function `redeemInviteCode`. |
| `HabitCircle.members` | `circles/{circleId}/members/{uid}` | Relación real usuario↔círculo. |
| `HabitCircle.checkIns` / `CheckIn` | `circles/{circleId}/checkIns/{uid_fecha}` | El ID del documento (`uid_yyyy-mm-dd`) es la unicidad: Firestore rechaza el `create` si ya existe. |
| `HabitCircle.freezesAvailable` | `memberStats.freezesAvailable` (denormalizado) | = `streakShieldGrants` − `streakShieldUses`, recalculado por Cloud Function. |
| `HabitCircle.freezeUsedDates` | `circles/{circleId}/streakShieldUses` | |
| `HabitCircle.claimedFreezeMilestones` | `circles/{circleId}/streakShieldGrants` | |
| `HabitCircle.streakDays` / `.longestStreakDays` / `.constancyDropsEarned` | `memberStats.*` | Calculados por `functions/src/streakLogic.ts`, mismo algoritmo que el getter Dart. |
| `AllyRequest` + lista local `allies` | `allyRequests/{fromUid_toUid}` | El estado `accepted`/`rejected` reemplaza el flujo simulado. Los "aliados" son las solicitudes con `status == 'accepted'` (consulta directa, no hace falta colección aparte). |
| `ActivityEvent` (círculo) | `circles/{circleId}/activityEvents` | Fase 4: lo escribe directo el cliente que hizo la acción (`HomeLogic._mirrorActivityEvent`), no una Cloud Function — ver más abajo. |
| `ActivityEvent` (aliados, miembros simulados) | Solo local (Hive), sin colección Firestore | No son eventos de un círculo compartido; cada dispositivo ya se entera por su propio listener de `allyRequests` (Fase 3) o no representan un usuario real (`addMemberToCircle`). |

## Por qué el feed y los escudos viven en Cloud Functions (excepto el feed de círculo, ver Fase 4)

Mismo motivo que en el diseño de Supabase: con múltiples dispositivos
compartiendo un círculo, el evento tiene que existir para todos los
miembros sin importar quién hizo la acción, y en el diseño ideal ningún
cliente debería poder insertar un evento o escudo falso. Las Firestore
Security Rules (`firestore.rules`) no permiten `write` directo del cliente
en `streakShieldGrants` ni `streakShieldUses` — solo el Admin SDK (que usan
las Cloud Functions, aún no desplegadas) puede, porque ignora las reglas.

**Excepción — `activityEvents` de círculo (Fase 4)**: para no bloquear el
feed de actividad detrás de la decisión de Blaze/Cloud Functions (sección
0), esta subcolección sí acepta `create` directo del cliente (con
`actorId == request.auth.uid`, para que nadie pueda escribir un evento a
nombre de otro). Es un trade-off consciente: un miembro podría en teoría
falsear el *texto* de su propio evento, pero no puede impersonar a otro ni
tocar racha/gotas/escudos reales (esos siguen siendo 100% locales o,
cuando se desplieguen las Cloud Functions, exclusivos de `memberStats`). Si
más adelante se despliegan las Cloud Functions, esta regla debe volver a
`write: if false` y los writes de `HomeLogic._mirrorActivityEvent` deben
quitarse (los pondría el trigger `onCheckInWrite`/etc.).

Triggers implementados en `functions/src/index.ts`:

| Trigger | Espejo de (diseño Postgres previo) |
|---|---|
| `onCheckInWrite` | `trg_check_in_activity` + `fn_maybe_grant_shield` |
| `onMemberCreate` | `trg_member_joined_activity` |
| `onShieldUseCreate` | `trg_shield_used_activity` |
| `onAllyRequestUpdate` | `trg_ally_status_activity` |
| `applyPendingShields` (Cloud Scheduler, diario) | `fn_apply_pending_shields` (pg_cron) |
| `redeemInviteCode` (callable) | canje de `invite_code` (en Postgres no hacía falta función aparte porque RLS permitía leer `circles` por índice único; en Firestore sí, ver security rules) |

## Seguridad (Firestore Security Rules)

Resumen — detalle completo comentado en `firestore.rules`:

- **`users/{uid}`**: cualquier usuario autenticado puede leer cualquier
  perfil (los usernames ya son públicos hoy vía QR/leaderboard); cada uno
  solo puede crear/editar el suyo. Su subcolección `activityEvents` es
  privada (solo el propio dueño la lee).
- **`circles/{circleId}` y sus subcolecciones `members`/`checkIns`**:
  visibles solo para miembros del círculo, vía la función helper
  `isCircleMember()`.
- **`streakShieldGrants` / `streakShieldUses` / `memberStats`**: de solo
  lectura para el cliente, `write: false` — únicamente las Cloud Functions
  escriben ahí (aún no desplegadas, ver sección 0 de `MIGRATION_PLAN.md`).
- **`activityEvents` de círculo**: excepción de la Fase 4 — el cliente
  puede `create` (no `update`/`delete`) siempre que `actorId` sea el suyo
  propio. Ver el trade-off explicado arriba.
- **`allyRequests`**: cada quien ve sus propias solicitudes (enviadas o
  recibidas); solo el receptor puede aceptar/rechazar.

## Cómo aplicar

```bash
firebase use rachatribu
firebase deploy --only firestore:rules,firestore:indexes,functions
```

Requiere el plan **Blaze** (pago por uso) para desplegar Cloud Functions
—el plan Spark gratuito no las permite—, aunque el uso normal de esta app
cae dentro de la capa gratuita de Blaze. Si de momento se prefiere seguir
100% en el plan Spark, ver la alternativa en `MIGRATION_PLAN.md` (cálculo
de racha en el cliente en vez de Cloud Functions).
