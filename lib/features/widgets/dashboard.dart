import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/today_habit.dart';
import 'package:edtech_tiktok/core/theme/app_assets.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/app_bottom_nav.dart';
import 'package:edtech_tiktok/features/widgets/circle_card.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.username,
    required this.circles,
    required this.todayHabits,
    required this.todayCompletedCount,
    required this.todayTotalCount,
    required this.todayProgress,
    required this.nextPendingHabit,
    required this.overallStreakDays,
    required this.streakPulseTick,
    required this.onCreateCircle,
    required this.onCheckIn,
    required this.onToggleTodayHabit,
    required this.onAddTodayHabit,
    required this.onOpenCircle,
    required this.onOpenRachas,
    required this.onOpenProfile,
  });

  final String username;
  final List<HabitCircle> circles;
  final List<TodayHabit> todayHabits;
  final int todayCompletedCount;
  final int todayTotalCount;
  final double todayProgress;
  final TodayHabit? nextPendingHabit;
  final int overallStreakDays;
  final int streakPulseTick;
  final VoidCallback onCreateCircle;
  final ValueChanged<HabitCircle> onCheckIn;
  final ValueChanged<TodayHabit> onToggleTodayHabit;
  final ValueChanged<String> onAddTodayHabit;
  final ValueChanged<HabitCircle> onOpenCircle;
  final VoidCallback onOpenRachas;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.circles,
        onCreateCircle: onCreateCircle,
        onOpenRachas: onOpenRachas,
        onOpenProfile: onOpenProfile,
      ),
      body: SafeArea(
        bottom: false,
        child: AppMaxWidth(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)
                .copyWith(bottom: AppSpacing.xl2),
            children: [
              const SizedBox(height: AppSpacing.sm),
              _TopBar(
                streakDays: overallStreakDays,
                pulseTick: streakPulseTick,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                '¡Buen día, $username! 👋',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tu tribu te espera. La constancia compartida pesa la mitad.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _TodayCard(
                habits: todayHabits,
                completed: todayCompletedCount,
                total: todayTotalCount,
                progress: todayProgress,
                onToggle: onToggleTodayHabit,
                onAdd: onAddTodayHabit,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (nextPendingHabit != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => onToggleTodayHabit(nextPendingHabit!),
                    icon: const Icon(Icons.playlist_add_check_rounded),
                    label: Text(
                      'Registrar hábito pendiente (${nextPendingHabit!.label})',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Tus Círculos Activos',
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CountPill(count: circles.length),
                  const Spacer(),
                  Text(
                    'Gestionar',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (circles.isEmpty)
                _EmptyCirclesCard(onCreateCircle: onCreateCircle)
              else ...[
                for (final circle in circles) ...[
                  CircleCard(
                    circle: circle,
                    onCheckIn: () => onCheckIn(circle),
                    onTap: () => onOpenCircle(circle),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                const _InviteBanner(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.streakDays, required this.pulseTick});

  final int streakDays;
  final int pulseTick;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Image.asset(AppAssets.logo, width: 28, height: 28),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'CírculoDiario',
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const Spacer(),
        _StreakPill(days: streakDays, pulseTick: pulseTick),
        const SizedBox(width: AppSpacing.md),
        const CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.surfaceContainer,
          backgroundImage: AssetImage(AppAssets.avatarSample),
        ),
      ],
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days, required this.pulseTick});

  final int days;
  final int pulseTick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StreakFirePulse(
            key: ValueKey(pulseTick),
            child: const Text('🔥', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$days DÍAS',
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

/// Pulso ligero (escala con rebote) que se reproduce una vez cada vez que
/// se le asigna una nueva [Key]. Se usa en el ícono de fuego para reforzar
/// visualmente que se completó un hábito o check-in.
class _StreakFirePulse extends StatelessWidget {
  const _StreakFirePulse({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.5, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.habits,
    required this.completed,
    required this.total,
    required this.progress,
    required this.onToggle,
    required this.onAdd,
  });

  final List<TodayHabit> habits;
  final int completed;
  final int total;
  final double progress;
  final ValueChanged<TodayHabit> onToggle;
  final ValueChanged<String> onAdd;

  Future<void> _promptAddHabit(BuildContext context) async {
    final label = await showDialog<String>(
      context: context,
      builder: (context) => const _AddHabitDialog(),
    );
    if (label != null && label.trim().isNotEmpty) onAdd(label);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lavenderContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.completedGlow,
                child: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-in de hoy',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$completed de $total completados',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surface,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (habits.isEmpty)
            Text(
              'Aún no tienes hábitos diarios. Agrega el primero.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              for (final habit in habits)
                InkWell(
                  onTap: () => onToggle(habit),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        habit.done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: habit.done
                            ? AppColors.primary
                            : AppColors.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        habit.label,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              InkWell(
                onTap: () => _promptAddHabit(context),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Agregar hábito',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Diálogo para crear un hábito diario nuevo. Es un [StatefulWidget] para
/// que el `TextEditingController` viva y se destruya junto con el propio
/// diálogo (incluida su animación de cierre) en vez de ser desechado a mano
/// justo después del `await showDialog`, lo que puede correr una carrera
/// contra la transición de salida y usar el controller ya destruido.
class _AddHabitDialog extends StatefulWidget {
  const _AddHabitDialog();

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo hábito diario'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Ej. Beber 2L de agua'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Agregar')),
      ],
    );
  }
}

class _EmptyCirclesCard extends StatelessWidget {
  const _EmptyCirclesCard({required this.onCreateCircle});

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
            'Aún no tienes círculos',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Crea tu primer círculo de hábito para empezar a acumular racha.',
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

class _InviteBanner extends StatelessWidget {
  const _InviteBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lavenderContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surface,
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Círculo con cupo libre',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Invita a un amigo y asegura 2x compromiso.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              shape: const StadiumBorder(),
            ),
            onPressed: () {},
            child: const Text('Invitar'),
          ),
        ],
      ),
    );
  }
}
