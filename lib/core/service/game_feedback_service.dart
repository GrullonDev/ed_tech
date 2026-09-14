import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Feedback sensorial (sonido + haptics) para acciones del juego.
///
/// Centralizado acá para que `HomeLogic` pueda dispararlo directo al
/// completar un check-in sin depender de un `BuildContext` (a diferencia del
/// confetti, que sí necesita un widget en pantalla — ver `celebrationTick`
/// en `HomeLogic` y el overlay en `home.dart`).
class GameFeedbackService {
  GameFeedbackService._();

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop)
    ..setPlayerMode(PlayerMode.lowLatency);

  /// Check-in de un círculo: la acción central de la app, repetida todos
  /// los días — impacto fuerte (haptic medio + chime de dos notas).
  static Future<void> checkIn() async {
    unawaited(HapticFeedback.mediumImpact());
    await _play('sounds/check_in.wav');
  }

  /// Hábito personal del día tildado: impacto liviano, para no competir
  /// con el check-in de círculo (que es el que de verdad mueve la racha).
  static Future<void> todayHabitToggled() async {
    unawaited(HapticFeedback.selectionClick());
  }

  /// Revelar una Carta de Racha (hito de 7/21/30/50/100 días) — el momento
  /// más importante de la progresión, así que el feedback es más grande que
  /// el del check-in normal: impacto pesado + una fanfarria de 4 notas en
  /// vez del chime de dos notas.
  static Future<void> milestone() async {
    unawaited(HapticFeedback.heavyImpact());
    await _play('sounds/milestone.wav');
  }

  static Future<void> _play(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Sonido es un extra de sensación, nunca debe romper el check-in en
      // sí (por ejemplo si el dispositivo está en silencio total o el
      // asset falla en algún plugin de audio específico de plataforma).
    }
  }
}
