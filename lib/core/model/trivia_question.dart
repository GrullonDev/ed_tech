/// Una pregunta de opción múltiple del "Desafío del día" (ver
/// `lib/core/data/trivia_bank.dart` y `HomeLogic.todaysTrivia`). Todo el
/// contenido vive hardcodeado en el bundle de la app — no depende de
/// Firebase ni de red, así que el desafío funciona igual 100% offline.
class TriviaQuestion {
  const TriviaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;

  /// Índice dentro de [options] de la respuesta correcta.
  final int correctIndex;

  /// Se muestra después de responder, acierte o no, para que el desafío
  /// también enseñe algo y no sea solo "bien/mal".
  final String explanation;
}
