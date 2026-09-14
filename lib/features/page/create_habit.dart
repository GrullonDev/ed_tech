import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/logic/logic.dart';
import 'package:edtech_tiktok/features/widgets/adaptive_glass.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';

/// Categorías sugeridas para un círculo nuevo, cada una con un emoji para
/// la vista previa y las tarjetas seleccionables — puramente decorativo,
/// no cambia el modelo de datos: [HabitCircle.category] sigue siendo un
/// `String` libre, así que elegir una de estas o escribir una propia da
/// exactamente el mismo resultado.
const Map<String, String> _kCategoryOptions = {
  'General': '⭐',
  'Fitness': '💪',
  'Estudio': '📚',
  'Salud': '🩺',
  'Trabajo': '💼',
  'Meditación': '🧘',
  'Lectura': '📖',
  'Creatividad': '🎨',
};

/// Formulario para crear un nuevo círculo de hábito. El estado del texto
/// (nombre/categoría) y la creación viven en `HomeLogic`; esta pantalla
/// solo agrega una vista previa en vivo y categorías tocables para que
/// completar el formulario se sienta menos como rellenar un form y más
/// como armar la identidad del círculo.
///
/// Rediseño de Stitch ("Fundar Tribu"): la mockup tiene varios campos sin
/// respaldo real hoy — aura/color del tótem, lema sagrado, tag de clan,
/// exigencias de racha configurables, tipo de alianza (pública/con
/// filtro/secreta), nivel mínimo de entrada — ninguno existe en
/// [HabitCircle] ni en `HomeLogic`, así que se omiten a propósito en vez de
/// simular una configuración que no hace nada. Lo que sí se mapea 1:1:
/// nombre real (nombre del círculo), "arquetipo tribal" = la categoría real
/// (mismo campo de siempre, solo con el copy de la mockup), y los
/// "Poderes de Líder Chamán" se muestran como texto informativo de
/// funciones que ya existen (invitar, retar 1v1) en vez de una lista de
/// privilegios ficticios.
class CreateHabitPage extends StatefulWidget {
  const CreateHabitPage({super.key, required this.logic});

  final HomeLogic logic;

  @override
  State<CreateHabitPage> createState() => _CreateHabitPageState();
}

class _CreateHabitPageState extends State<CreateHabitPage> {
  final _inviteCodeController = TextEditingController();
  bool _joiningCircle = false;

  @override
  void initState() {
    super.initState();
    widget.logic.habitNameController.addListener(_onFieldsChanged);
    widget.logic.habitCategoryController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    widget.logic.habitNameController.removeListener(_onFieldsChanged);
    widget.logic.habitCategoryController.removeListener(_onFieldsChanged);
    _inviteCodeController.dispose();
    super.dispose();
  }

  /// Une esta cuenta real a un círculo existente vía código de invitación
  /// (competencia real contra otras cuentas, ver
  /// `HomeLogic.joinCircleWithInviteCode`) — distinto de crear un círculo
  /// nuevo o de "Invitar a un amigo" (que solo agrega un nombre local sin
  /// backend dentro de un círculo ya creado por vos).
  Future<void> _joinWithCode() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty || _joiningCircle) return;
    setState(() => _joiningCircle = true);
    final error = await widget.logic.joinCircleWithInviteCode(code);
    if (!mounted) return;
    setState(() => _joiningCircle = false);
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  /// Los controladores son de [widget.logic] (sobreviven a esta pantalla),
  /// así que acá solo se escuchan para redibujar la vista previa y
  /// habilitar/deshabilitar el botón — nunca se disponen desde acá.
  void _onFieldsChanged() => setState(() {});

  void _submit() {
    final circle = widget.logic.submitNewCircle();
    if (circle != null) {
      Navigator.of(context).pop(circle);
    }
  }

  void _selectCategory(String category) {
    widget.logic.habitCategoryController.text = category;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = widget.logic.habitNameController.text.trim();
    final category = widget.logic.habitCategoryController.text.trim();
    final previewEmoji = _kCategoryOptions[category] ?? '⭐';
    final canSubmit = name.isNotEmpty;

    return AdaptiveGlassScaffold(
      title: const Text('Fundar Tribu'),
      // SafeArea a propósito — ver la misma nota en circle_detail.dart:
      // sin esto, el contenido queda debajo de la barra de estado del
      // sistema en un dispositivo real.
      body: SafeArea(
        child: AppMaxWidth(
          child: Material(
            type: MaterialType.transparency,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
            Text(
              '🔥 RITO CHAMÁNICO',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.06,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reúne a tus guerreros, forja el tótem ancestral y enciende '
              'la llama madre para el dominio en las tablas.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '🛡️ Tótem y Blasón',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _CirclePreviewCard(
              emoji: previewEmoji,
              name: name,
              category: category,
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              '📜 Pacto de Identidad',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: widget.logic.habitNameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Tribu',
                prefixIcon: Icon(Icons.local_fire_department_rounded),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '⚔️ Arquetipo Tribal',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Define el hábito que va a sostener toda la tribu.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final entry in _kCategoryOptions.entries)
                  _CategoryChip(
                    emoji: entry.value,
                    label: entry.key,
                    selected: category == entry.key,
                    onTap: () => _selectCategory(entry.key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: widget.logic.habitCategoryController,
              decoration: const InputDecoration(
                labelText: 'O escribí tu propio arquetipo (opcional)',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl2),
            const _FounderPowersCard(),
            const SizedBox(height: AppSpacing.xl2),
            AdaptiveGlassButton(
              onTap: _submit,
              enabled: canSubmit,
              label: '🔥 FUNDAR TRIBU',
              icon: const Icon(Icons.local_fire_department_rounded),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    'o',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '🔑 Unión Tribal con Código',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Unite al círculo de un amigo — competencia real, no un '
              'nombre simulado.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _inviteCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código de invitación',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
              onSubmitted: (_) => _joinWithCode(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AdaptiveGlassButton(
              onTap: _joiningCircle ? () {} : _joinWithCode,
              enabled: !_joiningCircle,
              label: _joiningCircle ? 'Uniéndome...' : 'Unirme con código',
              icon: const Icon(Icons.group_add_rounded),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vista previa en vivo de cómo va a quedar el círculo, con el mismo
/// bloque isométrico ([Iso3DIcon]) que el resto de la app usa para
/// logros/juegos — para que crear un círculo se sienta parte del mismo
/// "juego" en vez de un formulario aparte.
class _CirclePreviewCard extends StatelessWidget {
  const _CirclePreviewCard({
    required this.emoji,
    required this.name,
    required this.category,
  });

  final String emoji;
  final String name;
  final String category;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AdaptiveGlassOutlinedCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Iso3DIcon(
            icon: Icons.group_rounded,
            emoji: emoji,
            size: 52,
            colors: const [AppColors.primaryContainer, AppColors.primary],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Tu círculo' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: name.isEmpty
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.isEmpty ? 'General' : category,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
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

/// "Poderes de Líder Chamán" de la mockup, pero listando solo capacidades
/// que ya existen de verdad al fundar un círculo — nada de multiplicadores
/// ni cofres inventados.
class _FounderPowersCard extends StatelessWidget {
  const _FounderPowersCard();

  static const _powers = [
    (
      icon: Icons.qr_code_2_rounded,
      text: 'Vas a poder invitar guerreros reales con un código de '
          'invitación único.',
    ),
    (
      icon: Icons.leaderboard_rounded,
      text: 'Vas a ver el ranking y la racha colectiva del círculo en '
          'tiempo real.',
    ),
    (
      icon: Icons.local_fire_department_rounded,
      text: 'Cada check-in diario de un miembro suma a la racha '
          'compartida de la tribu.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AdaptiveGlassOutlinedCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👑 Al fundar sos el líder del clan',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final power in _powers)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(power.icon, size: 18, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      power.text,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GamePressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.completedGlow : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineWhisper,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
