import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/check_in.dart';
import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/milestone.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/adaptive_glass.dart';
import 'package:edtech_tiktok/features/widgets/app_bottom_nav.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';
import 'package:edtech_tiktok/features/widgets/ritual_path.dart';

/// Pantalla "Rachas": muestra la racha global y por círculo, la semana en
/// curso y los próximos hitos, todo derivado de los check-ins reales
/// almacenados en cada [HabitCircle] — no hay cifras de ejemplo.
///
/// Rediseño de Stitch ("Rachas Activas del Clan"): el toggle "TUS RACHAS" /
/// "RACHA DE TRIBU" de la mockup se mapea 1:1 a algo que ya existe en el
/// modelo — tu racha personal (global) vs. la racha de cada círculo/clan —
/// en vez de inventar un concepto nuevo.
class RachasPage extends StatefulWidget {
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
  State<RachasPage> createState() => _RachasPageState();
}

enum _RachasTab { personal, tribu }

class _RachasPageState extends State<RachasPage> {
  _RachasTab _tab = _RachasTab.personal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final circles = widget.circles;
    final overallStreakDays = widget.overallStreakDays;
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
    final unlockedRites = milestones.where((m) => m.unlocked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.rachas,
        onCreateCircle: widget.onCreateCircle,
        onOpenCircles: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        onOpenGames: widget.onOpenGames,
        onOpenProfile: widget.onOpenProfile,
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
                '⚡ NEXOS DE ENERGÍA',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.tertiary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.06,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Rachas Activas del Clan',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _AgoraShortcutButton(onTap: widget.onOpenAgora),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _RachasTabSwitch(
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: AppSpacing.lg),
              _TribalFireCard(
                circleCount: circles.length,
                overallStreakDays: overallStreakDays,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Ciclo Semanal Tribal',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _WeekCard(circles: circles),
              const SizedBox(height: AppSpacing.xl2),
              if (_tab == _RachasTab.personal) ...[
                _PersonalStreakCard(
                  overallStreakDays: overallStreakDays,
                  nextMilestone: nextMilestone,
                  daysToGo: daysToGo,
                  progress: milestoneProgress,
                  onSeeRewards: widget.onOpenProfile,
                ),
              ] else ...[
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
                  _EmptyStreaksCard(onCreateCircle: widget.onCreateCircle)
                else
                  for (final circle in circles) ...[
                    _ClanStreakCard(
                      circle: circle,
                      onCheckIn: () => widget.onCheckIn(circle),
                      onTap: () => widget.onOpenCircle(circle),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  const Text('📖', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'El Libro de los Ritos & Tótems',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$unlockedRites/${milestones.length} Tótems',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
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
              const SizedBox(height: AppSpacing.lg),
              GamePressable(
                onTap: widget.onOpenProfile,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onOpenProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    child: const Text('✨ VER RITOS Y TÓTEMS EN TU PERFIL'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _GoldenRuleCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgoraShortcutButton extends StatelessWidget {
  const _AgoraShortcutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GamePressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outlineWhisper),
        ),
        child: const Icon(
          Icons.center_focus_strong_rounded,
          color: AppColors.tertiary,
          size: 20,
        ),
      ),
    );
  }
}

/// Segmentado "TUS RACHAS" / "RACHA DE TRIBU" — alterna entre la racha
/// personal (global) y la lista de círculos, dos vistas que ya existían por
/// separado y ahora comparten pestaña como en la mockup de Stitch.
class _RachasTabSwitch extends StatelessWidget {
  const _RachasTabSwitch({required this.selected, required this.onChanged});

  final _RachasTab selected;
  final ValueChanged<_RachasTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RachasTabChip(
            label: '⚡ TUS RACHAS',
            active: selected == _RachasTab.personal,
            onTap: () => onChanged(_RachasTab.personal),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _RachasTabChip(
            label: '👥 RACHA DE TRIBU',
            active: selected == _RachasTab.tribu,
            onTap: () => onChanged(_RachasTab.tribu),
          ),
        ),
      ],
    );
  }
}

class _RachasTabChip extends StatelessWidget {
  const _RachasTabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GamePressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: active ? Colors.white : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// "Fuego Tribal Activo": resume cuántas rachas personales/de círculo hay
/// activas ahora mismo, sin inventar un contador nuevo — son los mismos
/// `circles` y `overallStreakDays` que el resto de la pantalla usa.
class _TribalFireCard extends StatelessWidget {
  const _TribalFireCard({
    required this.circleCount,
    required this.overallStreakDays,
  });

  final int circleCount;
  final int overallStreakDays;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = overallStreakDays > 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineWhisper),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fuego Tribal Activo',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$circleCount ${circleCount == 1 ? "Racha" : "Rachas"} '
                  'Personal${circleCount == 1 ? "" : "es"} • '
                  '$overallStreakDays Días de Tribu',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.tertiary.withValues(alpha: 0.15)
                  : AppColors.outlineWhisper,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              active ? 'ACTIVO' : 'INACTIVO',
              style: textTheme.labelSmall?.copyWith(
                color: active ? AppColors.tertiary : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Constancia Diaria" — la racha personal (global) del jugador, con el
/// mismo dato (`overallStreakDays`) y sistema de hitos (`Milestone`) que ya
/// existían, restyleado como la tarjeta de borde ígneo de la mockup.
class _PersonalStreakCard extends StatelessWidget {
  const _PersonalStreakCard({
    required this.overallStreakDays,
    required this.nextMilestone,
    required this.daysToGo,
    required this.progress,
    required this.onSeeRewards,
  });

  final int overallStreakDays;
  final int nextMilestone;
  final int daysToGo;
  final double progress;
  final VoidCallback onSeeRewards;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: AppShadows.streak,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GUERRERO',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.06,
                      ),
                    ),
                    Text(
                      'Constancia Diaria',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '🔥 ${overallStreakDays}d',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            overallStreakDays > 0
                ? 'Renueva antes de medianoche'
                : 'Haz tu primer check-in para empezar',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hito $nextMilestone Días',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                daysToGo == 0
                    ? '¡Completado!'
                    : '${(progress * 100).round()}% completado',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
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
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GamePressable(
            onTap: onSeeRewards,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSeeRewards,
                child: const Text('VER RECOMPENSAS DE RACHA'),
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

    return AdaptiveGlassCard(
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

/// "Racha Colectiva" de un círculo — mismo dato real que antes
/// (`circle.streakDays`, `circle.totalMembers`, `circle.members`), pero
/// restyleado como la tarjeta "CLAN CYBERFÉNIX" de la mockup: progreso
/// hacia el próximo hito (`Milestone.evaluate` aplicado a la racha de ESE
/// círculo) y una pila de iniciales reales de sus miembros.
class _ClanStreakCard extends StatelessWidget {
  const _ClanStreakCard({
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
    final milestones = Milestone.evaluate(circle.streakDays);
    final currentQuest = milestones.firstWhere(
      (m) => !m.unlocked,
      orElse: () => milestones.last,
    );
    final visibleMembers = circle.members.take(3).toList();
    final extraMembers = circle.members.length - visibleMembers.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.tertiary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icons.shield_rounded,
                    color: AppColors.tertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLAN ${circle.name.toUpperCase()}',
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Racha Colectiva',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${circle.streakDays}d',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.onTertiary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${circle.totalMembers} guerreros sincronizados',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💎 ${currentQuest.title} (${currentQuest.requiredDays} Días)',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${(currentQuest.progress * 100).round()}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: currentQuest.progress,
                minHeight: 8,
                backgroundColor: AppColors.surface,
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                SizedBox(
                  width:
                      20.0 * visibleMembers.length +
                      (extraMembers > 0 ? 24 : 0),
                  height: 24,
                  child: Stack(
                    children: [
                      for (var i = 0; i < visibleMembers.length; i++)
                        Positioned(
                          left: i * 20.0,
                          child: _MemberInitialsAvatar(name: visibleMembers[i]),
                        ),
                      if (extraMembers > 0)
                        Positioned(
                          left: visibleMembers.length * 20.0,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.surface,
                            child: Text(
                              '+$extraMembers',
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (circle.freezesAvailable > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '🛡️${circle.freezesAvailable}',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const Spacer(),
                GamePressable(
                  onTap: onCheckIn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: circle.checkedInToday
                          ? AppColors.completedGlow
                          : AppColors.tertiary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      circle.checkedInToday ? 'HOY LISTO ✓' : 'ANIMAR CLAN',
                      style: textTheme.labelSmall?.copyWith(
                        color: circle.checkedInToday
                            ? AppColors.tertiary
                            : AppColors.onTertiary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberInitialsAvatar extends StatelessWidget {
  const _MemberInitialsAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary,
        border: Border.all(color: AppColors.background, width: 2),
      ),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w800,
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
