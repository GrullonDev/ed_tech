import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/theme/app_assets.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/adaptive_glass.dart';

/// Vista de detalle de un círculo: progreso del grupo y estado de cada
/// miembro. Recibe el círculo y el callback de check-in; no conoce a
/// [HomeLogic] directamente.
class CircleDetailPage extends StatelessWidget {
  const CircleDetailPage({
    super.key,
    required this.circle,
    required this.onCheckIn,
    required this.onInviteMember,
  });

  final HabitCircle circle;
  final VoidCallback onCheckIn;
  final ValueChanged<String> onInviteMember;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AdaptiveGlassScaffold(
      title: Text(circle.name, overflow: TextOverflow.ellipsis),
      body: AppMaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AdaptiveGlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${circle.streakDays} días de racha',
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (circle.freezesAvailable > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lavenderContainer,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🛡️', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                '${circle.freezesAvailable}',
                                style: textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '${(circle.progress * 100).round()}%',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    circle.category,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Miembros',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < circle.members.length; i++) ...[
              _MemberTile(
                label: circle.members[i],
                isSample: i == 0,
                done: i < circle.completedMembers,
                isPending: circle.pendingMemberName == circle.members[i],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showInviteMemberDialog(context, onInviteMember),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Invitar a un amigo'),
              ),
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
          ],
        ),
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
                : Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              isSample ? 'Tú' : 'Miembro $label',
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
