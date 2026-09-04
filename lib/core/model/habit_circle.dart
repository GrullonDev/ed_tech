class HabitCircle {
  HabitCircle({
    required this.name,
    required this.category,
    required this.streakDays,
    required this.members,
    required this.totalMembers,
    required this.completedMembers,
    required this.checkedInToday,
    this.pendingMemberName,
  });

  final String name;
  final String category;
  final int streakDays;
  final List<String> members;
  final int totalMembers;
  int completedMembers;
  bool checkedInToday;
  final String? pendingMemberName;

  bool get isPerfect => completedMembers >= totalMembers;
  double get progress =>
      totalMembers == 0 ? 0 : completedMembers / totalMembers;
  int get extraMembers => totalMembers - members.length;

  /// Serializa a un mapa plano compatible con Hive (sin adaptadores
  /// generados) para persistencia local.
  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'streakDays': streakDays,
    'members': members,
    'totalMembers': totalMembers,
    'completedMembers': completedMembers,
    'checkedInToday': checkedInToday,
    'pendingMemberName': pendingMemberName,
  };

  factory HabitCircle.fromMap(Map<dynamic, dynamic> map) => HabitCircle(
    name: map['name'] as String,
    category: map['category'] as String,
    streakDays: map['streakDays'] as int,
    members: List<String>.from(map['members'] as List),
    totalMembers: map['totalMembers'] as int,
    completedMembers: map['completedMembers'] as int,
    checkedInToday: map['checkedInToday'] as bool,
    pendingMemberName: map['pendingMemberName'] as String?,
  );
}
