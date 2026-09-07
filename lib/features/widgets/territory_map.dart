import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';

/// Vista isométrica estilizada de "El Ecosistema del Hábito": cada círculo
/// activo se representa como un tótem sobre un tile de terreno. Al hacer
/// check-in el tótem se ilumina, crece y libera partículas de energía.
/// Todo se dibuja con [CustomPainter] y widgets nativos (sin assets de
/// arte) para mantener la app 100% offline y liviana.
class TerritoryMap extends StatelessWidget {
  const TerritoryMap({
    super.key,
    required this.circles,
    required this.onCheckIn,
    required this.onTap,
  });

  final List<HabitCircle> circles;
  final ValueChanged<HabitCircle> onCheckIn;
  final ValueChanged<HabitCircle> onTap;

  /// Sendero en zigzag (columna, fila) de tiles isométricos donde se ubican
  /// los tótems, para que se vean como estructuras a lo largo de un camino
  /// de la aldea en vez de una grilla rígida.
  static const _path = [
    [1, 0],
    [2, 0],
    [2, 1],
    [3, 1],
    [3, 2],
    [4, 2],
    [4, 3],
    [5, 3],
    [5, 4],
  ];

  static const _cols = 7;
  static const _rows = 6;
  static const _tileWidth = 60.0;
  static const _tileHeight = 32.0;

  @override
  Widget build(BuildContext context) {
    final mapWidth = (_cols + _rows) * _tileWidth / 2;
    final mapHeight = (_cols + _rows) * _tileHeight / 2 + 40;
    final originX = mapWidth / 2;

    Offset tileCenter(int col, int row) => Offset(
      originX + (col - row) * _tileWidth / 2,
      (col + row) * _tileHeight / 2 + 12,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // El mapa se dibuja siempre al mismo tamaño "natural" (mapWidth x
        // mapHeight) y luego se escala completo para llenar el ancho real
        // disponible en cada dispositivo, así tótems, texto y el terreno
        // isométrico crecen/encogen juntos sin desbordar ni dejar huecos.
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mapWidth;
        final scale = (availableWidth / mapWidth).clamp(0.55, 1.5);
        final displayHeight = (mapHeight * scale).clamp(180, 340).toDouble();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE3F2E9), Color(0xFFD3E9DC)],
            ),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: SizedBox(
              width: double.infinity,
              height: displayHeight,
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: mapWidth,
                    height: mapHeight,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        CustomPaint(
                          size: Size(mapWidth, mapHeight),
                          painter: _IsoGroundPainter(
                            cols: _cols,
                            rows: _rows,
                            tileWidth: _tileWidth,
                            tileHeight: _tileHeight,
                            litPath: _path
                                .take(circles.length)
                                .map(
                                  (p) => Offset(
                                    p[0].toDouble(),
                                    p[1].toDouble(),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        for (
                          var i = 0;
                          i < circles.length && i < _path.length;
                          i++
                        )
                          Builder(
                            builder: (context) {
                              final center = tileCenter(
                                _path[i][0],
                                _path[i][1],
                              );
                              return Positioned(
                                left: center.dx - 30,
                                top: center.dy - 58,
                                child: _TerritoryTotem(
                                  circle: circles[i],
                                  onCheckIn: () => onCheckIn(circles[i]),
                                  onTap: () => onTap(circles[i]),
                                ),
                              );
                            },
                          ),
                        if (circles.isEmpty)
                          Center(
                            child: Text(
                              'Tu territorio está esperando su primer '
                              'tótem 🌱',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dibuja el terreno isométrico: una grilla de tiles en tonos de verde, con
/// un tono más claro ("camino") bajo los tótems activos.
class _IsoGroundPainter extends CustomPainter {
  _IsoGroundPainter({
    required this.cols,
    required this.rows,
    required this.tileWidth,
    required this.tileHeight,
    required this.litPath,
  });

  final int cols;
  final int rows;
  final double tileWidth;
  final double tileHeight;
  final List<Offset> litPath;

  @override
  void paint(Canvas canvas, Size size) {
    final originX = size.width / 2;
    final grassA = Paint()..color = const Color(0xFFBFE3CB);
    final grassB = Paint()..color = const Color(0xFFAEDABE);
    final path = Paint()..color = const Color(0xFFEFE3C2);
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var col = 0; col < cols; col++) {
      for (var row = 0; row < rows; row++) {
        final cx = originX + (col - row) * tileWidth / 2;
        final cy = (col + row) * tileHeight / 2 + 12;
        final isLit = litPath.any(
          (p) => p.dx == col.toDouble() && p.dy == row.toDouble(),
        );
        final tilePaint = isLit
            ? path
            : ((col + row).isEven ? grassA : grassB);

        final diamond = Path()
          ..moveTo(cx, cy - tileHeight / 2)
          ..lineTo(cx + tileWidth / 2, cy)
          ..lineTo(cx, cy + tileHeight / 2)
          ..lineTo(cx - tileWidth / 2, cy)
          ..close();
        canvas.drawPath(diamond, tilePaint);
        canvas.drawPath(diamond, outline);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IsoGroundPainter oldDelegate) =>
      oldDelegate.litPath.length != litPath.length;
}

/// Tótem individual de un círculo de hábito. Se ilumina y libera partículas
/// de energía cuando el check-in de hoy pasa de pendiente a completado.
class _TerritoryTotem extends StatefulWidget {
  const _TerritoryTotem({
    required this.circle,
    required this.onCheckIn,
    required this.onTap,
  });

  final HabitCircle circle;
  final VoidCallback onCheckIn;
  final VoidCallback onTap;

  @override
  State<_TerritoryTotem> createState() => _TerritoryTotemState();
}

class _TerritoryTotemState extends State<_TerritoryTotem> {
  late bool _wasCheckedIn = widget.circle.checkedInToday;
  bool _burst = false;

  @override
  void didUpdateWidget(covariant _TerritoryTotem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isCheckedIn = widget.circle.checkedInToday;
    if (!_wasCheckedIn && isCheckedIn) {
      setState(() => _burst = true);
      Future.delayed(const Duration(milliseconds: 750), () {
        if (mounted) setState(() => _burst = false);
      });
    }
    _wasCheckedIn = isCheckedIn;
  }

  @override
  Widget build(BuildContext context) {
    final circle = widget.circle;
    final lit = circle.checkedInToday;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 56,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  if (_burst) ..._particles(),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: lit ? 0.6 : 1.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: GamePressable(
                      onTap: widget.onCheckIn,
                      pressedScale: 0.8,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        width: lit ? 46 : 38,
                        height: lit ? 46 : 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: lit
                                ? [
                                    AppColors.secondaryContainer,
                                    AppColors.secondary,
                                  ]
                                : [
                                    AppColors.outline.withValues(alpha: 0.25),
                                    AppColors.outline.withValues(alpha: 0.12),
                                  ],
                          ),
                          boxShadow: lit
                              ? [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          lit ? '🔥' : '🌱',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              circle.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            if (circle.streakDays > 0)
              Text(
                '${circle.streakDays}d',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _particles() {
    const count = 6;
    return List.generate(count, (i) {
      final angle = (i / count) * 2 * math.pi;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOut,
        builder: (context, t, child) {
          final dx = math.cos(angle) * 32 * t;
          final dy = math.sin(angle) * 20 * t - 18 * t;
          return Positioned(
            left: 30 + dx - 6,
            bottom: 12 - dy,
            child: Opacity(
              opacity: (1 - t).clamp(0, 1),
              child: const Text('✨', style: TextStyle(fontSize: 11)),
            ),
          );
        },
      );
    });
  }
}
