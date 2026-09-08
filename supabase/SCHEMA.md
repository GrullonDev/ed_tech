# Esquema de Supabase — Racha Tribu

Este documento mapea los modelos Dart actuales (`lib/core/model/*`,
100% locales vía Hive) al esquema Postgres en `supabase/migrations/`, y
explica las decisiones de diseño. Ver `MIGRATION_PLAN.md` para el plan de
reemplazo de `LocalStorageService`.

## Nombre del proyecto/base de datos

Al crear el proyecto en Supabase, usar **`racha_tribu`** como nombre del
proyecto (Supabase no permite renombrar la base de datos Postgres en sí
—siempre se llama `postgres`— pero sí el proyecto, que es lo que aparece
en el dashboard y en la URL del API). Un solo proyecto/entorno alcanza
por ahora — nada en este PR asume `staging`/`prod` separados ni depende
de ningún nombre en particular, así que las migraciones aplican igual
sin importar cómo se llame el proyecto.

## Mapeo modelo Dart → tabla Postgres

| Modelo Dart | Tabla/vista Postgres | Notas |
|---|---|---|
| `AppUser` | `profiles` | 1:1 con `auth.users`. `playerId` desaparece: se usa `auth.uid()` directamente en el QR. |
| `HabitCircle` (name, category) | `circles` | Suma `invite_code` para invitaciones reales (reemplaza el diálogo local "Invitar a un amigo"). |
| `HabitCircle.members` | `circle_members` | Relación real usuario↔círculo en vez de `List<String>` de nombres sueltos. |
| `HabitCircle.checkIns` / `CheckIn` | `check_ins` | Única fuente de verdad; `unique(circle_id, user_id, check_in_date)` evita doble check-in. |
| `HabitCircle.freezesAvailable` | `fn_circle_freezes_available()` | Derivado de `streak_shield_grants` menos `streak_shield_uses` (ledger, no contador mutable — evita condiciones de carrera entre dispositivos). |
| `HabitCircle.freezeUsedDates` | `streak_shield_uses` | |
| `HabitCircle.claimedFreezeMilestones` | `streak_shield_grants` | |
| `HabitCircle.streakDays` | `fn_circle_streak_days()` | Mismo algoritmo que el getter Dart, línea por línea. |
| `HabitCircle.longestStreakDays` | `fn_circle_longest_streak_days()` | Gaps-and-islands vía funciones de ventana. |
| `HabitCircle.constancyDropsEarned` | `fn_circle_drops_earned()` | Mismo multiplicador por racha (x1/x1.5/x2/x3). |
| `AllyRequest` + lista local `allies` | `ally_requests` + vista `allies` | El estado `accepted`/`rejected` reemplaza el flujo simulado de aceptar/rechazar. |
| `ActivityEvent` | `activity_events` | Ya no lo escribe el cliente: lo generan triggers `SECURITY DEFINER` en el servidor (`20250101000003_activity_triggers.sql`), así el feed no se puede falsear ni queda solo en un dispositivo. |
| `HomeLogic.constancyDrops` (bono por hito) | Se recalcula igual en el cliente a partir de `circle_member_stats` | El bono de +50 por hito histórico global sigue siendo lógica de agregación simple, no necesita vivir en SQL. |

## Por qué funciones/vistas y no columnas

Los comentarios originales en Dart insisten en que nada de esto se guarda
como contador aparte — todo se deriva de `checkIns` para que no se pueda
desincronizar. El esquema de Postgres sigue la misma filosofía:

- `streak_days`, `longest_streak_days`, `drops_earned` y
  `freezes_available` son **funciones**, no columnas: se recalculan en
  cada lectura desde `check_ins` / `streak_shield_*`.
- La vista `circle_member_stats` junta las cuatro en una sola consulta
  para que el cliente no tenga que llamar 4 RPCs por cada miembro visible
  en pantalla.

## Por qué el feed de actividad vive en triggers, no en el cliente

En Dart, `HomeLogic._pushActivityEvent()` corre en el propio dispositivo
que hizo la acción. Con múltiples dispositivos reales compartiendo un
círculo, eso ya no alcanza: si Ana hace check-in desde su teléfono, el
teléfono de Beto también necesita ver el evento en el Ágora. Generar los
eventos en triggers de Postgres (`trg_check_in_activity`,
`trg_member_joined_activity`, `trg_shield_used_activity`,
`trg_ally_status_activity`) resuelve dos problemas a la vez:

1. El evento existe para todos los miembros sin importar quién lo generó.
2. Ningún cliente puede insertar un evento falso: `activity_events` no
   tiene policy de `INSERT` para el rol `authenticated` (ver
   `20250101000004_rls.sql`), solo las funciones `SECURITY DEFINER` pueden
   escribir ahí.

## Seguridad (RLS)

Resumen por tabla — el detalle completo está comentado en
`20250101000004_rls.sql`:

- **`profiles`**: cualquier usuario autenticado puede leer cualquier
  perfil (los usernames ya son públicos hoy vía QR/leaderboard); cada uno
  solo puede crear/editar el suyo.
- **`circles` / `circle_members` / `check_ins`**: visibles solo para
  miembros del círculo, vía la función helper `is_circle_member()`
  (evita el problema de policies recursivas sobre la misma tabla).
- **`streak_shield_grants` / `streak_shield_uses` / `activity_events`**:
  de solo lectura para el cliente. Se escriben únicamente desde funciones
  `SECURITY DEFINER`, nunca directo.
- **`ally_requests`**: cada quien ve sus propias solicitudes (enviadas o
  recibidas); solo el receptor puede aceptar/rechazar.

## Cómo aplicar

Con el Supabase CLI, desde la raíz del proyecto:

```bash
supabase link --project-ref <tu-project-ref>
supabase db push
```

Las migraciones son idempotentes en el orden en que están numeradas
(`20250101000001` → `20250101000005`); no reordenar ni renombrar archivos
ya aplicados en un proyecto real, porque Supabase los trackea por nombre.

Para habilitar el job diario de escudos (`fn_apply_pending_shields`),
activa la extensión `pg_cron` desde el dashboard (Database → Extensions)
y descomenta el `cron.schedule(...)` al final de
`20250101000005_scheduled_shields.sql`. Si el plan del proyecto no
permite `pg_cron`, la alternativa es una Supabase Edge Function con cron
trigger que llame `select public.fn_apply_pending_shields();` — la lógica
es la misma, solo cambia el disparador.
