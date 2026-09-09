# Plan: resto de productos de Firebase para Racha Tribu

Hoy la app usa `firebase_core`, `firebase_auth` (anónimo), `cloud_firestore`
y `firebase_analytics`. Este documento cubre el resto de accesos directos
que aparecen en la consola de `rachatribu` (Authentication y Firestore ya
integrados, se listan solo para contexto): **Release Monitoring** (Crashlytics
+ Performance Monitoring), **A/B Testing** (sobre Remote Config), y
**Analytics Dashboard** (expandir lo que ya hay). "Latest Release" no es un
producto aparte: es una vista dentro de Crashlytics/Performance que agrupa
por versión de build (`FLUTTER_BUILD_NAME`), así que queda cubierta por
Release Monitoring.

Mismo criterio que en `MIGRATION_PLAN.md`: cada producto se integra sin que
la app deje de funcionar 100% offline si Firebase no está disponible — todo
best-effort, fire-and-forget, nunca bloqueante.

## 0. Orden recomendado

1. **Crashlytics** — el de mayor valor inmediato con menor riesgo: solo
   reporta, no cambia comportamiento visible de la app.
2. **Performance Monitoring** — mismo perfil de riesgo que Crashlytics,
   se agrega junto porque ambos viven bajo "Release Monitoring".
3. **Remote Config** — requisito técnico para A/B Testing.
4. **A/B Testing** — se configura en la consola sobre los parámetros que
   ya expone Remote Config; no agrega package nuevo.
5. **Analytics** — no requiere trabajo de "integración" (ya está desde la
   Fase 1/Analytics), esta sección lista qué falta para aprovecharlo mejor
   (user properties, conversión definida).
6. **Authentication** (upgrade de anónimo a cuenta real) — el más
   delicado de todos porque toca el flujo de onboarding; se deja al final
   y como opcional/futuro, no por prioridad técnica sino porque es el que
   más cambia la experiencia del usuario y merece decidirse aparte.

## 1. Crashlytics (`firebase_crashlytics`)

**Qué da**: reportes de crash con stack trace, agrupados por causa, con
el la versión de build y el % de usuarios "crash-free" por release (la
vista de "Latest Release" que se ve en la consola).

**Cómo se integra** (patrón ya usado en `main.dart` para Firebase Core: si
falla, la app sigue funcionando):

```dart
// pubspec.yaml
firebase_crashlytics: ^4.x

// main.dart, dentro de _initFirebase() tras Firebase.initializeApp():
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

No hace falta ningún cambio en `HomeLogic` ni en la UI. Único cuidado:
en modo debug, Crashlytics viene deshabilitado por defecto en algunos
setups — confirmar `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode)`
si se quiere evitar ruido de crashes durante desarrollo local.

**Nada que decidir de producto**: es puramente instrumentación.

## 2. Performance Monitoring (`firebase_performance`)

**Qué da**: tiempos de arranque de la app, duración de las pantallas, y
"custom traces"/"metrics" para medir operaciones puntuales (por ejemplo,
cuánto tarda `_watchCircleActivityEvents` en recibir su primer snapshot).

**Cómo se integra**:

```dart
// pubspec.yaml
firebase_performance: ^0.10.x

// Automático: HTTP y arranque de red se miden solos al agregar el
// package. Traces manuales opcionales, por ejemplo en HomeLogic:
final trace = FirebasePerformance.instance.newTrace('circle_creation');
await trace.start();
// ... _mirrorCircleCreation(circle) ...
await trace.stop();
```

Igual que Crashlytics, no cambia contrato de `HomeLogic` hacia la UI —
se puede agregar de forma incremental, empezando sin traces manuales
(las automáticas ya dan valor) y agregando 2-3 traces puntuales después
si hace falta diagnosticar algo lento en particular.

## 3. Remote Config (`firebase_remote_config`) — Hecho (parcial, a propósito)

**Qué da**: parámetros configurables desde la consola sin publicar una
nueva versión de la app — y es el requisito técnico de A/B Testing (un
experimento de A/B Testing "es" una asignación aleatoria de usuarios a
distintos valores de un parámetro de Remote Config).

**Candidatos de parámetros para esta app** (todos ya tienen su valor
"hardcoded" hoy, se volverían configurables):

| Parámetro | Hoy vive en | Valor por defecto | Estado |
|---|---|---|---|
| `onboarding_headline` | copy fija en la pantalla de onboarding | texto actual | **Hecho** |
| `constancy_drops_base` / `_tier2` / `_tier3` | `HabitCircle._dropsForStreakDay` | 10 / 15 / 20 / 30 | Pendiente, a propósito |
| `streak_shield_milestones` | `Milestone.targets` | 7, 21, 30, 50, 100 | Pendiente, a propósito |

**Estado de la infraestructura**: integrada. `pubspec.yaml` agrega
`firebase_remote_config`; `main.dart._initRemoteConfig()` configura
`fetchTimeout: 5s` / `minimumFetchInterval: 1h`, declara los defaults
locales y llama `fetchAndActivate()` — todo dentro del mismo try/catch
best-effort de `_initFirebase()`, así que un fallo (sin red, Firebase no
configurado) deja la app viéndose exactamente igual que antes. Se
implementó el primer parámetro, `onboarding_headline`
(`Onboarding._headline()`, con `Onboarding.defaultHeadline` como
fallback si Remote Config no activó a tiempo o Firebase no está
disponible — envuelto en su propio try/catch porque es la primera
pantalla que ve un usuario nuevo).

**Por qué `constancy_drops_*` y `streak_shield_milestones` quedan
pendientes a propósito**: a diferencia del titular de onboarding (puro
copy, sin lógica), estos dos valores están **duplicados y hardcodeados
también en el servidor** — `functions/src/streakLogic.ts`
(`computeDropsEarned`/`SHIELD_MILESTONES`) usa exactamente los mismos
números para calcular `circles/{id}/memberStats/{uid}` (racha/gotas/
escudos "de verdad", ver Fase 6 de `MIGRATION_PLAN.md`). Volver
Remote-Config-only el lado del cliente sin tocar la Cloud Function
crearía el mismo riesgo de desincronización que el diseño de
`memberStats` (sección 7 de `MIGRATION_PLAN.md`) fue pensado para
evitar: un experimento de A/B Testing que cambie `constancy_drops_tier2`
en el cliente mostraría un número de gotas que el servidor nunca
otorgó. Hacerlo bien requiere: (a) mover esos valores a Remote Config
también en la Cloud Function (que sí puede leer Remote Config desde el
Admin SDK), o (b) aceptar que el servidor sea la fuente de verdad y que
el cliente ignore el valor de Remote Config para estos dos parámetros
específicos una vez llegue `remoteDropsEarned`/etc. Cualquiera de las
dos es una decisión de producto/arquitectura que amerita su propio
PR — se deja fuera de este cambio para no ensancharlo ni introducir un
desface visible en la racha del usuario.

## 4. A/B Testing — sin código, 100% consola (guía para correr el primero)

No es un package aparte ni requiere ningún cambio en este repo: una vez
Remote Config está integrado (sección 3, ya hecho), un experimento de
A/B Testing se crea **desde la consola de Firebase** — se elige un
parámetro de Remote Config, se definen 2+ variantes de su valor, y
Firebase reparte usuarios entre variantes automáticamente, usando
Analytics (ya integrado) para medir qué variante se comporta mejor
contra una métrica objetivo.

**Primer experimento recomendado ahora mismo**: `onboarding_headline`
(el único parámetro que ya está implementado, ver sección 3), midiendo
impacto en el evento de conversión `onboarding_complete` (ya se
registra desde la Fase 4 de `MIGRATION_PLAN.md` — falta solo marcarlo
como "evento de conversión" en la consola, ver sección 5 más abajo).
Sin código nuevo: la app ya lee `onboarding_headline` de Remote Config
(`Onboarding._headline()`) y ya manda el evento; falta únicamente
crearlo en la consola.

**Pasos** (consola de Firebase, proyecto `rachatribu`):

1. Remote Config → confirmar que existe el parámetro `onboarding_headline`
   (se crea solo la primera vez que la app corre con esta versión y
   hace `fetchAndActivate`, pero también se puede crear a mano con el
   valor por defecto `Bienvenido a\nRacha Tribu` si preferís adelantarte).
2. A/B Testing → Crear experimento → "Remote Config experiment".
3. Nombre del experimento (por ejemplo `onboarding_headline_v1`),
   audiencia 100% de usuarios (o un % si preferís arrancar chico).
4. Parámetro objetivo: `onboarding_headline`. Definir 2-3 variantes de
   texto (el "Control" ya usa el valor actual/por defecto automáticamente
   — no hace falta declararlo aparte).
5. Métrica principal: `onboarding_complete` (una vez marcado como
   evento de conversión, sección 5) — Firebase reparte tráfico y
   muestra cuál variante convierte más onboardings completados por
   usuario que vio la pantalla.
6. Iniciar el experimento y dejarlo correr el tiempo que la consola
   recomiende (Firebase avisa cuándo hay significancia estadística).

**Sobre `constancy_drops_tier2` (el candidato "de gamificación" más
obvio)**: **todavía no se puede experimentar con este** de forma
segura — ver el detalle en la sección 3 ("Por qué `constancy_drops_*` y
`streak_shield_milestones` quedan pendientes a propósito"). Como ese
valor también está hardcodeado en `functions/src/streakLogic.ts` para
calcular `memberStats` en el servidor, un experimento de A/B Testing
que lo varíe en el cliente le mostraría a una parte de los usuarios un
número de "Gotas de Constancia" que el servidor nunca les otorgó
realmente — hay que resolver esa duplicación primero (moverla también a
Remote Config del lado de la Cloud Function, vía Admin SDK) antes de
correr este experimento. Queda como el candidato natural para *después*
de esa migración, no para ahora.

## 5. Analytics — qué falta más allá de lo ya integrado

Ya hay eventos (`onboarding_complete`, `circle_created`, `check_in`,
`perfect_circle`, `milestone_reached`, `ally_request_sent`,
`ally_request_accepted`) y pantallas automáticas vía
`FirebaseAnalyticsObserver`. Para aprovechar mejor el dashboard:

- **User properties**: `FirebaseAnalytics.instance.setUserProperty(name: 'primary_category', value: ...)` 
  con la categoría de círculo más usada por el usuario, para poder
  segmentar el dashboard por tipo de hábito (fitness, estudio, etc.).
- **Evento de conversión definido**: marcar `onboarding_complete` como
  evento de conversión en la consola (Analytics → Eventos → marcar como
  conversión) para que aparezca en reportes de embudo sin código nuevo.
- **`ally_request_sent`/`ally_request_accepted`**: agregar el parámetro
  `via` (`'username'` vs `'qr'`) para saber qué canal de invitación
  funciona mejor — ya se sabe cuál fue en `sendAllyRequest`/
  `addAllyFromScannedCode`, solo falta pasarlo al evento existente.

## 6. Authentication — de anónimo a cuenta real (opcional, a futuro)

Hoy el onboarding usa `signInAnonymously()` (Fase 1 de
`MIGRATION_PLAN.md`) — no hay contraseña ni forma de recuperar la cuenta
si se desinstala la app o se cambia de dispositivo. La consola de
Firebase ofrece Google/email/teléfono; el camino sin perder el `uid`
actual (y por lo tanto sin perder círculos/aliados/racha ya asociados a
ese `uid`) es `linkWithCredential`:

```dart
final googleCredential = ...; // via google_sign_in
await FirebaseAuth.instance.currentUser!.linkWithCredential(googleCredential);
```

Esto **no** se recomienda hacer ahora: cambia el flujo de onboarding
(agregar un botón "Vincular con Google" en el perfil, manejar el caso de
`credential-already-in-use` si el usuario ya tiene otra cuenta con ese
Google), y el valor principal es "no perder tu progreso si cambias de
teléfono" — un problema real pero no urgente mientras la base de
usuarios sea de prueba. Se deja documentado como el siguiente paso
natural de Authentication cuando haya usuarios reales a los que les
importe no perder su cuenta.

## 7. Qué NO se incluye en este plan

- **App Distribution**: es una herramienta de distribución de builds
  entre testers (equivalente a TestFlight), no algo que la app "use" en
  runtime — no requiere código, solo configurar `firebase appdistribution:distribute`
  en el pipeline de build si se quiere automatizar el reparto de APKs.
  Fuera del alcance de este documento (es proceso de equipo, no
  arquitectura de la app).
- **Cloud Messaging (push notifications)**: no estaba entre los accesos
  directos mostrados, pero es la integración natural si más adelante se
  quiere avisar "tu aliado hizo check-in" o recordatorios de racha en
  riesgo — se deja fuera de este plan hasta que se pida explícitamente,
  ya que agrega superficie nueva (permisos de notificación, tokens FCM)
  no cubierta por las capturas de pantalla que motivaron este documento.
