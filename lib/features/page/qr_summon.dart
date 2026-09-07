import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';

/// "Invocar por QR": emula la sensación de un juego multijugador local.
/// Una pestaña muestra el código QR único del jugador (su [qrPayload], que
/// contiene su ID local); la otra abre la cámara para escanear el de otro
/// dispositivo y agregarlo al instante como aliado, cara a cara y sin
/// conexión a internet.
class QrSummonPage extends StatefulWidget {
  const QrSummonPage({
    super.key,
    required this.username,
    required this.qrPayload,
    required this.onScanned,
  });

  final String username;
  final String qrPayload;
  final String? Function(String code) onScanned;

  @override
  State<QrSummonPage> createState() => _QrSummonPageState();
}

class _QrSummonPageState extends State<QrSummonPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Invocar por QR'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Mi Código'),
            Tab(text: 'Escanear'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyCodeTab(username: widget.username, qrPayload: widget.qrPayload),
          _ScanTab(onScanned: widget.onScanned),
        ],
      ),
    );
  }
}

class _MyCodeTab extends StatelessWidget {
  const _MyCodeTab({required this.username, required this.qrPayload});

  final String username;
  final String qrPayload;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.card,
              ),
              child: QrImageView(
                data: qrPayload,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.onSurface,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              username,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pide a tu aliado que escanee este código con su cámara para '
              'agregarte al instante a su tribu.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanTab extends StatefulWidget {
  const _ScanTab({required this.onScanned});

  final String? Function(String code) onScanned;

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  final MobileScannerController _controller = MobileScannerController();
  String? _resultMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_resultMessage != null) return;
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;
    final addedUsername = widget.onScanned(code);
    setState(() {
      _isSuccess = addedUsername != null;
      _resultMessage = addedUsername != null
          ? '¡@$addedUsername ahora es tu aliado!'
          : 'Ese código no es válido o ya es tu aliado.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      children: [
        MobileScanner(controller: _controller, onDetect: _handleDetect),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.xl,
          child: Column(
            children: [
              if (_resultMessage != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isSuccess ? '🔥🤝' : '⚠️',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _resultMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _isSuccess
                                  ? AppColors.primary
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_resultMessage != null) const SizedBox(height: AppSpacing.sm),
              if (_resultMessage != null)
                GamePressable(
                  onTap: () => setState(() => _resultMessage = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      'Escanear otro código',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
