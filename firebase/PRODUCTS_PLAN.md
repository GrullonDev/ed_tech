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

## 1. Crashlytics (`firebase_crashlytics`) — Hecho

**Qué da**: reportes de crash con stack trace, agrupados por causa, con
el la versión de build y el % de usuarios "crash-free" por release (la
vista de "Latest Release" que se ve en la consola).

**Estado**: integrado. `pubspec.yaml` agrega `firebase_crashlytics`;
`main.dart._initCrashlytics()` conecta `FlutterError.onError` y
`PlatformDispatcher.instance.onError`, con `setCrashlyticsCollectionEnabled(!kDebugMode)`
para no generar ruido en desarrollo local — solo se llama tras un
`Firebase.initializeApp()` exitoso, dentro del mismo try/catch de
`_initFirebase()`, así que un fallo ahí sigue sin tumbar la app (modo
100% local). Android: se agregó el plugin de Gradle
`com.google.firebase.crashlytics` en `android/settings.gradle.kts` y
`android/app/build.gradle.kts` (mismo patrón que `google-services`),
necesario para subir símbolos de crashes nativos/NDK. **Falta activar
Crashlytics para el proyecto `rachatribu` en la consola de Firebase**
(Release Monitoring → Crashlytics → habilitar) si todavía no está
activo — sin eso, la app manda los reportes pero la consola no los
muestra.

**iOS**: no necesitó cambios de proyecto Xcode para el reporte
Dart-level — `Firebase.initializeApp` ya usa `DefaultFirebaseOptions.currentPlatform`
(`lib/firebase_options.dart`) de forma 100% programática, así que
Crashlytics debería arrancar igual aunque `ios/Runner` no tenga un
`GoogleService-Info.plist` commiteado (hoy no lo tiene). Para una prueba
completa en dispositivo real, igual conviene:

1. Descargar el `GoogleService-Info.plist` real desde la consola de
   Firebase (Configuración del proyecto → app iOS, bundle id
   `com.example.edtechTiktok`) y agregarlo a `ios/Runner` desde Xcode
   ("Copy items if needed" + target membership en Runner) — es lo que
   el SDK nativo espera por convención.
2. Opcional, solo para symbolicar crashes nativos/NDK de iOS: agregar
   el Run Script Phase `${PODS_ROOT}/FirebaseCrashlytics/run` en Xcode.
   El reporte de crashes Dart-level ya funciona sin este paso.
3. `flutter build ios`/`flutter run` en un Mac corre `pod install` solo
   y trae `FirebaseCrashlytics` — no hace falta tocar el Podfile a mano
   (no está commiteado en este repo, es normal en proyectos Flutter).

Ninguno de los 3 pasos requiere Xcode GUI para que Crashlytics *empiece*
a reportar (la inicialización Dart ya cubre lo básico), pero si algo no
aparece en la consola durante la prueba en dispositivo, este es el
primer lugar a revisar. No pude verificar nada de esto desde este
entorno (no hay Mac/Xcode) — ver plan de pruebas más abajo.

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

## 2. Performance Monitoring (`firebase_performance`) — Hecho

**Qué da**: tiempos de arranque de la app, duración de las pantallas, y
"custom traces"/"metrics" para medir operaciones puntuales (por ejemplo,
cuánto tarda `_watchCircleActivityEvents` en recibir su primer snapshot).

**Estado**: integrado. `pubspec.yaml` agrega `firebase_performance`;
`main.dart._initPerformanceMonitoring()` llama
`FirebasePerformance.instance.setPerformanceCollectionEnabled(!kDebugMode)`
dentro del mismo try/catch de `_initFirebase()` (fire-and-forget, no
cambia contrato de `HomeLogic` hacia la UI). Arranque de app y HTTP se
miden automáticamente solo con agregar el package. Se agregó el primer
trace manual sugerido, `circle_creation`, envolviendo
`HomeLogic._mirrorCircleCreation` (con `trace.stop()` en un `finally`
para que no quede colgado si falla por falta de red). Android: se agregó
el plugin de Gradle `com.google.firebase.firebase-perf` en
`android/settings.gradle.kts` y `android/app/build.gradle.kts` (mismo
patrón que `google-services`/Crashlytics), recomendado para
instrumentación automática de red en Android. **iOS no necesitó ningún
plugin ni cambio de proyecto Xcode**: la instrumentación automática de
red en iOS se hace por method swizzling dentro del propio SDK nativo de
`firebase_performance`, sin el paso de bytecode-instrumentation que sí
hace falta en Android — alcanza con que CocoaPods instale el pod
`FirebasePerformance` (automático la primera vez que se corra `flutter
build ios`/`flutter run` en un Mac, ver nota de `GoogleService-Info.plist`
en la sección 1). **Falta activar Performance Monitoring para
`rachatribu` en la consola** si no está ya activo, y agregar más traces
manuales puntuales (2-3) si más adelante hace falta diagnosticar algo
lento en particular — se dejó solo el ejemplo del plan para no ensanchar
el cambio de más.

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

## 5. Analytics — qué falta más allá de lo ya integrado — Hecho (código); falta 1 paso en consola

Ya hay eventos (`onboarding_complete`, `circle_created`, `check_in`,
`perfect_circle`, `milestone_reached`, `ally_request_sent`,
`ally_request_accepted`) y pantallas automáticas vía
`FirebaseAnalyticsObserver`. Para aprovechar mejor el dashboard:

- **User properties — Hecho**: `HomeLogic._updatePrimaryCategoryUserProperty()`
  llama `FirebaseAnalytics.instance.setUserProperty(name: 'primary_category', value: ...)`
  con la categoría de círculo más usada por el usuario (por cantidad de
  círculos en esa categoría; empate lo gana la primera creada), para
  poder segmentar el dashboard por tipo de hábito (fitness, estudio,
  etc.). Se recalcula en `_loadFromStorage()` (arranque) y `createCircle()`
  (cada círculo nuevo) — fire-and-forget, mismo criterio que el resto de
  Analytics.
- **`ally_request_sent`/`ally_request_accepted` — Hecho**: ambos eventos
  ahora llevan el parámetro `via` (`'username'` vs `'qr'`).
  `sendAllyRequest` manda `via: 'username'` (es el único flujo de
  invitación por username); `acceptAllyRequest` (aceptar una solicitud
  pendiente) manda `ally_request_accepted` con `via: 'username'`;
  `addAllyFromScannedCode` (agregar de una al escanear un QR, sin pasar
  por solicitud pendiente) ahora también manda `ally_request_accepted`,
  con `via: 'qr'` — antes este flujo no registraba ningún evento de
  Analytics.
- **Evento de conversión — falta un paso manual en la consola** (no es
  código): marcar `onboarding_complete` como evento de conversión en la
  consola (Analytics → Eventos → marcar como conversión) para que
  aparezca en reportes de embudo. Es además la métrica que usa el primer
  experimento de A/B Testing sugerido en la sección 4 — hacerlo ahí
  desbloquea las dos cosas a la vez.

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
