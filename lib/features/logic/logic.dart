import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';

/// Estado y reglas de negocio del dashboard de hábitos.
///
/// Las pantallas (`page/home.dart` y los widgets en `features/widgets/`)
/// solo leen este estado y disparan estos métodos; no contienen lógica propia.
class HomeLogic extends ChangeNotifier {
  bool _hasUsername = false;
  String _username = '';

  final TextEditingController usernameController = TextEditingController();

  final List<HabitCircle> _circles = [
    HabitCircle(
      name: 'Programar 30 min',
      streakDays: 5,
      members: ['A', 'B', 'C'],
      checkedInToday: false,
    ),
    HabitCircle(
      name: 'Leer 10 páginas',
      streakDays: 12,
      members: ['D', 'E'],
      checkedInToday: true,
    ),
    HabitCircle(
      name: 'Beber 2L de agua',
      streakDays: 3,
      members: ['F', 'G', 'H', 'I'],
      checkedInToday: false,
    ),
  ];

  bool get hasUsername => _hasUsername;
  String get username => _username;
  List<HabitCircle> get circles => List.unmodifiable(_circles);

  void completeOnboarding() {
    final name = usernameController.text.trim();
    if (name.isEmpty) return;
    _username = name;
    _hasUsername = true;
    notifyListeners();
  }

  void toggleCheckIn(HabitCircle circle) {
    circle.checkedInToday = !circle.checkedInToday;
    notifyListeners();
  }

  void createNewCircle() {
    _circles.add(
      HabitCircle(
        name: 'Nuevo círculo ${_circles.length + 1}',
        streakDays: 0,
        members: ['Yo'],
        checkedInToday: false,
      ),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }
}
