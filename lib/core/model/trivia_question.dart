/// Una pregunta de opción múltiple del "Desafío del día" (ver
/// `HomeLogic.todaysTrivia`). Dos fuentes posibles, con el mismo modelo
/// para ambas:
///
/// - `lib/core/data/trivia_bank.dart`: banco fijo hardcodeado en el
///   bundle de la app — funciona 100% offline, sin Firebase ni red.
/// - `circles`-independiente, colección `triviaQuestions` de Firestore
///   (ver `firebase/FIRESTORE_SCHEMA.md`): permite agregar/editar
///   preguntas desde la consola de Firebase sin publicar una nueva
///   versión de la app. `HomeLogic` la sincroniza una vez por sesión y
///   cachea el resultado en Hive; si nunca hay red o Firebase no está
///   configurado, cae de vuelta al banco local — nunca se queda sin
///   desafío del día.
class TriviaQuestion {
  const TriviaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.order = 0,
  });

  final String question;
  final List<String> options;

  /// Índice dentro de [options] de la respuesta correcta.
  final int correctIndex;

  /// Se muestra después de responder, acierte o no, para que el desafío
  /// también enseñe algo y no sea solo "bien/mal".
  final String explanation;

  /// Posición dentro del banco (remoto o cacheado) usada para elegir la
  /// pregunta de cada día de forma estable — ver `HomeLogic.todaysTrivia`.
  /// Sin efecto en [TriviaBank.questions], que ya usa su propio orden de
  /// declaración en la lista.
  final int order;

  factory TriviaQuestion.fromMap(Map<String, dynamic> map) => TriviaQuestion(
    question: map['question'] as String,
    options: List<String>.from(map['options'] as List),
    correctIndex: map['correctIndex'] as int,
    explanation: map['explanation'] as String,
    order: map['order'] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
    'explanation': explanation,
    'order': order,
  };
}
