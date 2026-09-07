import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';

/// Pestaña actualmente activa, para resaltarla en [AppBottomNav].
enum AppTab { circles, rachas, profile }

/// Barra de navegación inferior flotante en forma de píldora. El botón "+"
/// vive dentro de la misma barra (no como FAB con muesca). Cada pantalla que
/// la usa indica su [currentTab] para resaltar el ítem correspondiente y
/// provee los callbacks de las demás pestañas.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onCreateCircle,
    this.onOpenCircles,
    this.onOpenRachas,
    this.onOpenProfile,
  });

  final AppTab currentTab;
  final VoidCallback onCreateCircle;
  final VoidCallback? onOpenCircles;
  final VoidCallback? onOpenRachas;
  final VoidCallback? onOpenProfile;

  /// Alto de la píldora de navegación en sí (sin contar el margen inferior
  /// ni el inset de la barra de sistema).
  static const double barHeight = 68;

  /// Margen que [SafeArea] agrega debajo de la píldora.
  static const double bottomMargin = AppSpacing.lg;

  /// Espacio total que la barra flotante ocupa desde el borde inferior de la
  /// pantalla (píldora + margen), sin contar el inset de la barra de
  /// sistema. Con `extendBody: true` el body pasa por detrás de esta barra,
  /// así que cualquier `ListView`/`ScrollView` de una pantalla con esta nav
  /// debe agregar al menos esto como padding inferior para que el contenido
  /// no quede oculto detrás de ella.
  static const double reservedHeight = barHeight + bottomMargin;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottomMargin,
      ),
      child: Container(
        height: barHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              icon: Icons.group_rounded,
              label: 'Círculos',
              selected: currentTab == AppTab.circles,
              onTap: onOpenCircles,
            ),
            _NavItem(
              icon: Icons.local_fire_department_rounded,
              label: 'Rachas',
              selected: currentTab == AppTab.rachas,
              onTap: onOpenRachas,
            ),
            _AddButton(onTap: onCreateCircle),
            _NavItem(
              icon: Icons.emoji_events_rounded,
              label: 'Perfil',
              selected: currentTab == AppTab.profile,
              onTap: onOpenProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              SizedBox(height: 3),
              Text(
                'Crear',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              SizedBox(width: 4, height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.outline;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 4,
                height: 4,
                child: selected
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
