import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:edtech_tiktok/app.dart';
import 'package:edtech_tiktok/core/service/local_storage_service.dart';
import 'package:edtech_tiktok/firebase_options.dart';
import 'package:edtech_tiktok/features/widgets/onboarding.dart';

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
