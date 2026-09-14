/**
 * Lógica pura de racha/gotas/escudos, espejo exacto de:
 *  - lib/core/model/habit_circle.dart (streakDays, longestStreakDays,
 *    constancyDropsEarned) del lado Dart, y
 *  - supabase/migrations/20250101000002_streak_functions.sql del intento
 *    previo con Postgres (mismo algoritmo, reescrito en TypeScript).
 *
 * Todo recibe fechas como strings "YYYY-MM-DD" (así se guardan en
 * Firestore, ver FIRESTORE_SCHEMA.md) para no depender de zonas horarias
 * de Timestamp. Son funciones puras y testeables sin tocar Firestore.
 */

const DAY_MS = 24 * 60 * 60 * 1000;

function toUtcDate(dateStr: string): Date {
  const [year, month, day] = dateStr.split('-').map(Number);
  return new Date(Date.UTC(year, month - 1, day));
}

function dateToStr(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function addDays(dateStr: string, days: number): string {
  return dateToStr(new Date(toUtcDate(dateStr).getTime() + days * DAY_MS));
}

function dayDiff(a: string, b: string): number {
  return Math.round((toUtcDate(a).getTime() - toUtcDate(b).getTime()) / DAY_MS);
}

export function todayStr(): string {
  return dateToStr(new Date());
}

/**
 * Espejo de HabitCircle.streakDays: cuenta hacia atrás desde hoy (o ayer
 * si hoy aún no tiene check-in) y trata una fecha cubierta por un escudo
 * como puente que no rompe la cadena pero tampoco suma un día.
 */
export function computeStreakDays(
  realDates: readonly string[],
  frozenDates: readonly string[],
  today: string = todayStr(),
): number {
  if (realDates.length === 0) return 0;
  const real = new Set(realDates);
  const frozen = new Set(frozenDates);

  let expected = real.has(today) ? today : addDays(today, -1);
  let streak = 0;
  // Cota de seguridad: nunca hace falta mirar más atrás que la fecha más
  // antigua registrada.
  const oldest = [...realDates, ...frozenDates].sort()[0];

  while (dayDiff(expected, oldest) >= 0) {
    if (real.has(expected)) {
      streak++;
    } else if (frozen.has(expected)) {
      // puente: sigue la racha, no suma día
    } else {
      break;
    }
    expected = addDays(expected, -1);
  }
  return streak;
}

/** Espejo de HabitCircle.longestStreakDays (récord histórico, sin escudos). */
export function computeLongestStreakDays(realDates: readonly string[]): number {
  if (realDates.length === 0) return 0;
  const sorted = [...new Set(realDates)].sort();
  let longest = 1;
  let current = 1;
  for (let i = 1; i < sorted.length; i++) {
    if (dayDiff(sorted[i], sorted[i - 1]) === 1) {
      current++;
      longest = Math.max(longest, current);
    } else {
      current = 1;
    }
  }
  return longest;
}

function dropsForStreakDay(streakAtDay: number): number {
  if (streakAtDay >= 50) return 30;
  if (streakAtDay >= 21) return 20;
  if (streakAtDay >= 7) return 15;
  return 10;
}

/**
 * Espejo de HabitCircle.constancyDropsEarned: el multiplicador crece con
 * la racha vigente el día de cada check-in real. Un día cubierto por un
 * escudo mantiene el conteo de racha para el multiplicador pero no gana
 * gotas propias.
 */
export function computeDropsEarned(
  realDates: readonly string[],
  frozenDates: readonly string[],
): number {
  if (realDates.length === 0) return 0;
  const frozen = new Set(frozenDates);
  const sorted = [...new Set(realDates)].sort();

  let drops = 0;
  let streak = 0;
  let previous: string | null = null;
  for (const day of sorted) {
    if (previous === null) {
      streak = 1;
    } else {
      const gap = dayDiff(day, previous);
      const bridged = gap === 2 && frozen.has(addDays(previous, 1));
      streak = gap === 1 || bridged ? streak + 1 : 1;
    }
    drops += dropsForStreakDay(streak);
    previous = day;
  }
  return drops;
}

/** Hitos de racha que otorgan un Escudo de Racha (ver Milestone.targets en Dart). */
export const SHIELD_MILESTONES = [7, 21, 30, 50, 100] as const;
