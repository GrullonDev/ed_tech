import 'package:edtech_tiktok/core/model/streak_card.dart';

/// Banco fijo de Cartas de Racha, una por cada hito de `Milestone.targets`
/// (7/21/30/50/100 días). Ver doc-comment de [StreakCard].
abstract final class StreakCards {
  static const List<StreakCard> all = [
    StreakCard(
      milestoneDays: 7,
      emoji: '🌱',
      title: 'Primer Brote',
      flavorText:
          'Una semana entera sin fallar. Recién empieza, pero ya es más '
          'de lo que la mayoría sostiene.',
    ),
    StreakCard(
      milestoneDays: 21,
      emoji: '🔥',
      title: 'Llama Constante',
      flavorText:
          '21 días es lo que suele tardar un hábito en dejar de sentirse '
          'como una decisión y empezar a sentirse automático.',
    ),
    StreakCard(
      milestoneDays: 30,
      emoji: '🛡️',
      title: 'Guardián de la Racha',
      flavorText:
          'Un mes entero de constancia. A esta altura ya sabés que un mal '
          'día no te va a tirar todo abajo.',
    ),
    StreakCard(
      milestoneDays: 50,
      emoji: '⚡',
      title: 'Corriente Imparable',
      flavorText:
          '50 días de racha activa. Lo que hacés ya no es un experimento: '
          'es quién sos.',
    ),
    StreakCard(
      milestoneDays: 100,
      emoji: '👑',
      title: 'Leyenda de la Tribu',
      flavorText:
          '100 días. Muy pocos llegan hasta acá — esta carta es prueba de '
          'que la constancia real, real existe.',
    ),
  ];
}
