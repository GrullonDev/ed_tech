import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Recordatorio diario de racha ("no perdás tu racha de N días"), a las
/// [_reminderHour]:00. Es el motor de tensión de una app de rachas (tipo
/// Duolingo/Snapchat): sin este aviso, un usuario con racha activa pero sin
/// check-in todavía hoy simplemente se olvida y la pierde sin darse cuenta.
///
/// Implementación 100% local (`flutter_local_notifications`), sin backend:
/// se reprograma una única notificación de "hoy a las 8pm" (o "mañana a las
/// 8pm" si ya pasó esa hora o si hoy ya se hizo check-in) cada vez que
/// [HomeLogic] carga o cambia el estado de racha, para que el texto siempre
/// refleje la racha real — ver `HomeLogic._refreshStreakReminder`.
class NotificationService {
  NotificationService._();

  static const int _reminderHour = 20;
  static const int _reminderNotificationId = 1;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Inicializa el plugin y pide permiso de notificaciones. Debe llamarse
  /// una vez en `main()` antes de `runApp`, igual que
  /// `LocalStorageService.init()`.
  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // Nombre de zona horaria no reconocido por el paquete `timezone`
      // (pasa en algunos dispositivos Android): se sigue usando UTC como
      // referencia interna, `zonedSchedule` igual dispara a la hora local
      // del dispositivo porque construimos la fecha con `DateTime.now()`.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('No se pudo pedir permiso de notificaciones: $error');
      }
    }

    _initialized = true;
  }

  /// Reprograma el recordatorio diario de racha según el estado actual.
  ///
  /// - Si [hasPendingCheckIn] es `false` (no hay ningún círculo con racha
  ///   activa esperando el check-in de hoy), se cancela: no tiene sentido
  ///   asustar a alguien que ya está al día o que todavía no tiene racha.
  /// - Si es `true`, se programa para hoy a las 8pm (o mañana a las 8pm si
  ///   ya pasó esa hora hoy), con [streakDays] en el mensaje.
  static Future<void> refreshStreakReminder({
    required bool hasPendingCheckIn,
    required int streakDays,
  }) async {
    if (!_initialized) return;
    await _plugin.cancel(_reminderNotificationId);
    if (!hasPendingCheckIn) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _reminderHour,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final body = streakDays > 0
        ? 'Llevás $streakDays días seguidos. No dejes que se corte hoy 🔥'
        : '¡Hacé tu check-in de hoy y arrancá tu racha! 🔥';

    try {
      await _plugin.zonedSchedule(
        _reminderNotificationId,
        'Tu racha te espera',
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_reminder_channel',
            'Recordatorio de racha',
            channelDescription:
                'Aviso diario para no perder tu racha de hábitos.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('No se pudo programar el recordatorio de racha: $error');
      }
    }
  }
}
