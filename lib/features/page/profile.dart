import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/check_in.dart';
import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/theme/app_assets.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/app_bottom_nav.dart';

const List<String> _kMonthNames = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Pantalla de perfil: solo muestra métricas que se pueden calcular a partir
/// de datos reales del usuario (círculos y check-ins persistidos). No hay
/// contadores sociales (toques de aliento, insignias de otros miembros) ni
/// recordatorios, porque todavía no existe backend multiusuario ni
/// notificaciones — se agregarán cuando esa funcionalidad exista de verdad.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.username,
    required this.memberSince,
    required this.overallStreakDays,
    required this.recordStreakDays,
    required this.monthlyComplianceRate,
    required this.circles,
    required this.onOpenCircle,
    required this.onOpenRachas,
    required this.onCreateCircle,
  });

  final String username;
  final DateTime? memberSince;
  final int overallStreakDays;
  final int recordStreakDays;
  final double monthlyComplianceRate;
  final List<HabitCircle> circles;
  final ValueChanged<HabitCircle> onOpenCircle;
  final VoidCallback onOpenRachas;
  final VoidCallback onCreateCircle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final perfectCount = circles.where((c) => c.isPerfect).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.profile,
        onCreateCircle: onCreateCircle,
        onOpenCircles: () => Navigator.of(context).pop(),
        onOpenRachas: onOpenRachas,
      ),
      body: SafeArea(
        bottom: false,
        child: AppMaxWidth(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg)
                .copyWith(bottom: AppSpacing.xl2),
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
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _memberSinceLabel(memberSince),
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
                  const Icon(
                    Icons.eco_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Tu Ritmo Vital',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.bolt_rounded,
                      color: AppColors.secondary,
                      value: '$overallStreakDays días',
                      label: 'Racha activa',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.emoji_events_rounded,
                      color: AppColors.primary,
                      value: '$recordStreakDays días',
                      label: 'Récord personal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.donut_large_rounded,
                      color: AppColors.primary,
                      value: '${(monthlyComplianceRate * 100).round()}%',
                      label: 'Cumplimiento (mes de ${_currentMonthName()})',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.group_rounded,
                      color: AppColors.secondary,
                      value: '${circles.length}',
                      label: 'Círculos activos',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Mapa de Presencia',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'Últimas 10 semanas',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Cada día cuenta para tu constancia, sin culpas ni presiones '
                'innecesarias.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PresenceMap(circles: circles),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                children: [
                  const Icon(
                    Icons.military_tech_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Insignias de Esfuerzo',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _BadgeGrid(
                overallStreakDays: overallStreakDays,
                recordStreakDays: recordStreakDays,
                hasPerfectCircle: perfectCount > 0,
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                'Tus círculos',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (circles.isEmpty)
                Text(
                  'Aún no tienes círculos.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              else
                for (final circle in circles) ...[
                  _CircleRow(circle: circle, onTap: () => onOpenCircle(circle)),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
      ),
    );
  }

  static String _memberSinceLabel(DateTime? memberSince) {
    if (memberSince == null) return 'Miembro de CírculoDiario';
    return 'Miembro desde ${_kMonthNames[memberSince.month - 1]} de '
        '${memberSince.year}';
  }

  static String _currentMonthName() => _kMonthNames[DateTime.now().month - 1];
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuadrícula de 10 semanas x 7 días. Cada celda refleja la fracción real de
/// círculos con check-in en ese día (0 = sin actividad, 1 = todos los
/// círculos activos ese día), no valores de ejemplo.
class _PresenceMap extends StatelessWidget {
  const _PresenceMap({required this.circles});

  final List<HabitCircle> circles;

  static const _labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _weeks = 10;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final today = CheckIn.today();
    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
    final gridStart = startOfThisWeek.subtract(
      const Duration(days: 7 * (_weeks - 1)),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (var row = 0; row < 7; row++) ...[
            Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text(
                    _labels[row],
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Row(
                    children: [
                      for (var week = 0; week < _weeks; week++) ...[
                        if (week > 0) const SizedBox(width: 4),
                        Expanded(
                          child: _PresenceCell(
                            day: gridStart.add(Duration(days: week * 7 + row)),
                            today: today,
                            circles: circles,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (row < 6) const SizedBox(height: 4),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Ritmo suave',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Plena presencia',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresenceCell extends StatelessWidget {
  const _PresenceCell({
    required this.day,
    required this.today,
    required this.circles,
  });

  final DateTime day;
  final DateTime today;
  final List<HabitCircle> circles;

  @override
  Widget build(BuildContext context) {
    if (day.isAfter(today) || circles.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.outlineWhisper,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }
    final completed = circles
        .where((c) => c.checkIns.any((ci) => ci.date == day))
        .length;
    final fraction = completed / circles.length;
    final color = Color.lerp(
      AppColors.surfaceContainer,
      AppColors.primary,
      fraction,
    )!;
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Logros calculados a partir de la racha activa, el récord histórico y si
/// algún círculo llegó al 100% hoy — todo derivable de los datos reales del
/// usuario, sin contadores sociales inventados.
class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({
    required this.overallStreakDays,
    required this.recordStreakDays,
    required this.hasPerfectCircle,
  });

  final int overallStreakDays;
  final int recordStreakDays;
  final bool hasPerfectCircle;

  @override
  Widget build(BuildContext context) {
    final badges = [
      _Badge(
        icon: Icons.shield_moon_rounded,
        title: 'Semana Imbatible',
        subtitle: '7 días seguidos sin fallar',
        unlocked: overallStreakDays >= 7,
      ),
      _Badge(
        icon: Icons.spa_rounded,
        title: 'Hábito Consolidado',
        subtitle: '21 días de racha histórica',
        unlocked: recordStreakDays >= 21,
      ),
      _Badge(
        icon: Icons.celebration_rounded,
        title: 'Círculo Perfecto',
        subtitle: '100% completado en un día',
        unlocked: hasPerfectCircle,
      ),
      _Badge(
        icon: Icons.workspace_premium_rounded,
        title: 'Pacto de 30 Días',
        subtitle: '${recordStreakDays.clamp(0, 30)}/30 días',
        unlocked: recordStreakDays >= 30,
        progress: (recordStreakDays / 30).clamp(0, 1).toDouble(),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.92,
      children: badges,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.unlocked,
    this.progress,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool unlocked;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = unlocked ? AppColors.secondary : AppColors.outline;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: unlocked
                ? AppColors.warningContainer
                : AppColors.surfaceContainer,
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (progress != null && !unlocked)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.surfaceContainer,
                color: AppColors.secondary,
              ),
            )
          else
            Text(
              unlocked ? 'Desbloqueado' : 'Bloqueado',
              style: textTheme.labelSmall?.copyWith(
                color: unlocked ? AppColors.primary : AppColors.outline,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleRow extends StatelessWidget {
  const _CircleRow({required this.circle, required this.onTap});

  final HabitCircle circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
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
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
      ),
    );
  }
}
