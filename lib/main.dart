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

/// Inicializa Firebase Core y, si tuvo éxito, cada producto por separado
/// (Crashlytics, Performance Monitoring, Remote Config) a través de
/// [_runFirebaseStep]. Antes los tres quedaban en el mismo try/catch que
/// `Firebase.initializeApp`, así que un fallo en cualquiera de ellos (por
/// ejemplo Remote Config sin red) se reportaba como "Firebase no se pudo
/// inicializar" — un mensaje engañoso cuando Firebase Core sí había
/// arrancado bien — y de paso salteaba los pasos siguientes sin necesidad.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint(
        'Firebase no se pudo inicializar, continuando en modo local: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
    return;
  }
  await _runFirebaseStep('Crashlytics', _initCrashlytics);
  await _runFirebaseStep(
    'Performance Monitoring',
    _initPerformanceMonitoring,
  );
  await _runFirebaseStep('Remote Config', _initRemoteConfig);
}

/// Corre un paso de inicialización que depende de que
/// [Firebase.initializeApp] ya haya tenido éxito. Cada paso es
/// independiente de los demás: si uno falla (ver doc-comment de
/// [_initFirebase]), los otros igual se intentan, y el mensaje de debug
/// dice exactamente cuál fue.
Future<void> _runFirebaseStep(
  String name,
  Future<void> Function() step,
) async {
  try {
    await step();
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('No se pudo inicializar $name, continuando sin él: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

/// Reporta crashes a Crashlytics (Fase "Release Monitoring" de
/// `firebase/PRODUCTS_PLAN.md`). Solo se llama cuando
/// `Firebase.initializeApp` ya tuvo éxito, vía [_runFirebaseStep] — un
/// fallo acá tampoco tumba la app ni impide que Performance Monitoring o
/// Remote Config se intenten igual.
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
/// Solo se llama tras un `Firebase.initializeApp` exitoso, vía
/// [_runFirebaseStep], así que un fallo acá tampoco tumba la app ni impide
/// que Remote Config se intente igual.
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
/// configurado, y un fallo tampoco tumba la app (ver [_runFirebaseStep]).
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
