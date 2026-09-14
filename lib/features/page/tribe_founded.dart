import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/adaptive_glass.dart';

/// "Fuego Sagrado Encendido": pantalla de éxito que se muestra una sola vez,
/// justo después de fundar un círculo nuevo (ver
/// `HomeLogic.submitNewCircle`, que ahora devuelve el [HabitCircle] recién
/// creado para poder mostrar sus datos reales acá en vez de simular una
/// celebración genérica).
///
/// La mockup de Stitch tiene un "Primer Mandato Chamánico" (misión de 24h
/// para reunir 5 guerreros y desbloquear un "Multiplicador Tribal x1.5") y
/// un "Enlace Directo" — ninguno existe: no hay temporizador de misión, ni
/// multiplicador, ni una URL propia a la que unirse (solo el código de
/// invitación). Se omiten a propósito. Lo que sí es 100% real y nuevo acá:
/// reclutar por WhatsApp con un mensaje prearmado (link `wa.me`, sin
/// necesitar el número del destinatario) y un QR del código de invitación
/// (mismo patrón que `qr_summon.dart` ya usaba para aliados).
class TribeFoundedPage extends StatelessWidget {
  const TribeFoundedPage({
    super.key,
    required this.circle,
    required this.onOpenCircleDetail,
    required this.onOpenAgora,
  });

  final HabitCircle circle;

  /// Va a la "Sala de Guerreros" (detalle del círculo recién creado).
  final VoidCallback onOpenCircleDetail;

  /// Va al Gran Ágora Tribal.
  final VoidCallback onOpenAgora;

  static int _levelFor(int streakDays) => (streakDays ~/ 7) + 1;

  Future<void> _shareViaWhatsapp(BuildContext context) async {
    final message =
        '🔥 ¡Únete a mi tribu "${circle.name}" en Racha Tribu! Usa el '
        'código de invitación: ${circle.inviteCode}';
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: circle.inviteCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado — compartilo con tu tribu'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AdaptiveGlassScaffold(
      title: const Text('Fuego Sagrado Encendido'),
      body: AppMaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              '🔥 RITO DE FUEGO COMPLETADO',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.06,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '¡FUEGO SAGRADO',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'ENCENDIDO!',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tu clan ha nacido en el reino de Racha Tribu. La primera '
              'chispa arde bajo tu mando.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Center(
              child: Container(
                width: 140,
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  boxShadow: AppShadows.streak,
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 64)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              circle.name,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              circle.category,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _FoundedStatBox(
                    label: 'RANGO',
                    value: 'Fundador',
                    color: AppColors.rankGold,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FoundedStatBox(
                    label: 'HOGUERA',
                    value: 'Nv.${_levelFor(circle.streakDays)}',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FoundedStatBox(
                    label: 'GUERREROS',
                    value: '${circle.totalMembers}',
                    color: AppColors.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              '🔑 Runa Sagrada de Invocación',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AdaptiveGlassOutlinedCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código de Hermandad',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          circle.inviteCode,
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
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: AdaptiveGlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: QrImageView(
                  data: circle.inviteCode,
                  size: 160,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.onSurface,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AdaptiveGlassButton(
              onTap: () => _shareViaWhatsapp(context),
              label: 'RECLUTAR POR WHATSAPP',
              icon: const Icon(Icons.chat_rounded),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              circle.totalMembers <= 1
                  ? 'Por ahora solo estás vos — comparte tu código para '
                        'sumar guerreros reales.'
                  : '${circle.totalMembers} guerreros ya forman parte de tu '
                        'tribu.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            AdaptiveGlassButton(
              onTap: onOpenCircleDetail,
              label: '🔥 IR A LA SALA DE GUERREROS',
              icon: const Icon(Icons.local_fire_department_rounded),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: onOpenAgora,
                child: const Text('EXPLORAR EL GRAN ÁGORA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoundedStatBox extends StatelessWidget {
  const _FoundedStatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
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
            label,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
