import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';

/// "El Gran Ágora Tribal": reemplaza las notificaciones de texto simples
/// ("¡Círculo Perfecto!") por un mapa de juego social. Cada círculo se ve
/// como una hoguera tribal — más grande y brillante cuanto mayor es su racha
/// colectiva — rodeada de los avatares de sus miembros, y una lista de
/// maestros ordena los círculos por racha. Sin backend social, los datos se
/// derivan por completo de [HabitCircle] (miembros y check-ins reales).
class AgoraPage extends StatelessWidget {
  const AgoraPage({super.key, required this.circles});

  final List<HabitCircle> circles;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ranked = [...circles]
      ..sort((a, b) => b.streakDays.compareTo(a.streakDays));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('El Gran Ágora Tribal'),
      ),
      body: SafeArea(
        child: AppMaxWidth(
          child: circles.isEmpty
              ? _EmptyAgora(textTheme: textTheme)
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ).copyWith(bottom: AppSpacing.xl2),
                  children: [
                    Text(
                      'Alrededor de cada hoguera se reúne tu tribu. Cuanto '
                      'más fuerte la racha colectiva, más brilla el fuego.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    for (final circle in ranked) ...[
                      _TribalBonfireCard(circle: circle),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Lista de Maestros de la Tribu',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _LeaderboardCard(ranked: ranked),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EmptyAgora extends StatelessWidget {
  const _EmptyAgora({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aún no hay hogueras encendidas',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Crea un círculo y haz tu primer check-in para encender la '
              'primera hoguera de la tribu.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de una hoguera tribal: crece, cambia de color e intensifica su
/// brillo según la racha del círculo (0 = apagada, 30+ = fuego intenso).
class _TribalBonfireCard extends StatelessWidget {
  const _TribalBonfireCard({required this.circle});

  final HabitCircle circle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final streak = circle.streakDays;
    final intensity = (streak / 30).clamp(0.15, 1.0);
    final fireSize = 44 + intensity * 30;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  circle.name,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (circle.isPerfect)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.completedGlow,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '¡Círculo Perfecto! ✨',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: SizedBox(
              height: 96,
              width: 200,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < circle.members.length; i++)
                    Positioned(
                      left:
                          100 +
                          64 *
                              (i % 2 == 0 ? 1 : -1) *
                              ((i ~/ 2 + 1) / (circle.members.length / 2 + 1))
                                  .clamp(0.3, 1.0) -
                          14,
                      bottom: 4,
                      child: _MemberAvatar(name: circle.members[i]),
                    ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: fireSize,
                      height: fireSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.secondary,
                            AppColors.secondary.withValues(alpha: 0),
                          ],
                        ),
                        boxShadow: streak > 0
                            ? [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.55 * intensity,
                                  ),
                                  blurRadius: 24 * intensity,
                                  spreadRadius: 4 * intensity,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        streak > 0 ? '🔥' : '🪵',
                        style: TextStyle(fontSize: 20 + intensity * 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              streak > 0
                  ? 'Racha colectiva: $streak días'
                  : 'Hoguera apagada — hagan su primer check-in',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.lavenderContainer,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Tabla de clasificación estilizada como pergamino de "Maestros de la
/// Tribu", ordenada por racha actual de cada círculo.
class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.ranked});

  final List<HabitCircle> ranked;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < ranked.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      i < _medals.length ? _medals[i] : '${i + 1}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      ranked[i].name,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${ranked[i].streakDays} días',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (i < ranked.length - 1)
              const Divider(height: 1, color: AppColors.outlineWhisper),
          ],
        ],
      ),
    );
  }
}
