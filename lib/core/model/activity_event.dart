/// Un evento del "Feed de la Tribu": una línea de actividad social ya
/// formateada (check-ins, hitos, escudos usados, nuevos miembros, aliados)
/// para que el Ágora se sienta viva.
///
/// Los eventos de un círculo compartido (check-ins, hitos, escudos) vienen
/// de `circles/{circleId}/activityEvents` en Firestore (ver
/// `HomeLogic._watchCircleActivityEvents`), con [id] igual al ID de ese
/// documento — así todos los miembros ven el mismo texto, generado una sola
/// vez por el dispositivo que hizo la acción, en vez de que cada dispositivo
/// adivine su propia versión del evento. Los eventos puramente locales
/// (aliados, miembros simulados) dejan [id] en `null`.
class ActivityEvent {
  ActivityEvent({
    required this.emoji,
    required this.message,
    required this.at,
    this.id,
    this.circleId,
    List<String>? reactedByUids,
  }) : reactedByUids = reactedByUids ?? [];

  final String? id;
  final String emoji;
  final String message;
  final DateTime at;

  /// ID del círculo dueño de este evento en Firestore (`circles/{circleId}`,
  /// ver `HomeLogic._watchCircleActivityEvents`), o `null` para eventos
  /// puramente locales (aliados, miembros simulados) — sin esto no hay
  /// dónde escribir la reacción de [reactedByUids] cuando se sincroniza con
  /// otros dispositivos (ver `HomeLogic.toggleActivityReaction`).
  final String? circleId;

  /// UIDs (o el `playerId` local si no hay sesión de Firebase, ver
  /// `HomeLogic.toggleActivityReaction`) de quienes reaccionaron con 🔥 a
  /// este evento — el Ágora deja de ser de solo lectura. Mutable a
  /// propósito: se actualiza en el mismo objeto para que la UI (que sostiene
  /// una referencia a través de `HomeLogic.activityFeed`) refleje el cambio
  /// sin tener que reconstruir toda la lista.
  final List<String> reactedByUids;

  Map<String, dynamic> toMap() => {
    'id': id,
    'emoji': emoji,
    'message': message,
    'at': at.toIso8601String(),
    'circleId': circleId,
    'reactedByUids': reactedByUids,
  };

  factory ActivityEvent.fromMap(Map<dynamic, dynamic> map) => ActivityEvent(
    id: map['id'] as String?,
    emoji: map['emoji'] as String,
    message: map['message'] as String,
    at: DateTime.parse(map['at'] as String),
    circleId: map['circleId'] as String?,
    reactedByUids: (map['reactedByUids'] as List?)
        ?.map((e) => e as String)
        .toList(),
  );
}
