import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/trivia_question.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/logic/logic.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';

/// Tarjetas de los juegos de "Racha Tribu" (ver `page/games.dart`): el
/// "Desafío del día" (trivia), la "Ruleta diaria de gotas", el "Duelo de
/// Racha Semanal" y la "Predicción de Tribu". Antes vivían dentro del
/// dashboard; ahora tienen su propia pantalla ("Juegos" en la barra
/// inferior) para no saturar la pantalla principal de círculos.
class TriviaCard extends StatelessWidget {
  const TriviaCard({
    super.key,
    required this.question,
    required this.answered,
    required this.selectedIndex,
    required this.onAnswer,
  });

  final TriviaQuestion question;
  final bool answered;
  final int? selectedIndex;
  final bool Function(int selectedIndex) onAnswer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final wasCorrect = answered && selectedIndex == question.correctIndex;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Desafío del día',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!answered)
                Text(
                  '+${HomeLogic.triviaCorrectAnswerReward} gotas',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                Icon(
                  wasCorrect
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  size: 18,
                  color: wasCorrect ? AppColors.primary : AppColors.outline,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            question.question,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < question.options.length; i++) ...[
            _TriviaOption(
              label: question.options[i],
              state: _optionState(i, answered, selectedIndex, question),
              onTap: answered ? null : () => onAnswer(i),
            ),
            if (i < question.options.length - 1)
              const SizedBox(height: AppSpacing.xs),
          ],
          if (answered) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                question.explanation,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static _TriviaOptionState _optionState(
    int index,
    bool answered,
    int? selectedIndex,
    TriviaQuestion question,
  ) {
    if (!answered) return _TriviaOptionState.pending;
    if (index == question.correctIndex) return _TriviaOptionState.correct;
    if (index == selectedIndex) return _TriviaOptionState.incorrect;
    return _TriviaOptionState.disabled;
  }
}

enum _TriviaOptionState { pending, correct, incorrect, disabled }

class _TriviaOption extends StatelessWidget {
  const _TriviaOption({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _TriviaOptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (background, border, icon) = switch (state) {
      _TriviaOptionState.pending => (
        AppColors.surfaceContainer,
        AppColors.outlineWhisper,
        null,
      ),
      _TriviaOptionState.correct => (
        AppColors.completedGlow,
        AppColors.primary,
        Icons.check_circle_rounded,
      ),
      _TriviaOptionState.incorrect => (
        AppColors.error.withValues(alpha: 0.1),
        AppColors.error,
        Icons.cancel_rounded,
      ),
      _TriviaOptionState.disabled => (
        AppColors.surfaceContainer,
        AppColors.outlineWhisper,
        null,
      ),
    };
    final iconColor = state == _TriviaOptionState.correct
        ? AppColors.primary
        : AppColors.error;
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: state == _TriviaOptionState.disabled
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
              ),
            ),
          ),
          if (icon != null) Icon(icon, size: 18, color: iconColor),
        ],
      ),
    );
    final tapHandler = onTap;
    return tapHandler == null
        ? content
        : GamePressable(onTap: tapHandler, child: content);
  }
}

class PredictionCard extends StatelessWidget {
  const PredictionCard({
    super.key,
    required this.circles,
    required this.hasPending,
    required this.pendingCircleId,
    required this.betAmount,
    required this.affordable,
    required this.onPlacePrediction,
  });

  final List<HabitCircle> circles;
  final bool hasPending;
  final String? pendingCircleId;
  final int betAmount;
  final bool affordable;
  final bool Function(HabitCircle circle) onPlacePrediction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    HabitCircle? pendingCircle;
    if (pendingCircleId != null) {
      for (final circle in circles) {
        if (circle.id == pendingCircleId) {
          pendingCircle = circle;
          break;
        }
      }
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔮', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Predicción de Tribu',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (hasPending && pendingCircle != null)
            Text(
              'Apostaste $betAmount gotas a que "${pendingCircle.name}" '
              'logra el Círculo Perfecto hoy. El resultado se revela '
              'mañana.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else if (circles.isEmpty)
            Text(
              'Creá un círculo para poder apostar a que logra el Círculo '
              'Perfecto hoy.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else ...[
            Text(
              'Apostá $betAmount gotas a que un círculo logra el Círculo '
              'Perfecto hoy. Si acertás, duplicás la apuesta mañana.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final circle in circles)
                  if (affordable)
                    GamePressable(
                      onTap: () => onPlacePrediction(circle),
                      child: ChoiceChip(
                        label: Text(circle.name),
                        selected: false,
                        onSelected: (_) => onPlacePrediction(circle),
                      ),
                    )
                  else
                    ChoiceChip(
                      label: Text(circle.name),
                      selected: false,
                      onSelected: null,
                    ),
              ],
            ),
            if (!affordable) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Te faltan gotas para apostar.',
                style: textTheme.labelSmall?.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class WheelCard extends StatelessWidget {
  const WheelCard({
    super.key,
    required this.hasSpun,
    required this.lastReward,
    required this.onSpin,
  });

  final bool hasSpun;
  final int? lastReward;
  final int Function() onSpin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const Text('🎰', style: TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ruleta diaria de gotas',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hasSpun
                      ? '¡Ganaste $lastReward gotas! Volvé mañana.'
                      : 'Un giro gratis por día. ¡Probá tu suerte!',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (hasSpun)
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(64, 40)),
              onPressed: null,
              child: Text('+$lastReward'),
            )
          else
            GamePressable(
              onTap: () => onSpin(),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(64, 40),
                ),
                onPressed: () => onSpin(),
                child: const Text('Girar'),
              ),
            ),
        ],
      ),
    );
  }
}

class WeeklyDuelCard extends StatelessWidget {
  const WeeklyDuelCard({
    super.key,
    required this.userTotal,
    required this.rivalTotal,
    required this.won,
  });

  final int userTotal;
  final int rivalTotal;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxTotal = [userTotal, rivalTotal, 1].reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚔️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Duelo de Racha Semanal',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (won)
                Icon(
                  Icons.emoji_events_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            won
                ? '¡Superaste a tu Racha Fantasma esta semana!'
                : 'Superá el total de check-ins de tu mejor semana pasada.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DuelBar(
            label: 'Vos',
            value: userTotal,
            maxValue: maxTotal,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DuelBar(
            label: 'Racha Fantasma',
            value: rivalTotal,
            maxValue: maxTotal,
            color: AppColors.outline,
          ),
        ],
      ),
    );
  }
}

class _DuelBar extends StatelessWidget {
  const _DuelBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fraction = maxValue == 0 ? 0.0 : value / maxValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.surfaceContainer,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
