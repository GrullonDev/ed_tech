import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/theme/app_assets.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/circle_card.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.username,
    required this.circles,
    required this.onCreateCircle,
    required this.onCheckIn,
  });

  final String username;
  final List<HabitCircle> circles;
  final VoidCallback onCreateCircle;
  final ValueChanged<HabitCircle> onCheckIn;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Image.asset(AppAssets.logo),
        ),
        title: Text('Hola, $username 👋'),
        actions: [
          IconButton(
            onPressed: onCreateCircle,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainer,
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Crear nuevo círculo',
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis Círculos de Hábitos',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
                itemCount: circles.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, index) {
                  final circle = circles[index];
                  return CircleCard(
                    circle: circle,
                    onCheckIn: () => onCheckIn(circle),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
