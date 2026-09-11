import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/theme/app_assets.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';

/// Tour explicativo de "cómo se juega" Racha Tribu — qué es la racha, cómo
/// se sube de nivel, para qué sirven las Gotas de Constancia y los
/// Escudos, y qué es el Desafío del día. Se muestra una vez, justo después
/// de completar el onboarding de username (ver `HomeLogic.hasSeenGameTour`
/// y `page/home.dart`), y queda disponible para volver a verlo desde el
/// perfil (`ProfilePage`, botón "¿Cómo funciona Racha Tribu?").
///
/// Es puramente informativo: no depende de Firebase, no cambia ningún dato
/// del usuario más que la bandera "ya lo vi" — se puede saltar en
/// cualquier momento con "Omitir".
class GameTour extends StatefulWidget {
  const GameTour({super.key, required this.onFinish});

  /// Se llama al tocar "Empezar" en la última página o "Omitir" en
  /// cualquier momento — en ambos casos el tour queda marcado como visto.
  final VoidCallback onFinish;

  static const List<_TourSlide> _slides = [
    _TourSlide(
      emoji: '🔥',
      title: 'Así funciona Racha Tribu',
      description:
          'Creá círculos de hábitos, invitá a tu tribu, y hacé check-in '
          'cada día que cumplas. Cada día seguido suma a tu racha — '
          'perderla un solo día no te hace empezar de cero, pero '
          'sostenerla es lo que más vale.',
    ),
    _TourSlide(
      emoji: '🏆',
      title: 'Subí de nivel con tu racha',
      description:
          'Tu Nivel de perfil sube solo, automáticamente, cada 7 días de '
          'racha activa acumulada. Cuanto más constante seas, más alto '
          'tu nivel — no hay compras ni atajos, es 100% lo que realmente '
          'hiciste.',
    ),
    _TourSlide(
      emoji: '💧',
      title: 'Gotas de Constancia y Escudos',
      description:
          'Cada check-in te da Gotas de Constancia, y ganan más mientras '
          'más larga sea tu racha vigente. Al llegar a hitos de racha '
          '(7, 21, 30, 50, 100 días) ganás un Escudo de Racha gratis, que '
          'cubre un día que se te pase sin romper la cadena.',
    ),
    _TourSlide(
      emoji: '🧠',
      title: 'Desafío del día',
      description:
          'Todos los días hay una pregunta nueva sobre hábitos y '
          'constancia esperándote en tu dashboard. Acertarla te da Gotas '
          'extra — y de paso aprendés algo. Es divertido y productivo al '
          'mismo tiempo: justo lo que buscamos.',
    ),
  ];

  @override
  State<GameTour> createState() => _GameTourState();
}

class _GameTourState extends State<GameTour> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastPage => _page == GameTour._slides.length - 1;

  void _next() {
    if (_isLastPage) {
      widget.onFinish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AppMaxWidth(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextButton(
                    onPressed: widget.onFinish,
                    child: const Text('Omitir'),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: GameTour._slides.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) =>
                      _TourSlideView(slide: GameTour._slides[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < GameTour._slides.length; i++)
                          _PageDot(active: i == _page),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        child: Text(_isLastPage ? 'Empezar' : 'Siguiente'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourSlide {
  const _TourSlide({
    required this.emoji,
    required this.title,
    required this.description,
  });

  final String emoji;
  final String title;
  final String description;
}

class _TourSlideView extends StatelessWidget {
  const _TourSlideView({required this.slide});

  final _TourSlide slide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppAssets.logo, width: 48, height: 48),
          const SizedBox(height: AppSpacing.xl),
          Text(slide.emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.outlineWhisper,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
