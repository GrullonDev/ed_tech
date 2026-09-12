# App Distribution: cómo generar builds de prueba (Android + iOS)

Objetivo puntual: tener una build de Android y otra de iOS en manos de un
dispositivo real, para poder probar Crashlytics/Performance Monitoring
(`firebase/PRODUCTS_PLAN.md`, secciones 1 y 2) fuera de un emulador/debug.
App Distribution en sí queda fuera del alcance de `PRODUCTS_PLAN.md`
(sección 7: "es proceso de equipo, no arquitectura de la app"), pero
armar el camino para generar y subir builds sí tiene sentido como parte
de poder probar el resto del plan.

## Android: automatizado (GitHub Actions)

`.github/workflows/app-distribution-android.yml` compila un APK release
(firmado con las claves de debug — mismo criterio que ya usa
`android/app/build.gradle.kts`, "Signing with the debug keys for now, so
`flutter run --release` works"; para Play Store hará falta una key real
más adelante, pero para probar en un dispositivo de prueba vía App
Distribution alcanza) y lo sube a Firebase App Distribution.

Se dispara solo con **cada push a `develop`** (build automática, sin que
nadie tenga que acordarse de correrla), y también se puede correr a mano
desde GitHub → Actions → "Android → Firebase App Distribution" → Run
workflow cuando se quieren notas de release específicas.

### Configuración de una sola vez

1. **Cuenta de servicio de Google Cloud** (reemplaza a `firebase login:ci`,
   que Google está deprecando):
   - Consola de Google Cloud del proyecto `rachatribu` → IAM y
     administración → Cuentas de servicio → Crear cuenta de servicio.
   - Nombre sugerido: `github-actions-app-distribution`.
   - Rol: **Firebase App Distribution Admin** (buscar ese nombre exacto
     en el selector de roles).
   - Crear una clave JSON para esa cuenta (Acciones → Administrar
     claves → Agregar clave → JSON) y descargarla.
2. **Grupo de testers en Firebase App Distribution**:
   - Consola de Firebase (`rachatribu`) → Release & Monitor → App
     Distribution → pestaña "Testers y grupos" → crear un grupo (por
     ejemplo `testers`) y agregar los emails de quienes van a probar
     (incluido el tuyo).
3. **Secrets del repo** (GitHub → `GrullonDev/ed_tech` → Settings →
   Secrets and variables → Actions → New repository secret):
   - `FIREBASE_SERVICE_ACCOUNT_JSON`: pegar el contenido completo del
     JSON descargado en el paso 1.
   - `FIREBASE_APP_DISTRIBUTION_GROUPS`: el alias del grupo del paso 2
     (por ejemplo `testers`; varios grupos separados por coma).

### Uso

Automático: cada push a `develop` (mergear un PR incluido) dispara una
build sola y la sube. Manual: GitHub → pestaña Actions → "Android →
Firebase App Distribution" → Run workflow → (opcional) escribir notas de
la release → Run workflow. En ambos casos, los testers del grupo reciben
un email con el link para instalar el APK desde la app de Firebase App
Distribution (o directo el APK) en su dispositivo.

### Número de build automático

El build number (lo que se ve entre paréntesis en la lista de releases
de App Distribution, ej. "1.0.3 (7)") ya no depende de editar
`version: X.Y.Z+BUILD` a mano en `pubspec.yaml` antes de cada release —
el workflow lo pasa con `--build-number=${{ github.run_number }}`,
el contador de corridas de GitHub Actions para este workflow (nunca se
repite ni retrocede, sin importar si la corrida fue automática o
manual). El `X.Y.Z` de `pubspec.yaml` sigue siendo una decisión manual
— es la versión "semántica" que sí elige una persona.

### Firma consistente entre builds

`android/app/debug.keystore` es un keystore de debug **fijo, commiteado**
(no el que Android autogenera por máquina en `~/.android/debug.keystore`).
Sin esto, cada corrida de CI en un runner efímero firmaba con una clave
nueva y aleatoria, y el tester no podía instalar un release nuevo encima
del anterior ("Installation failed" — Android rechaza un APK cuya firma
no coincide con la ya instalada). Ahora todas las builds (CI y locales)
usan la misma clave, así que las actualizaciones se instalan encima sin
problema. Es debug-only, no protege nada sensible: es seguro tenerlo en
el repo. Si de todas formas un tester ya tiene una instalación previa
firmada con una clave distinta (de antes de este cambio, o de un
`flutter run` local), tiene que desinstalar esa versión una vez antes de
poder instalar la siguiente.

### Avisar a los testers de una nueva versión (diálogo en la app)

La app (ver `HomeLogic._checkForUpdate` en `lib/features/logic/logic.dart`)
compara su propio build number contra dos parámetros de Remote Config, y
si el remoto es mayor, muestra un diálogo "Hay una nueva versión
disponible" con un botón que abre el link de descarga. Después de subir
un release nuevo con el workflow, para que el diálogo se active hay que
actualizar esos dos parámetros en Firebase Console → Remote Config:

- `latest_android_build_number` (número): el build number del release
  recién subido — es el número entre paréntesis que muestra la lista de
  releases en App Distribution (ver "Número de build automático" arriba;
  también es el mismo número que aparece como "run #N" en la pestaña
  Actions de esa corrida).
- `update_download_url` (string): el link de descarga del release. Se
  consigue en Firebase Console → Release & Monitor → App Distribution →
  abrir el release recién subido → "Copiar link" (o el link público del
  grupo de testers).

Publicar los cambios en Remote Config (botón "Publicar cambios") para que
tomen efecto — Remote Config los cachea hasta 1 hora
(`minimumFetchInterval` en `main.dart`), así que un tester puede tardar
hasta esa ventana en ver el diálogo tras reabrir la app, salvo que la
sesión de Remote Config todavía no haya hecho su primer fetch.

## iOS: manual, en tu Mac (por ahora)

La firma de iOS requiere una cuenta de Apple Developer Program,
certificados de distribución y provisioning profiles — nada de eso puede
generarse desde este entorno (no hay Mac/Xcode ni acceso a
developer.apple.com). Mientras no se automatice en CI, los pasos en tu
Mac con Xcode instalado son:

```bash
# 1. Traer dependencias
flutter pub get
cd ios && pod install && cd ..

# 2. Compilar el IPA (Xcode te va a pedir elegir tu Team/certificado la
#    primera vez si el proyecto no tiene firma automática configurada)
flutter build ipa --release

# 3. Instalar la Firebase CLI si no la tenés (una sola vez)
npm install -g firebase-tools
firebase login

# 4. Subir a App Distribution (mismo grupo de testers que Android)
firebase appdistribution:distribute \
  build/ios/ipa/*.ipa \
  --app 1:315811589668:ios:db1535fc9d5d16178a72b1 \
  --groups "testers" \
  --release-notes "Build de prueba manual (iOS)."
```

Notas:

- El App ID de iOS (`1:315811589668:ios:db1535fc9d5d16178a72b1`) es el
  mismo que ya está en `lib/firebase_options.dart`.
- `ios/Runner` no tiene un `GoogleService-Info.plist` commiteado — no
  debería hacer falta para que Crashlytics/Performance reporten (Firebase
  se inicializa 100% programático, ver `firebase_options.dart`), pero si
  Xcode se queja durante `pod install`/build, descargalo desde la consola
  de Firebase (Configuración del proyecto → tu app iOS, bundle id
  `com.example.edtechTiktok`) y agregalo a `ios/Runner` (arrastrándolo en
  Xcode con "Copy items if needed" + target membership en Runner).
- Si `flutter build ipa` falla pidiendo un Team de firma: Xcode → abrir
  `ios/Runner.xcworkspace` → seleccionar el target Runner → pestaña
  "Signing & Capabilities" → elegir tu Apple Developer Team ahí una vez;
  después `flutter build ipa` ya lo reutiliza.

### Automatizarlo en CI más adelante (opcional, no hecho todavía)

Si en algún momento se quiere automatizar también iOS (build en un
runner `macos-latest` de GitHub Actions), hace falta antes:

- Certificado de distribución (.p12) + contraseña, o una API Key de App
  Store Connect (recomendado: `fastlane match` o `xcodebuild` con
  "Automatic Signing" usando esa API Key es más fácil de mantener en CI
  que manejar certificados .p12 a mano).
- Un provisioning profile de distribución para
  `com.example.edtechTiktok`.
- Todo eso vive en secrets de GitHub, nunca commiteado.

Se deja documentado como el siguiente paso natural, pero no se
implementa ahora — requiere decisiones (qué método de firma, si vale la
pena el costo de mantenimiento en CI para el volumen actual de builds)
que le corresponden a quien tenga la cuenta de Apple Developer.
