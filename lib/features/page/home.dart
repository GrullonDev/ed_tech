import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/features/logic/logic.dart';
import 'package:edtech_tiktok/features/page/agora.dart';
import 'package:edtech_tiktok/features/page/circle_detail.dart';
import 'package:edtech_tiktok/features/page/create_habit.dart';
import 'package:edtech_tiktok/features/page/profile.dart';
import 'package:edtech_tiktok/features/page/qr_summon.dart';
import 'package:edtech_tiktok/features/page/rachas.dart';
import 'package:edtech_tiktok/features/widgets/dashboard.dart';
import 'package:edtech_tiktok/features/widgets/game_ui.dart';
import 'package:edtech_tiktok/features/widgets/onboarding.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final HomeLogic _logic = HomeLogic();

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _logic,
      builder: (context, _) {
        if (!_logic.hasUsername) {
          return Onboarding(
            usernameController: _logic.usernameController,
            onContinue: _logic.completeOnboarding,
          );
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
          onOpenProfile: _openProfile,
          onInviteMember: _logic.addMemberToCircle,
          allies: _logic.allies,
          todaysTrivia: _logic.todaysTrivia,
          hasAnsweredTodaysTrivia: _logic.hasAnsweredTodaysTrivia,
          triviaLastSelectedIndex: _logic.triviaLastSelectedIndex,
          onAnswerTrivia: _logic.answerTrivia,
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
            onOpenProfile: _openProfile,
            onOpenAgora: _openAgora,
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
          ),
        ),
      ),
    );
  }

  void _openCreateHabit() {
    Navigator.of(
      context,
    ).push(GamePageRoute(builder: (context) => CreateHabitPage(logic: _logic)));
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
            onCreateCircle: _openCreateHabit,
            onOpenQrSummon: _openQrSummon,
            isAnonymousAccount: _logic.isAnonymousAccount,
            linkedProviderIds: _logic.linkedProviderIds,
            onLinkWithGoogle: _logic.linkWithGoogle,
            onLinkWithEmailPassword: _logic.linkWithEmailPassword,
          ),
        ),
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
