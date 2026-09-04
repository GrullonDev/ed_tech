import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';

class CircleCard extends StatelessWidget {
  const CircleCard({super.key, required this.circle, required this.onCheckIn});

  final HabitCircle circle;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.outlineWhisper),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  circle.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StreakBadge(days: circle.streakDays),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _StackedAvatars(circle: circle),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                gradient: circle.checkedInToday
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryContainer],
                      ),
                color: circle.checkedInToday ? AppColors.surfaceContainer : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: onCheckIn,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        circle.checkedInToday
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        color: circle.checkedInToday
                            ? AppColors.primary
                            : AppColors.onPrimary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        circle.checkedInToday
                            ? 'Check-in completado'
                            : 'Hacer Check-in',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: circle.checkedInToday
                              ? AppColors.primary
                              : AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: days > 0 ? AppShadows.streak : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$days días',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedAvatars extends StatelessWidget {
  const _StackedAvatars({required this.circle});

  final HabitCircle circle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: circle.members.length,
        itemBuilder: (context, i) {
          final completed = circle.checkedInToday;
          return Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completed
                          ? AppColors.primaryContainer
                          : AppColors.outline.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppColors.surfaceContainer,
                    child: Text(
                      circle.members[i],
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 12,
                  color: completed ? AppColors.primaryContainer : AppColors.outline,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
