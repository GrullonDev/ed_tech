import 'package:flutter/material.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:edtech_tiktok/core/model/check_in.dart';
import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/milestone.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/app_bottom_nav.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';
import 'package:edtech_tiktok/features/widgets/ritual_path.dart';

/// Pantalla "Rachas": muestra la racha global y por círculo, la semana en
/// curso y los próximos hitos, todo derivado de los check-ins reales
/// almacenados en cada [HabitCircle] — no hay cifras de ejemplo.
class RachasPage extends StatelessWidget {
  const RachasPage({
    super.key,
    required this.circles,
    required this.overallStreakDays,
    required this.onCheckIn,
    required this.onOpenCircle,
    required this.onCreateCircle,
    required this.onOpenGames,
    required this.onOpenProfile,
    required this.onOpenAgora,
  });

  final List<HabitCircle> circles;
  final int overallStreakDays;
  final ValueChanged<HabitCircle> onCheckIn;
  final ValueChanged<HabitCircle> onOpenCircle;
  final VoidCallback onCreateCircle;
  final VoidCallback onOpenGames;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenAgora;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final milestones = Milestone.evaluate(overallStreakDays);
    final currentQuest = milestones.firstWhere(
      (m) => !m.unlocked,
      orElse: () => milestones.last,
    );
    final nextMilestone = currentQuest.requiredDays;
    final milestoneProgress = currentQuest.progress;
    final daysToGo = (nextMilestone - overallStreakDays).clamp(
      0,
      nextMilestone,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.rachas,
        onCreateCircle: onCreateCircle,
        onOpenCircles: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        onOpenGames: onOpenGames,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Tus Rachas Activas',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _GlobalStreakPill(days: overallStreakDays),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'La constancia no se trata de perfección absoluta, sino de '
                'sostener con cuidado la cadena de tus hábitos.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _AgoraEntryBanner(onTap: onOpenAgora),
              const SizedBox(height: AppSpacing.xl),
              _StreakHeroCard(
                overallStreakDays: overallStreakDays,
                nextMilestone: nextMilestone,
                daysToGo: daysToGo,
                progress: milestoneProgress,
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                'Esta Semana',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _WeekCard(circles: circles),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                children: [
                  Text(
                    'Círculos en Racha',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${circles.length} activos',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (circles.isEmpty)
                _EmptyStreaksCard(onCreateCircle: onCreateCircle)
              else
                for (final circle in circles) ...[
                  _CircleStreakRow(
                    circle: circle,
                    onCheckIn: () => onCheckIn(circle),
                    onTap: () => onOpenCircle(circle),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                'El Libro de los Ritos',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Cada hito ilumina un nuevo nodo del camino. Tu meta actual '
                'brilla con fuego propio.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RitualPath(milestones: milestones),
              const SizedBox(height: AppSpacing.md),
              const _GoldenRuleCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalStreakPill extends StatelessWidget {
  const _GlobalStreakPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$days Días\nGlobal',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakHeroCard extends StatelessWidget {
  const _StreakHeroCard({
    required this.overallStreakDays,
    required this.nextMilestone,
    required this.daysToGo,
    required this.progress,
  });

  final int overallStreakDays;
  final int nextMilestone;
  final int daysToGo;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.warningContainer, AppColors.lavenderContainer],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.secondaryContainer, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overallStreakDays > 0
                          ? 'SINTONÍA ACTIVA'
                          : 'AÚN SIN RACHA',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.06,
                      ),
                    ),
                    Text(
                      overallStreakDays > 0
                          ? '$overallStreakDays días construyendo el hábito'
                          : 'Haz tu primer check-in para empezar',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Próximo hito: $nextMilestone días',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso al hito de $nextMilestone días',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                daysToGo == 0 ? '¡Completado!' : 'Faltan $daysToGo días',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.surface,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuadrícula de la semana en curso (lunes a domingo). Para cada día pasado
/// (incluido hoy) cuenta cuántos círculos tienen check-in real en esa fecha;
/// los días futuros de la semana se muestran como pendientes, sin datos.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.circles});

  final List<HabitCircle> circles;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final today = CheckIn.today();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _DayCell(
                label: labels[i],
                day: startOfWeek.add(Duration(days: i)),
                today: today,
                circles: circles,
                textTheme: textTheme,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.day,
    required this.today,
    required this.circles,
    required this.textTheme,
  });

  final String label;
  final DateTime day;
  final DateTime today;
  final List<HabitCircle> circles;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final isFuture = day.isAfter(today);
    final isToday = day == today;
    final total = circles.length;
    final completed = isFuture
        ? 0
        : circles.where((c) => c.checkIns.any((ci) => ci.date == day)).length;
    final isPerfectDay = !isFuture && total > 0 && completed == total;

    Color background;
    Color foreground;
    Widget icon;
    if (isFuture) {
      background = AppColors.surfaceContainer;
      foreground = AppColors.outline;
      icon = Icon(Icons.hourglass_empty_rounded, size: 16, color: foreground);
    } else if (isToday) {
      background = AppColors.secondary;
      foreground = AppColors.onSecondary;
      icon = Icon(
        Icons.local_fire_department_rounded,
        size: 16,
        color: foreground,
      );
    } else if (isPerfectDay) {
      background = AppColors.completedGlow;
      foreground = AppColors.primary;
      icon = Icon(Icons.check_rounded, size: 16, color: foreground);
    } else if (completed > 0) {
      background = AppColors.surfaceContainer;
      foreground = AppColors.primary;
      icon = Icon(Icons.check_rounded, size: 16, color: foreground);
    } else {
      background = AppColors.surfaceContainer;
      foreground = AppColors.outline;
      icon = Icon(Icons.remove_rounded, size: 16, color: foreground);
    }

    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday ? AppColors.secondary : AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: isToday ? 1.35 : 1.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: icon,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isFuture ? '-' : '$completed/$total',
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _CircleStreakRow extends StatelessWidget {
  const _CircleStreakRow({
    required this.circle,
    required this.onCheckIn,
    required this.onTap,
  });

  final HabitCircle circle;
  final VoidCallback onCheckIn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.outlineWhisper),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.lavenderContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    circle.name,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    circle.checkedInToday
                        ? 'Completado hoy'
                        : 'Pendiente para ti hoy',
                    style: textTheme.bodySmall?.copyWith(
                      color: circle.checkedInToday
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (circle.freezesAvailable > 0) ...[
              Text(
                '🛡️${circle.freezesAvailable}',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.warningContainer,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${circle.streakDays} Días',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            TweenAnimationBuilder<double>(
              key: ValueKey('checkin-${circle.name}-${circle.checkedInToday}'),
              tween: Tween(begin: circle.checkedInToday ? 1.4 : 1.0, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: GamePressable(
                onTap: onCheckIn,
                child: Icon(
                  circle.checkedInToday
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 28,
                  color: circle.checkedInToday
                      ? AppColors.primary
                      : AppColors.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner que invita a entrar al Ágora Tribal (leaderboard/social) desde
/// Rachas, ya que hoy no hay una pestaña dedicada en la nav inferior.
class _AgoraEntryBanner extends StatelessWidget {
  const _AgoraEntryBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.celebrationStart, AppColors.celebrationEnd],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'El Gran Ágora Tribal',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Mira la hoguera de cada círculo y quién lidera la tribu.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _EmptyStreaksCard extends StatelessWidget {
  const _EmptyStreaksCard({required this.onCreateCircle});

  final VoidCallback onCreateCircle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.outlineWhisper),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Todavía no hay rachas',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Crea un círculo y registra tu primer check-in para empezar a '
            'ver tu progreso aquí.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreateCircle,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear círculo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldenRuleCard extends StatelessWidget {
  const _GoldenRuleCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.celebrationEnd,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Regla de Oro de Racha Tribu',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Un día difícil no rompe la racha si vuelves al siguiente. '
                  'Tu bienestar siempre es primero.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
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
