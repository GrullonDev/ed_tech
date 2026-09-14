import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:confetti/confetti.dart';

import 'package:edtech_tiktok/core/data/avatar_catalog.dart';
import 'package:edtech_tiktok/core/data/streak_cards.dart';
import 'package:edtech_tiktok/core/model/ally_request.dart';
import 'package:edtech_tiktok/core/model/challenge.dart';
import 'package:edtech_tiktok/core/model/check_in.dart';
import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/streak_card.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/widgets/adaptive_glass.dart';
import 'package:edtech_tiktok/features/widgets/app_bottom_nav.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';

const List<String> _kMonthNames = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Pantalla de perfil: solo muestra métricas que se pueden calcular a partir
/// de datos reales del usuario (círculos y check-ins persistidos). No hay
/// contadores sociales (toques de aliento, insignias de otros miembros) ni
/// recordatorios, porque todavía no existe backend multiusuario ni
/// notificaciones — se agregarán cuando esa funcionalidad exista de verdad.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.username,
    required this.memberSince,
    required this.overallStreakDays,
    required this.recordStreakDays,
    required this.monthlyComplianceRate,
    required this.constancyDrops,
    required this.userLevel,
    required this.circles,
    required this.pendingAllyRequests,
    required this.onAcceptAllyRequest,
    required this.onRejectAllyRequest,
    required this.onOpenCircle,
    required this.onOpenRachas,
    required this.onOpenGames,
    required this.onCreateCircle,
    required this.onOpenQrSummon,
    required this.isAnonymousAccount,
    required this.linkedProviderIds,
    required this.onLinkWithGoogle,
    required this.onLinkWithApple,
    required this.onLinkWithEmailPassword,
    required this.liquidGlassEnabled,
    required this.onLiquidGlassChanged,
    required this.unlockedStreakCardMilestones,
    required this.pendingStreakCardMilestones,
    required this.onOpenStreakCard,
    required this.onOpenGameTour,
    required this.userLevelTitle,
    required this.selectedAvatarEmoji,
    required this.selectedAvatarId,
    required this.unlockedAvatarIds,
    required this.onUnlockAvatar,
    required this.onSelectAvatar,
    required this.incomingChallenges,
    required this.onAcceptChallenge,
    required this.onDeclineChallenge,
  });

  final String username;
  final DateTime? memberSince;
  final int overallStreakDays;
  final int recordStreakDays;
  final double monthlyComplianceRate;
  final int constancyDrops;
  final int userLevel;
  final List<HabitCircle> circles;
  final List<AllyRequest> pendingAllyRequests;
  final ValueChanged<AllyRequest> onAcceptAllyRequest;
  final ValueChanged<AllyRequest> onRejectAllyRequest;
  final ValueChanged<HabitCircle> onOpenCircle;
  final VoidCallback onOpenRachas;
  final VoidCallback onOpenGames;
  final VoidCallback onCreateCircle;
  final VoidCallback onOpenQrSummon;

  /// `true` si la sesión sigue siendo anónima — controla si se muestra la
  /// sección "Vincular cuenta" (ver [_AccountLinkingSection]).
  final bool isAnonymousAccount;

  /// IDs de proveedores ya vinculados (`'google.com'`, `'password'`), para
  /// no ofrecer vincular de nuevo el mismo proveedor.
  final List<String> linkedProviderIds;

  /// Retorna `null` si se vinculó con éxito, o un mensaje de error para
  /// mostrar en un SnackBar.
  final Future<String?> Function() onLinkWithGoogle;

  /// Retorna `null` si se vinculó con éxito, o un mensaje de error para
  /// mostrar en un SnackBar.
  final Future<String?> Function() onLinkWithApple;

  /// Retorna `null` si se vinculó con éxito, o un mensaje de error para
  /// mostrar en un SnackBar.
  final Future<String?> Function(String email, String password)
  onLinkWithEmailPassword;

  /// `true` (default) si las tarjetas/superficies de la app usan el efecto
  /// "Liquid Glass" — controla el switch en [_AppearanceSection], disponible
  /// tanto en Android como en iOS.
  final bool liquidGlassEnabled;
  final ValueChanged<bool> onLiquidGlassChanged;

  /// Hitos de racha ya desbloqueados (ver `HomeLogic.unlockedStreakCard
  /// Milestones`) — la Carta de Racha correspondiente ya existe, abierta o
  /// no.
  final List<int> unlockedStreakCardMilestones;

  /// Hitos desbloqueados cuya carta todavía no fue abierta — se muestran
  /// "selladas" hasta que se tocan.
  final List<int> pendingStreakCardMilestones;
  final ValueChanged<int> onOpenStreakCard;

  /// Vuelve a mostrar el tour de "cómo se juega" (ver
  /// `lib/features/widgets/game_tour.dart`), a pedido, sin que cuente como
  /// la primera vez que lo ve el usuario.
  final VoidCallback onOpenGameTour;

  /// Título de progresión asociado al nivel (ver `HomeLogic.userLevelTitle`)
  /// — puramente cosmético, se muestra junto al número de nivel.
  final String userLevelTitle;

  /// Emoji del avatar elegido (ver `HomeLogic.selectedAvatarEmoji`),
  /// mostrado en vez de la imagen de muestra genérica.
  final String selectedAvatarEmoji;

  /// ID del avatar elegido (ver `HomeLogic.selectedAvatarId`), para marcarlo
  /// en la grilla de [_AvatarShop] sin tener que adivinarlo a partir del
  /// emoji.
  final String selectedAvatarId;

  /// IDs desbloqueados del catálogo (ver `HomeLogic.unlockedAvatarIds`),
  /// incluyendo siempre el avatar gratis.
  final List<String> unlockedAvatarIds;

  /// Intenta desbloquear un avatar gastando Gotas de Constancia — no hace
  /// nada si ya está desbloqueado, si el id no existe, o si no alcanza el
  /// saldo (ver `HomeLogic.unlockAvatar`).
  final ValueChanged<String> onUnlockAvatar;

  /// Cambia el avatar mostrado, si ya está desbloqueado.
  final ValueChanged<String> onSelectAvatar;

  /// Retos 1v1 pendientes recibidos de un aliado real (ver
  /// `HomeLogic.challengeAlly`).
  final List<Challenge> incomingChallenges;

  /// Acepta el reto: se une al círculo del duelo. Retorna `null` si salió
  /// bien, o un mensaje de error para mostrar en un SnackBar.
  final Future<String?> Function(Challenge challenge) onAcceptChallenge;
  final ValueChanged<Challenge> onDeclineChallenge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final perfectCount = circles.where((c) => c.isPerfect).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.profile,
        onCreateCircle: onCreateCircle,
        onOpenCircles: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        onOpenRachas: onOpenRachas,
        onOpenGames: onOpenGames,
      ),
      body: SafeArea(
        bottom: false,
        child: AppMaxWidth(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.lg).copyWith(
                  bottom:
                      AppSpacing.xl2 +
                      AppBottomNav.reservedHeight +
                      MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: AppColors.surfaceContainer,
                              child: Text(
                                selectedAvatarEmoji,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                            Positioned(
                              bottom: -6,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryContainer,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    border: Border.all(
                                      color: AppColors.background,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    'Nv. $userLevel',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          username,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _memberSinceLabel(memberSince),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '✨ ${userLevelTitle.toUpperCase()}',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.04,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (circles.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: AppColors.outlineWhisper,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shield_rounded,
                                  size: 14,
                                  color: AppColors.tertiary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Tribu ${circles.first.name} ✓',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                value: '$constancyDrops',
                                label: 'Gotas de Constancia',
                                color: AppColors.tertiary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _StatBox(
                                value: '$recordStreakDays',
                                label: 'Días Mejor Racha',
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _StatBox(
                                value: '$overallStreakDays',
                                label: 'Racha Activa',
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isAnonymousAccount) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _AccountLinkingSection(
                      linkedProviderIds: linkedProviderIds,
                      onLinkWithGoogle: onLinkWithGoogle,
                      onLinkWithApple: onLinkWithApple,
                      onLinkWithEmailPassword: onLinkWithEmailPassword,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _AppearanceSection(
                    liquidGlassEnabled: liquidGlassEnabled,
                    onLiquidGlassChanged: onLiquidGlassChanged,
                  ),
                  if (incomingChallenges.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _IncomingChallengesSection(
                      challenges: incomingChallenges,
                      onAccept: onAcceptChallenge,
                      onDecline: onDeclineChallenge,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl2),
                  Row(
                    children: [
                      const Text('🎭', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Personalización',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Desbloqueá avatares con tus Gotas de Constancia.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _AvatarShop(
                    unlockedAvatarIds: unlockedAvatarIds,
                    selectedAvatarId: selectedAvatarId,
                    constancyDrops: constancyDrops,
                    onUnlock: onUnlockAvatar,
                    onSelect: onSelectAvatar,
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  Row(
                    children: [
                      const Text('🏅', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Vitrina de Tótems',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${_unlockedTotemsCount(
                          overallStreakDays: overallStreakDays,
                          recordStreakDays: recordStreakDays,
                          hasPerfectCircle: perfectCount > 0,
                        )}/$_totalTotemsCount Desbloqueados',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Desliza tu vitrina de tótems coleccionables. Cada uno se '
                    'esculpe al alcanzar su rito.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _TotemShowcase(
                    overallStreakDays: overallStreakDays,
                    recordStreakDays: recordStreakDays,
                    hasPerfectCircle: perfectCount > 0,
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  Row(
                    children: [
                      const Text('🔲', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Piel de Tótem',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${(monthlyComplianceRate * 100).round()}% de '
                          'Constancia este Mes',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Registro biométrico de compromiso. Cada escama refleja '
                    'tus check-ins reales de las últimas 10 semanas.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PresenceMap(circles: circles),
                  const SizedBox(height: AppSpacing.xl2),
                  Row(
                    children: [
                      const Text('⚔️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Gestión de Guerrero',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _WarriorManagementRow(
                    icon: Icons.qr_code_2_rounded,
                    title: 'Invitar Amigos',
                    subtitle: 'Comparte tu código QR con la tribu',
                    onTap: onOpenQrSummon,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _WarriorManagementRow(
                    icon: Icons.help_outline_rounded,
                    title: '¿Cómo funciona Racha Tribu?',
                    subtitle: 'Repasa el tour de bienvenida',
                    onTap: onOpenGameTour,
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  Row(
                    children: [
                      const Text('🃏', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Cartas de Racha',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Cada hito de racha te regala una carta sellada. '
                    'Tocala para abrirla.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StreakCardsGallery(
                    unlockedMilestones: unlockedStreakCardMilestones,
                    pendingMilestones: pendingStreakCardMilestones,
                    onOpenCard: onOpenStreakCard,
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  Text(
                    'Tus círculos',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (circles.isEmpty)
                    Text(
                      'Aún no tienes círculos.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    )
                  else
                    for (final circle in circles) ...[
                      _CircleRow(
                        circle: circle,
                        onTap: () => onOpenCircle(circle),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                ],
              ),
              if (pendingAllyRequests.isNotEmpty)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: _AllyRequestsBadge(
                    pendingAllyRequests: pendingAllyRequests,
                    onAccept: onAcceptAllyRequest,
                    onReject: onRejectAllyRequest,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _memberSinceLabel(DateTime? memberSince) {
    if (memberSince == null) return 'Miembro de Racha Tribu';
    return 'Miembro desde ${_kMonthNames[memberSince.month - 1]} de '
        '${memberSince.year}';
  }
}

/// Retos 1v1 pendientes de un aliado real (ver `HomeLogic.challengeAlly`) —
/// aceptar une al usuario a un círculo de duelo real de verdad, rechazar
/// solo descarta la invitación.
class _IncomingChallengesSection extends StatefulWidget {
  const _IncomingChallengesSection({
    required this.challenges,
    required this.onAccept,
    required this.onDecline,
  });

  final List<Challenge> challenges;
  final Future<String?> Function(Challenge challenge) onAccept;
  final ValueChanged<Challenge> onDecline;

  @override
  State<_IncomingChallengesSection> createState() =>
      _IncomingChallengesSectionState();
}

class _IncomingChallengesSectionState
    extends State<_IncomingChallengesSection> {
  String? _acceptingChallengeId;

  Future<void> _accept(Challenge challenge) async {
    setState(() => _acceptingChallengeId = challenge.id);
    final error = await widget.onAccept(challenge);
    if (!mounted) return;
    setState(() => _acceptingChallengeId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? '¡Duelo aceptado contra @${challenge.fromUsername}!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Retos pendientes',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final challenge in widget.challenges) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '@${challenge.fromUsername} te retó a un duelo 1v1',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onDecline(challenge),
                    child: const Text('Rechazar'),
                  ),
                  FilledButton(
                    onPressed: _acceptingChallengeId == challenge.id
                        ? null
                        : () => _accept(challenge),
                    child: _acceptingChallengeId == challenge.id
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Aceptar'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Apariencia": switch para prender/apagar el efecto "Liquid Glass" en
/// toda la app (ver [GlassThemeController]) — mismo control en Android e
/// iOS, ya que el paquete `liquid_glass_widgets` no depende de código
/// nativo por plataforma. Siempre visible, a diferencia de
/// [_AccountLinkingSection], que solo aparece mientras la cuenta es
/// anónima.
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({
    required this.liquidGlassEnabled,
    required this.onLiquidGlassChanged,
  });

  final bool liquidGlassEnabled;
  final ValueChanged<bool> onLiquidGlassChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Efecto Liquid Glass',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tarjetas y pantallas con vidrio translúcido estilo iOS '
                  '26. Disponible en Android e iOS.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: liquidGlassEnabled, onChanged: onLiquidGlassChanged),
        ],
      ),
    );
  }
}

/// "Vincular cuenta" (Fase Authentication de `firebase/PRODUCTS_PLAN.md`,
/// sección 6): ofrece pasar de la sesión anónima de siempre a una cuenta
/// real (Google o email/contraseña), sin perder el `uid` — y por lo tanto
/// sin perder círculos/aliados/racha ya asociados a ese `uid`. Solo se
/// muestra mientras la cuenta sigue siendo anónima (ver
/// [ProfilePage.isAnonymousAccount]); cada botón se deshabilita si ese
/// proveedor puntual ya está vinculado (puede pasar que uno esté vinculado
/// y el otro no, si el usuario solo hizo una de las dos).
class _AccountLinkingSection extends StatelessWidget {
  const _AccountLinkingSection({
    required this.linkedProviderIds,
    required this.onLinkWithGoogle,
    required this.onLinkWithApple,
    required this.onLinkWithEmailPassword,
  });

  final List<String> linkedProviderIds;
  final Future<String?> Function() onLinkWithGoogle;
  final Future<String?> Function() onLinkWithApple;
  final Future<String?> Function(String email, String password)
  onLinkWithEmailPassword;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final googleLinked = linkedProviderIds.contains('google.com');
    final appleLinked = linkedProviderIds.contains('apple.com');
    final emailLinked = linkedProviderIds.contains('password');
    // En iOS, Apple exige que "Sign in with Apple" esté disponible si se
    // ofrece otro inicio de sesión social (Google incluido); por eso ahí se
    // muestra primero Apple y también se deja Google como alternativa. En
    // Android no existe Sign in with Apple, así que solo se ofrece Google.
    final showApple = Platform.isIOS;
    final allRelevantLinked =
        googleLinked && emailLinked && (appleLinked || !showApple);
    if (allRelevantLinked) return const SizedBox.shrink();

    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Asegura tu cuenta',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Vincula una cuenta real para no perder tu racha si cambias de '
            'dispositivo o desinstalas la app.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (showApple && !appleLinked)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _linkWithApple(context),
                icon: const Icon(Icons.apple, size: 20),
                label: const Text('Continuar con Apple'),
              ),
            ),
          if (showApple && !appleLinked && !googleLinked)
            const SizedBox(height: AppSpacing.sm),
          if (!googleLinked)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _linkWithGoogle(context),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
                label: const Text('Continuar con Google'),
              ),
            ),
          if (!googleLinked && !emailLinked)
            const SizedBox(height: AppSpacing.sm),
          if (!emailLinked)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openEmailPasswordSheet(context),
                icon: const Icon(Icons.email_rounded, size: 18),
                label: const Text('Vincular con email y contraseña'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _linkWithGoogle(BuildContext context) async {
    final error = await onLinkWithGoogle();
    if (!context.mounted) return;
    _showResult(context, error, successMessage: 'Cuenta de Google vinculada.');
  }

  Future<void> _linkWithApple(BuildContext context) async {
    final error = await onLinkWithApple();
    if (!context.mounted) return;
    _showResult(context, error, successMessage: 'Cuenta de Apple vinculada.');
  }

  void _openEmailPasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => _EmailPasswordLinkSheet(
        onLinkWithEmailPassword: onLinkWithEmailPassword,
      ),
    );
  }

  static void _showResult(
    BuildContext context,
    String? error, {
    required String successMessage,
  }) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? successMessage)));
  }
}

/// Hoja inferior con el formulario de email/contraseña para
/// [_AccountLinkingSection.onLinkWithEmailPassword]. Widget con estado
/// propio (no vive en [HomeLogic]) porque el texto de los campos y el
/// spinner de carga son puramente de esta pantalla — nadie más los
/// necesita.
class _EmailPasswordLinkSheet extends StatefulWidget {
  const _EmailPasswordLinkSheet({required this.onLinkWithEmailPassword});

  final Future<String?> Function(String email, String password)
  onLinkWithEmailPassword;

  @override
  State<_EmailPasswordLinkSheet> createState() =>
      _EmailPasswordLinkSheetState();
}

class _EmailPasswordLinkSheetState extends State<_EmailPasswordLinkSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vincular con email y contraseña',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _emailController,
              enabled: !_submitting,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _passwordController,
              enabled: !_submitting,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña (mínimo 6 caracteres)',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Vincular'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final error = await widget.onLinkWithEmailPassword(
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta vinculada con email y contraseña.'),
        ),
      );
      return;
    }
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

/// Distintivo flotante con icono de fuego que avisa de solicitudes de
/// aliado pendientes (simuladas localmente, sin conexión a internet). Al
/// tocarlo abre una hoja inferior donde se puede aceptar o rechazar cada
/// solicitud.
class _AllyRequestsBadge extends StatelessWidget {
  const _AllyRequestsBadge({
    required this.pendingAllyRequests,
    required this.onAccept,
    required this.onReject,
  });

  final List<AllyRequest> pendingAllyRequests;
  final ValueChanged<AllyRequest> onAccept;
  final ValueChanged<AllyRequest> onReject;

  @override
  Widget build(BuildContext context) {
    return GamePressable(
      onTap: () => _openSheet(context),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.secondaryContainer, AppColors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.5),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${pendingAllyRequests.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => _AllyRequestsSheet(
        pendingAllyRequests: pendingAllyRequests,
        onAccept: onAccept,
        onReject: onReject,
      ),
    );
  }
}

class _AllyRequestsSheet extends StatelessWidget {
  const _AllyRequestsSheet({
    required this.pendingAllyRequests,
    required this.onAccept,
    required this.onReject,
  });

  final List<AllyRequest> pendingAllyRequests;
  final ValueChanged<AllyRequest> onAccept;
  final ValueChanged<AllyRequest> onReject;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solicitudes de Aliados',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (pendingAllyRequests.isEmpty)
              Text(
                'No hay solicitudes pendientes.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              )
            else
              for (final request in pendingAllyRequests) ...[
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '@${request.fromUsername}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.onSurfaceVariant,
                      ),
                      onPressed: () {
                        onReject(request);
                        Navigator.of(context).pop();
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        onAccept(request);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
          ],
        ),
      ),
    );
  }
}

/// Caja de estadística compacta del encabezado de Perfil (Gotas, Mejor
/// Racha, Racha Activa) — mismo criterio de "un dato real por caja" que el
/// resto del rediseño.
class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineWhisper),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de "Gestión de Guerrero" — acciones reales ya existentes (invocar
/// por QR, tour de bienvenida), solo restyleadas como lista con chevron en
/// vez de botones sueltos.
class _WarriorManagementRow extends StatelessWidget {
  const _WarriorManagementRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GamePressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outlineWhisper),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
              child: Icon(icon, size: 18, color: AppColors.secondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuadrícula de 10 semanas x 7 días. Cada celda refleja la fracción real de
/// círculos con check-in en ese día (0 = sin actividad, 1 = todos los
/// círculos activos ese día), no valores de ejemplo.
class _PresenceMap extends StatelessWidget {
  const _PresenceMap({required this.circles});

  final List<HabitCircle> circles;

  static const _labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _weeks = 10;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final today = CheckIn.today();
    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
    final gridStart = startOfThisWeek.subtract(
      const Duration(days: 7 * (_weeks - 1)),
    );

    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (var row = 0; row < 7; row++) ...[
            Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text(
                    _labels[row],
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Row(
                    children: [
                      for (var week = 0; week < _weeks; week++) ...[
                        if (week > 0) const SizedBox(width: 4),
                        Expanded(
                          child: _PresenceCell(
                            day: gridStart.add(Duration(days: week * 7 + row)),
                            today: today,
                            circles: circles,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (row < 6) const SizedBox(height: 4),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Ritmo suave',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Plena presencia',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresenceCell extends StatelessWidget {
  const _PresenceCell({
    required this.day,
    required this.today,
    required this.circles,
  });

  final DateTime day;
  final DateTime today;
  final List<HabitCircle> circles;

  @override
  Widget build(BuildContext context) {
    if (day.isAfter(today) || circles.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.outlineWhisper,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }
    final completed = circles
        .where((c) => c.checkIns.any((ci) => ci.date == day))
        .length;
    final fraction = completed / circles.length;
    final color = Color.lerp(
      AppColors.surfaceContainer,
      AppColors.primary,
      fraction,
    )!;
    final isToday = day == today;
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: isToday
              ? Border.all(color: AppColors.secondary, width: 1.5)
              : null,
        ),
      ),
    );
  }
}

/// Cantidad total de tótems de [_TotemShowcase] — usado por el contador
/// "X/4 Desbloqueados" del encabezado de la sección, sin duplicar los datos
/// de cada tótem (eso vive en `_TotemShowcaseState.build`).
const _totalTotemsCount = 4;

/// Replica exactamente las 4 condiciones `unlocked` de
/// `_TotemShowcaseState.build` (7 días, 21 días, círculo perfecto, 30 días)
/// para poder mostrar "X/4 Desbloqueados" en el encabezado sin repetir la
/// lista completa de tótems ahí.
int _unlockedTotemsCount({
  required int overallStreakDays,
  required int recordStreakDays,
  required bool hasPerfectCircle,
}) {
  var count = 0;
  if (overallStreakDays >= 7) count++;
  if (recordStreakDays >= 21) count++;
  if (hasPerfectCircle) count++;
  if (recordStreakDays >= 30) count++;
  return count;
}

/// Logros calculados a partir de la racha activa, el récord histórico y si
/// algún círculo llegó al 100% hoy — todo derivable de los datos reales del
/// usuario, sin contadores sociales inventados. Se muestran como una vitrina
/// interactiva de tótems 3D en vez de una grilla plana de insignias.
class _TotemShowcase extends StatefulWidget {
  const _TotemShowcase({
    required this.overallStreakDays,
    required this.recordStreakDays,
    required this.hasPerfectCircle,
  });

  final int overallStreakDays;
  final int recordStreakDays;
  final bool hasPerfectCircle;

  @override
  State<_TotemShowcase> createState() => _TotemShowcaseState();
}

class _TotemShowcaseState extends State<_TotemShowcase> {
  late final PageController _controller = PageController(
    viewportFraction: 0.42,
  );
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totems = [
      _TotemData(
        icon: Icons.shield_moon_rounded,
        colors: const [AppColors.secondaryContainer, AppColors.secondary],
        title: 'Semana Imbatible',
        subtitle: '7 días seguidos sin fallar',
        unlocked: widget.overallStreakDays >= 7,
      ),
      _TotemData(
        icon: Icons.spa_rounded,
        colors: const [AppColors.primaryContainer, AppColors.primary],
        title: 'Hábito Consolidado',
        subtitle: '21 días de racha histórica',
        unlocked: widget.recordStreakDays >= 21,
      ),
      _TotemData(
        icon: Icons.celebration_rounded,
        colors: const [AppColors.lavenderContainer, AppColors.secondary],
        title: 'Círculo Perfecto',
        subtitle: '100% completado en un día',
        unlocked: widget.hasPerfectCircle,
      ),
      _TotemData(
        icon: Icons.workspace_premium_rounded,
        colors: const [AppColors.warningContainer, AppColors.secondary],
        title: 'Pacto de 30 Días',
        subtitle: '${widget.recordStreakDays.clamp(0, 30)}/30 días',
        unlocked: widget.recordStreakDays >= 30,
        progress: (widget.recordStreakDays / 30).clamp(0, 1).toDouble(),
      ),
    ];

    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: _controller,
        itemCount: totems.length,
        padEnds: true,
        itemBuilder: (context, index) {
          final delta = (index - _page).abs().clamp(0.0, 1.0);
          final scale = 1 - delta * 0.22;
          final rotation = (index - _page).clamp(-1.0, 1.0) * 0.12;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(rotation)
              ..scaleByDouble(scale, scale, scale, 1),
            child: Opacity(
              opacity: 1 - delta * 0.35,
              child: _MasteryTotem(data: totems[index]),
            ),
          );
        },
      ),
    );
  }
}

class _TotemData {
  const _TotemData({
    required this.icon,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.unlocked,
    this.progress,
  });

  final IconData icon;
  final List<Color> colors;
  final String title;
  final String subtitle;
  final bool unlocked;
  final double? progress;
}

/// Un tótem coleccionable individual: un bloque con profundidad 3D
/// (ver [Iso3DIcon]) que se "esculpe" (aparece con rebote) al desbloquearse,
/// o se ve en piedra gris mientras sigue bloqueado.
class _MasteryTotem extends StatelessWidget {
  const _MasteryTotem({required this.data});

  final _TotemData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unlocked = data.unlocked;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: unlocked
            ? Border.all(color: AppColors.secondary.withValues(alpha: 0.35))
            : Border.all(color: AppColors.outlineWhisper),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ]
            : AppShadows.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey('totem-${data.title}-$unlocked'),
            tween: Tween(begin: unlocked ? 0.3 : 1.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Iso3DIcon(
              icon: data.icon,
              size: 52,
              colors: unlocked
                  ? data.colors
                  : [AppColors.surfaceContainer, AppColors.outline],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          if (data.progress != null && !unlocked)
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: data.progress,
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceContainer,
                  color: AppColors.secondary,
                ),
              ),
            )
          else
            Text(
              unlocked ? 'Esculpido' : 'En bruto',
              style: textTheme.labelSmall?.copyWith(
                color: unlocked ? AppColors.primary : AppColors.outline,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

/// Grilla horizontal de Cartas de Racha (ver [StreakCards.all]). Cada carta
/// puede estar bloqueada (hito todavía no alcanzado), sellada (hito
/// alcanzado, esperando que se toque para revelarla) o abierta (ya
/// revelada, muestra el texto de sabor completo).
class _StreakCardsGallery extends StatelessWidget {
  const _StreakCardsGallery({
    required this.unlockedMilestones,
    required this.pendingMilestones,
    required this.onOpenCard,
  });

  final List<int> unlockedMilestones;
  final List<int> pendingMilestones;
  final ValueChanged<int> onOpenCard;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: StreakCards.all.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final card = StreakCards.all[index];
          final unlocked = unlockedMilestones.contains(card.milestoneDays);
          final sealed = pendingMilestones.contains(card.milestoneDays);
          return _StreakCardTile(
            card: card,
            unlocked: unlocked,
            sealed: sealed,
            onTap: sealed
                ? () => _revealStreakCard(context, card, onOpenCard)
                : null,
          );
        },
      ),
    );
  }
}

/// Revela [card] con una celebración a pantalla completa (confetti propio +
/// el sonido/haptic de [HomeLogic.openStreakCard], que se dispara al llamar
/// [onOpenCard] acá mismo) en vez de solo voltear la miniatura en la
/// grilla — este es el hito más importante de la progresión (7/21/30/50/100
/// días), así que merece el momento más grande de toda la app.
///
/// El confetti vive en este diálogo (no en el overlay global de
/// `home.dart`) porque `ProfilePage` es una ruta empujada por `Navigator`
/// distinta de `MyHomePage` — el overlay de `home.dart` queda tapado detrás
/// de rutas opacas como esta, así que un confetti propio es la única forma
/// de que se vea acá.
void _revealStreakCard(
  BuildContext context,
  StreakCard card,
  ValueChanged<int> onOpenCard,
) {
  onOpenCard(card.milestoneDays);
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => _StreakCardRevealDialog(card: card),
  );
}

class _StreakCardRevealDialog extends StatefulWidget {
  const _StreakCardRevealDialog({required this.card});

  final StreakCard card;

  @override
  State<_StreakCardRevealDialog> createState() =>
      _StreakCardRevealDialogState();
}

class _StreakCardRevealDialogState extends State<_StreakCardRevealDialog> {
  late final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¡Carta desbloqueada!',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Text(
                    widget.card.emoji,
                    style: const TextStyle(fontSize: 72),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.card.title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${widget.card.milestoneDays} días de racha',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.card.flavorText,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Genial'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -20,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 32,
                maxBlastForce: 16,
                minBlastForce: 8,
                gravity: 0.35,
                shouldLoop: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCardTile extends StatelessWidget {
  const _StreakCardTile({
    required this.card,
    required this.unlocked,
    required this.sealed,
    required this.onTap,
  });

  final StreakCard card;
  final bool unlocked;
  final bool sealed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final content = Container(
      width: 128,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: unlocked ? AppColors.secondary : AppColors.outlineWhisper,
        ),
        boxShadow: unlocked ? AppShadows.card : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            sealed ? '🎁' : (unlocked ? card.emoji : '🔒'),
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            sealed
                ? '¡Nueva carta!'
                : (unlocked ? card.title : '${card.milestoneDays} días'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (sealed) ...[
            const SizedBox(height: 2),
            Text(
              'Tocá para abrir',
              style: textTheme.labelSmall?.copyWith(color: AppColors.primary),
            ),
          ] else if (!unlocked) ...[
            const SizedBox(height: 2),
            Text(
              'Bloqueada',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
    return onTap == null
        ? content
        : GamePressable(onTap: onTap!, child: content);
  }
}

/// Grilla del catálogo de avatares (ver `core/data/avatar_catalog.dart`):
/// cada celda muestra el emoji, desbloqueado/bloqueado/seleccionado, y su
/// costo si todavía no se desbloqueó. Tocar una celda desbloqueada la
/// selecciona; tocar una bloqueada intenta comprarla (silenciosamente no
/// hace nada si no alcanzan las gotas — `HomeLogic.unlockAvatar` ya valida
/// eso, así que no hace falta duplicar la validación acá).
class _AvatarShop extends StatelessWidget {
  const _AvatarShop({
    required this.unlockedAvatarIds,
    required this.selectedAvatarId,
    required this.constancyDrops,
    required this.onUnlock,
    required this.onSelect,
  });

  final List<String> unlockedAvatarIds;
  final String selectedAvatarId;
  final int constancyDrops;
  final ValueChanged<String> onUnlock;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final avatar in AvatarCatalog.all)
          _AvatarTile(
            avatar: avatar,
            unlocked: unlockedAvatarIds.contains(avatar.id),
            selected: avatar.id == selectedAvatarId,
            affordable: constancyDrops >= avatar.cost,
            onTap: () {
              if (unlockedAvatarIds.contains(avatar.id)) {
                onSelect(avatar.id);
              } else {
                onUnlock(avatar.id);
              }
            },
          ),
      ],
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatar,
    required this.unlocked,
    required this.selected,
    required this.affordable,
    required this.onTap,
  });

  final AvatarOption avatar;
  final bool unlocked;
  final bool selected;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GamePressable(
      onTap: onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineWhisper,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              avatar.emoji,
              style: TextStyle(
                fontSize: 28,
                color: unlocked ? null : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            if (unlocked)
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 14,
                color: selected ? AppColors.primary : AppColors.outline,
              )
            else
              Text(
                '${avatar.cost} 💧',
                style: textTheme.labelSmall?.copyWith(
                  color: affordable
                      ? AppColors.secondary
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleRow extends StatelessWidget {
  const _CircleRow({required this.circle, required this.onTap});

  final HabitCircle circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outlineWhisper),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                circle.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${circle.streakDays}d 🔥',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
