import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/features/logic/logic.dart';
import 'package:edtech_tiktok/features/page/circle_detail.dart';
import 'package:edtech_tiktok/features/page/create_habit.dart';
import 'package:edtech_tiktok/features/page/profile.dart';
import 'package:edtech_tiktok/features/widgets/dashboard.dart';
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
          onCreateCircle: _openCreateHabit,
          onCheckIn: _logic.toggleCheckIn,
          onToggleTodayHabit: _logic.toggleTodayHabit,
          onOpenCircle: _openCircleDetail,
          onOpenProfile: _openProfile,
        );
      },
    );
  }

  void _openCircleDetail(HabitCircle circle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ListenableBuilder(
          listenable: _logic,
          builder: (context, _) => CircleDetailPage(
            circle: circle,
            onCheckIn: () => _logic.toggleCheckIn(circle),
          ),
        ),
      ),
    );
  }

  void _openCreateHabit() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CreateHabitPage(logic: _logic)),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ListenableBuilder(
          listenable: _logic,
          builder: (context, _) => ProfilePage(
            username: _logic.username,
            overallStreakDays: _logic.overallStreakDays,
            circles: _logic.circles,
          ),
        ),
      ),
    );
  }
}
