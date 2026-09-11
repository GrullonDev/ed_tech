import 'package:flutter/material.dart';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:edtech_tiktok/core/theme/app_assets.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({
    super.key,
    required this.usernameController,
    required this.onContinue,
  });

  final TextEditingController usernameController;
  final VoidCallback onContinue;

  /// Titular por defecto, usado tanto como fallback si Remote Config no
  /// llegó a activarse como valor por defecto que se declara en
  /// `main.dart._initRemoteConfig` (así el parámetro `onboarding_headline`
  /// de la consola de Firebase tiene, desde el día uno, el mismo texto que
  /// ya se veía antes de esta integración).
  static const defaultHeadline = 'Bienvenido a\nRacha Tribu';

  /// Lee `onboarding_headline` de Remote Config (Fase "A/B Testing" de
  /// `firebase/PRODUCTS_PLAN.md`, sección 3). Envuelto en try/catch porque
  /// esta pantalla es lo primero que ve un usuario nuevo: si Firebase nunca
  /// se inicializó (sin red, sin configurar), no debe romper el onboarding
  /// — cae al mismo texto de siempre.
  static String _headline() {
    try {
      final value = FirebaseRemoteConfig.instance.getString(
        'onboarding_headline',
      );
      return value.isEmpty ? defaultHeadline : value;
    } catch (_) {
      return defaultHeadline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AppMaxWidth(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical -
                    AppSpacing.xl2 * 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(AppAssets.logo, width: 72, height: 72),
                  const SizedBox(height: AppSpacing.xl2),
                  Text(
                    _headline(),
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.02,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Crea círculos de hábitos con tus amigos, haz check-in diario '
                    'y mantén tu racha viva junto a los demás miembros del grupo.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl3),
                  TextField(
                    controller: usernameController,
                    style: textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Tu apodo de usuario',
                    ),
                    onSubmitted: (_) => onContinue(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
