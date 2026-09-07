/// Una solicitud de "Aliado" pendiente de aceptar o rechazar. Sin backend
/// real, no hay forma de que viaje de un dispositivo a otro: al enviarse, se
/// simula que ya llegó al dispositivo del receptor registrándola de una vez
/// como pendiente, para poder demostrar el flujo completo (notificación +
/// aceptar/rechazar) sin conexión a internet.
class AllyRequest {
  AllyRequest({required this.fromUsername, required this.sentAt});

  final String fromUsername;
  final DateTime sentAt;

  Map<String, dynamic> toMap() => {
    'fromUsername': fromUsername,
    'sentAt': sentAt.toIso8601String(),
  };

  factory AllyRequest.fromMap(Map<dynamic, dynamic> map) => AllyRequest(
    fromUsername: map['fromUsername'] as String,
    sentAt: DateTime.parse(map['sentAt'] as String),
  );
}
