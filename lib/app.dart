import 'package:flutter/material.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/page/home.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Registra vistas de pantalla en Firebase Analytics solo si Firebase
  /// llegó a inicializarse (ver main.dart#_initFirebase). En los tests de
  /// widgets, o si `firebase_options.dart` sigue siendo el placeholder,
  /// `Firebase.apps` queda vacío: se omite el observer en vez de lanzar al
  /// acceder a `FirebaseAnalytics.instance` sin una app por defecto.
  static List<NavigatorObserver> _analyticsObservers() {
    if (Firebase.apps.isEmpty) return const [];
    return [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Racha Tribu',
      theme: AppTheme.light(),
      navigatorObservers: _analyticsObservers(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child!,
        );
      },
      home: const MyHomePage(),
    );
  }
}
