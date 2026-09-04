import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/today_habit.dart';
import 'package:edtech_tiktok/core/service/local_storage_service.dart';

/// Datos de ejemplo usados solo la primera vez que se abre la app (cuando
/// Hive todavía no tiene nada guardado localmente).
List<TodayHabit> _seedTodayHabits() => [
  TodayHabit(label: 'Lectura 20p', done: true),
  TodayHabit(label: 'Madrugar', done: true),
  TodayHabit(label: 'Caminata 7k', done: false),
];

List<HabitCircle> _seedCircles() => [
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

/// Estado y reglas de negocio del dashboard de hábitos.
///
/// Las pantallas (`page/home.dart` y los widgets en `features/widgets/`)
/// solo leen este estado y disparan estos métodos; no contienen lógica propia.
///
/// El estado se persiste en local (Hive, vía [LocalStorageService]) para que
/// el alias de usuario, los círculos y los check-ins del día sobrevivan a un
/// reinicio de la app mientras no exista backend. Al integrar Supabase, este
/// es el único lugar que necesita cambiar: la UI no conoce el origen de los
/// datos.
class HomeLogic extends ChangeNotifier {
  HomeLogic() {
    _loadFromStorage();
  }

  bool _hasUsername = false;
  String _username = '';

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

  void _loadFromStorage() {
    final savedUsername = LocalStorageService.readUsername();
    final savedCircles = LocalStorageService.readCircles();
    final savedTodayHabits = LocalStorageService.readTodayHabits();

    _hasUsername = savedUsername != null && savedUsername.isNotEmpty;
    _username = savedUsername ?? '';
    usernameController.text = _username;
    _circles = savedCircles.isNotEmpty ? savedCircles : _seedCircles();
    _todayHabits = savedTodayHabits.isNotEmpty
        ? savedTodayHabits
        : _seedTodayHabits();
    notifyListeners();
  }

  bool get hasUsername => _hasUsername;
  String get username => _username;
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

  void completeOnboarding() {
    final name = usernameController.text.trim();
    if (name.isEmpty) return;
    _username = name;
    _hasUsername = true;
    LocalStorageService.saveUsername(name);
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
    circle.checkedInToday = !circle.checkedInToday;
    circle.completedMembers =
        (circle.completedMembers + (circle.checkedInToday ? 1 : -1)).clamp(
          0,
          circle.totalMembers,
        );
    if (!wasCheckedIn && circle.checkedInToday) _streakPulseTick++;
    LocalStorageService.saveCircles(_circles);
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
