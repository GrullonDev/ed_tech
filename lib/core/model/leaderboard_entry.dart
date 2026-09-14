/// Una fila de la tabla de posiciones real de un círculo, construida a
/// partir de `circles/{circleId}/memberStats/{uid}` (ver
/// `HomeLogic._watchCircleLeaderboard` y `firebase/FIRESTORE_SCHEMA.md`).
///
/// A diferencia de `HabitCircle.members` (una lista de nombres simulados
/// sin backend, agregados con "Invitar a un amigo"), cada entrada acá
/// corresponde a una cuenta de Firebase real que se unió al círculo con un
/// código de invitación (`HomeLogic.joinCircleWithInviteCode`) — es
/// competencia contra otras personas de verdad, no contra un fantasma de la
/// propia racha pasada (el "Duelo Semanal" de `GamesPage`).
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.username,
    required this.streakDays,
    required this.dropsEarned,
    required this.checkedInToday,
    required this.isCurrentUser,
  });

  final String uid;
  final String username;
  final int streakDays;
  final int dropsEarned;
  final bool checkedInToday;
  final bool isCurrentUser;
}
