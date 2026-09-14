import 'package:flutter/material.dart';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:edtech_tiktok/core/theme/app_assets.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';

/// Placeholder de carga mientras `HomeLogic._checkDeviceForExistingAccount`
/// todavía no respondió — se muestra en vez de [Onboarding] o
/// [ExistingAccountLogin] para no arrancar el onboarding de cuenta
/// anónima antes de saber si este dispositivo ya tiene cuenta (ver
/// `page/home.dart`). Solo dura la ida y vuelta de una Cloud Function, así
/// que no hace falta más que un spinner centrado.
class DeviceAccountCheckSplash extends StatelessWidget {
  const DeviceAccountCheckSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Se muestra en vez de [Onboarding] cuando `HomeLogic.deviceHasExistingAccount`
/// detectó (vía la Cloud Function `checkDeviceAccount`) que este mismo
/// dispositivo ya vinculó una cuenta real antes — típicamente porque el
/// jugador desinstaló y reinstaló la app. Ofrece iniciar sesión de verdad
/// (no crear una cuenta anónima nueva) con Google o con email/contraseña,
/// según qué proveedores devolvió el backend, y con una salida a "Crear
/// una cuenta nueva" por si el dispositivo se comparte con otra persona.
class ExistingAccountLogin extends StatefulWidget {
  const ExistingAccountLogin({
    super.key,
    required this.providers,
    required this.onSignInWithGoogle,
    required this.onSignInWithEmailPassword,
    required this.onCreateNewAccountInstead,
  });

  /// Proveedores ya vinculados a la cuenta detectada (`'google.com'`,
  /// `'password'`, `'apple.com'`), tal como los devuelve
  /// `checkDeviceAccount`. Determina qué botones se muestran primero.
  final List<String> providers;

  /// Debe intentar `HomeLogic.signInExistingWithGoogle` y devolver el
  /// mensaje de error a mostrar, o `null` si funcionó.
  final Future<String?> Function() onSignInWithGoogle;

  /// Debe intentar `HomeLogic.signInExistingWithEmailPassword` y devolver
  /// el mensaje de error a mostrar, o `null` si funcionó.
  final Future<String?> Function(String email, String password)
  onSignInWithEmailPassword;

  /// El jugador prefiere no iniciar sesión con la cuenta detectada (ej.
  /// dispositivo compartido) y quiere seguir el onboarding normal.
  final VoidCallback onCreateNewAccountInstead;

  @override
  State<ExistingAccountLogin> createState() => _ExistingAccountLoginState();
}

class _ExistingAccountLoginState extends State<ExistingAccountLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showEmailForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _hasGoogle => widget.providers.contains('google.com');
  bool get _hasPassword => widget.providers.contains('password');

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await action();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(AppAssets.logo, width: 72, height: 72),
                const SizedBox(height: AppSpacing.xl2),
                Text(
                  'Ya tenés una cuenta\nen este dispositivo',
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.02,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Iniciá sesión con esa cuenta en vez de crear una nueva.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl3),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (_hasGoogle) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () => _run(widget.onSignInWithGoogle),
                      child: const Text('Iniciar sesión con Google'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (_hasPassword && !_showEmailForm)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _showEmailForm = true),
                      child: const Text('Iniciar sesión con email'),
                    ),
                  ),
                if (_showEmailForm) ...[
                  TextField(
                    controller: _emailController,
                    style: textTheme.bodyLarge,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _passwordController,
                    style: textTheme.bodyLarge,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    onSubmitted: (_) => _loading
                        ? null
                        : _run(
                            () => widget.onSignInWithEmailPassword(
                              _emailController.text,
                              _passwordController.text,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () => _run(
                              () => widget.onSignInWithEmailPassword(
                                _emailController.text,
                                _passwordController.text,
                              ),
                            ),
                      child: const Text('Iniciar sesión'),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl2),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : widget.onCreateNewAccountInstead,
                    child: const Text('No es mi cuenta, crear una nueva'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
