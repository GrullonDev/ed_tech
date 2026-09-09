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
  });

  final String? id;
  final String emoji;
  final String message;
  final DateTime at;

  Map<String, dynamic> toMap() => {
    'id': id,
    'emoji': emoji,
    'message': message,
    'at': at.toIso8601String(),
  };

  factory ActivityEvent.fromMap(Map<dynamic, dynamic> map) => ActivityEvent(
    id: map['id'] as String?,
    emoji: map['emoji'] as String,
    message: map['message'] as String,
    at: DateTime.parse(map['at'] as String),
  );
}
