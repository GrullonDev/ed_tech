import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';

import 'package:edtech_tiktok/core/model/activity_event.dart';
import 'package:edtech_tiktok/core/model/ally_request.dart';
import 'package:edtech_tiktok/core/model/app_user.dart';
import 'package:edtech_tiktok/core/model/check_in.dart';
import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/core/model/milestone.dart';
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
  List<ActivityEvent> _activityFeed = [];

  /// Tope del feed de actividad: suficiente para ver la última semana de
  /// vida de la tribu sin que la caja de Hive crezca sin límite.
  static const int _maxActivityFeedLength = 40;

  /// Suscripciones activas a `circles/{id}/activityEvents` por círculo, ver
  /// [_watchCircleActivityEvents]. Se cancelan en [dispose].
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _activityEventSubscriptions = {};

  /// Suscripciones activas a `circles/{id}/memberStats/{uid}` por círculo,
  /// ver [_watchCircleMemberStats]. Se cancelan en [dispose].
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
  _memberStatsSubscriptions = {};

  /// Suscripciones a `allyRequests` (ver [_watchIncomingAllyRequests] y
  /// [_watchOutgoingAllyRequests]). Se cancelan en [dispose].
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _incomingAllyRequestsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _outgoingAllyRequestsSubscription;

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
  List<ActivityEvent> get activityFeed => List.unmodifiable(_activityFeed);

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
  /// de datos reales (ver [HabitCircle.constancyDropsEarned]: 10 gotas por
  /// check-in que escalan hasta x3 cuanto más larga sea la racha vigente ese
  /// día, más un bono de 50 por cada hito de racha ya alcanzado), nunca de un
  /// contador guardado aparte, para que no se pueda desincronizar de los
  /// check-ins reales del usuario.
  int get constancyDrops {
    final totalDrops = _circles.fold<int>(
      0,
      (total, c) => total + c.constancyDropsEarned,
    );
    const milestoneBonuses = [7, 21, 30, 50, 100];
    final milestonesReached = milestoneBonuses
        .where((m) => recordStreakDays >= m)
        .length;
    return totalDrops + milestonesReached * 50;
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
    _activityFeed = LocalStorageService.readActivityFeed();

    _hasUsername = savedUser != null;
    _username = savedUser?.username ?? '';
    _memberSince = savedUser?.memberSince;
    _playerId = savedUser?.playerId ?? '';
    usernameController.text = _username;

    // Círculos guardados antes de que HabitCircle tuviera `id` reciben uno
    // nuevo al leerse (ver HabitCircle.fromMap); se persiste de una vez
    // para que ese id quede fijo entre reinicios y sirva de ID de
    // documento estable al espejar el círculo en Firestore.
    if (_circles.isNotEmpty) LocalStorageService.saveCircles(_circles);

    _applyDailyResetIfNeeded();
    _applyPendingStreakFreezes();
    for (final circle in _circles) {
      _watchCircleActivityEvents(circle);
      _watchCircleMemberStats(circle);
    }
    _watchIncomingAllyRequests();
    _watchOutgoingAllyRequests();
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

  /// Revisa si ayer se dejó pasar sin check-in un círculo que traía racha
  /// activa y, si el círculo tiene un "Escudo de Racha" disponible, lo
  /// consume automáticamente para que la cadena no se rompa — el mismo
  /// mecanismo de "freeze" de apps de rachas, pensado para bajar la ansiedad
  /// de perderlo todo por un solo día difícil. Se ejecuta al abrir la app,
  /// así el usuario ve el resultado (racha viva + escudo gastado) apenas
  /// entra, en vez de descubrirlo a mitad de sesión.
  void _applyPendingStreakFreezes() {
    final today = CheckIn.today();
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = yesterday.subtract(const Duration(days: 1));
    var changed = false;
    for (final circle in _circles) {
      if (circle.checkIns.isEmpty) continue;
      final hasYesterday = circle.checkIns.any((c) => c.date == yesterday);
      if (hasYesterday || circle.freezeUsedDates.contains(yesterday)) continue;
      final hadActiveStreak =
          circle.checkIns.any((c) => c.date == dayBeforeYesterday) ||
          circle.freezeUsedDates.contains(dayBeforeYesterday);
      if (!hadActiveStreak) continue;
      if (!circle.useFreezeFor(yesterday)) continue;
      changed = true;
      _recordCircleActivity(
        circle,
        emoji: '🛡️',
        message:
            '${circle.name} usó un Escudo de Racha para no perder la cadena.',
      );
    }
    if (changed) LocalStorageService.saveCircles(_circles);
  }

  /// Otorga un escudo gratis la primera vez que [circle] cruza cada hito de
  /// [Milestone.targets], y lo anuncia en el feed de la tribu.
  void _grantFreezeIfMilestoneReached(HabitCircle circle) {
    for (final days in Milestone.targets) {
      if (circle.streakDays < days) continue;
      if (!circle.grantFreezeForMilestone(days)) continue;
      _recordCircleActivity(
        circle,
        emoji: '🏆',
        message:
            '${circle.name} alcanzó $days días de racha — ¡ganaste un '
            'Escudo de Racha! 🛡️',
      );
      _logAnalyticsEvent('milestone_reached', {
        'milestone_days': days,
        'circle_category': circle.category,
      });
    }
  }

  /// Agrega un evento al feed de actividad de la tribu (más reciente
  /// primero) y lo recorta a [_maxActivityFeedLength] para no crecer sin
  /// límite. No notifica ni persiste por sí solo: quien llama ya lo hace
  /// junto con el resto de su cambio de estado.
  void _pushActivityEvent({required String emoji, required String message}) {
    _activityFeed.insert(
      0,
      ActivityEvent(emoji: emoji, message: message, at: DateTime.now()),
    );
    if (_activityFeed.length > _maxActivityFeedLength) {
      _activityFeed = _activityFeed.sublist(0, _maxActivityFeedLength);
    }
    LocalStorageService.saveActivityFeed(_activityFeed);
  }

  Future<void> completeOnboarding() async {
    final name = usernameController.text.trim();
    if (name.isEmpty) return;
    _username = name;
    _hasUsername = true;
    _playerId = await _signInAndResolvePlayerId(name);
    // Se espera a que el usuario quede escrito en disco antes de avisar a la
    // UI: así, si el sistema mata la app justo después de continuar, el
    // apodo ya quedó persistido y no se volverá a pedir en el siguiente
    // arranque.
    await LocalStorageService.saveUser(
      AppUser(username: name, memberSince: DateTime.now(), playerId: _playerId),
    );
    _logAnalyticsEvent('onboarding_complete');
    // El onboarding es el primer momento en que puede existir un uid de
    // Firebase (en arranques posteriores ya lo hace _loadFromStorage): si el
    // Auth anónimo tuvo éxito arriba, hay que arrancar aquí las
    // suscripciones a aliados/check-ins que dependen de él.
    _watchIncomingAllyRequests();
    _watchOutgoingAllyRequests();
    for (final circle in _circles) {
      _watchCircleActivityEvents(circle);
    }
    notifyListeners();
  }

  /// Intenta autenticarse de forma anónima en Firebase (proyecto
  /// "rachatribu") y usar el `uid` resultante como playerId — a diferencia
  /// del id generado localmente, este es estable si el backend algún día
  /// necesita reconocer al mismo jugador desde otro dispositivo. Guarda el
  /// nombre como `displayName` del usuario anónimo y como documento de
  /// perfil en Firestore (`users/{uid}`, ver [_saveFirestoreProfile]).
  ///
  /// Si Firebase no está configurado todavía (ver lib/firebase_options.dart)
  /// o no hay conexión, cae de vuelta al id generado localmente: la app
  /// sigue funcionando 100% offline como hasta ahora.
  Future<String> _signInAndResolvePlayerId(String username) async {
    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      final user = credential.user;
      if (user == null) return _generatePlayerId();
      await user.updateDisplayName(username);
      await _saveFirestoreProfile(uid: user.uid, username: username);
      return user.uid;
    } catch (_) {
      return _generatePlayerId();
    }
  }

  /// Escribe/actualiza el documento de perfil `users/{uid}` (ver
  /// firebase/FIRESTORE_SCHEMA.md), espejo de [AppUser] del lado de
  /// Firestore. `set(..., merge: true)` para no pisar `createdAt` si el
  /// documento ya existía de una sesión anterior en este mismo uid.
  ///
  /// No se espera una excepción aquí en condiciones normales: Firestore
  /// encola la escritura localmente y la sincroniza solo cuando vuelve la
  /// red (persistencia offline nativa, ver sección 4 de
  /// firebase/MIGRATION_PLAN.md), así que este método no bloquea el
  /// onboarding sin conexión. Si de todos modos falla (ej. reglas de
  /// seguridad desactualizadas), no debe tumbar el onboarding completo:
  /// el usuario ya quedó autenticado y guardado localmente en Hive.
  Future<void> _saveFirestoreProfile({
    required String uid,
    required String username,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'memberSince': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Se ignora a propósito: el perfil local (Hive) ya quedó guardado en
      // completeOnboarding() y es la fuente de verdad mientras no exista
      // todavía un HabitRepository que reconcilie ambos (ver Fase 5/6 de
      // firebase/MIGRATION_PLAN.md).
    }
  }

  /// Registra un evento de Firebase Analytics de forma "fire-and-forget":
  /// nunca debe bloquear ni romper el flujo que lo dispara. Si Firebase no
  /// está inicializado (ver lib/firebase_options.dart), acceder a
  /// `FirebaseAnalytics.instance` lanza de inmediato — se captura aquí para
  /// que llamar a este método sea siempre seguro, con o sin Firebase.
  void _logAnalyticsEvent(String name, [Map<String, Object>? parameters]) {
    try {
      unawaited(
        FirebaseAnalytics.instance
            .logEvent(name: name, parameters: parameters)
            .catchError((_) {}),
      );
    } catch (_) {
      // Firebase no inicializado todavía: se ignora, igual que el resto de
      // las llamadas a Firebase en HomeLogic.
    }
  }

  /// `uid` de Firebase si el Auth anónimo de [completeOnboarding] tuvo
  /// éxito, o `null` si la app sigue en modo 100% local. Se usa como
  /// guardia para no intentar escribir en Firestore cuando no hay sesión.
  String? get _firebaseUid => FirebaseAuth.instance.currentUser?.uid;

  /// Espeja la creación de [circle] en Firestore (`circles/{id}` +
  /// `circles/{id}/members/{uid}` como dueño), ver
  /// firebase/FIRESTORE_SCHEMA.md. Fire-and-forget: si falla (sin red, sin
  /// Firebase configurado, reglas desactualizadas), el círculo sigue
  /// funcionando 100% local en Hive — este PR todavía no lee de vuelta
  /// desde Firestore, solo escribe (ver Fase 2 en
  /// firebase/MIGRATION_PLAN.md).
  ///
  /// Envuelto en un trace manual de Performance Monitoring (`circle_creation`,
  /// ver `firebase/PRODUCTS_PLAN.md` sección 2) para medir cuánto tarda este
  /// batch en la consola — el trace también se detiene si falla, así que no
  /// se queda "colgado" cuando no hay red.
  Future<void> _mirrorCircleCreation(HabitCircle circle) async {
    final uid = _firebaseUid;
    if (uid == null) return;
    final trace = FirebasePerformance.instance.newTrace('circle_creation');
    await trace.start();
    try {
      final circleRef = FirebaseFirestore.instance
          .collection('circles')
          .doc(circle.id);
      final batch = FirebaseFirestore.instance.batch()
        ..set(circleRef, {
          'name': circle.name,
          'category': circle.category,
          'ownerId': uid,
          'inviteCode': circle.id.substring(0, circle.id.length.clamp(0, 8)),
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..set(circleRef.collection('members').doc(uid), {
          'role': 'owner',
          'joinedAt': FieldValue.serverTimestamp(),
        });
      await batch.commit();
    } catch (_) {
      // Se ignora a propósito: ver doc-comment del método.
    } finally {
      await trace.stop();
    }
  }

  /// Espeja el check-in/deshacer de hoy en [circle] hacia
  /// `circles/{id}/checkIns/{uid}_{fecha}` (ID de documento = unicidad,
  /// ver firestore.rules). Mismo criterio fire-and-forget que
  /// [_mirrorCircleCreation].
  Future<void> _mirrorCheckIn(HabitCircle circle) async {
    final uid = _firebaseUid;
    if (uid == null) return;
    try {
      final dateKey = _dateKey(CheckIn.today());
      final checkInRef = FirebaseFirestore.instance
          .collection('circles')
          .doc(circle.id)
          .collection('checkIns')
          .doc('${uid}_$dateKey');
      if (circle.checkedInToday) {
        await checkInRef.set({
          'userId': uid,
          'date': dateKey,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await checkInRef.delete();
      }
    } catch (_) {
      // Se ignora a propósito: ver doc-comment del método.
    }
  }

  /// Registra un evento de actividad de [circle] (check-in, hito, escudo
  /// usado). Fase 6 (plan Blaze, ver sección 0 de
  /// firebase/MIGRATION_PLAN.md): con Cloud Functions desplegadas
  /// (`functions/src/index.ts`), el evento real ya lo genera el servidor
  /// como efecto de los `checkIns`/`members`/`streakShieldUses` que la app
  /// escribe (`_mirrorCheckIn`, `_mirrorCircleCreation`, el job diario
  /// `applyPendingShields`) — así que aquí, con sesión de Firebase, no se
  /// escribe nada: escribirlo también duplicaría el evento en el feed, ya
  /// que [_watchCircleActivityEvents] ya está escuchando esa colección y
  /// recibirá el que genere el trigger del servidor. Sin sesión, cae al
  /// [_pushActivityEvent] local de siempre (modo 100% offline).
  void _recordCircleActivity(
    HabitCircle circle, {
    required String emoji,
    required String message,
  }) {
    if (_firebaseUid == null) {
      _pushActivityEvent(emoji: emoji, message: message);
    }
  }

  /// Se suscribe al feed de actividad real de [circle]
  /// (`circles/{id}/activityEvents`), generado por las Cloud Functions de
  /// `functions/src/index.ts` (Fase 6) como efecto de los `checkIns`/
  /// `members`/escudos que la app escribe — nunca por el propio cliente
  /// (ver [_recordCircleActivity]), para que **todos** los miembros vean
  /// el mismo evento sin que ninguno pueda falsearlo. Los documentos ya
  /// traen [ActivityEvent.id] para no duplicar un evento que ya está en
  /// el feed local si Firestore lo reenvía (por ejemplo, al reconectar).
  /// No hace nada si no hay sesión de Firebase.
  void _watchCircleActivityEvents(HabitCircle circle) {
    final uid = _firebaseUid;
    if (uid == null || _activityEventSubscriptions.containsKey(circle.id)) {
      return;
    }
    final query = FirebaseFirestore.instance
        .collection('circles')
        .doc(circle.id)
        .collection('activityEvents')
        .orderBy('createdAt', descending: true)
        .limit(_maxActivityFeedLength);
    try {
      _activityEventSubscriptions[circle.id] = query.snapshots().listen((
        snapshot,
      ) {
        var changed = false;
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          if (_activityFeed.any((e) => e.id == change.doc.id)) continue;
          final data = change.doc.data();
          if (data == null) continue;
          final createdAt = data['createdAt'] as Timestamp?;
          _activityFeed.insert(
            0,
            ActivityEvent(
              id: change.doc.id,
              emoji: data['emoji'] as String? ?? '🔥',
              message: data['message'] as String? ?? '',
              at: createdAt?.toDate() ?? DateTime.now(),
            ),
          );
          changed = true;
        }
        if (changed) {
          _activityFeed.sort((a, b) => b.at.compareTo(a.at));
          if (_activityFeed.length > _maxActivityFeedLength) {
            _activityFeed = _activityFeed.sublist(0, _maxActivityFeedLength);
          }
          LocalStorageService.saveActivityFeed(_activityFeed);
          _circlesUpdatedTick++;
          notifyListeners();
        }
      }, onError: (_) {});
    } catch (_) {
      // Se ignora a propósito: sin Firebase configurado, la app sigue
      // funcionando 100% local con el feed de actividad generado en el
      // dispositivo (ver [_pushActivityEvent]).
    }
  }

  /// Se suscribe a `circles/{id}/memberStats/{uid}` (el propio usuario), el
  /// documento que la Cloud Function `recomputeMemberStats`
  /// (`functions/src/index.ts`) recalcula a partir del historial real de
  /// `checkIns`/`streakShieldUses`/`streakShieldGrants` cada vez que alguno
  /// cambia — Fase 6 de `firebase/MIGRATION_PLAN.md` (plan Blaze). Puebla
  /// los campos `remote*` de [circle] (ver doc-comment en
  /// `HabitCircle.remoteStreakDays`), que desde ahí tienen prioridad sobre
  /// el cálculo local en los getters públicos (`streakDays`,
  /// `longestStreakDays`, `constancyDropsEarned`, `freezesAvailable`). No
  /// hace nada si no hay sesión de Firebase.
  void _watchCircleMemberStats(HabitCircle circle) {
    final uid = _firebaseUid;
    if (uid == null || _memberStatsSubscriptions.containsKey(circle.id)) {
      return;
    }
    final docRef = FirebaseFirestore.instance
        .collection('circles')
        .doc(circle.id)
        .collection('memberStats')
        .doc(uid);
    try {
      _memberStatsSubscriptions[circle.id] = docRef.snapshots().listen((
        snapshot,
      ) {
        final data = snapshot.data();
        if (data == null) return;
        circle.remoteStreakDays = data['streakDays'] as int?;
        circle.remoteLongestStreakDays = data['longestStreakDays'] as int?;
        circle.remoteDropsEarned = data['dropsEarned'] as int?;
        circle.remoteFreezesAvailable = data['freezesAvailable'] as int?;
        _circlesUpdatedTick++;
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {
      // Se ignora a propósito: sin Firebase configurado, la app sigue
      // funcionando 100% con el cálculo local de siempre (ver
      // [HabitCircle.streakDays] y afines).
    }
  }

  /// Formatea [date] como "yyyy-mm-dd", igual que el `date` string que
  /// esperan las Cloud Functions en functions/src/streakLogic.ts.
  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Genera un ID de jugador local corto (marca de tiempo + sufijo
  /// aleatorio en base 36) que identifica a este dispositivo dentro del
  /// código QR de "Invocar por QR". No requiere red: solo debe ser distinto
  /// entre dispositivos con probabilidad razonablemente alta. Sirve de
  /// respaldo cuando Firebase no está disponible (ver
  /// [_signInAndResolvePlayerId]).
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
    final wasPerfect = circle.isPerfect;
    if (wasCheckedIn) {
      circle.removeCheckInToday();
    } else {
      circle.addCheckInToday();
      _streakPulseTick++;
      _recordCircleActivity(
        circle,
        emoji: '🔥',
        message:
            '$_username completó "${circle.name}" — racha de '
            '${circle.streakDays} días.',
      );
      _logAnalyticsEvent('check_in', {
        'circle_category': circle.category,
        'streak_days': circle.streakDays,
      });
      _grantFreezeIfMilestoneReached(circle);
      if (!wasPerfect && circle.isPerfect && circle.totalMembers > 1) {
        _recordCircleActivity(
          circle,
          emoji: '✨',
          message: '¡"${circle.name}" logró el Círculo Perfecto de hoy!',
        );
        _logAnalyticsEvent('perfect_circle', {
          'circle_category': circle.category,
        });
      }
    }
    _circlesUpdatedTick++;
    LocalStorageService.saveCircles(_circles);
    unawaited(_mirrorCheckIn(circle));
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
    _pushActivityEvent(
      emoji: '🎉',
      message: '$trimmed se unió a "${circle.name}".',
    );
    notifyListeners();
  }

  void createCircle({required String name, required String category}) {
    final circle = HabitCircle(name: name, category: category);
    _circles.add(circle);
    LocalStorageService.saveCircles(_circles);
    _logAnalyticsEvent('circle_created', {'circle_category': category});
    unawaited(_mirrorCircleCreation(circle));
    _watchCircleActivityEvents(circle);
    _watchCircleMemberStats(circle);
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

  /// Envía una solicitud de aliado real a partir de [allyUsernameController]
  /// (ej. "@usuario"). Si hay sesión de Firebase, busca el `uid` dueño de ese
  /// username en `users` y escribe `allyRequests/{miUid}_{suUid}` con
  /// `status: 'pending'` — el otro dispositivo la ve al instante vía
  /// [_watchIncomingAllyRequests] (o en cuanto recupere conexión, gracias a
  /// la persistencia offline nativa de Firestore). Si Firebase no está
  /// disponible, cae al modo simulado anterior: registra la solicitud de
  /// inmediato como pendiente en este mismo dispositivo, solo para poder
  /// demostrar el flujo de aceptar/rechazar sin backend.
  ///
  /// Retorna `false` sin hacer nada si el campo está vacío, si el username
  /// es el propio, si ya es aliado/solicitud pendiente, o (con Firebase
  /// disponible) si no existe ningún usuario con ese username.
  Future<bool> sendAllyRequest() async {
    final trimmed = allyUsernameController.text.trim().replaceFirst('@', '');
    if (trimmed.isEmpty || trimmed == _username) return false;
    if (_pendingAllyRequests.any((r) => r.fromUsername == trimmed) ||
        _allies.contains(trimmed)) {
      return false;
    }
    final uid = _firebaseUid;
    if (uid == null) {
      _pendingAllyRequests.add(
        AllyRequest(fromUsername: trimmed, sentAt: DateTime.now()),
      );
      LocalStorageService.saveAllyRequests(_pendingAllyRequests);
      allyUsernameController.clear();
      _logAnalyticsEvent('ally_request_sent');
      notifyListeners();
      return true;
    }
    try {
      final matches = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: trimmed)
          .limit(1)
          .get();
      if (matches.docs.isEmpty) return false;
      final targetUid = matches.docs.first.id;
      await FirebaseFirestore.instance
          .collection('allyRequests')
          .doc('${uid}_$targetUid')
          .set({
            'fromUserId': uid,
            'fromUsername': _username,
            'toUserId': targetUid,
            'toUsername': trimmed,
            'status': 'pending',
            'sentAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {
      return false;
    }
    allyUsernameController.clear();
    _logAnalyticsEvent('ally_request_sent');
    return true;
  }

  void acceptAllyRequest(AllyRequest request) {
    _pendingAllyRequests.remove(request);
    if (!_allies.contains(request.fromUsername)) {
      _allies.add(request.fromUsername);
    }
    LocalStorageService.saveAllyRequests(_pendingAllyRequests);
    LocalStorageService.saveAllies(_allies);
    _pushActivityEvent(
      emoji: '🕊️',
      message: 'Ahora eres aliado de ${request.fromUsername}.',
    );
    _logAnalyticsEvent('ally_request_accepted');
    unawaited(_updateAllyRequestStatus(request, 'accepted'));
    notifyListeners();
  }

  /// Procesa el contenido de un QR escaneado con "Invocar por QR"
  /// (formato `RACHATRIBU:<uid>:<username>`, ver [qrPayload] — el `uid` es
  /// el playerId, que desde la Fase 1 es el `uid` real de Firebase Auth
  /// cuando hay sesión) y agrega al instante a ese username como aliado —
  /// sin pasar por el flujo de solicitud pendiente, ya que el escaneo
  /// presencial ya es la prueba de confianza. Si hay sesión de Firebase,
  /// además escribe `allyRequests/{miUid}_{suUid}` con `status: 'accepted'`
  /// directamente, para que el otro dispositivo (que escanea el escáner, no
  /// al revés) también reciba el aliado vía [_watchIncomingAllyRequests].
  /// Retorna el username agregado, o `null` si el código no es válido, es el
  /// propio jugador, o ya era aliado.
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
    _pushActivityEvent(
      emoji: '⚡',
      message: 'Invocaste a $scannedUsername como aliado.',
    );
    final uid = _firebaseUid;
    if (uid != null) {
      unawaited(
        FirebaseFirestore.instance
            .collection('allyRequests')
            .doc('${uid}_$scannedPlayerId')
            .set({
              'fromUserId': uid,
              'fromUsername': _username,
              'toUserId': scannedPlayerId,
              'toUsername': scannedUsername,
              'status': 'accepted',
              'sentAt': FieldValue.serverTimestamp(),
            })
            .catchError((_) {}),
      );
    }
    notifyListeners();
    return scannedUsername;
  }

  void rejectAllyRequest(AllyRequest request) {
    _pendingAllyRequests.remove(request);
    LocalStorageService.saveAllyRequests(_pendingAllyRequests);
    unawaited(_updateAllyRequestStatus(request, 'rejected'));
    notifyListeners();
  }

  /// Actualiza el `status` del documento real de [request] en Firestore
  /// (`allyRequests/{fromUserId}_{toUserId}`) tras aceptarla o rechazarla.
  /// No hace nada si [request] viene del modo simulado local
  /// (`fromUserId`/`toUserId` nulos, ver [AllyRequest]) ni si no hay sesión.
  Future<void> _updateAllyRequestStatus(
    AllyRequest request,
    String status,
  ) async {
    final fromUserId = request.fromUserId;
    final toUserId = request.toUserId;
    if (fromUserId == null || toUserId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('allyRequests')
          .doc('${fromUserId}_$toUserId')
          .update({'status': status});
    } catch (_) {
      // Se ignora a propósito: el estado local (Hive) ya quedó actualizado.
    }
  }

  /// Se suscribe a las solicitudes de aliado dirigidas a este `uid`
  /// (`allyRequests` con `toUserId == uid`), para reflejar en vivo lo que
  /// haga otro dispositivo: una solicitud nueva con `status: 'pending'`
  /// aparece en [pendingAllyRequests] (ver [sendAllyRequest] del remitente),
  /// y una con `status: 'accepted'` agrega de inmediato a `fromUsername`
  /// como aliado (caso del escaneo de QR, ver [addAllyFromScannedCode]).
  /// No hace nada si no hay sesión de Firebase.
  void _watchIncomingAllyRequests() {
    final uid = _firebaseUid;
    if (uid == null || _incomingAllyRequestsSubscription != null) return;
    try {
      _incomingAllyRequestsSubscription = FirebaseFirestore.instance
          .collection('allyRequests')
          .where('toUserId', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {
            var changed = false;
            for (final change in snapshot.docChanges) {
              final data = change.doc.data();
              if (data == null) continue;
              final fromUserId = data['fromUserId'] as String?;
              final fromUsername = data['fromUsername'] as String?;
              final status = data['status'] as String?;
              if (fromUserId == null || fromUsername == null) continue;
              if (status == 'pending') {
                if (_pendingAllyRequests.any(
                  (r) => r.fromUserId == fromUserId,
                )) {
                  continue;
                }
                _pendingAllyRequests.add(
                  AllyRequest(
                    fromUsername: fromUsername,
                    sentAt: DateTime.now(),
                    fromUserId: fromUserId,
                    toUserId: uid,
                  ),
                );
                changed = true;
              } else if (status == 'accepted') {
                _pendingAllyRequests.removeWhere(
                  (r) => r.fromUserId == fromUserId,
                );
                if (!_allies.contains(fromUsername)) {
                  _allies.add(fromUsername);
                  _pushActivityEvent(
                    emoji: '🕊️',
                    message: 'Ahora eres aliado de $fromUsername.',
                  );
                }
                changed = true;
              } else {
                _pendingAllyRequests.removeWhere(
                  (r) => r.fromUserId == fromUserId,
                );
                changed = true;
              }
            }
            if (changed) {
              LocalStorageService.saveAllyRequests(_pendingAllyRequests);
              LocalStorageService.saveAllies(_allies);
              notifyListeners();
            }
          }, onError: (_) {});
    } catch (_) {
      // Se ignora a propósito: sin Firebase configurado, la app sigue
      // funcionando 100% local con las solicitudes simuladas en Hive.
    }
  }

  /// Se suscribe a las solicitudes de aliado que **yo** envié
  /// (`allyRequests` con `fromUserId == uid`, ver [sendAllyRequest]), para
  /// enterarse cuando el receptor las acepta desde su propio dispositivo y
  /// agregarlo como aliado también de este lado. No hace nada si no hay
  /// sesión de Firebase.
  void _watchOutgoingAllyRequests() {
    final uid = _firebaseUid;
    if (uid == null || _outgoingAllyRequestsSubscription != null) return;
    try {
      _outgoingAllyRequestsSubscription = FirebaseFirestore.instance
          .collection('allyRequests')
          .where('fromUserId', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {
            var changed = false;
            for (final change in snapshot.docChanges) {
              final data = change.doc.data();
              if (data == null) continue;
              if ((data['status'] as String?) != 'accepted') continue;
              final toUsername = data['toUsername'] as String?;
              if (toUsername == null || _allies.contains(toUsername)) continue;
              _allies.add(toUsername);
              _pushActivityEvent(
                emoji: '🕊️',
                message: 'Ahora eres aliado de $toUsername.',
              );
              changed = true;
            }
            if (changed) {
              LocalStorageService.saveAllies(_allies);
              notifyListeners();
            }
          }, onError: (_) {});
    } catch (_) {
      // Se ignora a propósito: ver doc-comment de _watchIncomingAllyRequests.
    }
  }

  @override
  void dispose() {
    for (final subscription in _activityEventSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    for (final subscription in _memberStatsSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    unawaited(_incomingAllyRequestsSubscription?.cancel());
    unawaited(_outgoingAllyRequestsSubscription?.cancel());
    usernameController.dispose();
    habitNameController.dispose();
    habitCategoryController.dispose();
    allyUsernameController.dispose();
    super.dispose();
  }
}
