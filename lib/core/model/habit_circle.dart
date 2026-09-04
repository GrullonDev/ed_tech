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
}
