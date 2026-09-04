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
  }) : members = members ?? ['Yo'],
       checkIns = checkIns ?? [];

  final String name;
  final String category;
  final List<String> members;
  final String? pendingMemberName;
  final List<CheckIn> checkIns;

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
  int get streakDays {
    if (checkIns.isEmpty) return 0;
    final days = checkIns.map((c) => c.date).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    var expected = CheckIn.today();
    if (days.first != expected) {
      expected = expected.subtract(const Duration(days: 1));
      if (days.first != expected) return 0;
    }
    var streak = 0;
    for (final day in days) {
      if (day != expected) break;
      streak++;
      expected = expected.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void addCheckInToday() {
    if (checkedInToday) return;
    checkIns.add(CheckIn(date: CheckIn.today()));
  }

  void removeCheckInToday() {
    checkIns.removeWhere((c) => c.date == CheckIn.today());
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'members': members,
    'pendingMemberName': pendingMemberName,
    'checkIns': checkIns.map((c) => c.toMap()).toList(),
  };

  factory HabitCircle.fromMap(Map<dynamic, dynamic> map) => HabitCircle(
    name: map['name'] as String,
    category: map['category'] as String,
    members: List<String>.from(map['members'] as List),
    pendingMemberName: map['pendingMemberName'] as String?,
    checkIns: (map['checkIns'] as List)
        .map((e) => CheckIn.fromMap(e as Map<dynamic, dynamic>))
        .toList(),
  );
}
