import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/today_habit.dart';

/// Estado y reglas de negocio del dashboard de hábitos.
///
/// Las pantallas (`page/home.dart` y los widgets en `features/widgets/`)
/// solo leen este estado y disparan estos métodos; no contienen lógica propia.
class HomeLogic extends ChangeNotifier {
  bool _hasUsername = false;
  String _username = '';

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController habitNameController = TextEditingController();
  final TextEditingController habitCategoryController = TextEditingController();

  final List<TodayHabit> _todayHabits = [
    TodayHabit(label: 'Lectura 20p', done: true),
    TodayHabit(label: 'Madrugar', done: true),
    TodayHabit(label: 'Caminata 7k', done: false),
  ];

  final List<HabitCircle> _circles = [
    HabitCircle(
      name: 'Club Lectura 20 Páginas',
      category: 'Enfoque Vespertino',
      streakDays: 24,
      members: ['A', 'B', 'C', 'D', 'E'],
      totalMembers: 8,
      completedMembers: 6,
      checkedInToday: true,
    ),
    HabitCircle(
      name: 'Madrugadores 6:30 AM',
      category: 'Ritmo Matutino',
      streakDays: 12,
      members: ['F', 'G', 'H'],
      totalMembers: 6,
      completedMembers: 5,
      checkedInToday: true,
      pendingMemberName: 'Mateo',
    ),
    HabitCircle(
      name: 'Caminata 7k Pasos',
      category: 'Círculo Perfecto',
      streakDays: 9,
      members: ['I', 'J', 'K', 'L'],
      totalMembers: 7,
      completedMembers: 7,
      checkedInToday: true,
    ),
  ];

  bool get hasUsername => _hasUsername;
  String get username => _username;
  List<HabitCircle> get circles => List.unmodifiable(_circles);
  List<TodayHabit> get todayHabits => List.unmodifiable(_todayHabits);

  int get todayCompletedCount => _todayHabits.where((h) => h.done).length;
  int get todayTotalCount => _todayHabits.length;
  double get todayProgress =>
      todayTotalCount == 0 ? 0 : todayCompletedCount / todayTotalCount;
  TodayHabit? get nextPendingHabit {
    for (final habit in _todayHabits) {
      if (!habit.done) return habit;
    }
    return null;
  }

  int get overallStreakDays => _circles.isEmpty
      ? 0
      : _circles.map((c) => c.streakDays).reduce((a, b) => a > b ? a : b);

  void completeOnboarding() {
    final name = usernameController.text.trim();
    if (name.isEmpty) return;
    _username = name;
    _hasUsername = true;
    notifyListeners();
  }

  void toggleTodayHabit(TodayHabit habit) {
    habit.done = !habit.done;
    notifyListeners();
  }

  void toggleCheckIn(HabitCircle circle) {
    circle.checkedInToday = !circle.checkedInToday;
    circle.completedMembers =
        (circle.completedMembers + (circle.checkedInToday ? 1 : -1)).clamp(
          0,
          circle.totalMembers,
        );
    notifyListeners();
  }

  void createNewCircle() {
    createCircle(
      name: 'Nuevo círculo ${_circles.length + 1}',
      category: 'Recién creado',
    );
  }

  void createCircle({required String name, required String category}) {
    _circles.add(
      HabitCircle(
        name: name,
        category: category,
        streakDays: 0,
        members: ['Yo'],
        totalMembers: 1,
        completedMembers: 0,
        checkedInToday: false,
      ),
    );
    notifyListeners();
  }

  /// Crea un círculo a partir de [habitNameController] y
  /// [habitCategoryController], y limpia ambos campos. Retorna `false` sin
  /// hacer nada si el nombre está vacío.
  bool submitNewCircle() {
    final name = habitNameController.text.trim();
    if (name.isEmpty) return false;
    final category = habitCategoryController.text.trim().isEmpty
        ? 'General'
        : habitCategoryController.text.trim();
    createCircle(name: name, category: category);
    habitNameController.clear();
    habitCategoryController.clear();
    return true;
  }

  @override
  void dispose() {
    usernameController.dispose();
    habitNameController.dispose();
    habitCategoryController.dispose();
    super.dispose();
  }
}
