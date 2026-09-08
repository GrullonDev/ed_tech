/// Un evento del "Feed de la Tribu": una línea de actividad social ya
/// formateada (check-ins, hitos, escudos usados, nuevos miembros, aliados)
/// para que el Ágora se sienta viva. Sin backend real, todos los eventos los
/// genera el propio dispositivo a partir de acciones reales del usuario —
/// nada de datos de ejemplo — pero el modelo ya está listo para recibir
/// eventos de otros miembros cuando exista sync remoto vía Supabase.
class ActivityEvent {
  ActivityEvent({required this.emoji, required this.message, required this.at});

  final String emoji;
  final String message;
  final DateTime at;

  Map<String, dynamic> toMap() => {
    'emoji': emoji,
    'message': message,
    'at': at.toIso8601String(),
  };

  factory ActivityEvent.fromMap(Map<dynamic, dynamic> map) => ActivityEvent(
    emoji: map['emoji'] as String,
    message: map['message'] as String,
    at: DateTime.parse(map['at'] as String),
  );
}
