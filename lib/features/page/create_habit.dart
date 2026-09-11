import 'package:flutter/material.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/logic/logic.dart';

/// Formulario para crear un nuevo círculo de hábito. No mantiene estado
/// propio: los campos y la creación viven en `HomeLogic`, esta pantalla
/// solo los muestra.
class CreateHabitPage extends StatelessWidget {
  const CreateHabitPage({super.key, required this.logic});

  final HomeLogic logic;

  void _submit(BuildContext context) {
    if (logic.submitNewCircle()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('Crear círculo')),
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
            const SizedBox(height: AppSpacing.xl2),
            TextField(
              controller: logic.habitNameController,
              decoration: const InputDecoration(labelText: 'Nombre del hábito'),
              onSubmitted: (_) => _submit(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: logic.habitCategoryController,
              decoration: const InputDecoration(
                labelText: 'Categoría (opcional)',
              ),
              onSubmitted: (_) => _submit(context),
            ),
            const SizedBox(height: AppSpacing.xl2),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                onTap: () => _submit(context),
                label: 'Crear círculo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
