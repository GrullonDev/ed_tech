import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';

/// Formulario para crear un nuevo círculo de hábito. Es dueño únicamente
/// del estado de sus campos de texto; la creación real se delega al
/// callback [onCreate], que vive en `HomeLogic`.
class CreateHabitPage extends StatefulWidget {
  const CreateHabitPage({super.key, required this.onCreate});

  final void Function(String name, String category) onCreate;

  @override
  State<CreateHabitPage> createState() => _CreateHabitPageState();
}

class _CreateHabitPageState extends State<CreateHabitPage> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final category = _categoryController.text.trim().isEmpty
        ? 'General'
        : _categoryController.text.trim();
    widget.onCreate(name, category);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Crear círculo')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dale nombre a tu nuevo círculo de hábito',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del hábito'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Categoría (opcional)'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl2),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Crear círculo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
