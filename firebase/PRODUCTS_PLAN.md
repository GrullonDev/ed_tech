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

## 3. Remote Config (`firebase_remote_config`)

**Qué da**: parámetros configurables desde la consola sin publicar una
nueva versión de la app — y es el requisito técnico de A/B Testing (un
experimento de A/B Testing "es" una asignación aleatoria de usuarios a
distintos valores de un parámetro de Remote Config).

**Candidatos de parámetros para esta app** (todos ya tienen su valor
"hardcoded" hoy, se volverían configurables):

| Parámetro | Hoy vive en | Valor por defecto |
|---|---|---|
| `constancy_drops_base` / `_tier2` / `_tier3` | `HabitCircle._dropsForStreakDay` | 10 / 15 / 20 / 30 |
| `streak_shield_milestones` | `Milestone.targets` | 7, 21, 30, 50, 100 |
| `onboarding_headline` | copy fija en la pantalla de onboarding | texto actual |

**Cómo se integra**:

```dart
// pubspec.yaml
firebase_remote_config: ^5.x

// Al iniciar (main.dart o primer uso en HomeLogic), con defaults locales
// para que la app funcione igual si no hay red la primera vez:
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.setConfigSettings(RemoteConfigSettings(
  fetchTimeout: const Duration(seconds: 5),
  minimumFetchInterval: const Duration(hours: 1),
));
await remoteConfig.setDefaults({'constancy_drops_tier2': 15, ...});
await remoteConfig.fetchAndActivate(); // fire-and-forget, con try/catch
```

`HabitCircle._dropsForStreakDay` pasaría de constantes fijas a leer
`FirebaseRemoteConfig.instance.getInt(...)` con el valor actual como
fallback si Remote Config no llegó a sincronizar — mismo patrón
fire-and-forget que el resto de la integración de Firebase.

## 4. A/B Testing

No es un package aparte: una vez Remote Config está integrado (sección
3), un experimento de A/B Testing se crea **desde la consola de
Firebase**, no desde código — se elige un parámetro de Remote Config
(por ejemplo `constancy_drops_tier2`), se definen 2+ variantes de su
valor, y Firebase reparte usuarios entre variantes automáticamente,
usando Analytics (ya integrado) para medir qué variante retiene mejor.

**Primer experimento sugerido**: variar `constancy_drops_tier2` (15 vs.
20 vs. 25) y medir impacto en `check_in` diario por usuario (evento de
Analytics que ya se registra desde la Fase 4 de `MIGRATION_PLAN.md`) —
es la palanca de gamificación más directa para probar si más
recompensa = más constancia.

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

## 6. Authentication — de anónimo a cuenta real — Hecho (Google + email); teléfono pendiente

Hoy el onboarding usa `signInAnonymously()` (Fase 1 de
`MIGRATION_PLAN.md`) — no hay contraseña ni forma de recuperar la cuenta
si se desinstala la app o se cambia de dispositivo. El camino elegido
para no perder el `uid` actual (y por lo tanto sin perder
círculos/aliados/racha ya asociados a ese `uid`) es `linkWithCredential`,
igual que proponía este documento.

**Decisión de dónde ofrecerlo**: opcional, desde el perfil — el
onboarding actual (solo username + `signInAnonymously()`) **no cambió en
nada**. `ProfilePage` muestra una sección "Asegura tu cuenta" solo
mientras `HomeLogic.isAnonymousAccount` sea `true`, con un botón por
proveedor todavía no vinculado (`HomeLogic.linkedProviderIds`). Se eligió
esta opción (sobre agregar un paso al onboarding) porque es cero riesgo
para el flujo de entrada de usuarios nuevos, que sigue siendo de una sola
pantalla.

**Estado**:

- **Google — Hecho**: `pubspec.yaml` agrega `google_sign_in`;
  `HomeLogic.linkWithGoogle()` abre el selector de cuentas nativo y
  vincula con `linkWithCredential`. Si el usuario cancela el selector, no
  es error (retorna `null` igual que un éxito silencioso). Si esa cuenta
  de Google ya está vinculada a *otro* usuario de Firebase
  (`credential-already-in-use`), se muestra un mensaje claro en vez de
  fallar en silencio — **a propósito no se intenta fusionar los datos de
  ambas cuentas** (mover círculos/aliados de un `uid` a otro en Firestore
  es una operación de datos bastante más delicada, fuera de este cambio).
- **Email/contraseña — Hecho**: `HomeLogic.linkWithEmailPassword(email, password)`
  valida formato mínimo en el cliente y vincula con
  `EmailAuthProvider.credential` + `linkWithCredential`, con mensajes de
  error específicos por código (`email-already-in-use`, `invalid-email`,
  `weak-password`).
- **Teléfono (SMS) — pendiente, a propósito no se tocó**: mayor
  complejidad (verificación por reCAPTCHA/Play Integrity en Android,
  push silencioso vía APNs en iOS) y costo (SMS fuera de la capa
  gratuita) que las otras dos, y no se puede probar de punta a punta
  desde este entorno. Queda para cuando haya oportunidad de probarlo en
  un dispositivo real.

**Pasos manuales pendientes para que funcione en dispositivo** (ninguno
es código; ninguno se pudo verificar desde este entorno):

- **Android**: registrar el SHA-1 (y SHA-256 para Play App Signing) del
  certificado de firma en la consola de Firebase (Configuración del
  proyecto → tu app Android → Agregar huella digital) — sin esto, Google
  Sign-In falla en runtime aunque el código esté bien. Con la firma debug
  actual (`android/app/build.gradle.kts`, "Signing with the debug keys
  for now"), es el SHA-1 de esa keystore de debug.
- **iOS**: agregar un `CFBundleURLTypes`/`CFBundleURLSchemes` a
  `ios/Runner/Info.plist` con el `REVERSED_CLIENT_ID` del
  `GoogleService-Info.plist` real (ver nota de este mismo archivo que
  falta, sección 1) — sin esto, Google Sign-In no puede volver a la app
  tras el login. `ios/Runner/Info.plist` hoy no tiene ningún
  `CFBundleURLTypes` — confirmado al revisar el archivo.
- **Consola de Firebase**: habilitar los proveedores Google y
  Email/contraseña en Authentication → Sign-in method, si no están ya
  habilitados (`signInAnonymously()` solo necesita el proveedor
  Anónimo, que sí está activo desde la Fase 1).

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
