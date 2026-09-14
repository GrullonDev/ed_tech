import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/trivia_question.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/app_bottom_nav.dart';
import 'package:edtech_tiktok/features/widgets/game_cards.dart';

/// Pantalla "Juegos": reúne los cuatro minijuegos de Racha Tribu (Desafío
/// del día, Ruleta diaria de gotas, Duelo de Racha Semanal y Predicción de
/// Tribu). Antes vivían todos apilados arriba del dashboard de círculos;
/// tener su propia pestaña deja a "Círculos" enfocado en los hábitos del
/// día y además permite que "Crear" quede centrado en la barra de
/// navegación (dos pestañas a cada lado).
///
/// Rediseño de Stitch ("Arena de la Tribu"): la mockup tiene 4 juegos con
/// nombres ficticios (Cyber Dash Tribal, Duelo de Tótems, Glifo Memoria,
/// Tapper Tambor) — acá se mapean 1:1 a los 4 minijuegos reales que ya
/// existen (Desafío del día, Duelo Semanal, Predicción de Tribu, Ruleta),
/// solo con el look de la mockup por encima. Se omiten a propósito el
/// contador de temporada, los filtros por género y el leaderboard de la
/// captura porque no hay datos reales detrás de ninguno de los tres hoy.
class GamesPage extends StatelessWidget {
  const GamesPage({
    super.key,
    required this.circles,
    required this.onCreateCircle,
    required this.onOpenRachas,
    required this.onOpenProfile,
    required this.todaysTrivia,
    required this.hasAnsweredTodaysTrivia,
    required this.triviaLastSelectedIndex,
    required this.onAnswerTrivia,
    required this.hasSpunTodaysWheel,
    required this.wheelLastReward,
    required this.onSpinWheel,
    required this.weeklyDuelUserTotal,
    required this.weeklyDuelRivalTotal,
    required this.hasWonWeeklyDuel,
    required this.hasPendingPredictionToday,
    required this.pendingPredictionCircleId,
    required this.predictionBetAmount,
    required this.constancyDrops,
    required this.onPlacePrediction,
  });

  final List<HabitCircle> circles;
  final VoidCallback onCreateCircle;
  final VoidCallback onOpenRachas;
  final VoidCallback onOpenProfile;

  final TriviaQuestion todaysTrivia;
  final bool hasAnsweredTodaysTrivia;
  final int? triviaLastSelectedIndex;
  final bool Function(int selectedIndex) onAnswerTrivia;

  final bool hasSpunTodaysWheel;
  final int? wheelLastReward;
  final int Function() onSpinWheel;

  final int weeklyDuelUserTotal;
  final int weeklyDuelRivalTotal;
  final bool hasWonWeeklyDuel;

  final bool hasPendingPredictionToday;
  final String? pendingPredictionCircleId;
  final int predictionBetAmount;
  final int constancyDrops;
  final bool Function(HabitCircle circle) onPlacePrediction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.games,
        onCreateCircle: onCreateCircle,
        onOpenCircles: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        onOpenRachas: onOpenRachas,
        onOpenProfile: onOpenProfile,
      ),
      body: SafeArea(
        bottom: false,
        child: AppMaxWidth(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)
                .copyWith(
                  top: AppSpacing.lg,
                  bottom:
                      AppSpacing.xl2 +
                      AppBottomNav.reservedHeight +
                      MediaQuery.paddingOf(context).bottom,
                ),
            children: [
              Text(
                '⚡ ARENA DE LA TRIBU',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.tertiary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.06,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Arena de la Tribu',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sumá Gotas de Constancia jugando, además de con tus '
                'check-ins de todos los días.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _GameStatBox(
                      label: 'Gotas de Constancia',
                      value: '$constancyDrops',
                      color: AppColors.tertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _GameStatBox(
                      label: 'Duelo Semanal',
                      value: '$weeklyDuelUserTotal - $weeklyDuelRivalTotal',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                children: [
                  const Text('🕹️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Galería de Juegos',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '4 juegos',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _GameSlot(
                badge: '🔥 DESTACADO DEL DÍA',
                badgeColor: AppColors.primary,
                caption: 'Solo • 1 pregunta por día',
                child: TriviaCard(
                  question: todaysTrivia,
                  answered: hasAnsweredTodaysTrivia,
                  selectedIndex: triviaLastSelectedIndex,
                  onAnswer: onAnswerTrivia,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _GameSlot(
                badge: '⚡ PVP RACHA',
                badgeColor: AppColors.secondary,
                caption: 'Duelo 1v1 • Esta semana',
                child: WeeklyDuelCard(
                  userTotal: weeklyDuelUserTotal,
                  rivalTotal: weeklyDuelRivalTotal,
                  won: hasWonWeeklyDuel,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _GameSlot(
                badge: '🧩 TRIBU COOP',
                badgeColor: AppColors.tertiary,
                caption: 'Apuesta gotas por tu círculo',
                child: PredictionCard(
                  circles: circles,
                  hasPending: hasPendingPredictionToday,
                  pendingCircleId: pendingPredictionCircleId,
                  betAmount: predictionBetAmount,
                  affordable: constancyDrops >= predictionBetAmount,
                  onPlacePrediction: onPlacePrediction,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _GameSlot(
                badge: '🥁 RITMO RÁPIDO',
                badgeColor: AppColors.rankGold,
                caption: 'Ruleta diaria de gotas',
                child: WheelCard(
                  hasSpun: hasSpunTodaysWheel,
                  lastReward: wheelLastReward,
                  onSpin: onSpinWheel,
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Misiones de Hoy',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DailyMissionsCard(
                hasAnsweredTrivia: hasAnsweredTodaysTrivia,
                hasSpunWheel: hasSpunTodaysWheel,
                hasWonWeeklyDuel: hasWonWeeklyDuel,
                hasPendingPrediction: hasPendingPredictionToday,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameStatBox extends StatelessWidget {
  const _GameStatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineWhisper),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Envuelve un `*Card` de minijuego ya existente (`game_cards.dart`) con la
/// etiqueta/badge de la mockup de Stitch por encima, sin tocar su lógica ni
/// su estado interno.
class _GameSlot extends StatelessWidget {
  const _GameSlot({
    required this.badge,
    required this.badgeColor,
    required this.caption,
    required this.child,
  });

  final String badge;
  final Color badgeColor;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                badge,
                style: textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                caption,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

/// "Misiones de Hoy" — un estado por cada uno de los 4 minijuegos reales,
/// sin inventar un sistema de misiones nuevo: son exactamente los mismos
/// booleans que ya deciden qué muestra cada `*Card` de arriba.
class _DailyMissionsCard extends StatelessWidget {
  const _DailyMissionsCard({
    required this.hasAnsweredTrivia,
    required this.hasSpunWheel,
    required this.hasWonWeeklyDuel,
    required this.hasPendingPrediction,
  });

  final bool hasAnsweredTrivia;
  final bool hasSpunWheel;
  final bool hasWonWeeklyDuel;
  final bool hasPendingPrediction;

  @override
  Widget build(BuildContext context) {
    final missions = [
      (label: 'Responder el Desafío del Día', done: hasAnsweredTrivia),
      (label: 'Girar la Ruleta de Gotas', done: hasSpunWheel),
      (label: 'Ganar el Duelo de Racha Semanal', done: hasWonWeeklyDuel),
      (label: 'Hacer una Predicción de Tribu', done: hasPendingPrediction),
    ];
    final completed = missions.where((m) => m.done).length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.outlineWhisper),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progreso del día',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$completed/${missions.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.tertiary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final mission in missions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    mission.done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: mission.done
                        ? AppColors.tertiary
                        : AppColors.outline,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      mission.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mission.done
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
