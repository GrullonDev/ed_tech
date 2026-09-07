import 'dart:math';

import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/ally_request.dart';
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
  String _playerId = '';

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController habitNameController = TextEditingController();
  final TextEditingController habitCategoryController = TextEditingController();
  final TextEditingController allyUsernameController = TextEditingController();

  List<TodayHabit> _todayHabits = [];
  List<HabitCircle> _circles = [];
  List<AllyRequest> _pendingAllyRequests = [];
  List<String> _allies = [];

  /// Contador que se incrementa cada vez que se completa un hábito o
  /// check-in. Sirve como trigger para la micro-animación de pulso en el
  /// ícono de racha: la UI observa este valor (no su magnitud) y reproduce
  /// la animación cada vez que cambia.
  int _streakPulseTick = 0;

  /// Contador que se incrementa cada vez que un círculo compartido cambia
  /// (check-in de un miembro, nuevo aliado agregado a la tribu). Sirve para
  /// que las "hogueras tribales" del Ágora reproduzcan su animación de
  /// reignición al instante, como señal visual de que la base de datos
  /// local ya quedó sincronizada sin depender de un servidor externo.
  int _circlesUpdatedTick = 0;

  bool get hasUsername => _hasUsername;
  String get username => _username;
  DateTime? get memberSince => _memberSince;
  String get playerId => _playerId;
  List<HabitCircle> get circles => List.unmodifiable(_circles);
  List<TodayHabit> get todayHabits => List.unmodifiable(_todayHabits);
  int get streakPulseTick => _streakPulseTick;
  int get circlesUpdatedTick => _circlesUpdatedTick;
  List<AllyRequest> get pendingAllyRequests =>
      List.unmodifiable(_pendingAllyRequests);
  List<String> get allies => List.unmodifiable(_allies);

  /// Contenido del código QR de "Invocar por QR": el ID de jugador local más
  /// el nombre de usuario, separados por ':'. Al escanearlo, el otro
  /// dispositivo separa ambos campos para agregar al aliado al instante.
  String get qrPayload => 'RACHATRIBU:$_playerId:$_username';

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

  /// Nivel de perfil: sube automáticamente un nivel por cada bloque completo
  /// de 7 días de racha acumulada (racha global actual), empezando siempre
  /// en el Nivel 1 aunque el usuario no tenga racha todavía.
  int get userLevel => (overallStreakDays ~/ 7) + 1;

  /// "Gotas de Constancia": moneda blanda del juego. Se derivan por completo
  /// de datos reales (10 gotas por cada check-in histórico en cualquier
  /// círculo, más un bono de 50 por cada hito de racha ya alcanzado), nunca
  /// de un contador guardado aparte, para que no se pueda desincronizar de
  /// los check-ins reales del usuario.
  int get constancyDrops {
    final totalCheckIns = _circles.fold<int>(
      0,
      (sum, c) => sum + c.checkIns.length,
    );
    const milestoneBonuses = [7, 21, 30, 50, 100];
    final milestonesReached = milestoneBonuses
        .where((m) => recordStreakDays >= m)
        .length;
    return totalCheckIns * 10 + milestonesReached * 50;
  }

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
    _pendingAllyRequests = LocalStorageService.readAllyRequests();
    _allies = LocalStorageService.readAllies();

    _hasUsername = savedUser != null;
    _username = savedUser?.username ?? '';
    _memberSince = savedUser?.memberSince;
    _playerId = savedUser?.playerId ?? '';
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

  Future<void> completeOnboarding() async {
    final name = usernameController.text.trim();
    if (name.isEmpty) return;
    _username = name;
    _hasUsername = true;
    _playerId = _generatePlayerId();
    // Se espera a que el usuario quede escrito en disco antes de avisar a la
    // UI: así, si el sistema mata la app justo después de continuar, el
    // apodo ya quedó persistido y no se volverá a pedir en el siguiente
    // arranque.
    await LocalStorageService.saveUser(
      AppUser(username: name, memberSince: DateTime.now(), playerId: _playerId),
    );
    notifyListeners();
  }

  /// Genera un ID de jugador local corto (marca de tiempo + sufijo
  /// aleatorio en base 36) que identifica a este dispositivo dentro del
  /// código QR de "Invocar por QR". No requiere red: solo debe ser distinto
  /// entre dispositivos con probabilidad razonablemente alta.
  static String _generatePlayerId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randomSuffix = Random().nextInt(46656).toRadixString(36);
    return '$timestamp$randomSuffix';
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
    _circlesUpdatedTick++;
    LocalStorageService.saveCircles(_circles);
    notifyListeners();
  }

  /// Agrega un miembro simulado a [circle]. Sin backend real, "invitar" solo
  /// añade un nombre local a la lista de miembros del círculo (no envía nada
  /// a nadie); sirve para que el usuario simule su tribu mientras no exista
  /// un sistema de invitaciones real.
  void addMemberToCircle(HabitCircle circle, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    circle.addMember(trimmed);
    _circlesUpdatedTick++;
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

  /// Envía una "misiva" de solicitud de aliado a partir de
  /// [allyUsernameController] (ej. "@usuario"). Sin backend real no hay forma
  /// de que llegue a otro dispositivo, así que se simula que ya llegó
  /// registrándola de inmediato como pendiente, lista para ser aceptada o
  /// rechazada desde el perfil sin conexión a internet. Retorna `false` sin
  /// hacer nada si el campo está vacío o si ya existe una solicitud o
  /// aliado con ese nombre.
  bool sendAllyRequest() {
    final trimmed = allyUsernameController.text.trim().replaceFirst('@', '');
    if (trimmed.isEmpty) return false;
    if (_pendingAllyRequests.any((r) => r.fromUsername == trimmed) ||
        _allies.contains(trimmed)) {
      return false;
    }
    _pendingAllyRequests.add(
      AllyRequest(fromUsername: trimmed, sentAt: DateTime.now()),
    );
    LocalStorageService.saveAllyRequests(_pendingAllyRequests);
    allyUsernameController.clear();
    notifyListeners();
    return true;
  }

  void acceptAllyRequest(AllyRequest request) {
    _pendingAllyRequests.remove(request);
    if (!_allies.contains(request.fromUsername)) {
      _allies.add(request.fromUsername);
    }
    LocalStorageService.saveAllyRequests(_pendingAllyRequests);
    LocalStorageService.saveAllies(_allies);
    notifyListeners();
  }

  /// Procesa el contenido de un QR escaneado con "Invocar por QR"
  /// (formato `RACHATRIBU:<playerId>:<username>`, ver [qrPayload]) y agrega
  /// al instante a ese username como aliado — sin pasar por el flujo de
  /// solicitud pendiente, ya que el escaneo presencial ya es la prueba de
  /// confianza. Retorna el username agregado, o `null` si el código no es
  /// válido, es el propio jugador, o ya era aliado.
  String? addAllyFromScannedCode(String code) {
    final parts = code.split(':');
    if (parts.length < 3 || parts[0] != 'RACHATRIBU') return null;
    final scannedPlayerId = parts[1];
    final scannedUsername = parts.sublist(2).join(':').trim();
    if (scannedUsername.isEmpty) return null;
    if (scannedPlayerId == _playerId || _allies.contains(scannedUsername)) {
      return null;
    }
    _allies.add(scannedUsername);
    LocalStorageService.saveAllies(_allies);
    notifyListeners();
    return scannedUsername;
  }

  void rejectAllyRequest(AllyRequest request) {
    _pendingAllyRequests.remove(request);
    LocalStorageService.saveAllyRequests(_pendingAllyRequests);
    notifyListeners();
  }

  @override
  void dispose() {
    usernameController.dispose();
    habitNameController.dispose();
    habitCategoryController.dispose();
    allyUsernameController.dispose();
    super.dispose();
  }
}
