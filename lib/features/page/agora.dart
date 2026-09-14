import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/activity_event.dart';
import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/adaptive_glass.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';

/// "El Gran Ágora Tribal": reemplaza las notificaciones de texto simples
/// ("¡Círculo Perfecto!") por un mapa de juego social. Cada círculo se ve
/// como una hoguera tribal — más grande y brillante cuanto mayor es su racha
/// colectiva — rodeada de los avatares de sus miembros, y una lista de
/// maestros ordena los círculos por racha. Sin backend social, los datos se
/// derivan por completo de [HabitCircle] (miembros y check-ins reales).
///
/// Rediseño de Stitch: la mockup muestra estadísticas de plataforma entera
/// ("14,820 Hogueras Vivas", "+3.2k Guerreros Online", un tab "Top Fuego
/// Global") y un boost "Impulso Chamánico" — nada de eso existe, porque esta
/// app no tiene un backend social global, solo los círculos propios del
/// usuario. Se mapean en cambio a agregados reales de ESOS círculos: cuántos
/// tienen racha activa, qué porcentaje ya hizo check-in hoy, cuántos
/// guerreros en total. El tab "Al Borde" sí es real: círculos con racha que
/// todavía no marcaron hoy, en riesgo de romperse.
class AgoraPage extends StatefulWidget {
  const AgoraPage({
    super.key,
    required this.circles,
    required this.circlesUpdatedTick,
    required this.allyUsernameController,
    required this.onSendAllyRequest,
    required this.activityFeed,
    required this.hasReactedTo,
    required this.onToggleReaction,
    required this.onCheckIn,
  });

  final List<HabitCircle> circles;

  /// Se incrementa cada vez que un check-in o un nuevo miembro actualiza
  /// algún círculo; se usa como parte de la key de cada hoguera para que
  /// reproduzca su animación de reignición al instante, como señal visual
  /// de sincronización local sin servidor.
  final int circlesUpdatedTick;
  final TextEditingController allyUsernameController;
  final Future<bool> Function() onSendAllyRequest;

  /// Feed de actividad de la tribu (check-ins, hitos, escudos usados, nuevos
  /// miembros, aliados), más reciente primero.
  final List<ActivityEvent> activityFeed;

  /// `true` si el usuario actual ya reaccionó 🔥 a ese evento (ver
  /// `HomeLogic.hasReactedTo`).
  final bool Function(ActivityEvent event) hasReactedTo;

  /// Alterna la reacción 🔥 del usuario actual sobre un evento (ver
  /// `HomeLogic.toggleActivityReaction`) — el feed deja de ser de solo
  /// lectura.
  final ValueChanged<ActivityEvent> onToggleReaction;

  /// Check-in directo desde una hoguera "Al Borde" — misma acción que en
  /// Círculos/Rachas, para poder apagar el riesgo sin salir del Ágora.
  final ValueChanged<HabitCircle> onCheckIn;

  @override
  State<AgoraPage> createState() => _AgoraPageState();
}

enum _AgoraFilter { mine, atRisk }

class _AgoraPageState extends State<AgoraPage> {
  _AgoraFilter _filter = _AgoraFilter.mine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final circles = widget.circles;
    final ranked = [...circles]
      ..sort((a, b) => b.streakDays.compareTo(a.streakDays));
    final atRisk = ranked
        .where((c) => c.streakDays > 0 && !c.checkedInToday)
        .toList();
    final visible = _filter == _AgoraFilter.atRisk ? atRisk : ranked;

    final activeCount = circles.where((c) => c.streakDays > 0).length;
    final sustainedPct = circles.isEmpty
        ? 0
        : (circles.where((c) => c.checkedInToday).length / circles.length * 100)
              .round();
    final totalWarriors = circles.fold<int>(
      0,
      (sum, c) => sum + c.totalMembers,
    );

    return AdaptiveGlassScaffold(
      title: const Text('El Gran Ágora Tribal'),
      // Material(type: transparency) a propósito — mismo parche que ya
      // usaba create_habit.dart: en modo Liquid Glass, GlassScaffold no
      // provee un ancestro Material (confirmado: no hay ningún `Material(`
      // en el paquete `liquid_glass_widgets`), y el TextField de "Añadir
      // Aliado" de más abajo lo necesita — sin esto, `debugCheckHasMaterial`
      // falla apenas se intenta enfocar/tocar ese campo con el efecto
      // Liquid Glass activo (el default). No afecta el modo plano, donde
      // `AdaptiveGlassScaffold` ya usa un `Scaffold` normal (que sí trae
      // su propio Material).
      body: SafeArea(
        child: AppMaxWidth(
          child: Material(
            type: MaterialType.transparency,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)
                  .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl2),
              children: [
                Text(
                  '🌐 MAPA EN VIVO • TU REINO',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Observa el pulso de tus hogueras en tiempo real y '
                  'sincroniza tu fuego.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (circles.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _AgoraStatBox(
                          value: '$activeCount',
                          label: 'Hogueras Vivas',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _AgoraStatBox(
                          value: '$sustainedPct%',
                          label: 'Fuego Sostenido Hoy',
                          color: AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _AgoraStatBox(
                          value: '$totalWarriors',
                          label: 'Guerreros en tu Tribu',
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _AgoraFilterChip(
                          label: '🔥 Mis Círculos',
                          active: _filter == _AgoraFilter.mine,
                          onTap: () =>
                              setState(() => _filter = _AgoraFilter.mine),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _AgoraFilterChip(
                          label: '⚠️ Al Borde (${atRisk.length})',
                          active: _filter == _AgoraFilter.atRisk,
                          onTap: () =>
                              setState(() => _filter = _AgoraFilter.atRisk),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                _AddAllySection(
                  usernameController: widget.allyUsernameController,
                  onSend: widget.onSendAllyRequest,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (circles.isEmpty)
                  _EmptyAgora(textTheme: textTheme)
                else ...[
                  Text(
                    'Círculos de Poder',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (visible.isEmpty)
                    _NoRiskCard(textTheme: textTheme)
                  else
                    for (final circle in visible) ...[
                      _TribalBonfireCard(
                        key: ValueKey(
                          '${circle.name}-${widget.circlesUpdatedTick}',
                        ),
                        circle: circle,
                        onCheckIn: () => widget.onCheckIn(circle),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Chamanes del Podio',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (ranked.length >= 2) _PodiumRow(ranked: ranked),
                  const SizedBox(height: AppSpacing.md),
                  _LeaderboardCard(ranked: ranked),
                  const SizedBox(height: AppSpacing.xl2),
                  Text(
                    'Bitácora de Llamas',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActivityFeedCard(
                    events: widget.activityFeed,
                    hasReactedTo: widget.hasReactedTo,
                    onToggleReaction: widget.onToggleReaction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgoraStatBox extends StatelessWidget {
  const _AgoraStatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineWhisper),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgoraFilterChip extends StatelessWidget {
  const _AgoraFilterChip({
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

class _NoRiskCard extends StatelessWidget {
  const _NoRiskCard({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassOutlinedCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        '✅ Ninguna hoguera al borde — toda tu tribu ya hizo check-in hoy.',
        style: textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

/// Podio de los 2-3 círculos con más racha — mismo dato que
/// [_LeaderboardCard] (`streakDays`), solo destacado visualmente para los
/// primeros puestos como en la mockup.
class _PodiumRow extends StatelessWidget {
  const _PodiumRow({required this.ranked});

  final List<HabitCircle> ranked;

  @override
  Widget build(BuildContext context) {
    final second = ranked.length > 1 ? ranked[1] : null;
    final first = ranked[0];
    final third = ranked.length > 2 ? ranked[2] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: second == null
              ? const SizedBox.shrink()
              : _PodiumSpot(circle: second, place: 2, height: 84),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _PodiumSpot(circle: first, place: 1, height: 104)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: third == null
              ? const SizedBox.shrink()
              : _PodiumSpot(circle: third, place: 3, height: 68),
        ),
      ],
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const _PodiumSpot({
    required this.circle,
    required this.place,
    required this.height,
  });

  final HabitCircle circle;
  final int place;
  final double height;

  static const _medals = {1: '🥇', 2: '🥈', 3: '🥉'};
  static const _colors = {
    1: AppColors.rankGold,
    2: AppColors.rankSilver,
    3: AppColors.rankBronze,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _colors[place]!;
    return Column(
      children: [
        Text(_medals[place]!, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          circle.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          '${circle.streakDays}d',
          style: textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            border: Border.all(color: color, width: 1.5),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.md),
            ),
          ),
        ),
      ],
    );
  }
}

/// Feed de actividad de la tribu: cada línea es un evento real generado por
/// una acción del usuario en este dispositivo (check-in, hito, escudo
/// usado, nuevo miembro, aliado). Refuerza la sensación de vida social del
/// Ágora incluso antes de tener sync remoto entre dispositivos.
class _ActivityFeedCard extends StatelessWidget {
  const _ActivityFeedCard({
    required this.events,
    required this.hasReactedTo,
    required this.onToggleReaction,
  });

  final List<ActivityEvent> events;
  final bool Function(ActivityEvent event) hasReactedTo;
  final ValueChanged<ActivityEvent> onToggleReaction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (events.isEmpty) {
      return AdaptiveGlassOutlinedCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Todavía no hay actividad. Haz tu primer check-in para encender '
          'el feed de la tribu.',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    return AdaptiveGlassCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        events[i].emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          events[i].message,
                          style: textTheme.bodySmall?.copyWith(height: 1.4),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _relativeTime(events[i].at),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: _ReactionChip(
                      count: events[i].reactedByUids.length,
                      reacted: hasReactedTo(events[i]),
                      onTap: () => onToggleReaction(events[i]),
                    ),
                  ),
                ],
              ),
            ),
            if (i < events.length - 1)
              const Divider(height: 1, color: AppColors.outlineWhisper),
          ],
        ],
      ),
    );
  }

  static String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }
}

/// Chip de reacción 🔥 tocable — el Ágora deja de ser de solo lectura. Sin
/// contador muestra solo el emoji apagado; con reacciones propias se ve
/// relleno y con el número. Real entre cuentas de verdad para eventos de
/// círculo compartido (ver `HomeLogic.toggleActivityReaction`), local para
/// eventos puramente del dispositivo (aliados/miembros simulados).
class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.count,
    required this.reacted,
    required this.onTap,
  });

  final int count;
  final bool reacted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GamePressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: reacted ? AppColors.completedGlow : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: reacted ? AppColors.secondary : AppColors.outlineWhisper,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 12, height: 1)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: textTheme.labelSmall?.copyWith(
                  color: reacted
                      ? AppColors.secondary
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Añadir Aliado": campo para ingresar un @usuario exacto y enviar una
/// misiva de solicitud. Sin backend real no existe búsqueda de usuarios de
/// verdad, así que solo valida que el campo no esté vacío y delega el envío
/// (y su simulación local de "ya llegó al receptor") a [onSend]. Al enviarse
/// con éxito, muestra una breve animación de misiva enviada como refuerzo
/// tipo juego.
class _AddAllySection extends StatefulWidget {
  const _AddAllySection({
    required this.usernameController,
    required this.onSend,
  });

  final TextEditingController usernameController;
  final Future<bool> Function() onSend;

  @override
  State<_AddAllySection> createState() => _AddAllySectionState();
}

class _AddAllySectionState extends State<_AddAllySection> {
  bool _justSent = false;

  Future<void> _handleSend() async {
    final sent = await widget.onSend();
    if (!sent) return;
    setState(() => _justSent = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _justSent = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_add_alt_1_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Añadir Aliado',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Envía una misiva a un aliado por su @usuario exacto.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.usernameController,
                  decoration: InputDecoration(
                    hintText: '@usuario',
                    filled: true,
                    fillColor: AppColors.surfaceContainer,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Flexible (no un tamaño fijo) a propósito: en una pantalla
              // angosta, el TextField (Expanded) ya cede todo lo que puede
              // ceder, así que sin esto el botón desbordaba el Row en vez
              // de que su propio texto se recorte con ellipsis.
              Flexible(
                child: GamePressable(
                  onTap: _handleSend,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryContainer],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      'Enviar Solicitud',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !_justSent
                ? const SizedBox(width: double.infinity)
                : TweenAnimationBuilder<double>(
                    key: const ValueKey('ally-sent'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🕊️✨', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '¡Misiva enviada al entorno local!',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAgora extends StatelessWidget {
  const _EmptyAgora({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aún no hay hogueras encendidas',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Crea un círculo y haz tu primer check-in para encender la '
              'primera hoguera de la tribu.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de una hoguera tribal: crece, cambia de color e intensifica su
/// brillo según la racha del círculo (0 = apagada, 30+ = fuego intenso).
class _TribalBonfireCard extends StatelessWidget {
  const _TribalBonfireCard({
    super.key,
    required this.circle,
    required this.onCheckIn,
  });

  final HabitCircle circle;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final streak = circle.streakDays;
    final intensity = (streak / 30).clamp(0.15, 1.0);
    final fireSize = 44 + intensity * 30;

    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  circle.name,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (circle.isPerfect)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.completedGlow,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '¡Círculo Perfecto! ✨',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: SizedBox(
              height: 96,
              width: 200,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < circle.members.length; i++)
                    Positioned(
                      left:
                          100 +
                          64 *
                              (i % 2 == 0 ? 1 : -1) *
                              ((i ~/ 2 + 1) / (circle.members.length / 2 + 1))
                                  .clamp(0.3, 1.0) -
                          14,
                      bottom: 4,
                      child: _MemberAvatar(name: circle.members[i]),
                    ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: fireSize,
                      height: fireSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.secondary,
                            AppColors.secondary.withValues(alpha: 0),
                          ],
                        ),
                        boxShadow: streak > 0
                            ? [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.55 * intensity,
                                  ),
                                  blurRadius: 24 * intensity,
                                  spreadRadius: 4 * intensity,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        streak > 0 ? '🔥' : '🪵',
                        style: TextStyle(fontSize: 20 + intensity * 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              streak > 0
                  ? 'Racha colectiva: $streak días'
                  : 'Hoguera apagada — hagan su primer check-in',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!circle.checkedInToday) ...[
            const SizedBox(height: AppSpacing.md),
            GamePressable(
              onTap: onCheckIn,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: streak > 0
                        ? AppColors.secondary
                        : AppColors.primary,
                  ),
                  child: Text(
                    streak > 0
                        ? '⚠️ EVITAR QUE SE APAGUE — CHECK-IN'
                        : '🔥 ENCENDER HOGUERA',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.lavenderContainer,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
      ),
    );
  }
}

/// Tabla de clasificación estilizada como pergamino de "Maestros de la
/// Tribu", ordenada por racha actual de cada círculo.
class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.ranked});

  final List<HabitCircle> ranked;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AdaptiveGlassCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          for (var i = 0; i < ranked.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      i < _medals.length ? _medals[i] : '${i + 1}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      ranked[i].name,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${ranked[i].streakDays} días',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (i < ranked.length - 1)
              const Divider(height: 1, color: AppColors.outlineWhisper),
          ],
        ],
      ),
    );
  }
}
