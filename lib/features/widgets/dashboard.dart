import 'package:flutter/material.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/today_habit.dart';
import 'package:edtech_tiktok/core/model/trivia_question.dart';
import 'package:edtech_tiktok/core/theme/app_assets.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/logic/logic.dart';
import 'package:edtech_tiktok/features/widgets/app_bottom_nav.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';
import 'package:edtech_tiktok/features/widgets/territory_map.dart';

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
    required this.constancyDrops,
    required this.userLevel,
    required this.onCreateCircle,
    required this.onCheckIn,
    required this.onToggleTodayHabit,
    required this.onAddTodayHabit,
    required this.onOpenCircle,
    required this.onOpenRachas,
    required this.onOpenProfile,
    required this.onInviteMember,
    required this.allies,
    required this.todaysTrivia,
    required this.hasAnsweredTodaysTrivia,
    required this.triviaLastSelectedIndex,
    required this.onAnswerTrivia,
    required this.hasPendingPredictionToday,
    required this.pendingPredictionCircleId,
    required this.predictionBetAmount,
    required this.onPlacePrediction,
    required this.hasSpunTodaysWheel,
    required this.wheelLastReward,
    required this.onSpinWheel,
    required this.weeklyDuelUserTotal,
    required this.weeklyDuelRivalTotal,
    required this.hasWonWeeklyDuel,
  });

  final String username;
  final List<HabitCircle> circles;
  final List<String> allies;
  final List<TodayHabit> todayHabits;
  final int todayCompletedCount;
  final int todayTotalCount;
  final double todayProgress;
  final TodayHabit? nextPendingHabit;
  final int overallStreakDays;
  final int streakPulseTick;
  final int constancyDrops;
  final int userLevel;
  final VoidCallback onCreateCircle;
  final ValueChanged<HabitCircle> onCheckIn;
  final ValueChanged<TodayHabit> onToggleTodayHabit;
  final ValueChanged<String> onAddTodayHabit;
  final ValueChanged<HabitCircle> onOpenCircle;
  final VoidCallback onOpenRachas;
  final VoidCallback onOpenProfile;
  final void Function(HabitCircle circle, String name) onInviteMember;

  /// "Desafío del día" (ver `HomeLogic.todaysTrivia`).
  final TriviaQuestion todaysTrivia;
  final bool hasAnsweredTodaysTrivia;
  final int? triviaLastSelectedIndex;
  final bool Function(int selectedIndex) onAnswerTrivia;

  /// "Predicción de Tribu" (ver `HomeLogic.placePrediction`).
  final bool hasPendingPredictionToday;
  final String? pendingPredictionCircleId;
  final int predictionBetAmount;
  final bool Function(HabitCircle circle) onPlacePrediction;

  /// "Ruleta diaria de gotas" (ver `HomeLogic.spinWheel`).
  final bool hasSpunTodaysWheel;
  final int? wheelLastReward;
  final int Function() onSpinWheel;

  /// "Duelo de Racha Semanal" (ver `HomeLogic.weeklyDuelUserTotal`).
  final int weeklyDuelUserTotal;
  final int weeklyDuelRivalTotal;
  final bool hasWonWeeklyDuel;

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
                .copyWith(
                  bottom:
                      AppSpacing.xl2 +
                      AppBottomNav.reservedHeight +
                      MediaQuery.paddingOf(context).bottom,
                ),
            children: [
              const SizedBox(height: AppSpacing.sm),
              _TopBar(
                streakDays: overallStreakDays,
                pulseTick: streakPulseTick,
                constancyDrops: constancyDrops,
                userLevel: userLevel,
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
              _TriviaCard(
                question: todaysTrivia,
                answered: hasAnsweredTodaysTrivia,
                selectedIndex: triviaLastSelectedIndex,
                onAnswer: onAnswerTrivia,
              ),
              if (circles.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _PredictionCard(
                  circles: circles,
                  hasPending: hasPendingPredictionToday,
                  pendingCircleId: pendingPredictionCircleId,
                  betAmount: predictionBetAmount,
                  affordable: constancyDrops >= predictionBetAmount,
                  onPlacePrediction: onPlacePrediction,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _WheelCard(
                hasSpun: hasSpunTodaysWheel,
                lastReward: wheelLastReward,
                onSpin: onSpinWheel,
              ),
              const SizedBox(height: AppSpacing.lg),
              _WeeklyDuelCard(
                userTotal: weeklyDuelUserTotal,
                rivalTotal: weeklyDuelRivalTotal,
                won: hasWonWeeklyDuel,
              ),
              const SizedBox(height: AppSpacing.lg),
              _TodayCard(
                habits: todayHabits,
                completed: todayCompletedCount,
                total: todayTotalCount,
                progress: todayProgress,
                onToggle: onToggleTodayHabit,
                onAdd: onAddTodayHabit,
              ),
              if (todayTotalCount > 0 && todayProgress >= 1.0) ...[
                const SizedBox(height: AppSpacing.md),
                const _AllDoneBanner(),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (nextPendingHabit != null)
                GamePressable(
                  onTap: () => onToggleTodayHabit(nextPendingHabit!),
                  child: SizedBox(
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
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: circles.isEmpty
                        ? null
                        : () => _showManageCirclesSheet(
                            context,
                            circles: circles,
                            allies: allies,
                            onOpenCircle: onOpenCircle,
                            onInviteMember: onInviteMember,
                          ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        'Gestionar',
                        style: textTheme.labelLarge?.copyWith(
                          color: circles.isEmpty
                              ? AppColors.onSurfaceVariant
                              : AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (circles.isEmpty)
                _EmptyCirclesCard(onCreateCircle: onCreateCircle)
              else ...[
                TerritoryMap(
                  circles: circles,
                  onCheckIn: onCheckIn,
                  onTap: onOpenCircle,
                ),
                const SizedBox(height: AppSpacing.lg),
                _InviteBanner(
                  onInvite: (name) =>
                      onInviteMember(_circleWithRoom(circles), name),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// El círculo con menos miembros es el más "urgente" para invitar a alguien.
HabitCircle _circleWithRoom(List<HabitCircle> circles) =>
    circles.reduce((a, b) => a.totalMembers <= b.totalMembers ? a : b);

/// Hoja de "Gestionar": lista los círculos del jugador (para abrir su
/// detalle) y sus aliados (agregados por QR o solicitud) listos para sumar
/// a un círculo con un toque, sin tener que volver a escribir el nombre.
void _showManageCirclesSheet(
  BuildContext context, {
  required List<HabitCircle> circles,
  required List<String> allies,
  required ValueChanged<HabitCircle> onOpenCircle,
  required void Function(HabitCircle circle, String name) onInviteMember,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) => _ManageCirclesSheet(
      circles: circles,
      allies: allies,
      onOpenCircle: (circle) {
        Navigator.of(sheetContext).pop();
        onOpenCircle(circle);
      },
      onInviteMember: onInviteMember,
    ),
  );
}

class _ManageCirclesSheet extends StatelessWidget {
  const _ManageCirclesSheet({
    required this.circles,
    required this.allies,
    required this.onOpenCircle,
    required this.onInviteMember,
  });

  final List<HabitCircle> circles;
  final List<String> allies;
  final ValueChanged<HabitCircle> onOpenCircle;
  final void Function(HabitCircle circle, String name) onInviteMember;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tus círculos',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final circle in circles)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GamePressable(
                  onTap: () => onOpenCircle(circle),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            circle.name,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${circle.totalMembers} miembros',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tus aliados',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Solo se guardan en este dispositivo: "Agregar" no invita a nadie '
              'de verdad ni avisa al otro teléfono.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (allies.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'Aún no tienes aliados. Ve a "Invocar por QR" para agregar '
                  'a alguien cara a cara.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final ally in allies)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.surfaceContainer,
                        child: Text(
                          ally.isNotEmpty ? ally[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '@$ally',
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      if (circles.isNotEmpty)
                        if (circles.every((c) => c.members.contains(ally)))
                          Text(
                            'Ya en el círculo',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          )
                        else
                          TextButton(
                            onPressed: () => _promptAddAllyToCircle(
                              context,
                              circles,
                              ally,
                              onInviteMember,
                            ),
                            child: const Text('Agregar'),
                          ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Si hay un solo círculo lo agrega directo; con varios, pide elegir cuál.
Future<void> _promptAddAllyToCircle(
  BuildContext context,
  List<HabitCircle> circles,
  String allyUsername,
  void Function(HabitCircle circle, String name) onInviteMember,
) async {
  final available = circles
      .where((c) => !c.members.contains(allyUsername))
      .toList();
  if (available.isEmpty) return;
  if (available.length == 1) {
    onInviteMember(available.first, allyUsername);
    return;
  }
  final chosen = await showDialog<HabitCircle>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('¿A qué círculo?'),
      children: [
        for (final circle in available)
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(circle),
            child: Text(circle.name),
          ),
      ],
    ),
  );
  if (chosen != null) onInviteMember(chosen, allyUsername);
}

/// Diálogo para agregar un miembro simulado a un círculo. Sin backend, no
/// hay envío real de invitación: solo se guarda el nombre localmente.
Future<void> _showInviteDialog(
  BuildContext context,
  ValueChanged<String> onInvite,
) async {
  final name = await showDialog<String>(
    context: context,
    builder: (context) => const _InviteMemberDialog(),
  );
  if (name != null && name.trim().isNotEmpty) onInvite(name.trim());
}

/// El controller debe vivir y morir junto al State del diálogo: si se
/// dispone justo después de `showDialog`, la animación de salida (que aún
/// referencia el TextField) puede intentar usarlo ya destruido.
class _InviteMemberDialog extends StatefulWidget {
  const _InviteMemberDialog();

  @override
  State<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<_InviteMemberDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invitar a un amigo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Nombre del amigo'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          const SizedBox(height: 8),
          Text(
            'Se agrega solo en este teléfono, como marcador visual: tu '
            'amigo no recibe ninguna invitación real.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Invitar'),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.streakDays,
    required this.pulseTick,
    required this.constancyDrops,
    required this.userLevel,
  });

  final int streakDays;
  final int pulseTick;
  final int constancyDrops;
  final int userLevel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(AppAssets.logo, width: 28, height: 28),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Racha Tribu',
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
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _LevelPill(level: userLevel),
            const SizedBox(width: AppSpacing.sm),
            ConstancyDropsPill(drops: constancyDrops),
          ],
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

/// Insignia de "nivel" derivada de la racha general: cada 7 días de racha
/// suma un nivel. Es puramente decorativo (sin backend) pero refuerza la
/// sensación de progreso tipo juego.
class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});

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
            'Nv. $level',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Celebración que aparece al completar el 100% del check-in diario, para
/// dar una recompensa visual inmediata (refuerzo tipo juego).
class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.celebrationStart, AppColors.celebrationEnd],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '¡Día completo! Tu tribu sigue avanzando contigo.',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
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

/// "Desafío del día": trivia de opción múltiple sobre hábitos/constancia
/// (ver `HomeLogic.todaysTrivia`), la misma para todos los usuarios ese día.
/// Antes de responder muestra las 4 opciones tocables; después, resalta la
/// correcta (y la elegida, si falló) y muestra la explicación + si ganó
/// gotas. Es [StatelessWidget]: todo el estado (si ya respondió, qué
/// eligió) vive en [HomeLogic] y llega por props, así que sobrevive a que
/// se cierre y reabra la app.
class _TriviaCard extends StatelessWidget {
  const _TriviaCard({
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
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
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

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({
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
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
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

class _WheelCard extends StatelessWidget {
  const _WheelCard({
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
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
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

class _WeeklyDuelCard extends StatelessWidget {
  const _WeeklyDuelCard({
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
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.surface,
                color: AppColors.primary,
              ),
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
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('${habit.label}-${habit.done}'),
                    tween: Tween(begin: habit.done ? 1.3 : 1.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
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
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.6,
                          ),
                          child: Text(
                            habit.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
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
  const _InviteBanner({required this.onInvite});

  final ValueChanged<String> onInvite;

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
            onPressed: () => _showInviteDialog(context, onInvite),
            child: const Text('Invitar'),
          ),
        ],
      ),
    );
  }
}
