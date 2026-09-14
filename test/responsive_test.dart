// Prueba de responsividad: monta cada pantalla de la app a varios anchos de
// pantalla reales — desde el Android/iPhone más angosto en uso hasta una
// tablet — y falla si Flutter reporta un overflow de layout (RenderFlex
// overflowed) o cualquier otra excepción durante el build. Usa datos "de
// estrés" (nombres/usuarios muy largos, listas largas) para forzar los
// casos límite en vez de solo los nombres cortos que se usaron durante el
// desarrollo.
//
// No cubre CreateHabitPage: recibe un `HomeLogic` real, que en su
// constructor ya dispara `_loadFromStorage()` (Hive/Firebase) — instanciarlo
// en un test liviano requeriría mockear ambos, fuera de alcance acá. Su
// contenido (TextFields + Wrap de chips dentro de un ListView) es en sí
// mismo un patrón de bajo riesgo de overflow, a diferencia de las Row con
// texto variable que sí causaron los bugs reales de este archivo.
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:edtech_tiktok/core/model/activity_event.dart';
import 'package:edtech_tiktok/core/model/ally_request.dart';
import 'package:edtech_tiktok/core/model/challenge.dart';
import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/leaderboard_entry.dart';
import 'package:edtech_tiktok/core/model/today_habit.dart';
import 'package:edtech_tiktok/core/model/trivia_question.dart';
import 'package:edtech_tiktok/core/theme/app_theme.dart';
import 'package:edtech_tiktok/features/page/agora.dart';
import 'package:edtech_tiktok/features/page/circle_detail.dart';
import 'package:edtech_tiktok/features/page/games.dart';
import 'package:edtech_tiktok/features/page/profile.dart';
import 'package:edtech_tiktok/features/page/qr_summon.dart';
import 'package:edtech_tiktok/features/page/rachas.dart';
import 'package:edtech_tiktok/features/page/tribe_founded.dart';
import 'package:edtech_tiktok/features/widgets/app_bottom_nav.dart';
import 'package:edtech_tiktok/features/widgets/dashboard.dart';
import 'package:edtech_tiktok/features/widgets/game_tour.dart';
import 'package:edtech_tiktok/features/widgets/onboarding.dart';

/// Anchos reales a cubrir: el Android/iPhone más angosto que sigue en uso
/// (iPhone SE 1ª gen / Galaxy J-series ≈ 320), el piso "moderno" típico
/// (iPhone SE 2020+/12 mini ≈ 360-375), un teléfono grande (iPhone Pro Max/
/// Galaxy Ultra ≈ 428-430), y una tablet chica en portrait (donde
/// `AppMaxWidth` empieza a limitar el ancho del contenido, ≈ 800).
const _widths = <double>[320, 375, 430, 800];
const _height = 900.0;

void main() {
  Future<void> pumpAtWidth(
    WidgetTester tester,
    double width,
    Widget child,
  ) async {
    tester.view.physicalSize = Size(width, _height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: child));
    await tester.pumpAndSettle();
  }

  void noop1<T>(T _) {}
  void noop0() {}
  Future<String?> asyncNull() async => null;
  Future<bool> asyncTrue() async => true;
  Future<String?> asyncNullArg1(Object _) async => null;

  final longCircleName =
      'Círculo con un nombre extremadamente largo para '
      'forzar el límite del layout';
  final circles = [
    HabitCircle(
      name: longCircleName,
      category: 'Una categoría también muy larga de verdad',
      members: [
        'Guerrero_Con_Nombre_Larguísimo',
        'Otro Miembro',
        'Tercer Miembro',
        'Cuarto',
        'Quinto',
      ],
    )..addCheckInToday(),
    HabitCircle(name: 'Corto', category: 'General'),
  ];

  final todayHabits = [
    TodayHabit(
      label: 'Un hábito con un nombre bastante largo también',
      done: true,
    ),
    TodayHabit(label: 'Otro', done: false),
  ];

  final activityFeed = [
    ActivityEvent(
      emoji: '🔥',
      message:
          'Un mensaje de actividad muy largo que debería truncarse o '
          'ajustarse sin romper el layout de la tarjeta del feed',
      at: DateTime.now(),
      reactedByUids: ['a', 'b', 'c'],
    ),
  ];

  final leaderboard = [
    const LeaderboardEntry(
      uid: '1',
      username: 'Usuario_Con_Nombre_De_Verdad_Largo',
      streakDays: 47,
      dropsEarned: 12345,
      checkedInToday: true,
      isCurrentUser: true,
    ),
    const LeaderboardEntry(
      uid: '2',
      username: 'Otro',
      streakDays: 3,
      dropsEarned: 10,
      checkedInToday: false,
      isCurrentUser: false,
    ),
  ];

  final incomingChallenges = [
    Challenge(
      id: '1',
      fromUid: 'a',
      fromUsername: 'Retador_Con_Nombre_Largo',
      toUid: 'b',
      toUsername: 'yo',
      circleId: 'c1',
      circleName: 'Duelo largo de nombre',
      inviteCode: 'ABC123',
      status: 'pending',
      createdAt: DateTime.now(),
    ),
  ];

  const trivia = TriviaQuestion(
    question: 'Una pregunta de trivia bastante larga para probar el layout',
    options: ['Opción uno larga', 'Opción dos', 'Opción tres larga también'],
    correctIndex: 0,
    explanation: 'Explicación',
  );

  for (final width in _widths) {
    testWidgets('AppBottomNav no desborda a ${width}px', (tester) async {
      await pumpAtWidth(
        tester,
        width,
        Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentTab: AppTab.circles,
            onCreateCircle: noop0,
            onOpenCircles: noop0,
            onOpenRachas: noop0,
            onOpenGames: noop0,
            onOpenProfile: noop0,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Dashboard (Inicio) no desborda a ${width}px', (tester) async {
      await pumpAtWidth(
        tester,
        width,
        Dashboard(
          username: 'Un_Usuario_De_Nombre_Largo',
          circles: circles,
          todayHabits: todayHabits,
          todayCompletedCount: 1,
          todayTotalCount: 2,
          todayProgress: 0.5,
          nextPendingHabit: todayHabits[1],
          overallStreakDays: 14,
          streakPulseTick: 0,
          constancyDrops: 123456,
          userLevel: 12,
          onCreateCircle: noop0,
          onCheckIn: noop1,
          onToggleTodayHabit: noop1,
          onAddTodayHabit: noop1,
          onOpenCircle: noop1,
          onOpenRachas: noop0,
          onOpenGames: noop0,
          onOpenProfile: noop0,
          onInviteMember: (_, _) {},
          allies: const ['Aliado uno', 'Aliado dos'],
          onChallengeAlly: asyncNullArg1,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('RachasPage no desborda a ${width}px', (tester) async {
      await pumpAtWidth(
        tester,
        width,
        RachasPage(
          circles: circles,
          overallStreakDays: 47,
          onCheckIn: noop1,
          onOpenCircle: noop1,
          onCreateCircle: noop0,
          onOpenGames: noop0,
          onOpenProfile: noop0,
          onOpenAgora: noop0,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('GamesPage no desborda a ${width}px', (tester) async {
      await pumpAtWidth(
        tester,
        width,
        GamesPage(
          circles: circles,
          onCreateCircle: noop0,
          onOpenRachas: noop0,
          onOpenProfile: noop0,
          todaysTrivia: trivia,
          hasAnsweredTodaysTrivia: false,
          triviaLastSelectedIndex: null,
          onAnswerTrivia: (_) => true,
          hasSpunTodaysWheel: false,
          wheelLastReward: null,
          onSpinWheel: () => 10,
          weeklyDuelUserTotal: 12345,
          weeklyDuelRivalTotal: 6789,
          hasWonWeeklyDuel: false,
          hasPendingPredictionToday: false,
          pendingPredictionCircleId: null,
          predictionBetAmount: 20,
          constancyDrops: 500,
          onPlacePrediction: (_) => true,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfilePage no desborda a ${width}px', (tester) async {
      await pumpAtWidth(
        tester,
        width,
        ProfilePage(
          username: 'Un_Usuario_De_Nombre_Extremadamente_Largo',
          memberSince: DateTime(2024, 1, 1),
          overallStreakDays: 47,
          recordStreakDays: 99,
          monthlyComplianceRate: 0.96,
          constancyDrops: 987654,
          userLevel: 28,
          circles: circles,
          pendingAllyRequests: [
            AllyRequest(
              fromUsername: 'Un aliado con nombre largo',
              sentAt: DateTime.now(),
            ),
          ],
          onAcceptAllyRequest: noop1,
          onRejectAllyRequest: noop1,
          onOpenCircle: noop1,
          onOpenRachas: noop0,
          onOpenGames: noop0,
          onCreateCircle: noop0,
          onOpenQrSummon: noop0,
          isAnonymousAccount: true,
          linkedProviderIds: const [],
          onLinkWithGoogle: asyncNull,
          onLinkWithApple: asyncNull,
          onLinkWithEmailPassword: (_, _) async => null,
          liquidGlassEnabled: true,
          onLiquidGlassChanged: noop1,
          unlockedStreakCardMilestones: const [7, 21],
          pendingStreakCardMilestones: const [21],
          onOpenStreakCard: noop1,
          onOpenGameTour: noop0,
          userLevelTitle: 'Chamán de Fuego',
          selectedAvatarEmoji: '🔥',
          selectedAvatarId: 'default',
          unlockedAvatarIds: const ['default'],
          onUnlockAvatar: noop1,
          onSelectAvatar: noop1,
          incomingChallenges: incomingChallenges,
          onAcceptChallenge: (_) async => null,
          onDeclineChallenge: noop1,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('AgoraPage no desborda a ${width}px', (tester) async {
      await pumpAtWidth(
        tester,
        width,
        AgoraPage(
          circles: circles,
          circlesUpdatedTick: 0,
          allyUsernameController: TextEditingController(),
          onSendAllyRequest: asyncTrue,
          activityFeed: activityFeed,
          hasReactedTo: (_) => false,
          onToggleReaction: noop1,
          onCheckIn: noop1,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('CircleDetailPage no desborda a ${width}px', (tester) async {
      await pumpAtWidth(
        tester,
        width,
        CircleDetailPage(
          circle: circles.first,
          onCheckIn: noop0,
          onInviteMember: noop1,
          onOpenGames: noop0,
          leaderboard: leaderboard,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('TribeFoundedPage no desborda a ${width}px', (tester) async {
      await pumpAtWidth(
        tester,
        width,
        TribeFoundedPage(
          circle: circles.first,
          onOpenCircleDetail: noop0,
          onOpenAgora: noop0,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Onboarding no desborda a ${width}px', (tester) async {
      await pumpAtWidth(
        tester,
        width,
        Onboarding(
          usernameController: TextEditingController(),
          onContinue: noop0,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('GameTour no desborda a ${width}px', (tester) async {
      await pumpAtWidth(tester, width, GameTour(onFinish: noop0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('QrSummonPage (Mi Código) no desborda a ${width}px', (
      tester,
    ) async {
      await pumpAtWidth(
        tester,
        width,
        QrSummonPage(
          username: 'Un_Usuario_De_Nombre_Extremadamente_Largo',
          qrPayload: 'payload',
          onScanned: (_) => null,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
