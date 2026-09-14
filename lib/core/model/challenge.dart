/// Un reto directo 1v1 entre dos aliados reales (ver
/// `HomeLogic.challengeAlly`) — evolución del leaderboard por círculo:
/// en vez de competir contra todo un círculo o contra el propio historial
/// (el "Duelo Semanal" de `GamesPage`), reta a una persona específica.
///
/// Por debajo no es una mecánica nueva: crea un círculo real de 2 miembros
/// (mismo camino que `HomeLogic.joinCircleWithInviteCode`) y este documento
/// es solo la "invitación" que le avisa al aliado y le ahorra escribir el
/// código a mano.
class Challenge {
  const Challenge({
    required this.id,
    required this.fromUid,
    required this.fromUsername,
    required this.toUid,
    required this.toUsername,
    required this.circleId,
    required this.circleName,
    required this.inviteCode,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String fromUid;
  final String fromUsername;
  final String toUid;
  final String toUsername;
  final String circleId;
  final String circleName;
  final String inviteCode;

  /// `'pending'` | `'accepted'` | `'declined'`.
  final String status;
  final DateTime createdAt;
}
