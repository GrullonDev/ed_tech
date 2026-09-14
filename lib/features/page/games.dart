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
                'Juegos 🎮',
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
              const SizedBox(height: AppSpacing.xl),
              TriviaCard(
                question: todaysTrivia,
                answered: hasAnsweredTodaysTrivia,
                selectedIndex: triviaLastSelectedIndex,
                onAnswer: onAnswerTrivia,
              ),
              const SizedBox(height: AppSpacing.lg),
              WheelCard(
                hasSpun: hasSpunTodaysWheel,
                lastReward: wheelLastReward,
                onSpin: onSpinWheel,
              ),
              const SizedBox(height: AppSpacing.lg),
              WeeklyDuelCard(
                userTotal: weeklyDuelUserTotal,
                rivalTotal: weeklyDuelRivalTotal,
                won: hasWonWeeklyDuel,
              ),
              const SizedBox(height: AppSpacing.lg),
              PredictionCard(
                circles: circles,
                hasPending: hasPendingPredictionToday,
                pendingCircleId: pendingPredictionCircleId,
                betAmount: predictionBetAmount,
                affordable: constancyDrops >= predictionBetAmount,
                onPlacePrediction: onPlacePrediction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
