import 'package:flutter/material.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';

/// Fuente de verdad app-wide para si las superficies deben renderizarse con
/// el efecto "Liquid Glass" (`liquid_glass_widgets`) o su estilo plano
/// original — controlado por el switch en Perfil (ver
/// `HomeLogic.setLiquidGlassEnabled`), disponible tanto en Android como en
/// iOS: el paquete es puro Flutter, sin código nativo por plataforma.
///
/// Vive fuera de `HomeLogic` a propósito: varias pantallas que usan estas
/// tarjetas adaptativas se abren como rutas nuevas del `Navigator` (no como
/// descendientes directas del árbol que ya escucha `HomeLogic`), así que un
/// `InheritedWidget` clásico no las alcanzaría a todas sin re-cablear cada
/// página. Un `ValueNotifier` global evita ese problema de raíz: cualquier
/// `AdaptiveGlass*` en cualquier pantalla se refresca solo.
class GlassThemeController {
  GlassThemeController._();

  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);
}

/// Envuelve [child] en una tarjeta elevada: [GlassCard] si el efecto está
/// activo, o el `Container` plano (color de superficie + sombra + radio)
/// que la app usaba antes de introducir `liquid_glass_widgets`. [radius]
/// por defecto es [AppRadius.xl] (tarjeta); pasar [AppRadius.pill] da una
/// píldora — mismo radio en ambos modos, glass y plano — para superficies
/// como la barra de navegación flotante.
class AdaptiveGlassCard extends StatelessWidget {
  const AdaptiveGlassCard({
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.height,
    this.radius = AppRadius.xl,
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final double? height;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlassThemeController.enabled,
      builder: (context, glassEnabled, _) {
        if (glassEnabled) {
          return GlassCard(
            padding: padding,
            height: height,
            shape: LiquidRoundedRectangle(borderRadius: radius),
            child: child,
          );
        }
        return Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: AppShadows.card,
          ),
          child: child,
        );
      },
    );
  }
}

/// Igual que [AdaptiveGlassCard] pero con el borde sutil que usan las
/// tarjetas de vista previa (ver `create_habit.dart`), en vez de sombra.
class AdaptiveGlassOutlinedCard extends StatelessWidget {
  const AdaptiveGlassOutlinedCard({
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlassThemeController.enabled,
      builder: (context, glassEnabled, _) {
        if (glassEnabled) {
          return GlassCard(
            padding: padding,
            shape: const LiquidRoundedRectangle(
              borderRadius: AppRadius.xl,
              side: BorderSide(color: AppColors.outlineWhisper),
            ),
            child: child,
          );
        }
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card,
            border: Border.all(color: AppColors.outlineWhisper),
          ),
          child: child,
        );
      },
    );
  }
}

/// `Scaffold`/`GlassScaffold` con `AppBar`/`GlassAppBar` de título simple —
/// cubre el caso común (`create_habit.dart`, `circle_detail.dart`): un
/// título de texto y un body, sin acciones ni leading personalizados.
class AdaptiveGlassScaffold extends StatelessWidget {
  const AdaptiveGlassScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottom,
  });

  final Widget title;
  final Widget body;

  /// Ej. un `TabBar` — mismo lugar en ambos casos (`AppBar.bottom` /
  /// `GlassAppBar.bottom`).
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlassThemeController.enabled,
      builder: (context, glassEnabled, _) {
        if (glassEnabled) {
          return GlassScaffold(
            appBar: GlassAppBar(title: title, bottom: bottom),
            body: body,
          );
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: title, bottom: bottom),
          body: body,
        );
      },
    );
  }
}

/// Botón primario de ancho completo: [GlassButton] activo, o el
/// `ElevatedButton` + [GamePressable] que la app usaba antes — mismo
/// criterio de habilitado/deshabilitado (`enabled`) en ambos casos.
class AdaptiveGlassButton extends StatelessWidget {
  const AdaptiveGlassButton({
    super.key,
    required this.onTap,
    this.enabled = true,
    required this.label,
    required this.icon,
    this.width = double.infinity,
  });

  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final Widget icon;

  /// `GlassButton` es un botón cuadrado de ícono (56x56) por defecto — se
  /// pasa `double.infinity` para que ocupe todo el ancho disponible, como
  /// un botón primario normal.
  final double width;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlassThemeController.enabled,
      builder: (context, glassEnabled, _) {
        if (glassEnabled) {
          return GlassButton.custom(
            onTap: onTap,
            enabled: enabled,
            width: width,
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Text(label),
              ],
            ),
          );
        }
        final button = SizedBox(
          width: width,
          child: ElevatedButton.icon(
            onPressed: enabled ? onTap : null,
            icon: icon,
            label: Text(label),
          ),
        );
        return enabled ? GamePressable(onTap: onTap, child: button) : button;
      },
    );
  }
}
