import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/check_in.dart';
import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/theme/app_assets.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/app_bottom_nav.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';

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
    required this.constancyDrops,
    required this.userLevel,
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
  final int constancyDrops;
  final int userLevel;
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
        onOpenCircles: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        onOpenRachas: onOpenRachas,
      ),
      body: SafeArea(
        bottom: false,
        child: AppMaxWidth(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg)
                .copyWith(
                  bottom: AppSpacing.xl2 +
                      AppBottomNav.reservedHeight +
                      MediaQuery.paddingOf(context).bottom,
                ),
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
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ProfileLevelPill(level: userLevel),
                        const SizedBox(width: AppSpacing.sm),
                        ConstancyDropsPill(drops: constancyDrops),
                      ],
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
                      'Tótems de Maestría',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Desliza tu vitrina de tótems coleccionables. Cada uno se '
                'esculpe al alcanzar su rito.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _TotemShowcase(
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
    if (memberSince == null) return 'Miembro de Racha Tribu';
    return 'Miembro desde ${_kMonthNames[memberSince.month - 1]} de '
        '${memberSince.year}';
  }

  static String _currentMonthName() => _kMonthNames[DateTime.now().month - 1];
}

/// Insignia de "nivel" derivada de la racha general, igual criterio que en
/// el dashboard (cada 7 días de racha suma un nivel), para reforzar la
/// sensación de progresión tipo juego también en el perfil.
class _ProfileLevelPill extends StatelessWidget {
  const _ProfileLevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.military_tech_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'Nivel $level',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
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
    final isToday = day == today;
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: isToday
              ? Border.all(color: AppColors.secondary, width: 1.5)
              : null,
        ),
      ),
    );
  }
}

/// Logros calculados a partir de la racha activa, el récord histórico y si
/// algún círculo llegó al 100% hoy — todo derivable de los datos reales del
/// usuario, sin contadores sociales inventados. Se muestran como una vitrina
/// interactiva de tótems 3D en vez de una grilla plana de insignias.
class _TotemShowcase extends StatefulWidget {
  const _TotemShowcase({
    required this.overallStreakDays,
    required this.recordStreakDays,
    required this.hasPerfectCircle,
  });

  final int overallStreakDays;
  final int recordStreakDays;
  final bool hasPerfectCircle;

  @override
  State<_TotemShowcase> createState() => _TotemShowcaseState();
}

class _TotemShowcaseState extends State<_TotemShowcase> {
  late final PageController _controller = PageController(viewportFraction: 0.42);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totems = [
      _TotemData(
        icon: Icons.shield_moon_rounded,
        colors: const [AppColors.secondaryContainer, AppColors.secondary],
        title: 'Semana Imbatible',
        subtitle: '7 días seguidos sin fallar',
        unlocked: widget.overallStreakDays >= 7,
      ),
      _TotemData(
        icon: Icons.spa_rounded,
        colors: const [AppColors.primaryContainer, AppColors.primary],
        title: 'Hábito Consolidado',
        subtitle: '21 días de racha histórica',
        unlocked: widget.recordStreakDays >= 21,
      ),
      _TotemData(
        icon: Icons.celebration_rounded,
        colors: const [AppColors.lavenderContainer, AppColors.secondary],
        title: 'Círculo Perfecto',
        subtitle: '100% completado en un día',
        unlocked: widget.hasPerfectCircle,
      ),
      _TotemData(
        icon: Icons.workspace_premium_rounded,
        colors: const [AppColors.warningContainer, AppColors.secondary],
        title: 'Pacto de 30 Días',
        subtitle: '${widget.recordStreakDays.clamp(0, 30)}/30 días',
        unlocked: widget.recordStreakDays >= 30,
        progress: (widget.recordStreakDays / 30).clamp(0, 1).toDouble(),
      ),
    ];

    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: _controller,
        itemCount: totems.length,
        padEnds: true,
        itemBuilder: (context, index) {
          final delta = (index - _page).abs().clamp(0.0, 1.0);
          final scale = 1 - delta * 0.22;
          final rotation = (index - _page).clamp(-1.0, 1.0) * 0.12;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(rotation)
              ..scaleByDouble(scale, scale, scale, 1),
            child: Opacity(
              opacity: 1 - delta * 0.35,
              child: _MasteryTotem(data: totems[index]),
            ),
          );
        },
      ),
    );
  }
}

class _TotemData {
  const _TotemData({
    required this.icon,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.unlocked,
    this.progress,
  });

  final IconData icon;
  final List<Color> colors;
  final String title;
  final String subtitle;
  final bool unlocked;
  final double? progress;
}

/// Un tótem coleccionable individual: un bloque con profundidad 3D
/// (ver [Iso3DIcon]) que se "esculpe" (aparece con rebote) al desbloquearse,
/// o se ve en piedra gris mientras sigue bloqueado.
class _MasteryTotem extends StatelessWidget {
  const _MasteryTotem({required this.data});

  final _TotemData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unlocked = data.unlocked;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: unlocked
            ? Border.all(color: AppColors.secondary.withValues(alpha: 0.35))
            : Border.all(color: AppColors.outlineWhisper),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ]
            : AppShadows.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey('totem-${data.title}-$unlocked'),
            tween: Tween(begin: unlocked ? 0.3 : 1.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Iso3DIcon(
              icon: data.icon,
              size: 52,
              colors: unlocked
                  ? data.colors
                  : [AppColors.surfaceContainer, AppColors.outline],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          if (data.progress != null && !unlocked)
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: data.progress,
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceContainer,
                  color: AppColors.secondary,
                ),
              ),
            )
          else
            Text(
              unlocked ? 'Esculpido' : 'En bruto',
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
