// Placeholder — reemplázalo ejecutando el Firebase CLI + FlutterFire CLI:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=rachatribu
//
// desde la raíz del proyecto (requiere estar autenticado con la cuenta
// dueña del proyecto Firebase "rachatribu"). El comando regenera este
// archivo completo con las claves reales de cada plataforma (Android,
// iOS, Web); no rellenes los valores a mano ni copies claves de otro
// proyecto.
//
// Hasta que se regenere, `currentPlatform` lanza a propósito: así el
// error es explícito y explica qué hacer, en vez de que
// Firebase.initializeApp() falle de forma críptica dentro del SDK nativo
// con una API key inválida. `main.dart` ya captura este error y deja la
// app funcionando en modo 100% local mientras tanto (ver
// HomeLogic._signInAndResolvePlayerId).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'DefaultFirebaseOptions.currentPlatform no está configurado. '
      'Ejecuta `flutterfire configure --project=rachatribu` para generar '
      'este archivo con las claves reales del proyecto.',
    );
  }
}
