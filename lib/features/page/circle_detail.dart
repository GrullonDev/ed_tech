import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/leaderboard_entry.dart';
import 'package:edtech_tiktok/core/theme/app_assets.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/adaptive_glass.dart';

/// Vista de detalle de un círculo: progreso del grupo y estado de cada
/// miembro. Recibe el círculo y el callback de check-in; no conoce a
/// [HomeLogic] directamente.
///
/// Rediseño de Stitch ("Detalle De Tribu"): la mockup muestra estadísticas
/// por-guerrero (nivel, gotas, "en llamas", "en duelo", "escudo activo") que
/// no existen para miembros simulados (sin backend, [HabitCircle.members]
/// es solo una lista de nombres) — sí existen, ya calculadas, para cuentas
/// reales en [leaderboard] (`LeaderboardEntry`: streakDays, dropsEarned,
/// checkedInToday). Por eso "Guerreros de Guardia" usa el leaderboard real
/// cuando hay cuentas unidas por código, y solo cae a la lista simulada de
/// siempre cuando todavía no se unió nadie de verdad. Se omiten a propósito
/// los 3 botones de "Estímulos & Clamor Tribal" (alerta, duelo 1v1, regalar
/// gotas) y el cupo fijo de guerreros de la mockup: ninguno tiene mecánica
/// real detrás hoy.
class CircleDetailPage extends StatelessWidget {
  const CircleDetailPage({
    super.key,
    required this.circle,
    required this.onCheckIn,
    required this.onInviteMember,
    required this.onOpenGames,
    this.leaderboard = const [],
  });

  final HabitCircle circle;
  final VoidCallback onCheckIn;
  final ValueChanged<String> onInviteMember;
  final VoidCallback onOpenGames;

  /// Tabla de posiciones real del círculo (ver `HomeLogic.leaderboardFor`) —
  /// vacía si nadie se unió todavía con un código de invitación real. No
  /// reemplaza la lista de "Miembros" simulados de abajo: son dos cosas
  /// complementarias (miembros locales sin backend vs. cuentas reales).
  final List<LeaderboardEntry> leaderboard;

  static int _levelFor(int streakDays) => (streakDays ~/ 7) + 1;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final clanLevel = _levelFor(circle.streakDays);
    return AdaptiveGlassScaffold(
      title: const Text('Detalle De Tribu'),
      body: AppMaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '🔥 LOBBY SAGRADO ACTIVO',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.group_rounded,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${circle.totalMembers} Guerreros',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AdaptiveGlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                            colors: [
                              AppColors.primaryContainer,
                              AppColors.primary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(
                          'LVL $clanLevel',
                          textAlign: TextAlign.center,
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
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
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              circle.category,
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
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          '${circle.streakDays} DÍAS RACHA CLAN',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.water_drop_rounded,
                        size: 16,
                        color: AppColors.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${circle.constancyDropsEarned}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: circle.progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceContainer,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${circle.completedMembers} de ${circle.totalMembers} miembros completaron hoy',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (circle.freezesAvailable > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Text('🛡️', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '${circle.freezesAvailable} escudo(s) de racha disponibles',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _InviteCodeCard(code: circle.inviteCode),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    leaderboard.isNotEmpty
                        ? 'Guerreros de Guardia'
                        : 'Guerreros de Guardia (simulados)',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${circle.completedMembers}/${circle.totalMembers} sin romper racha',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              leaderboard.isNotEmpty
                  ? 'Competencia real contra quienes se unieron con el '
                        'código de invitación.'
                  : 'Todavía nadie se unió con el código real — estos son '
                        'marcadores locales, no cuentas de verdad.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (leaderboard.isNotEmpty)
              for (final entry in leaderboard) ...[
                _WarriorTile(
                  username: entry.isCurrentUser
                      ? '${entry.username} (TÚ)'
                      : entry.username,
                  level: _levelFor(entry.streakDays),
                  drops: entry.dropsEarned,
                  streakDays: entry.streakDays,
                  checkedInToday: entry.checkedInToday,
                  isCurrentUser: entry.isCurrentUser,
                ),
                const SizedBox(height: AppSpacing.sm),
              ]
            else
              for (var i = 0; i < circle.members.length; i++) ...[
                _MemberTile(
                  label: circle.members[i],
                  isSample: i == 0,
                  // El índice 0 es siempre "Tú" (el único miembro real): su
                  // estado de check-in refleja circle.checkedInToday. Los
                  // demás son miembros simulados (sin backend) y se
                  // muestran siempre completados, salvo el pendiente de
                  // invitación.
                  done: i == 0 ? circle.checkedInToday : true,
                  isPending: circle.pendingMemberName == circle.members[i],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            const SizedBox(height: AppSpacing.md),
            _InviteMoreWarriorsBanner(
              onInvite: () => _showInviteMemberDialog(context, onInviteMember),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCheckIn,
                icon: Icon(
                  circle.checkedInToday
                      ? Icons.check_circle_rounded
                      : Icons.playlist_add_check_rounded,
                ),
                label: Text(
                  circle.checkedInToday
                      ? 'Ya hiciste check-in hoy'
                      : 'Hacer check-in',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenGames,
                icon: const Icon(Icons.sports_esports_rounded),
                label: const Text('Entrar a la Zona de Juegos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner "hay lugar para más guerreros" — sin cupo fijo (no existe un
/// límite de miembros en [HabitCircle]), así que en vez de "faltan N
/// lugares" invita en general a sumar gente con el código real o un
/// marcador local.
class _InviteMoreWarriorsBanner extends StatelessWidget {
  const _InviteMoreWarriorsBanner({required this.onInvite});

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AdaptiveGlassOutlinedCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Text('🧑‍🤝‍🧑', style: TextStyle(fontSize: 28)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '¡Plaza de Guerrero Disponible!',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Comparte el código real de invitación, o agrega un marcador '
            'local para llevar la cuenta de un amigo.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Invitar a un amigo'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Guerrero real (cuenta unida por código de invitación): mismos datos de
/// `LeaderboardEntry` que antes se veían en la tabla de posiciones, ahora
/// como fila individual con nivel derivado de su racha (misma fórmula que
/// `HomeLogic.userLevel`).
class _WarriorTile extends StatelessWidget {
  const _WarriorTile({
    required this.username,
    required this.level,
    required this.drops,
    required this.streakDays,
    required this.checkedInToday,
    required this.isCurrentUser,
  });

  final String username;
  final int level;
  final int drops;
  final int streakDays;
  final bool checkedInToday;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.completedGlow
            : AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isCurrentUser ? AppColors.primary : AppColors.outlineWhisper,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          if (isCurrentUser) ...[
            const Icon(
              Icons.workspace_premium_rounded,
              size: 16,
              color: AppColors.rankGold,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Nvl $level · 💧$drops',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                checkedInToday ? '${streakDays}d En Llamas' : '$streakDays d',
                style: textTheme.labelMedium?.copyWith(
                  color: checkedInToday
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                checkedInToday
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: checkedInToday
                    ? AppColors.primary
                    : AppColors.outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Diálogo para agregar un miembro simulado al círculo. Sin backend, no hay
/// envío real de invitación: solo se guarda el nombre localmente.
Future<void> _showInviteMemberDialog(
  BuildContext context,
  ValueChanged<String> onInviteMember,
) async {
  final name = await showDialog<String>(
    context: context,
    builder: (context) => const _InviteMemberDialog(),
  );
  if (name != null && name.trim().isNotEmpty) onInviteMember(name.trim());
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

/// Tarjeta con el código corto para invitar cuentas reales al círculo (ver
/// `HabitCircle.inviteCode` y `HomeLogic.joinCircleWithInviteCode`) — a
/// diferencia de "Invitar a un amigo" (solo un nombre local sin backend),
/// quien ingrese este código desde "Crear círculo" → "Unirme con código" se
/// une de verdad y aparece en la tabla de posiciones.
class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.code});

  final String code;

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado — compartilo con tu amigo')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AdaptiveGlassOutlinedCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código de invitación',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => _copyCode(context),
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copiar código',
          ),
        ],
      ),
    );
  }
}


class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.label,
    required this.isSample,
    required this.done,
    required this.isPending,
  });

  final String label;
  final bool isSample;
  final bool done;
  final bool isPending;

  /// Iniciales del nombre para que el avatar nunca desborde su círculo,
  /// sin importar qué tan largo sea el nombre del miembro.
  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

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
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceContainer,
            backgroundImage: isSample
                ? const AssetImage(AppAssets.avatarSample)
                : null,
            child: isSample
                ? null
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        _initials(label),
                        maxLines: 1,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              isSample ? 'Tú' : 'Miembro $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isPending)
            Text(
              'Pendiente',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: done ? AppColors.primary : AppColors.outline,
            ),
        ],
      ),
    );
  }
}
