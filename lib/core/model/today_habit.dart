class TodayHabit {
  TodayHabit({required this.label, required this.done});

  final String label;
  bool done;

  Map<String, dynamic> toMap() => {'label': label, 'done': done};

  factory TodayHabit.fromMap(Map<dynamic, dynamic> map) =>
      TodayHabit(label: map['label'] as String, done: map['done'] as bool);
}
