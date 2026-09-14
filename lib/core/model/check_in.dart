/// Registro de que el usuario actual confirmó su hábito en un círculo, en
/// una fecha concreta (normalizada a medianoche, sin hora). Es la única
/// fuente de verdad para saber si ya se hizo check-in hoy y para calcular la
/// racha de días consecutivos — nada de contadores fijos.
class CheckIn {
  CheckIn({required this.date});

  final DateTime date;

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Map<String, dynamic> toMap() => {'date': date.toIso8601String()};

  factory CheckIn.fromMap(Map<dynamic, dynamic> map) =>
      CheckIn(date: DateTime.parse(map['date'] as String));
}
