import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/logic/logic.dart';
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
class CreateHabitPage extends StatefulWidget {
  const CreateHabitPage({super.key, required this.logic});

  final HomeLogic logic;

  @override
  State<CreateHabitPage> createState() => _CreateHabitPageState();
}

class _CreateHabitPageState extends State<CreateHabitPage> {
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
    super.dispose();
  }

  /// Los controladores son de [widget.logic] (sobreviven a esta pantalla),
  /// así que acá solo se escuchan para redibujar la vista previa y
  /// habilitar/deshabilitar el botón — nunca se disponen desde acá.
  void _onFieldsChanged() => setState(() {});

  void _submit() {
    if (widget.logic.submitNewCircle()) {
      Navigator.of(context).pop();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Crear círculo')),
      body: AppMaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Dale nombre a tu nuevo círculo de hábito',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Invita después a tus amigos para compartir la racha.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _CirclePreviewCard(
              emoji: previewEmoji,
              name: name,
              category: category,
            ),
            const SizedBox(height: AppSpacing.xl2),
            TextField(
              controller: widget.logic.habitNameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre del hábito',
                prefixIcon: Icon(Icons.local_fire_department_rounded),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Elegí una categoría',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
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
                labelText: 'O escribí tu propia categoría (opcional)',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl2),
            SizedBox(
              width: double.infinity,
              child: canSubmit
                  ? GamePressable(
                      onTap: _submit,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Crear círculo'),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: null,
                      child: const Text('Crear círculo'),
                    ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.outlineWhisper),
      ),
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
