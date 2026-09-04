import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/theme/app_assets.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.username,
    required this.overallStreakDays,
    required this.circles,
  });

  final String username;
  final int overallStreakDays;
  final List<HabitCircle> circles;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final perfectCount = circles.where((c) => c.isPerfect).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.surfaceContainer,
                  backgroundImage: AssetImage(AppAssets.avatarSample),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  username,
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Miembro de CírculoDiario',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.secondary,
                  value: '$overallStreakDays',
                  label: 'Racha máxima',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.group_rounded,
                  color: AppColors.primary,
                  value: '${circles.length}',
                  label: 'Círculos activos',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.primary,
                  value: '$perfectCount',
                  label: 'Perfectos',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl2),
          Text(
            'Tus círculos',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final circle in circles) ...[
            _CircleRow(circle: circle),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleRow extends StatelessWidget {
  const _CircleRow({required this.circle});

  final HabitCircle circle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineWhisper),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              circle.name,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${circle.streakDays}d 🔥',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
