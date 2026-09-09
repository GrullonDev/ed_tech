import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';

/// Utilidades compartidas de "Game UI": botones con feedback táctil tipo
/// juego (splash + rebote de escala), íconos con profundidad/estilo
/// isométrico 3D (en vez de íconos planos) y transiciones de pantalla con
/// tweening en vez de navegación instantánea. Se usan en todas las pantallas
/// para mantener una sola fuente de verdad para estas sensaciones.
/// Envuelve [child] y anima un rebote de escala al presionar/soltar, similar
/// al feedback de botones en juegos móviles. Úsalo en acciones primarias
/// como "Check-in" o "Celebrar".
class GamePressable extends StatefulWidget {
  const GamePressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.88,
  });

  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;

  @override
  State<GamePressable> createState() => _GamePressableState();
}

class _GamePressableState extends State<GamePressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Ícono con apariencia 3D/isométrica: un bloque con gradiente, un borde
/// superior más claro ("highlight") y una sombra inferior más oscura que
/// simula profundidad, en vez de un ícono plano de un solo tono.
class Iso3DIcon extends StatelessWidget {
  const Iso3DIcon({
    super.key,
    required this.icon,
    required this.colors,
    this.size = 44,
    this.iconSize,
    this.emoji,
  });

  final IconData icon;
  final List<Color> colors;
  final double size;
  final double? iconSize;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final depth = size * 0.09;
    return SizedBox(
      width: size,
      height: size + depth,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: depth,
            child: Container(
              height: size,
              decoration: BoxDecoration(
                color: colors.last.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(size * 0.28),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(size * 0.28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: emoji != null
                  ? Text(
                      emoji!,
                      style: TextStyle(fontSize: iconSize ?? size * 0.45),
                    )
                  : Icon(
                      icon,
                      color: Colors.white,
                      size: iconSize ?? size * 0.5,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastilla que muestra el saldo de "Gotas de Constancia", la moneda blanda
/// del juego que se gana al completar rachas y check-ins.
class ConstancyDropsPill extends StatelessWidget {
  const ConstancyDropsPill({super.key, required this.drops});

  final int drops;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.lavenderContainer, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💧', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$drops',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ruta con tweening (fundido + leve escala/deslizamiento) para reemplazar
/// la navegación instantánea de [MaterialPageRoute] por transiciones más
/// propias de un juego entre pantallas.
class GamePageRoute<T> extends PageRouteBuilder<T> {
  GamePageRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
                child: child,
              ),
            ),
          );
        },
      );
}
