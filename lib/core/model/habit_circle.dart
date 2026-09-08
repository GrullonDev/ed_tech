import 'package:edtech_tiktok/core/model/check_in.dart';

/// Círculo de hábito. Sin backend, cada círculo solo tiene un miembro real
/// (el usuario del dispositivo): `totalMembers`, `completedMembers`,
/// `checkedInToday` y `streakDays` se derivan de [checkIns], no de números
/// fijos. `members`/`pendingMemberName` quedan listos para cuando existan
/// otros miembros reales vía Supabase.
class HabitCircle {
  HabitCircle({
    required this.name,
    required this.category,
    List<String>? members,
    List<CheckIn>? checkIns,
    this.pendingMemberName,
    this.freezesAvailable = 0,
    List<DateTime>? freezeUsedDates,
    List<int>? claimedFreezeMilestones,
  }) : members = members ?? ['Yo'],
       checkIns = checkIns ?? [],
       freezeUsedDates = freezeUsedDates ?? [],
       claimedFreezeMilestones = claimedFreezeMilestones ?? [];

  final String name;
  final String category;
  final List<String> members;
  final String? pendingMemberName;
  final List<CheckIn> checkIns;

  /// "Escudos de Racha" disponibles: cuando un día se salta sin check-in,
  /// [HomeLogic] consume uno automáticamente para que la racha no se rompa
  /// (ver [freezeUsedDates]), en vez de perder toda la cadena de golpe.
  int freezesAvailable;

  /// Fechas (normalizadas a medianoche) en las que un escudo cubrió un día
  /// sin check-in real. No cuentan como check-in para el progreso del día,
  /// pero sí mantienen viva la racha en [streakDays].
  final List<DateTime> freezeUsedDates;

  /// Hitos de racha (7/21/30/50/100, ver [Milestone.targets]) por los que ya
  /// se otorgó un escudo gratis, para no volver a regalarlo si la racha baja
  /// y vuelve a cruzar el mismo umbral.
  final List<int> claimedFreezeMilestones;

  int get totalMembers => members.length;
  int get completedMembers => checkedInToday ? totalMembers : totalMembers - 1;
  bool get isPerfect => completedMembers >= totalMembers;
  double get progress =>
      totalMembers == 0 ? 0 : completedMembers / totalMembers;
  int get extraMembers => 0;

  bool get checkedInToday => checkIns.any((c) => c.date == CheckIn.today());

  /// Días consecutivos con check-in, contando hacia atrás desde hoy (o desde
  /// ayer si hoy todavía no se ha marcado, para que la racha no "muera" a la
  /// medianoche antes de que el usuario tenga oportunidad de marcar el día).
  ///
  /// Una fecha cubierta por un escudo ([freezeUsedDates]) no rompe la cadena
  /// hacia atrás (actúa como puente), pero tampoco suma un día extra al
  /// conteo: el escudo protege la racha, no la infla.
  int get streakDays {
    if (checkIns.isEmpty) return 0;
    final realDays = checkIns.map((c) => c.date).toSet();
    final frozenDays = freezeUsedDates.toSet();
    final allDays = {...realDays, ...frozenDays}.toList()
      ..sort((a, b) => b.compareTo(a));
    var expected = CheckIn.today();
    if (allDays.first != expected) {
      expected = expected.subtract(const Duration(days: 1));
      if (allDays.first != expected) return 0;
    }
    var streak = 0;
    for (final day in allDays) {
      if (day != expected) break;
      if (realDays.contains(day)) streak++;
      expected = expected.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Racha consecutiva más larga alcanzada en toda la historia del círculo
  /// (no solo la actual). Se usa como "récord personal" en el perfil.
  int get longestStreakDays {
    if (checkIns.isEmpty) return 0;
    final days = checkIns.map((c) => c.date).toSet().toList()..sort();
    var longest = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        current++;
        longest = longest > current ? longest : current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  /// "Gotas de Constancia" ganadas por los check-ins reales de este círculo,
  /// con un multiplicador que crece con la racha vigente el día en que se
  /// hizo cada check-in (10 gotas en racha 1-6, x1.5 desde el día 7, x2
  /// desde el día 21, x3 desde el día 50). Un día cubierto por un escudo
  /// mantiene el conteo de racha para el multiplicador pero no gana gotas
  /// propias, porque no hubo check-in real ese día.
  int get constancyDropsEarned {
    if (checkIns.isEmpty) return 0;
    final orderedDays = checkIns.map((c) => c.date).toSet().toList()..sort();
    final frozenDays = freezeUsedDates.toSet();
    var drops = 0;
    var streakSoFar = 0;
    DateTime? previous;
    for (final day in orderedDays) {
      final gap = previous == null ? null : day.difference(previous).inDays;
      final bridgedByFreeze =
          gap == 2 && frozenDays.contains(previous!.add(const Duration(days: 1)));
      if (gap == 1 || bridgedByFreeze) {
        streakSoFar++;
      } else {
        streakSoFar = 1;
      }
      drops += _dropsForStreakDay(streakSoFar);
      previous = day;
    }
    return drops;
  }

  static int _dropsForStreakDay(int streakAtDay) {
    if (streakAtDay >= 50) return 30;
    if (streakAtDay >= 21) return 20;
    if (streakAtDay >= 7) return 15;
    return 10;
  }

  void addCheckInToday() {
    if (checkedInToday) return;
    checkIns.add(CheckIn(date: CheckIn.today()));
  }

  void removeCheckInToday() {
    checkIns.removeWhere((c) => c.date == CheckIn.today());
  }

  void addMember(String name) {
    if (members.contains(name)) return;
    members.add(name);
  }

  /// Consume un escudo disponible para cubrir [date] (un día sin check-in
  /// real que de otro modo habría roto la racha). No hace nada si no quedan
  /// escudos o si esa fecha ya fue cubierta antes.
  bool useFreezeFor(DateTime date) {
    if (freezesAvailable <= 0 || freezeUsedDates.contains(date)) return false;
    freezesAvailable--;
    freezeUsedDates.add(date);
    return true;
  }

  /// Otorga un escudo gratis por alcanzar [milestoneDays] por primera vez.
  /// No hace nada si ese hito ya fue reclamado antes.
  bool grantFreezeForMilestone(int milestoneDays) {
    if (claimedFreezeMilestones.contains(milestoneDays)) return false;
    claimedFreezeMilestones.add(milestoneDays);
    freezesAvailable++;
    return true;
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'members': members,
    'pendingMemberName': pendingMemberName,
    'checkIns': checkIns.map((c) => c.toMap()).toList(),
    'freezesAvailable': freezesAvailable,
    'freezeUsedDates': freezeUsedDates.map((d) => d.toIso8601String()).toList(),
    'claimedFreezeMilestones': claimedFreezeMilestones,
  };

  factory HabitCircle.fromMap(Map<dynamic, dynamic> map) => HabitCircle(
    name: map['name'] as String,
    category: map['category'] as String,
    members: List<String>.from(map['members'] as List),
    pendingMemberName: map['pendingMemberName'] as String?,
    checkIns: (map['checkIns'] as List)
        .map((e) => CheckIn.fromMap(e as Map<dynamic, dynamic>))
        .toList(),
    freezesAvailable: map['freezesAvailable'] as int? ?? 0,
    freezeUsedDates: (map['freezeUsedDates'] as List?)
            ?.map((e) => DateTime.parse(e as String))
            .toList() ??
        [],
    claimedFreezeMilestones: (map['claimedFreezeMilestones'] as List?)
            ?.map((e) => e as int)
            .toList() ??
        [],
  );
}
