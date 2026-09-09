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
Distribution alcanza) y lo sube a Firebase App Distribution. Se dispara a
mano desde GitHub → Actions → "Android → Firebase App Distribution" →
Run workflow.

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

GitHub → pestaña Actions → "Android → Firebase App Distribution" → Run
workflow → (opcional) escribir notas de la release → Run workflow. Los
testers del grupo reciben un email con el link para instalar el APK
desde la app de Firebase App Distribution (o directo el APK) en su
dispositivo.

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
