import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';

/// Barra de navegación inferior con FAB central, puramente visual por ahora:
/// solo la pestaña "Círculos" tiene contenido implementado.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.onCreateCircle});

  final VoidCallback onCreateCircle;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const _NavItem(
              icon: Icons.group_rounded,
              label: 'Círculos',
              selected: true,
            ),
            const _NavItem(
              icon: Icons.local_fire_department_rounded,
              label: 'Rachas',
            ),
            const SizedBox(width: 56),
            const _NavItem(icon: Icons.emoji_events_rounded, label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, this.selected = false});

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.outline;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
