import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:edtech_tiktok/app.dart';
import 'package:edtech_tiktok/core/service/local_storage_service.dart';
import 'package:edtech_tiktok/core/service/notification_service.dart';
import 'package:edtech_tiktok/features/widgets/onboarding.dart';
import 'package:edtech_tiktok/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorageService.init();
  await NotificationService.init();
  await _initFirebase();
  await LiquidGlassWidgets.initialize();

  runApp(LiquidGlassWidgets.wrap(child: const MyApp()));
}

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
  await _runFirebaseStep('Performance Monitoring', _initPerformanceMonitoring);
  await _runFirebaseStep('Remote Config', _initRemoteConfig);
}

Future<void> _runFirebaseStep(String name, Future<void> Function() step) async {
  try {
    await step();
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('No se pudo inicializar $name, continuando sin él: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

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

Future<void> _initPerformanceMonitoring() async {
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(
    !kDebugMode,
  );
}

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
    // Fase "App Distribution" (firebase/APP_DISTRIBUTION.md): 0 por
    // defecto para que el diálogo de "nueva versión" (HomeLogic.
    // _checkForUpdate) nunca aparezca hasta que se publique un valor real
    // desde la consola de Remote Config después de subir un release.
    'latest_android_build_number': 0,
    'update_download_url': '',
  });
  await remoteConfig.fetchAndActivate();
}

const _remoteConfigFetchTimeout = Duration(seconds: 5);
