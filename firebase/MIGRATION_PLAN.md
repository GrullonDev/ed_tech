# Plan de migración: `LocalStorageService` → Firebase

Objetivo: reemplazar la persistencia local (Hive) por Firebase (proyecto
`rachatribu`) sin que `HomeLogic` cambie su contrato hacia la UI. Mismo
principio guía que en el intento previo con Supabase: `HomeLogic` es hoy
el único punto que llama a `LocalStorageService`, y el plan respeta esa
frontera con una capa de repositorio.

## 0. Antes que nada: plan de Firebase (Spark vs. Blaze)

El diseño en `FIRESTORE_SCHEMA.md` usa Cloud Functions para calcular
racha/gotas/escudos y generar el feed de actividad en el servidor —
**Cloud Functions requiere el plan Blaze** (pago por uso; tiene capa
gratuita generosa, pero exige tarjeta asociada al proyecto). Si el plan
es quedarse en Spark (100% gratis, sin tarjeta), la alternativa es:

- Calcular `streakDays`/`longestStreakDays`/`constancyDropsEarned` **en
  el cliente Dart** (reutilizando literalmente los getters que ya existen
  en `HabitCircle`, sin tocarlos) en vez de en `memberStats` vía Cloud
  Function.
- El feed de actividad lo genera cada cliente localmente (como hace hoy
  `HomeLogic._pushActivityEvent`) y lo escribe directo en
  `circles/{circleId}/activityEvents` — se pierde la garantía de "no se
  puede falsear" que dan las Cloud Functions, pero es aceptable para una
  app sin premios reales en juego.
- Los Escudos de Racha se otorgan/consumen desde el cliente en vez del
  trigger/scheduler — mismo trade-off.

Cualquiera de las dos rutas usa el mismo esquema de colecciones; la
decisión solo cambia quién escribe `memberStats`/`activityEvents` (Cloud
Function vs. cliente) y las Security Rules correspondientes (`write:
false` vs. `write: if isCircleMember(...) && ...`). Recomendación: si el
proyecto ya tiene Blaze habilitado (hace falta para algunas integraciones
comunes de Firebase, como notificaciones push complejas), usar Cloud
Functions — es la ruta más difícil de falsear y la que ya está
implementada en `functions/src/index.ts`.

## 1. Nueva capa: `HabitRepository` (interfaz)

Igual que en el plan anterior: crear `lib/core/repository/habit_repository.dart`
con una interfaz que declare todo lo que hoy hace `LocalStorageService`
estáticamente, como métodos de instancia + streams:

```dart
abstract class HabitRepository {
  Future<AppUser?> readUser();
  Future<void> saveUser(AppUser user);

  Stream<List<HabitCircle>> watchCircles();
  Future<HabitCircle> createCircle({required String name, required String category});
  Future<void> toggleCheckIn(String circleId, {required bool checkedIn});
  Future<Map<String, dynamic>> redeemInviteCode(String code); // llama a la Cloud Function callable

  Stream<List<ActivityEvent>> watchActivityFeed();

  Future<List<AllyRequest>> readAllyRequests();
  Future<void> acceptAllyRequest(String requestId);
  Future<void> rejectAllyRequest(String requestId);
  Future<void> sendAllyRequest(String toUsername);
}
```

Dos implementaciones: `LocalHabitRepository` (envoltorio sobre el
`LocalStorageService` actual, comportamiento 100% offline de hoy) y
`FirebaseHabitRepository` (usa `cloud_firestore` + `firebase_auth` +
`cloud_functions`). `HomeLogic` recibe un `HabitRepository` por
constructor, con `LocalHabitRepository()` como default.

## 2. Cambios concretos por método de `HomeLogic`

| Método actual | Cambio |
|---|---|
| `_loadFromStorage()` | Se suscribe a `watchCircles()`/`watchActivityFeed()` (`snapshots()` de Firestore) en vez de leer una sola vez de Hive. |
| `toggleCheckIn(circle)` | `set()`/`delete()` en `checkIns/{uid}_{fecha}` vía el repositorio. Ya no calcula `streakDays` ni empuja el evento localmente si se usa la ruta con Cloud Functions (sección 0) — llegan solos por el stream de `memberStats`/`activityEvents`. |
| `_grantFreezeIfMilestoneReached` | Se borra si hay Cloud Functions (lo hace `maybeGrantShields`); se mantiene si se optó por la ruta 100% cliente. |
| `_applyPendingStreakFreezes` | Se borra del cliente si hay Cloud Functions (lo hace `applyPendingShields` vía Cloud Scheduler); se mantiene en la ruta 100% cliente. |
| `_pushActivityEvent` | Se borra si hay Cloud Functions; se mantiene (escribiendo directo a Firestore) en la ruta 100% cliente. |
| `createCircle` | `add()` en `circles` + `set()` inmediato en `circles/{id}/members/{uid}` con `role: 'owner'` (en Firestore no hay trigger automático post-insert como en Postgres: la propia app crea ambos documentos, idealmente en un `WriteBatch` para que sean atómicos). |
| `addMemberToCircle` | Se reemplaza por `redeemInviteCode(code)` (Cloud Function callable) reutilizando la pantalla de QR ya existente para compartir el código. |
| `sendAllyRequest` / `acceptAllyRequest` / `addAllyFromScannedCode` | `set()`/`update()` real en `allyRequests/{fromUid}_{toUid}`; el otro dispositivo lo ve vía `snapshots()`. |
| `constancyDrops`, `overallStreakDays`, etc. | Se leen de `memberStats` (stream) por círculo en vez de iterar `HabitCircle` en memoria. |

## 3. Autenticación

1. Firebase Auth: **Anonymous Sign-in** (`firebase_auth`'s
   `signInAnonymously()`) para el onboarding actual de un solo campo, con
   upgrade opcional a Google/email más adelante sin perder el `uid`
   (`linkWithCredential`).
2. Al completar el onboarding: `signInAnonymously()` → `set()` en
   `users/{uid}` con `username`, `memberSince`.
3. El QR pasa de `RACHATRIBU:<playerId>:<username>` a
   `RACHATRIBU:<uid>:<username>` — mismo formato, mismo parsing en
   `qr_summon.dart`. Escanearlo hace `set()` en `allyRequests/{scannedUid}_{miUid}`
   (o al revés, según quién invoca a quién).

## 4. Offline: Firestore ya lo resuelve — no hace falta outbox propio

**Este es el cambio más importante frente al plan que se había hecho para
Supabase.** Ahí se había diseñado un "outbox" manual en Hive porque
Postgres/PostgREST no ofrece persistencia offline nativa. **Firestore sí
la trae de fábrica**: con `FirebaseFirestore.instance.settings =
Settings(persistenceEnabled: true)` (ya es el default en móvil), el SDK:

- Cachea todas las lecturas localmente.
- Deja escribir (`set`/`update`/`delete`) aunque no haya red: la
  operación se aplica de inmediato al caché local (la UI la ve al
  instante, optimista) y queda encolada.
- Reenvía la cola sola en cuanto vuelve la conexión, en orden, sin que la
  app tenga que detectar reconexión ni implementar reintentos.

Aplicado a la pregunta original ("si agrego un amigo sin internet, ¿se
mapea y se le avisa después?"): con Firestore, `sendAllyRequest()` hace
el `set()` normal en `allyRequests` sin ninguna rama especial para
offline — si no hay red, Firestore lo encola solo; en cuanto el receptor
tenga conexión, su `snapshots()` (o la Cloud Function `onAllyRequestUpdate`
más su propio listener) dispara igual, sin importar cuánto tiempo estuvo
offline el remitente. El diseño de outbox manual documentado para
Supabase queda obsoleto — Firestore ya es ese outbox.

Lo único que sigue haciendo falta del lado de la app:

- `local_storage_service.dart`/Hive puede retirarse una vez migrado todo
  a Firestore (el propio SDK de Firestore ya cachea en disco), o
  mantenerse como fallback de arranque ultra-rápido antes de que el
  primer snapshot de Firestore llegue — decisión de producto, no
  necesidad técnica.
- Un indicador visual opcional de "sincronizando" usando
  `metadata.hasPendingWrites` del snapshot de Firestore (reemplaza el
  badge "pendiente de sincronizar" que se había diseñado a mano para el
  outbox de Supabase).

## 5. Fases sugeridas

1. **Fase 0 (este PR)**: colecciones + Security Rules + Cloud Functions +
   documentación, sin tocar Dart todavía.
2. **Fase 1 (hecha)**: `firebase_core`, `firebase_auth` y `cloud_firestore`
   están en `pubspec.yaml`; `lib/firebase_options.dart` ya tiene las claves
   reales del proyecto `rachatribu` (generadas con `flutterfire configure`);
   `main.dart` inicializa Firebase (con caída elegante a modo local si
   falla); y `HomeLogic.completeOnboarding()` se autentica de forma anónima,
   usa el `uid` como playerId, y escribe/actualiza el perfil en
   `users/{uid}` (`_saveFirestoreProfile`, con `merge: true` y sin tumbar el
   onboarding si la escritura falla). `HomeLogic` sigue usando
   `LocalHabitRepository`/Hive para círculos, check-ins, aliados y el feed
   de actividad — eso es la Fase 2 en adelante.
3. **Fase 2 (en progreso — escritura + primera lectura)**: `HabitCircle`
   ya tiene un `id` estable (antes no existía ningún identificador
   persistente; se generó y se agregó a `toMap`/`fromMap` con el mismo
   patrón de fallback que `AppUser.playerId`). `createCircle()` y
   `toggleCheckIn()` ya espejan el círculo y el check-in del día hacia
   Firestore (`circles/{id}`, `circles/{id}/members/{uid}` como dueño,
   `circles/{id}/checkIns/{uid}_{fecha}`) de forma fire-and-forget: si
   falla (sin red, reglas desactualizadas), el círculo sigue funcionando
   100% local en Hive sin que el usuario note nada.

   Ya hay una primera lectura real: `HomeLogic._watchCircleCheckIns()` se
   suscribe con `snapshots()` a los check-ins de **hoy** de cada círculo
   (`circles/{id}/checkIns`, filtrado por `date`) y, cuando detecta un
   documento con un `userId` distinto al propio, empuja un evento al feed
   de actividad ("Un miembro de X completó su hábito hoy") — así la tribu
   deja de ser 100% simulada en el feed. A propósito **no** toca
   `streakDays`/`constancyDropsEarned`/`isPerfect`: esos siguen
   calculándose 100% en el cliente sobre los check-ins propios en Hive, no
   sobre `memberStats` (que requeriría además desplegar las Cloud
   Functions de `functions/src/`) — mezclar check-ins remotos de otros
   `uid` directamente en `HabitCircle.checkIns` (que hoy representa solo
   los check-ins del usuario del dispositivo) rompería esos cálculos, así
   que esa unificación queda para cuando se desplieguen las Cloud
   Functions y `memberStats` sea la fuente de verdad compartida.

   Pendiente de esta fase: decidir si se despliegan las Cloud Functions
   (plan Blaze) o se sigue calculando todo en el cliente (ver sección 0);
   si se despliegan, migrar `completedMembers`/`isPerfect`/progreso del
   día a leer de `memberStats` en vez de simular miembros locales.
4. **Fase 3 (hecha — solicitudes de aliado reales)**: `sendAllyRequest()`
   busca el `uid` dueño del username en `users` (query por campo, sin
   Cloud Function) y escribe `allyRequests/{miUid}_{suUid}` con
   `status: 'pending'`. `HomeLogic._watchIncomingAllyRequests()` /
   `_watchOutgoingAllyRequests()` se suscriben con `snapshots()` a
   `allyRequests` (`toUserId == uid` y `fromUserId == uid`
   respectivamente) para reflejar en vivo lo que pase en el otro
   dispositivo: una solicitud pendiente nueva aparece en
   `pendingAllyRequests`, y una aceptada agrega al instante al aliado en
   ambos lados. `acceptAllyRequest()`/`rejectAllyRequest()` actualizan el
   `status` del documento real además de su efecto local de siempre. El
   escaneo de QR (`addAllyFromScannedCode`) ya usaba el `uid` real como
   playerId desde la Fase 1; ahora además escribe la solicitud
   directamente con `status: 'accepted'` (el escaneo presencial ya es la
   prueba de confianza, no hace falta un paso pendiente) para que el
   otro dispositivo también reciba el aliado.

   Si no hay sesión de Firebase, cae al modo simulado anterior (solicitud
   local inmediata en el mismo dispositivo) para no perder la demo
   sin backend. Pendiente: el canje de `inviteCode` vía la Cloud Function
   callable `redeemInviteCode` para unirse a un círculo por código (hoy
   `addMemberToCircle` sigue siendo 100% simulado) — depende de la
   decisión de Blaze/Cloud Functions de la sección 0.
5. **Fase 4 (hecha — feed de actividad de círculo compartido)**: los
   eventos de un círculo (check-in, hito, escudo usado) ya no los redacta
   cada dispositivo por separado a partir de datos que observa (así
   funcionaba desde la Fase 2, con el riesgo de que cada quien viera un
   texto distinto). Ahora `HomeLogic._recordCircleActivity()` los escribe
   una sola vez, directo desde el cliente que hizo la acción, en
   `circles/{id}/activityEvents` (ruta sin Cloud Functions — plan Spark,
   ver sección 0), y `_watchCircleActivityEvents()` los lee con
   `snapshots()` para que **todos** los miembros del círculo vean el mismo
   evento, incluido quien lo generó (el propio caché optimista de
   Firestore se lo devuelve casi al instante). `ActivityEvent` gana un
   `id` (= ID del documento) para no duplicar un evento que Firestore
   reenvíe al reconectar. `firestore.rules` para `activityEvents` pasó de
   `write: if false` a `create: if isCircleMember(...) && actorId ==
   auth.uid` — si más adelante se despliegan las Cloud Functions de
   `functions/src/index.ts`, hay que revertir esa regla a `write: if
   false` y quitar estos writes de Dart (los pondría el trigger).

   `_pushActivityEvent` (feed 100% local en Hive) se mantiene como
   respaldo para cuando no hay sesión de Firebase, y para los eventos que
   no son de un círculo (aliados, miembros simulados vía
   `addMemberToCircle`) — esos siguen siendo locales a propósito, ver sus
   propios doc-comments.
6. **Fase 5 (hecha — decisión: Hive se queda como fallback)**: Hive
   **no** se retira. Sigue siendo la fuente de verdad que arranca la app
   al instante (incluso en la primerísima apertura sin red, antes de que
   exista cualquier caché de Firestore) y el respaldo si Firebase no
   está disponible — todo el código de esta migración ya está escrito
   sobre esa premisa (ver doc-comments de `_mirrorCircleCreation`,
   `_mirrorCheckIn`, `_mirrorActivityEvent`, `sendAllyRequest`, etc.: cada
   escritura a Firestore es fire-and-forget, nunca bloquea ni reemplaza
   el guardado local). Retirarlo ataría la app por completo a tener una
   sesión de Firestore ya sincronizada, perdiendo la garantía de "100%
   funcional offline" que tiene hoy.

   El "outbox manual" que motivaba originalmente esta fase nunca llegó a
   construirse (sección 4 ya explica por qué no hacía falta), así que no
   queda nada que retirar ahí tampoco.

   Con esto, las Fases 1–5 de este plan quedan completas. Lo único
   pendiente de todo el documento sigue siendo la decisión de la
   sección 0 (Blaze/Cloud Functions vs. cálculo 100% cliente) y, si se
   opta por Blaze, migrar `completedMembers`/`isPerfect`/racha/gotas a
   leer de `memberStats` en vez de los cálculos locales actuales.

Cada fase deja la app funcional y testeable de punta a punta antes de
empezar la siguiente.

## 6. Qué NO cambia

- El contrato `HomeLogic` (ChangeNotifier) → UI no cambia.
- `HabitCircle`, `CheckIn`, `Milestone`, `ActivityEvent`, `AllyRequest`
  siguen siendo los modelos Dart de la UI; solo cambia de dónde los llena
  el repositorio (antes: `fromMap` de Hive; ahora: `fromMap` adaptado a
  `DocumentSnapshot.data()`).
