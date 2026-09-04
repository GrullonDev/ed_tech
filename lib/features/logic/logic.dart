import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/app_user.dart';
import 'package:edtech_tiktok/core/model/check_in.dart';
import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/today_habit.dart';
import 'package:edtech_tiktok/core/service/local_storage_service.dart';

/// Estado y reglas de negocio del dashboard de hábitos.
///
/// Las pantallas (`page/home.dart` y los widgets en `features/widgets/`)
/// solo leen este estado y disparan estos métodos; no contienen lógica ni
/// datos propios. Todo el estado se persiste en local (Hive, vía
/// [LocalStorageService]): usuario, círculos y hábitos del día sobreviven a
/// un reinicio de la app, y no hay datos de ejemplo quemados — una
/// instalación nueva arranca completamente vacía hasta que el usuario crea
/// sus propios círculos y hábitos. Al integrar Supabase, este es el único
/// lugar que necesita cambiar: la UI no conoce el origen de los datos.
class HomeLogic extends ChangeNotifier {
  HomeLogic() {
    _loadFromStorage();
  }

  bool _hasUsername = false;
  String _username = '';
  DateTime? _memberSince;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController habitNameController = TextEditingController();
  final TextEditingController habitCategoryController = TextEditingController();

  List<TodayHabit> _todayHabits = [];
  List<HabitCircle> _circles = [];

  /// Contador que se incrementa cada vez que se completa un hábito o
  /// check-in. Sirve como trigger para la micro-animación de pulso en el
  /// ícono de racha: la UI observa este valor (no su magnitud) y reproduce
  /// la animación cada vez que cambia.
  int _streakPulseTick = 0;

  bool get hasUsername => _hasUsername;
  String get username => _username;
  DateTime? get memberSince => _memberSince;
  List<HabitCircle> get circles => List.unmodifiable(_circles);
  List<TodayHabit> get todayHabits => List.unmodifiable(_todayHabits);
  int get streakPulseTick => _streakPulseTick;

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

  /// Racha consecutiva más larga alcanzada alguna vez en cualquier círculo
  /// (récord histórico), no solo la que sigue activa hoy.
  int get recordStreakDays => _circles.isEmpty
      ? 0
      : _circles
            .map((c) => c.longestStreakDays)
            .reduce((a, b) => a > b ? a : b);

  /// Fracción de días transcurridos en el mes actual (desde el día 1 hasta
  /// hoy) en los que hubo al menos un check-in en algún círculo.
  double get monthlyComplianceRate {
    final today = CheckIn.today();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final elapsedDays = today.difference(startOfMonth).inDays + 1;
    if (elapsedDays <= 0 || _circles.isEmpty) return 0;
    var daysWithActivity = 0;
    for (var i = 0; i < elapsedDays; i++) {
      final day = startOfMonth.add(Duration(days: i));
      final hasActivity = _circles.any(
        (c) => c.checkIns.any((ci) => ci.date == day),
      );
      if (hasActivity) daysWithActivity++;
    }
    return daysWithActivity / elapsedDays;
  }

  void _loadFromStorage() {
    final savedUser = LocalStorageService.readUser();
    _circles = LocalStorageService.readCircles();
    _todayHabits = LocalStorageService.readTodayHabits();

    _hasUsername = savedUser != null;
    _username = savedUser?.username ?? '';
    _memberSince = savedUser?.memberSince;
    usernameController.text = _username;

    _applyDailyResetIfNeeded();
    notifyListeners();
  }

  /// Los hábitos de "hoy" son diarios: si cambió el día calendario desde la
  /// última vez que se abrió la app, se desmarcan para que reflejen el
  /// progreso real del nuevo día en vez de arrastrar el de ayer.
  void _applyDailyResetIfNeeded() {
    final today = CheckIn.today();
    final lastActive = LocalStorageService.readLastActiveDate();
    if (lastActive == today) return;

    if (lastActive != null && _todayHabits.isNotEmpty) {
      for (final habit in _todayHabits) {
        habit.done = false;
      }
      LocalStorageService.saveTodayHabits(_todayHabits);
    }
    LocalStorageService.saveLastActiveDate(today);
  }

  void completeOnboarding() {
    final name = usernameController.text.trim();
    if (name.isEmpty) return;
    _username = name;
    _hasUsername = true;
    LocalStorageService.saveUser(
      AppUser(username: name, memberSince: DateTime.now()),
    );
    notifyListeners();
  }

  void addTodayHabit(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    _todayHabits.add(TodayHabit(label: trimmed, done: false));
    LocalStorageService.saveTodayHabits(_todayHabits);
    notifyListeners();
  }

  void toggleTodayHabit(TodayHabit habit) {
    final wasDone = habit.done;
    habit.done = !habit.done;
    if (!wasDone && habit.done) _streakPulseTick++;
    LocalStorageService.saveTodayHabits(_todayHabits);
    notifyListeners();
  }

  void toggleCheckIn(HabitCircle circle) {
    final wasCheckedIn = circle.checkedInToday;
    if (wasCheckedIn) {
      circle.removeCheckInToday();
    } else {
      circle.addCheckInToday();
      _streakPulseTick++;
    }
    LocalStorageService.saveCircles(_circles);
    notifyListeners();
  }

  void createCircle({required String name, required String category}) {
    _circles.add(HabitCircle(name: name, category: category));
    LocalStorageService.saveCircles(_circles);
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
