import 'package:hive_flutter/hive_flutter.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/today_habit.dart';

/// Persistencia local temporal (Hive) para que la app sea funcional sin
/// backend. Guarda el alias de usuario, los círculos y los check-ins del
/// día. No usa adaptadores generados: los modelos se serializan a
/// `Map<String, dynamic>` vía `toMap`/`fromMap` y Hive los guarda tal cual.
///
/// Cuando se integre Supabase, este servicio puede quedar como caché offline
/// o ser reemplazado por un repositorio remoto sin tocar la UI, ya que
/// [HomeLogic] es el único punto que lo consume.
class LocalStorageService {
  LocalStorageService._();

  static const String _settingsBoxName = 'settings_box';
  static const String _circlesBoxName = 'circles_box';
  static const String _todayHabitsBoxName = 'today_habits_box';
  static const String _usernameKey = 'username';

  static late Box<dynamic> _settingsBox;
  static late Box<dynamic> _circlesBox;
  static late Box<dynamic> _todayHabitsBox;

  /// Inicializa Hive y abre las cajas necesarias. Debe llamarse una vez en
  /// `main()` antes de `runApp`.
  static Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    _circlesBox = await Hive.openBox<dynamic>(_circlesBoxName);
    _todayHabitsBox = await Hive.openBox<dynamic>(_todayHabitsBoxName);
  }

  // ---- Usuario ----

  static String? readUsername() => _settingsBox.get(_usernameKey) as String?;

  static Future<void> saveUsername(String username) =>
      _settingsBox.put(_usernameKey, username);

  // ---- Círculos ----

  static List<HabitCircle> readCircles() {
    final raw = _circlesBox.values.toList();
    return raw
        .map((e) => HabitCircle.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  static Future<void> saveCircles(List<HabitCircle> circles) async {
    await _circlesBox.clear();
    await _circlesBox.addAll(circles.map((c) => c.toMap()));
  }

  // ---- Hábitos de hoy ----

  static List<TodayHabit> readTodayHabits() {
    final raw = _todayHabitsBox.values.toList();
    return raw
        .map((e) => TodayHabit.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  static Future<void> saveTodayHabits(List<TodayHabit> habits) async {
    await _todayHabitsBox.clear();
    await _todayHabitsBox.addAll(habits.map((h) => h.toMap()));
  }

  /// Borra todo el estado local (útil para pruebas o "cerrar sesión" local).
  static Future<void> clearAll() async {
    await _settingsBox.clear();
    await _circlesBox.clear();
    await _todayHabitsBox.clear();
  }
}
