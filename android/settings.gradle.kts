pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.4.4") apply false
    // START: Crashlytics (firebase/PRODUCTS_PLAN.md, sección 1)
    id("com.google.firebase.crashlytics") version("3.0.2") apply false
    // END: Crashlytics
    // Performance Monitoring (firebase/PRODUCTS_PLAN.md, sección 2): el
    // plugin de Gradle com.google.firebase.firebase-perf (probado hasta
    // 1.4.2) todavía depende de com.android.build.api.transform.Transform,
    // que AGP 9.x eliminó por completo — aplicarlo rompe el build entero
    // ("Could not generate a decorated class for type FirebasePerfPlugin").
    // Se saca el plugin hasta que Firebase publique una versión compatible
    // con AGP 9; firebase_performance en pubspec.yaml sigue funcionando
    // igual para app-start y traces manuales (ver nota en PRODUCTS_PLAN.md),
    // solo se pierde la instrumentación automática de red en Android.
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
