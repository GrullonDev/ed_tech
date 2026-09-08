# Plan de migración: `LocalStorageService` → Supabase

Objetivo: reemplazar la persistencia local (Hive) por Supabase sin que
`HomeLogic` cambie su contrato hacia la UI — las pantallas ya no conocen
el origen de los datos, y ese límite se mantiene.

## 0. Principio guía

`HomeLogic` es hoy el único punto que llama a `LocalStorageService`
(está documentado en su propio doc-comment: *"Al integrar Supabase, este
es el único lugar que necesita cambiar"*). El plan respeta esa frontera:
se introduce una capa de repositorio detrás de `HomeLogic`, y Hive pasa a
ser **caché offline**, no la fuente de verdad.

## 1. Nueva capa: `HabitRepository` (interfaz)

Crear `lib/core/repository/habit_repository.dart` con una interfaz que
declare todo lo que hoy hace `LocalStorageService` estáticamente, pero
como métodos de instancia + streams donde haga falta tiempo real:

```dart
abstract class HabitRepository {
  Future<AppUser?> readUser();
  Future<void> saveUser(AppUser user);

  Future<List<HabitCircle>> readCircles();
  Future<HabitCircle> createCircle({required String name, required String category});
  Future<void> toggleCheckIn(String circleId, {required bool checkedIn});
  Future<void> addMember(String circleId, String username); // pasa a "canjear invite_code"

  Stream<List<ActivityEvent>> watchActivityFeed(); // antes: readActivityFeed()
  Stream<List<HabitCircle>> watchCircles();         // reemplaza el polling manual

  Future<List<AllyRequest>> readAllyRequests();
  Future<void> acceptAllyRequest(String requestId);
  Future<void> rejectAllyRequest(String requestId);
  Future<void> sendAllyRequest(String toUsername);
}
```

Dos implementaciones:

- `LocalHabitRepository` — envoltorio delgado sobre el
  `LocalStorageService` actual (comportamiento de hoy, sin red).
- `SupabaseHabitRepository` — usa `supabase_flutter`.

`HomeLogic` recibe un `HabitRepository` por constructor (con
`LocalHabitRepository()` como default para no romper `test/widget_test.dart`
ni el modo 100% offline documentado en el README).

## 2. Cambios concretos por método de `HomeLogic`

| Método actual | Cambio |
|---|---|
| `_loadFromStorage()` | Pasa a `await` sobre el repositorio + se suscribe a `watchCircles()`/`watchActivityFeed()` (Supabase Realtime) en vez de leer una sola vez de Hive. |
| `toggleCheckIn(circle)` | Hace `insert`/`delete` en `check_ins` vía el repositorio. **Ya no calcula `streakDays` ni empuja el evento de actividad localmente** — ambos ahora los da el servidor (`circle_member_stats`, `activity_events`), así que `HomeLogic` solo dispara la mutación y confía en el stream de vuelta. |
| `_grantFreezeIfMilestoneReached` | Se borra: lo hace `fn_maybe_grant_shield` en el trigger de Postgres. |
| `_applyPendingStreakFreezes` | Se borra del cliente: lo hace `fn_apply_pending_shields()` vía cron en el servidor. |
| `_pushActivityEvent` | Se borra: los triggers de Postgres son la única fuente de eventos. |
| `createCircle` | Inserta en `circles` (el trigger `on_circle_insert` ya agrega al dueño en `circle_members`); si se quiere invitar por código, expone `circle.inviteCode` en vez del diálogo "Invitar a un amigo" con nombre local. |
| `addMemberToCircle` | Se reemplaza por un flujo de "canjear código": la app que invita comparte `invite_code` (reutilizando la pantalla de QR ya existente), quien lo escanea hace `insert` en `circle_members` con `user_id = auth.uid()`. |
| `sendAllyRequest` / `acceptAllyRequest` / `addAllyFromScannedCode` | Pasan de simular localmente "ya llegó" a un `insert`/`update` real en `ally_requests`; el otro dispositivo lo ve vía Realtime, no hace falta simular nada. |
| `constancyDrops`, `overallStreakDays`, `recordStreakDays`, `userLevel` | Se recalculan igual, pero leyendo de `circle_member_stats` (ya trae `streak_days`, `longest_streak_days`, `drops_earned`, `freezes_available` por círculo) en vez de iterar `HabitCircle` en memoria. |

## 3. Autenticación

Hoy no existe — el "playerId" cumple ese rol de forma local. Se necesita:

1. Supabase Auth: recomendado **Anonymous Sign-in** para el onboarding
   actual ("solo ingresa tu apodo, sin contraseña") + upgrade opcional a
   email/OAuth más adelante para no perder la cuenta al cambiar de
   dispositivo. Evita forzar un registro con contraseña en el primer uso,
   que hoy no existe y rompería el onboarding de un solo campo.
2. Al completar el onboarding (`completeOnboarding()`), en vez de generar
   `playerId` localmente: `supabase.auth.signInAnonymously()` →
   `insert` en `profiles` con `id = auth.uid()`, `username`.
3. El QR pasa de `RACHATRIBU:<playerId>:<username>` a
   `RACHATRIBU:<authUid>:<username>` — mismo formato, mismo parsing en
   `qr_summon.dart`, solo cambia qué id se usa. Escanearlo ya no agrega un
   nombre local: hace `insert` en `ally_requests` con `to_user_id` = ese
   uid.

## 4. Hive como caché offline (no se elimina)

`local_storage_service.dart` se conserva, pero cambia de rol:

- `SupabaseHabitRepository` escribe en Hive **después** de cada
  operación exitosa contra Supabase (write-through cache).
- Al iniciar sin conexión, `HomeLogic` puede leer el último estado
  cacheado en Hive mientras `SupabaseHabitRepository` reintenta conectar,
  en vez de mostrar una pantalla vacía.
- `activity_feed_box` dentro de Hive guarda los últimos eventos vistos
  para que el Ágora no quede en blanco offline.

Esto cierra el ítem pendiente del README: *"Modo offline mejorado con
sync cuando haya conexión"*.

## 5. Cola de sincronización offline (outbox)

Pregunta abierta del equipo: si el usuario agrega un aliado (u otra
acción social) sin internet, ¿se deja "mapeado" localmente y se le avisa
al otro usuario aparte cuando vuelva la conexión, o hace falta algo más?

**Propuesta: patrón outbox, sin mecanismo aparte de notificación.**

1. **Cola local (`outbox_box` en Hive)**: cada acción que necesita
   escribir en Supabase (`sendAllyRequest`, `toggleCheckIn`,
   `addMemberToCircle`, etc.) primero se aplica de forma optimista al
   estado en memoria de `HomeLogic` (la UI responde al instante, como
   hoy) y, si no hay conexión, además encola un registro:
   `{id, type: 'send_ally_request', payload: {...}, createdAt}`.
2. **Detección de conexión**: `connectivity_plus` (o el propio cliente
   de Supabase, que ya expone reconexión de Realtime) dispara
   `_flushOutbox()` en `HomeLogic` en cuanto vuelve la red.
3. **Flush**: `_flushOutbox()` reproduce la cola en orden contra
   `SupabaseHabitRepository` (mismo método que se habría llamado online).
   Si una entrada falla por conflicto real (ej. el círculo ya no existe),
   se descarta y se registra en el feed local; si falla por red, se
   reintenta en el siguiente flush.
4. **Notificación al otro usuario — no hace falta nada aparte**: en
   cuanto la solicitud de aliado se inserta en `ally_requests` (paso 3),
   el mismo mecanismo que ya cubre este PR entra a jugar solo — el
   receptor ve la fila nueva vía su propia suscripción Realtime a
   `ally_requests`/`activity_events`, sin importar si el remitente la
   creó online o la trae encolada de hace tres días sin señal. **No se
   necesita un segundo camino de "mapeado local + aviso aparte"**: el
   outbox ya resuelve el "mapeado local", y Realtime + los triggers de
   `20250101000003_activity_triggers.sql` ya resuelven el aviso — construir
   algo adicional sería duplicar lógica que el esquema de este PR ya cubre.
5. **UI**: mientras una acción sigue en el outbox sin confirmar, se marca
   con un badge sutil ("pendiente de sincronizar") reutilizando el patrón
   visual que ya existe para "Pendiente" en `circle_detail.dart`
   (`_MemberTile.isPending`).

Este diseño evita dos problemas del enfoque "solo dejarlo mapeado": (a)
que la invitación se pierda si se cierra la app antes de sincronizar
manualmente, y (b) tener que inventar un canal de notificación paralelo
al que ya generan los triggers — el outbox solo decide *cuándo* se hace
el `insert` real, no *cómo* se entera el otro usuario.

## 6. Fases sugeridas (para no romper la app en un solo PR)

1. **Fase 0 (ya hecho en este PR)**: esquema Postgres + RLS + funciones +
   triggers, sin tocar Dart todavía. Se puede aplicar a un proyecto
   Supabase de prueba y validar con SQL directo.
2. **Fase 1**: agregar `supabase_flutter` al `pubspec.yaml`, inicializar
   el cliente en `main.dart`, implementar Auth anónimo + `profiles`.
   `HomeLogic` sigue usando `LocalHabitRepository` (Hive) para todo lo
   demás — solo el usuario ya vive en Supabase.
3. **Fase 2**: migrar círculos + check-ins a `SupabaseHabitRepository`
   (lee/escribe `circles`, `circle_members`, `check_ins`,
   `circle_member_stats`). Sigue habiendo un solo miembro real por
   círculo hasta este punto, como hoy.
4. **Fase 3**: migrar aliados/invitaciones reales (`ally_requests`,
   canje de `invite_code`) — aquí es cuando "la tribu" deja de ser
   simulada y círculos pasan a tener miembros reales de otros
   dispositivos.
5. **Fase 4**: migrar el feed de actividad a `activity_events` +
   Supabase Realtime (`supabase.channel('activity_events').on(...)`),
   retirar `_pushActivityEvent` de Dart.
6. **Fase 5**: Hive pasa de ser la fuente de verdad a ser cache
   write-through; agregar reconciliación al reconectar.
7. **Fase 6**: implementar el outbox de la sección 5 (cola local +
   flush al reconectar) para las acciones sociales — aliados e
   invitaciones de círculo primero, por ser las que más importan offline.

Cada fase deja la app funcional y testeable de punta a punta antes de
empezar la siguiente.

## 7. Qué NO cambia

- El contrato `HomeLogic` (ChangeNotifier) → UI no cambia: las pantallas
  siguen leyendo getters y llamando métodos, sin saber si hay red o no.
- `HabitCircle`, `CheckIn`, `Milestone`, `ActivityEvent`, `AllyRequest`
  siguen siendo los modelos Dart de la UI; solo cambia de dónde los llena
  el repositorio (antes: `fromMap` de Hive: ahora: fila de Supabase +
  el mismo `fromMap`/mapper adaptado a la forma de la respuesta REST).
