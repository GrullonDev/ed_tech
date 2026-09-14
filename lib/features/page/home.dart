import 'dart:math';

import 'package:flutter/material.dart';

import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/logic/logic.dart';
import 'package:edtech_tiktok/features/page/agora.dart';
import 'package:edtech_tiktok/features/page/circle_detail.dart';
import 'package:edtech_tiktok/features/page/create_habit.dart';
import 'package:edtech_tiktok/features/page/games.dart';
import 'package:edtech_tiktok/features/page/profile.dart';
import 'package:edtech_tiktok/features/page/qr_summon.dart';
import 'package:edtech_tiktok/features/page/rachas.dart';
import 'package:edtech_tiktok/features/page/tribe_founded.dart';
import 'package:edtech_tiktok/features/widgets/dashboard.dart';
import 'package:edtech_tiktok/features/widgets/game_tour.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';
import 'package:edtech_tiktok/features/widgets/onboarding.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final HomeLogic _logic = HomeLogic();

  /// Evita reabrir el diálogo de actualización en cada `notifyListeners()`
  /// posterior (check-ins, hábitos, etc.) — una vez que el usuario lo vio
  /// (lo cierre con "Actualizar" o "Ahora no"), no vuelve a aparecer hasta
  /// el próximo arranque de la app.
  bool _updateDialogShown = false;

  /// Overlay global de confetti: vive acá (no en `Dashboard`) porque
  /// `toggleCheckIn` se dispara desde tres pantallas distintas (Dashboard,
  /// CircleDetail, Rachas) y todas comparten esta misma instancia de
  /// `_MyHomePageState` por debajo — un solo `ConfettiController` cubre los
  /// tres casos sin duplicar el widget en cada pantalla.
  late final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(milliseconds: 600),
  );
  int _lastCelebrationTick = 0;

  @override
  void initState() {
    super.initState();
    _lastCelebrationTick = _logic.celebrationTick;
    _logic.addListener(_maybeShowUpdateDialog);
    _logic.addListener(_maybeCelebrate);
    _logic.addListener(_maybeShowSurpriseBonus);
  }

  @override
  void dispose() {
    _logic.removeListener(_maybeShowUpdateDialog);
    _logic.removeListener(_maybeCelebrate);
    _confettiController.dispose();
    _logic.removeListener(_maybeShowSurpriseBonus);
    _logic.dispose();
    super.dispose();
  }

  void _maybeCelebrate() {
    if (_logic.celebrationTick == _lastCelebrationTick) return;
    _lastCelebrationTick = _logic.celebrationTick;
    _confettiController.play();
  }

  /// Aviso especial del bono sorpresa aleatorio del check-in (ver
  /// `HomeLogic._maybeGrantSurpriseBonus`) — variedad/sorpresa del loop
  /// principal, distinto del resultado normal del check-in. Se limpia con
  /// [HomeLogic.clearLastSurpriseBonus] apenas se muestra, para no repetir
  /// el mismo SnackBar en el próximo `notifyListeners()` que no venga de un
  /// check-in nuevo.
  void _maybeShowSurpriseBonus() {
    final bonus = _logic.lastSurpriseBonus;
    if (bonus == null) return;
    _logic.clearLastSurpriseBonus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎁 ¡Bono sorpresa! +$bonus Gotas de Constancia'),
          backgroundColor: AppColors.secondary,
        ),
      );
    });
  }

  void _maybeShowUpdateDialog() {
    if (_updateDialogShown || !_logic.hasUpdateAvailable) return;
    _updateDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showUpdateDialog();
    });
  }

  /// Diálogo "Hay una nueva versión disponible" (Fase App Distribution,
  /// `firebase/APP_DISTRIBUTION.md`) — dispara cuando `HomeLogic` detecta
  /// que Remote Config publicó un `latest_android_build_number` mayor al
  /// build instalado. "Actualizar" abre el link de descarga de Firebase
  /// App Distribution en el navegador/la app de App Distribution;
  /// "Ahora no" solo cierra el diálogo por esta sesión.
  Future<void> _showUpdateDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hay una nueva versión disponible'),
        content: const Text(
          'Actualiza Racha Tribu para tener las últimas mejoras y '
          'correcciones.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _logic.dismissUpdateBanner();
            },
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              _logic.dismissUpdateBanner();
              final url = _logic.updateDownloadUrl;
              if (url.isEmpty) return;
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [_buildContent(context), _buildConfettiOverlay()]);
  }

  /// Confetti cayendo desde arriba de toda la pantalla, sin bloquear toques
  /// (`IgnorePointer`) — solo se ve, nunca interfiere con el resto de la UI.
  Widget _buildConfettiOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 24,
            maxBlastForce: 12,
            minBlastForce: 6,
            gravity: 0.4,
            shouldLoop: false,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListenableBuilder(
      listenable: _logic,
      builder: (context, _) {
        if (!_logic.hasUsername) {
          if (!_logic.deviceAccountCheckDone) {
            return const DeviceAccountCheckSplash();
          }
          if (_logic.deviceHasExistingAccount) {
            return ExistingAccountLogin(
              providers: _logic.existingAccountProviders,
              onSignInWithGoogle: _logic.signInExistingWithGoogle,
              onSignInWithEmailPassword:
                  _logic.signInExistingWithEmailPassword,
              onCreateNewAccountInstead: _logic.dismissExistingAccountPrompt,
            );
          }
          return Onboarding(
            usernameController: _logic.usernameController,
            onContinue: _logic.completeOnboarding,
          );
        }
        if (!_logic.hasSeenGameTour) {
          return GameTour(onFinish: _logic.completeGameTour);
        }
        return Dashboard(
          username: _logic.username,
          circles: _logic.circles,
          todayHabits: _logic.todayHabits,
          todayCompletedCount: _logic.todayCompletedCount,
          todayTotalCount: _logic.todayTotalCount,
          todayProgress: _logic.todayProgress,
          nextPendingHabit: _logic.nextPendingHabit,
          overallStreakDays: _logic.overallStreakDays,
          streakPulseTick: _logic.streakPulseTick,
          constancyDrops: _logic.constancyDrops,
          userLevel: _logic.userLevel,
          onCreateCircle: _openCreateHabit,
          onCheckIn: _logic.toggleCheckIn,
          onToggleTodayHabit: _logic.toggleTodayHabit,
          onAddTodayHabit: _logic.addTodayHabit,
          onOpenCircle: _openCircleDetail,
          onOpenRachas: _openRachas,
          onOpenGames: _openGames,
          onOpenProfile: _openProfile,
          onInviteMember: _logic.addMemberToCircle,
          allies: _logic.allies,
          onChallengeAlly: _logic.challengeAlly,
        );
      },
    );
  }

  void _openCircleDetail(HabitCircle circle) {
    Navigator.of(context).push(
      GamePageRoute(
        builder: (context) => ListenableBuilder(
          listenable: _logic,
          builder: (context, _) => CircleDetailPage(
            circle: circle,
            onCheckIn: () => _logic.toggleCheckIn(circle),
            onInviteMember: (name) => _logic.addMemberToCircle(circle, name),
            leaderboard: _logic.leaderboardFor(circle.id),
            onOpenGames: _openGames,
          ),
        ),
      ),
    );
  }

  void _openRachas() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(
      GamePageRoute(
        builder: (context) => ListenableBuilder(
          listenable: _logic,
          builder: (context, _) => RachasPage(
            circles: _logic.circles,
            overallStreakDays: _logic.overallStreakDays,
            onCheckIn: _logic.toggleCheckIn,
            onOpenCircle: _openCircleDetail,
            onCreateCircle: _openCreateHabit,
            onOpenGames: _openGames,
            onOpenProfile: _openProfile,
            onOpenAgora: _openAgora,
          ),
        ),
      ),
    );
  }

  void _openGames() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(
      GamePageRoute(
        builder: (context) => ListenableBuilder(
          listenable: _logic,
          builder: (context, _) => GamesPage(
            circles: _logic.circles,
            onCreateCircle: _openCreateHabit,
            onOpenRachas: _openRachas,
            onOpenProfile: _openProfile,
            todaysTrivia: _logic.todaysTrivia,
            hasAnsweredTodaysTrivia: _logic.hasAnsweredTodaysTrivia,
            triviaLastSelectedIndex: _logic.triviaLastSelectedIndex,
            onAnswerTrivia: _logic.answerTrivia,
            hasSpunTodaysWheel: _logic.hasSpunTodaysWheel,
            wheelLastReward: _logic.wheelLastReward,
            onSpinWheel: _logic.spinWheel,
            weeklyDuelUserTotal: _logic.weeklyDuelUserTotal,
            weeklyDuelRivalTotal: _logic.weeklyDuelRivalTotal,
            hasWonWeeklyDuel: _logic.hasWonWeeklyDuel,
            hasPendingPredictionToday: _logic.hasPendingPredictionToday,
            pendingPredictionCircleId: _logic.pendingPredictionCircleId,
            predictionBetAmount: HomeLogic.predictionBetAmount,
            constancyDrops: _logic.constancyDrops,
            onPlacePrediction: _logic.placePrediction,
          ),
        ),
      ),
    );
  }

  void _openAgora() {
    Navigator.of(context).push(
      GamePageRoute(
        builder: (context) => ListenableBuilder(
          listenable: _logic,
          builder: (context, _) => AgoraPage(
            circles: _logic.circles,
            circlesUpdatedTick: _logic.circlesUpdatedTick,
            allyUsernameController: _logic.allyUsernameController,
            onSendAllyRequest: _logic.sendAllyRequest,
            activityFeed: _logic.activityFeed,
            hasReactedTo: _logic.hasReactedTo,
            onToggleReaction: _logic.toggleActivityReaction,
            onCheckIn: _logic.toggleCheckIn,
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateHabit() async {
    final circle = await Navigator.of(context).push<HabitCircle>(
      GamePageRoute(builder: (context) => CreateHabitPage(logic: _logic)),
    );
    if (circle == null || !mounted) return;
    Navigator.of(context).push(
      GamePageRoute(
        builder: (context) => TribeFoundedPage(
          circle: circle,
          onOpenCircleDetail: () {
            Navigator.of(context).pop();
            _openCircleDetail(circle);
          },
          onOpenAgora: () {
            Navigator.of(context).pop();
            _openAgora();
          },
        ),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(
      GamePageRoute(
        builder: (context) => ListenableBuilder(
          listenable: _logic,
          builder: (context, _) => ProfilePage(
            username: _logic.username,
            memberSince: _logic.memberSince,
            overallStreakDays: _logic.overallStreakDays,
            recordStreakDays: _logic.recordStreakDays,
            monthlyComplianceRate: _logic.monthlyComplianceRate,
            constancyDrops: _logic.constancyDrops,
            userLevel: _logic.userLevel,
            circles: _logic.circles,
            pendingAllyRequests: _logic.pendingAllyRequests,
            onAcceptAllyRequest: _logic.acceptAllyRequest,
            onRejectAllyRequest: _logic.rejectAllyRequest,
            onOpenCircle: _openCircleDetail,
            onOpenRachas: _openRachas,
            onOpenGames: _openGames,
            onCreateCircle: _openCreateHabit,
            onOpenQrSummon: _openQrSummon,
            isAnonymousAccount: _logic.isAnonymousAccount,
            linkedProviderIds: _logic.linkedProviderIds,
            onLinkWithGoogle: _logic.linkWithGoogle,
            onLinkWithApple: _logic.linkWithApple,
            onLinkWithEmailPassword: _logic.linkWithEmailPassword,
            liquidGlassEnabled: _logic.liquidGlassEnabled,
            onLiquidGlassChanged: _logic.setLiquidGlassEnabled,
            unlockedStreakCardMilestones: _logic.unlockedStreakCardMilestones,
            pendingStreakCardMilestones: _logic.pendingStreakCardMilestones,
            onOpenStreakCard: _logic.openStreakCard,
            onOpenGameTour: _openGameTour,
            userLevelTitle: _logic.userLevelTitle,
            selectedAvatarEmoji: _logic.selectedAvatarEmoji,
            selectedAvatarId: _logic.selectedAvatarId,
            unlockedAvatarIds: _logic.unlockedAvatarIds,
            onUnlockAvatar: _logic.unlockAvatar,
            onSelectAvatar: _logic.selectAvatar,
            incomingChallenges: _logic.incomingChallenges,
            onAcceptChallenge: _logic.acceptChallenge,
            onDeclineChallenge: _logic.declineChallenge,
          ),
        ),
      ),
    );
  }

  /// Vuelve a mostrar el tour de "cómo se juega" a pedido (botón en
  /// `ProfilePage`), sin depender de `HomeLogic.hasSeenGameTour` — a
  /// diferencia de la primera vez (justo después del onboarding), acá solo
  /// cierra la pantalla al terminar en vez de desbloquear el dashboard.
  void _openGameTour() {
    Navigator.of(context).push(
      GamePageRoute(
        builder: (context) =>
            GameTour(onFinish: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _openQrSummon() {
    Navigator.of(context).push(
      GamePageRoute(
        builder: (context) => QrSummonPage(
          username: _logic.username,
          qrPayload: _logic.qrPayload,
          onScanned: _logic.addAllyFromScannedCode,
        ),
      ),
    );
  }
}
