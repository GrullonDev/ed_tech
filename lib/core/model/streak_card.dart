/// Una "Carta de Racha" coleccionable: la versión de tarjeta para abrir
/// (ver `HomeLogic.openStreakCard`) de un hito de racha global (mismos
/// objetivos que [Milestone.targets]). A diferencia de la vitrina de
/// tótems de `ProfilePage` (que solo muestra el logro), esta se entrega
/// "sellada" al alcanzar el hito y hay que tocarla para revelarla —
/// pensada como una mecánica de coleccionable aparte para validar si
/// engancha más que la vitrina existente.
class StreakCard {
  const StreakCard({
    required this.milestoneDays,
    required this.emoji,
    required this.title,
    required this.flavorText,
  });

  /// Días de racha requeridos para desbloquearla — coincide con
  /// `Milestone.targets`.
  final int milestoneDays;
  final String emoji;
  final String title;

  /// Texto breve que se revela al abrir la carta.
  final String flavorText;
}
