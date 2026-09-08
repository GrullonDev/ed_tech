import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:edtech_tiktok/app.dart';
import 'package:edtech_tiktok/core/service/local_storage_service.dart';
import 'package:edtech_tiktok/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  await _initFirebase();
  runApp(const MyApp());
}

/// La app sigue siendo 100% funcional sin Firebase configurado todavía
/// (ver lib/firebase_options.dart): si la inicialización falla —por no
/// haberse regenerado ese archivo, o por no haber red— se traga el error
/// aquí y `HomeLogic` cae de vuelta al playerId generado localmente, tal
/// como funcionaba antes de este cambio.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase no se pudo inicializar, continuando en modo local: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
