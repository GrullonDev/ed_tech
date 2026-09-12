import 'package:hive_flutter/hive_flutter.dart';

import 'package:edtech_tiktok/core/model/activity_event.dart';
import 'package:edtech_tiktok/core/model/ally_request.dart';
import 'package:edtech_tiktok/core/model/app_user.dart';
import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/today_habit.dart';
import 'package:edtech_tiktok/core/model/trivia_question.dart';

/// Persistencia local temporal (Hive) para que la app sea funcional sin
/// backend. Guarda el usuario, los círculos y los hábitos diarios. No usa
/// adaptadores generados: los modelos se serializan a `Map<String, dynamic>`
/// vía `toMap`/`fromMap` y Hive los guarda tal cual.
///
/// Cuando se integre Supabase, este servicio puede quedar como caché offline
/// o ser reemplazado por un repositorio remoto sin tocar la UI, ya que
/// [HomeLogic] es el único punto que lo consume.
class LocalStorageService {
  LocalStorageService._();

  static const String _settingsBoxName = 'settings_box';
  static const String _circlesBoxName = 'circles_box';
  static const String _todayHabitsBoxName = 'today_habits_box';
  static const String _allyRequestsBoxName = 'ally_requests_box';
  static const String _activityFeedBoxName = 'activity_feed_box';
  static const String _triviaQuestionsBoxName = 'trivia_questions_box';
  static const String _userKey = 'user';
  static const String _lastActiveDateKey = 'lastActiveDate';
  static const String _alliesKey = 'allies';
  static const String _triviaLastAnsweredDateKey = 'triviaLastAnsweredDate';
  static const String _triviaLastSelectedIndexKey = 'triviaLastSelectedIndex';
  static const String _triviaBonusDropsKey = 'triviaBonusDrops';
  static const String _openedStreakCardMilestonesKey =
      'openedStreakCardMilestones';
  static const String _predictionPendingCircleIdKey =
      'predictionPendingCircleId';
  static const String _predictionPendingDateKey = 'predictionPendingDate';
  static const String _predictionNetDropsKey = 'predictionNetDrops';
  static const String _wheelLastSpunDateKey = 'wheelLastSpunDate';
  static const String _wheelLastRewardKey = 'wheelLastReward';
  static const String _wheelBonusDropsKey = 'wheelBonusDrops';
  static const String _duelRewardedWeekMondayKey = 'duelRewardedWeekMonday';
  static const String _duelBonusDropsKey = 'duelBonusDrops';
  static const String _hasSeenGameTourKey = 'hasSeenGameTour';

  static late Box<dynamic> _settingsBox;
  static late Box<dynamic> _circlesBox;
  static late Box<dynamic> _todayHabitsBox;
  static late Box<dynamic> _allyRequestsBox;
  static late Box<dynamic> _activityFeedBox;
  static late Box<dynamic> _triviaQuestionsBox;

  /// Inicializa Hive y abre las cajas necesarias. Debe llamarse una vez en
  /// `main()` antes de `runApp`.
  static Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    _circlesBox = await Hive.openBox<dynamic>(_circlesBoxName);
    _todayHabitsBox = await Hive.openBox<dynamic>(_todayHabitsBoxName);
    _allyRequestsBox = await Hive.openBox<dynamic>(_allyRequestsBoxName);
    _activityFeedBox = await Hive.openBox<dynamic>(_activityFeedBoxName);
    _triviaQuestionsBox = await Hive.openBox<dynamic>(_triviaQuestionsBoxName);
  }

  // ---- Usuario ----

  static AppUser? readUser() {
    final raw = _settingsBox.get(_userKey);
    if (raw == null) return null;
    return AppUser.fromMap(raw as Map<dynamic, dynamic>);
  }

  static Future<void> saveUser(AppUser user) =>
      _settingsBox.put(_userKey, user.toMap());

  // ---- Día activo (para resetear los hábitos de "hoy" al cambiar de día) ----

  static DateTime? readLastActiveDate() {
    final raw = _settingsBox.get(_lastActiveDateKey) as String?;
    return raw == null ? null : DateTime.parse(raw);
  }

  static Future<void> saveLastActiveDate(DateTime date) =>
      _settingsBox.put(_lastActiveDateKey, date.toIso8601String());

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

  // ---- Aliados ----

  static List<AllyRequest> readAllyRequests() => _allyRequestsBox.values
      .map((e) => AllyRequest.fromMap(e as Map<dynamic, dynamic>))
      .toList();

  static Future<void> saveAllyRequests(List<AllyRequest> requests) async {
    await _allyRequestsBox.clear();
    await _allyRequestsBox.addAll(requests.map((r) => r.toMap()));
  }

  static List<String> readAllies() =>
      List<String>.from(_settingsBox.get(_alliesKey) as List? ?? []);

  static Future<void> saveAllies(List<String> allies) =>
      _settingsBox.put(_alliesKey, allies);

  // ---- Feed de actividad de la tribu ----

  static List<ActivityEvent> readActivityFeed() => _activityFeedBox.values
      .map((e) => ActivityEvent.fromMap(e as Map<dynamic, dynamic>))
      .toList();

  static Future<void> saveActivityFeed(List<ActivityEvent> events) async {
    await _activityFeedBox.clear();
    await _activityFeedBox.addAll(events.map((e) => e.toMap()));
  }

  // ---- Desafío de trivia diario ----

  /// Fecha (normalizada a medianoche) en la que se respondió el desafío de
  /// trivia por última vez, o `null` si nunca se respondió uno. Se compara
  /// contra `CheckIn.today()` para saber si el desafío de hoy ya se
  /// contestó (ver `HomeLogic.hasAnsweredTodaysTrivia`).
  static DateTime? readTriviaLastAnsweredDate() {
    final raw = _settingsBox.get(_triviaLastAnsweredDateKey) as String?;
    return raw == null ? null : DateTime.parse(raw);
  }

  static Future<void> saveTriviaLastAnsweredDate(DateTime date) =>
      _settingsBox.put(_triviaLastAnsweredDateKey, date.toIso8601String());

  /// Índice de la opción elegida en el desafío de hoy, para poder mostrar
  /// el mismo resultado (acertaste/fallaste) si se vuelve a abrir la
  /// pantalla el mismo día sin volver a preguntar.
  static int? readTriviaLastSelectedIndex() =>
      _settingsBox.get(_triviaLastSelectedIndexKey) as int?;

  static Future<void> saveTriviaLastSelectedIndex(int index) =>
      _settingsBox.put(_triviaLastSelectedIndexKey, index);

  /// Total acumulado de Gotas de Constancia ganadas respondiendo bien el
  /// desafío de trivia — ver doc-comment de [HomeLogic.constancyDrops]
  /// sobre por qué esta es la única excepción a "nunca un contador
  /// guardado aparte".
  static int readTriviaBonusDrops() =>
      _settingsBox.get(_triviaBonusDropsKey) as int? ?? 0;

  static Future<void> saveTriviaBonusDrops(int drops) =>
      _settingsBox.put(_triviaBonusDropsKey, drops);

  // ---- Tour de "cómo se juega" ----

  /// `true` si el usuario ya vio el tour explicativo (ver
  /// `lib/features/widgets/game_tour.dart`) — controla si `page/home.dart`
  /// lo muestra automáticamente después del onboarding de username.
  static bool readHasSeenGameTour() =>
      _settingsBox.get(_hasSeenGameTourKey) as bool? ?? false;

  static Future<void> saveHasSeenGameTour(bool value) =>
      _settingsBox.put(_hasSeenGameTourKey, value);

  /// Caché local del banco de preguntas sincronizado desde Firestore (ver
  /// `HomeLogic._syncTriviaQuestions`, colección `triviaQuestions`). Vacío
  /// hasta la primera sincronización exitosa; mientras esté vacío,
  /// `HomeLogic.todaysTrivia` usa `TriviaBank.questions` (banco local
  /// hardcodeado) — nunca se queda sin desafío del día por falta de red.
  static List<TriviaQuestion> readRemoteTriviaQuestions() => _triviaQuestionsBox
      .values
      .map((e) => TriviaQuestion.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();

  static Future<void> saveRemoteTriviaQuestions(
    List<TriviaQuestion> questions,
  ) async {
    await _triviaQuestionsBox.clear();
    await _triviaQuestionsBox.addAll(questions.map((q) => q.toMap()));
  }

  // ---- Cartas de Racha coleccionables ----

  /// Hitos (`StreakCard.milestoneDays`) cuya carta ya fue abierta — ver
  /// `HomeLogic.openStreakCard`. Un hito desbloqueado que todavía no está
  /// en esta lista se muestra "sellado" (pendiente de abrir).
  static List<int> readOpenedStreakCardMilestones() => List<int>.from(
    _settingsBox.get(_openedStreakCardMilestonesKey) as List? ?? [],
  );

  static Future<void> saveOpenedStreakCardMilestones(List<int> milestones) =>
      _settingsBox.put(_openedStreakCardMilestonesKey, milestones);

  // ---- Predicción de Tribu ----

  /// ID del círculo sobre el que hay una predicción pendiente de resolver,
  /// o `null` si no hay ninguna. Ver `HomeLogic.placePrediction`.
  static String? readPredictionPendingCircleId() =>
      _settingsBox.get(_predictionPendingCircleIdKey) as String?;

  static Future<void> savePredictionPendingCircleId(String? circleId) =>
      _settingsBox.put(_predictionPendingCircleIdKey, circleId);

  /// Fecha (normalizada a medianoche) sobre la que se hizo la predicción
  /// pendiente, o `null` si no hay ninguna.
  static DateTime? readPredictionPendingDate() {
    final raw = _settingsBox.get(_predictionPendingDateKey) as String?;
    return raw == null ? null : DateTime.parse(raw);
  }

  static Future<void> savePredictionPendingDate(DateTime? date) =>
      _settingsBox.put(_predictionPendingDateKey, date?.toIso8601String());

  /// Saldo neto (puede ser negativo) de Gotas de Constancia ganadas o
  /// perdidas apostando en la Predicción de Tribu — misma excepción de
  /// "contador persistido aparte" que [readTriviaBonusDrops], salvo que
  /// este sí puede restar (ver doc-comment de
  /// `HomeLogic.constancyDrops`).
  static int readPredictionNetDrops() =>
      _settingsBox.get(_predictionNetDropsKey) as int? ?? 0;

  static Future<void> savePredictionNetDrops(int netDrops) =>
      _settingsBox.put(_predictionNetDropsKey, netDrops);

  // ---- Ruleta diaria de gotas ----

  /// Fecha (normalizada a medianoche) del último giro de la ruleta diaria,
  /// o `null` si nunca se giró. Igual criterio que
  /// [readTriviaLastAnsweredDate]: se compara contra `CheckIn.today()` para
  /// saber si ya se giró hoy (ver `HomeLogic.hasSpunTodaysWheel`).
  static DateTime? readWheelLastSpunDate() {
    final raw = _settingsBox.get(_wheelLastSpunDateKey) as String?;
    return raw == null ? null : DateTime.parse(raw);
  }

  static Future<void> saveWheelLastSpunDate(DateTime date) =>
      _settingsBox.put(_wheelLastSpunDateKey, date.toIso8601String());

  /// Recompensa del último giro, para poder mostrarla si se reabre la
  /// pantalla el mismo día sin volver a girar.
  static int? readWheelLastReward() =>
      _settingsBox.get(_wheelLastRewardKey) as int?;

  static Future<void> saveWheelLastReward(int reward) =>
      _settingsBox.put(_wheelLastRewardKey, reward);

  /// Total acumulado de Gotas de Constancia ganadas girando la ruleta
  /// diaria — misma excepción de "contador persistido aparte" que
  /// [readTriviaBonusDrops] (ver doc-comment de [HomeLogic.constancyDrops]).
  static int readWheelBonusDrops() =>
      _settingsBox.get(_wheelBonusDropsKey) as int? ?? 0;

  static Future<void> saveWheelBonusDrops(int drops) =>
      _settingsBox.put(_wheelBonusDropsKey, drops);

  // ---- Duelo de Racha Semanal ----

  /// Lunes (normalizado a medianoche) de la semana por la que ya se otorgó
  /// la recompensa de haber ganado el Duelo de Racha Semanal, o `null` si
  /// todavía no se ganó ninguna. Evita volver a otorgarla dos veces la
  /// misma semana (ver `HomeLogic._checkWeeklyDuelWin`).
  static DateTime? readDuelRewardedWeekMonday() {
    final raw = _settingsBox.get(_duelRewardedWeekMondayKey) as String?;
    return raw == null ? null : DateTime.parse(raw);
  }

  static Future<void> saveDuelRewardedWeekMonday(DateTime monday) =>
      _settingsBox.put(_duelRewardedWeekMondayKey, monday.toIso8601String());

  /// Total acumulado de Gotas de Constancia ganadas ganando el Duelo de
  /// Racha Semanal — misma excepción de "contador persistido aparte" que
  /// [readTriviaBonusDrops].
  static int readDuelBonusDrops() =>
      _settingsBox.get(_duelBonusDropsKey) as int? ?? 0;

  static Future<void> saveDuelBonusDrops(int drops) =>
      _settingsBox.put(_duelBonusDropsKey, drops);

  /// Borra todo el estado local (útil para pruebas o "cerrar sesión" local).
  static Future<void> clearAll() async {
    await _settingsBox.clear();
    await _circlesBox.clear();
    await _todayHabitsBox.clear();
    await _allyRequestsBox.clear();
    await _activityFeedBox.clear();
    await _triviaQuestionsBox.clear();
  }
}
