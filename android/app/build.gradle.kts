plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // START: Crashlytics (firebase/PRODUCTS_PLAN.md, sección 1)
    id("com.google.firebase.crashlytics")
    // END: Crashlytics
    // Performance Monitoring: plugin sacado por incompatibilidad con AGP 9.x
    // — ver nota en android/settings.gradle.kts y PRODUCTS_PLAN.md sección 2.
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.grullondev.rachatribu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        applicationId = "com.grullondev.rachatribu"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {
            // Un keystore de debug FIJO, commiteado (android/app/debug.keystore),
            // en vez del que Android Gradle Plugin autogenera por máquina
            // (~/.android/debug.keystore). Sin esto, cada corrida de CI en un
            // runner efímero firmaba con una clave nueva y aleatoria, así que
            // instalar un release nuevo sobre uno anterior fallaba con
            // "Installation failed" (Android rechaza un APK cuya firma no
            // coincide con la ya instalada). Es debug-only: no protege nada
            // sensible, por eso es seguro tenerlo en el repo.
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // El Flutter Gradle Plugin habilita R8 (minifyEnabled) por defecto
            // en release desde hace unas versiones, y sin reglas de ProGuard
            // para Firebase rompe la reflexión que usa para autoregistrarse
            // (`ComponentDiscoveryService`): la app instala bien pero
            // `Firebase.initializeApp()` falla en silencio (el catch en
            // main.dart solo hace debugPrint en modo debug) y cualquier uso
            // posterior de Firebase (`FirebaseAuth.instance`, etc.) tira
            // "No Firebase App '[DEFAULT]' has been created", lo que
            // crashea el árbol de widgets y deja la pantalla en gris liso
            // (la pantalla de error por defecto de Flutter en release).
            // Se desactiva por ahora — para una futura release real de Play
            // Store, hay que agregar las reglas de ProGuard de Firebase en
            // vez de dejarlo desactivado sin más.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
    }
}

flutter {
    source = "../.."
}
