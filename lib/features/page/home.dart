import 'package:flutter/material.dart';

import 'package:edtech_tiktok/features/logic/logic.dart';
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
          onCreateCircle: _logic.createNewCircle,
          onCheckIn: _logic.toggleCheckIn,
        );
      },
    );
  }
}
