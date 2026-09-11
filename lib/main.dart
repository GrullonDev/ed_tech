import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:edtech_tiktok/app.dart';
import 'package:edtech_tiktok/core/service/local_storage_service.dart';
import 'package:edtech_tiktok/features/widgets/onboarding.dart';
import 'package:edtech_tiktok/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  await _initFirebase();
  runApp(const MyApp());
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _initCrashlytics();
    await _initPerformanceMonitoring();
    await _initRemoteConfig();
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint(
        'Firebase no se pudo inicializar, continuando en modo local: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

/// Reporta crashes a Crashlytics (Fase "Release Monitoring" de
/// `firebase/PRODUCTS_PLAN.md`). Solo se llama cuando
/// `Firebase.initializeApp` ya tuvo éxito, así que no necesita su propio
/// try/catch por falta de Firebase — pero cualquier error inesperado acá
/// tampoco debe tumbar la app, de ahí que quede dentro del try/catch de
/// [_initFirebase].
Future<void> _initCrashlytics() async {
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Mide tiempos de arranque/pantallas y peticiones HTTP automáticamente
/// (Fase "Release Monitoring" de `firebase/PRODUCTS_PLAN.md`, sección 2) —
/// solo con agregar `firebase_performance` ya empieza a recolectar, sin
/// tocar `HomeLogic` ni la UI. Deshabilitado en debug por el mismo motivo
/// que Crashlytics: no ensuciar la consola con datos de desarrollo local.
/// Solo se llama tras un `Firebase.initializeApp` exitoso, dentro del
/// mismo try/catch de [_initFirebase], así que un fallo acá tampoco tumba
/// la app.
Future<void> _initPerformanceMonitoring() async {
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(
    !kDebugMode,
  );
}

/// Trae parámetros configurables desde la consola sin publicar una nueva
/// versión de la app (Fase "A/B Testing" de `firebase/PRODUCTS_PLAN.md`,
/// sección 3) — hoy solo `onboarding_headline` (ver [Onboarding]). Los
/// defaults locales son el mismo texto que ya está hardcodeado hoy, así que
/// si esto falla o tarda más que [_remoteConfigFetchTimeout] la app se ve
/// exactamente igual que antes. `fetchAndActivate` se espera acá (una sola
/// vez, antes de `runApp`) para que la primera pantalla ya tenga el valor
/// activado si llegó a tiempo — nunca bloquea más allá del timeout
/// configurado, y un fallo tampoco tumba la app (mismo try/catch de
/// [_initFirebase]).
Future<void> _initRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: _remoteConfigFetchTimeout,
      minimumFetchInterval: const Duration(hours: 1),
    ),
  );
  await remoteConfig.setDefaults({
    'onboarding_headline': Onboarding.defaultHeadline,
  });
  await remoteConfig.fetchAndActivate();
}

const _remoteConfigFetchTimeout = Duration(seconds: 5);
