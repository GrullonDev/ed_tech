/// Una solicitud de "Aliado" pendiente de aceptar o rechazar.
///
/// [fromUserId]/[toUserId] identifican el documento real en Firestore
/// (`allyRequests/{fromUserId}_{toUserId}`, ver `HomeLogic._watchIncomingAllyRequests`)
/// cuando la solicitud llegó por un dispositivo real; quedan en `null` para
/// solicitudes en el modo simulado local que se usa si Firebase no está
/// disponible (sin backend real no hay forma de que viaje de un dispositivo
/// a otro, así que se simula que ya llegó de inmediato al receptor).
class AllyRequest {
  AllyRequest({
    required this.fromUsername,
    required this.sentAt,
    this.fromUserId,
    this.toUserId,
  });

  final String fromUsername;
  final DateTime sentAt;
  final String? fromUserId;
  final String? toUserId;

  Map<String, dynamic> toMap() => {
    'fromUsername': fromUsername,
    'sentAt': sentAt.toIso8601String(),
    'fromUserId': fromUserId,
    'toUserId': toUserId,
  };

  factory AllyRequest.fromMap(Map<dynamic, dynamic> map) => AllyRequest(
    fromUsername: map['fromUsername'] as String,
    sentAt: DateTime.parse(map['sentAt'] as String),
    fromUserId: map['fromUserId'] as String?,
    toUserId: map['toUserId'] as String?,
  );
}
