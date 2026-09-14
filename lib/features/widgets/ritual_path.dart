import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/milestone.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';

/// "El Libro de los Ritos": un camino sinuoso de nodos (uno por [Milestone])
/// que reemplaza la lista plana de barras de progreso. Cada nodo se ilumina
/// y muestra una insignia cuando su hito ya fue alcanzado ([Milestone.unlocked]);
/// el primer hito aún bloqueado queda resaltado como "meta actual" con un
/// brillo pulsante. Se dibuja con [CustomPainter] a un tamaño "natural" fijo
/// y luego se escala al ancho real disponible, igual que [TerritoryMap], para
/// que se vea consistente y responsivo en cualquier dispositivo.
class RitualPath extends StatelessWidget {
  const RitualPath({super.key, required this.milestones});

  final List<Milestone> milestones;

  static const _naturalWidth = 320.0;
  static const _rowHeight = 104.0;
  static const _nodeSize = 60.0;

  /// Fracciones horizontales (0..1) en zigzag para que el camino serpentee.
  static const _xFractions = [0.5, 0.82, 0.5, 0.18];

  @override
  Widget build(BuildContext context) {
    final naturalHeight = milestones.length * _rowHeight + _nodeSize;
    final centers = <Offset>[
      for (var i = 0; i < milestones.length; i++)
        Offset(
          _xFractions[i % _xFractions.length] * _naturalWidth,
          _nodeSize / 2 + i * _rowHeight,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _naturalWidth;
        final scale = (availableWidth / _naturalWidth).clamp(0.75, 1.4);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4EEDD), Color(0xFFEAE0C4)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          child: Center(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: _naturalWidth,
                height: naturalHeight,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(_naturalWidth, naturalHeight),
                      painter: _RitualPathPainter(
                        centers: centers,
                        reachedCount: milestones
                            .where((m) => m.unlocked)
                            .length,
                      ),
                    ),
                    for (var i = 0; i < milestones.length; i++)
                      Positioned(
                        left: centers[i].dx - _nodeSize / 2,
                        top: centers[i].dy - _nodeSize / 2,
                        child: _RitualNode(
                          milestone: milestones[i],
                          index: i,
                          isCurrentQuest:
                              !milestones[i].unlocked &&
                              milestones.indexWhere((m) => !m.unlocked) == i,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dibuja la línea curva que conecta cada nodo, en tono dorado sólido para
/// el tramo ya recorrido y punteado gris para el tramo aún por descubrir.
class _RitualPathPainter extends CustomPainter {
  _RitualPathPainter({required this.centers, required this.reachedCount});

  final List<Offset> centers;
  final int reachedCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    final donePaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final todoPaint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.35)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < centers.length - 1; i++) {
      final start = centers[i];
      final end = centers[i + 1];
      final control = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final segment = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(start.dx, control.dy, control.dx, control.dy)
        ..quadraticBezierTo(end.dx, control.dy, end.dx, end.dy);
      final isDone = i < reachedCount - 1 || (i == reachedCount - 1);
      canvas.drawPath(segment, isDone ? donePaint : todoPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RitualPathPainter oldDelegate) =>
      oldDelegate.reachedCount != reachedCount;
}

class _RitualNode extends StatelessWidget {
  const _RitualNode({
    required this.milestone,
    required this.index,
    required this.isCurrentQuest,
  });

  final Milestone milestone;
  final int index;
  final bool isCurrentQuest;

  @override
  Widget build(BuildContext context) {
    final reached = milestone.unlocked;
    final days = milestone.requiredDays;
    final textTheme = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 120),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: reached
                    ? [AppColors.secondaryContainer, AppColors.secondary]
                    : isCurrentQuest
                    ? [AppColors.lavenderContainer, AppColors.surface]
                    : [AppColors.surfaceContainer, AppColors.surfaceContainer],
              ),
              border: isCurrentQuest && !reached
                  ? Border.all(color: AppColors.secondary, width: 2)
                  : null,
              boxShadow: reached || isCurrentQuest
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.45),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              reached ? '⭐' : (isCurrentQuest ? '🔥' : '🔒'),
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$days d',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: reached ? AppColors.secondary : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
