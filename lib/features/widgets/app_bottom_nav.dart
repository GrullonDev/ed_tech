import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/adaptive_glass.dart';

/// Pestaña actualmente activa, para resaltarla en [AppBottomNav].
enum AppTab { circles, rachas, games, profile }

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
    this.onOpenGames,
    this.onOpenProfile,
  });

  final AppTab currentTab;
  final VoidCallback onCreateCircle;
  final VoidCallback? onOpenCircles;
  final VoidCallback? onOpenRachas;
  final VoidCallback? onOpenGames;
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
      child: AdaptiveGlassCard(
        height: barHeight,
        radius: AppRadius.pill,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        // Cada ítem va en un Expanded a propósito: con el Row midiendo el
        // ancho intrínseco de cada hijo (como era antes), 5 ítems con
        // ícono+label no entran en el ancho de pantalla más angosto en uso
        // real (320px, ej. iPhone SE 1ª gen) — desborda ~120px, confirmado
        // con `flutter test test/responsive_test.dart`. Con Expanded cada
        // ítem se reparte el ancho disponible por igual sin importar el
        // tamaño de pantalla, y el label adentro trunca con ellipsis en vez
        // de desbordar si igual no entra.
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.group_rounded,
                label: 'Inicio',
                selected: currentTab == AppTab.circles,
                onTap: onOpenCircles,
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.local_fire_department_rounded,
                label: 'Rachas',
                selected: currentTab == AppTab.rachas,
                onTap: onOpenRachas,
              ),
            ),
            Expanded(child: _TribuButton(onTap: onCreateCircle)),
            Expanded(
              child: _NavItem(
                icon: Icons.sports_esports_rounded,
                label: 'Juegos',
                selected: currentTab == AppTab.games,
                onTap: onOpenGames,
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.emoji_events_rounded,
                label: 'Perfil',
                selected: currentTab == AppTab.profile,
                onTap: onOpenProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ítem central de la nav — abre el flujo de fundar/unirse a una tribu
/// (`CreateHabitPage`, ver `create_habit.dart`), igual acción que el viejo
/// botón "Crear", solo restyleado como el aro de fuego destacado de la
/// mockup de Stitch en vez de un simple "+". El aro/gradiente es plano
/// (`Container`, no `AdaptiveGlassCard`) a propósito: la píldora que lo
/// envuelve ya resuelve el modo Liquid Glass on/off, y un segundo efecto de
/// vidrio anidado adentro se vería sobrecargado en ambos modos.
class _TribuButton extends StatelessWidget {
  const _TribuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                      AppColors.tertiary,
                    ],
                  ),
                  boxShadow: AppShadows.streak,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'TRIBU',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.06,
                ),
              ),
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
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
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
