class HabitCircle {
  HabitCircle({
    required this.name,
    required this.streakDays,
    required this.members,
    required this.checkedInToday,
  });

  final String name;
  final int streakDays;
  final List<String> members;
  bool checkedInToday;
}
