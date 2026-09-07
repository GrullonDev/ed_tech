/// Un hito de racha global (ej. "Pacto de 7 Días"): los días requeridos para
/// alcanzarlo, un título de producto, si ya fue desbloqueado y qué tan cerca
/// está el usuario de lograrlo (0.0 a 1.0). [unlocked] y [progress] no se
/// guardan — se recalculan siempre a partir de la racha real del usuario via
/// [Milestone.evaluate].
class Milestone {
  const Milestone({
    required this.requiredDays,
    required this.title,
    required this.unlocked,
    required this.progress,
  });

  final int requiredDays;
  final String title;
  final bool unlocked;
  final double progress;

  /// Objetivos clave de producto, en días de racha consecutiva.
  static const List<int> targets = [7, 21, 30, 50, 100];

  static const Map<int, String> _titles = {
    7: 'Pacto de 7 Días',
    21: 'Pacto de 21 Días',
    30: 'Pacto de 30 Días',
    50: 'Pacto de 50 Días',
    100: 'Pacto de 100 Días',
  };

  /// Evalúa [targets] contra [currentStreak] y devuelve un [Milestone] por
  /// cada objetivo: desbloqueado y con progreso 1.0 si ya se alcanzó, o con
  /// el avance proporcional (`currentStreak / requiredDays`) si aún no.
  static List<Milestone> evaluate(int currentStreak) => [
    for (final days in targets)
      if (currentStreak >= days)
        Milestone(
          requiredDays: days,
          title: _titles[days] ?? 'Pacto de $days Días',
          unlocked: true,
          progress: 1.0,
        )
      else
        Milestone(
          requiredDays: days,
          title: _titles[days] ?? 'Pacto de $days Días',
          unlocked: false,
          progress: (currentStreak / days).clamp(0.0, 1.0),
        ),
  ];
}
