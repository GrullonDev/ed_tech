import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';

import 'package:edtech_tiktok/app.dart';
import 'package:edtech_tiktok/core/service/local_storage_service.dart';
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
    await _initPerformanceMonitoring();
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint(
        'Firebase no se pudo inicializar, continuando en modo local: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }
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
