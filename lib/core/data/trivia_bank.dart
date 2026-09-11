import 'package:edtech_tiktok/core/model/trivia_question.dart';

/// Banco fijo de preguntas del "Desafío del día" (ver
/// `HomeLogic.todaysTrivia`). Se eligió un banco estático hardcodeado en vez
/// de un backend/colección de Firestore a propósito: es contenido educativo
/// de bajo riesgo (no hay nada que "falsear" ni sincronizar entre
/// dispositivos), así que no amerita la complejidad de mantenerlo remoto —
/// agregar o editar preguntas es un PR normal a este archivo.
///
/// El orden importa: `HomeLogic` elige la pregunta del día por índice
/// (`día desde una fecha fija % length`), así que insertar una pregunta en
/// medio de la lista corre el índice de todas las que quedan detrás y
/// cambia qué pregunta le toca a un día que ya había pasado — no rompe
/// nada, pero agregar al final es lo más predecible si se quiere evitar eso.
abstract final class TriviaBank {
  static const List<TriviaQuestion> questions = [
    TriviaQuestion(
      question: '¿Cuánto tiempo suele tardar en formarse un hábito nuevo, '
          'según los estudios más citados sobre el tema?',
      options: ['3 días', '21 días exactos', 'Entre 2 y 3 meses', '1 año'],
      correctIndex: 2,
      explanation: 'El famoso "21 días" es un mito. Investigaciones como la '
          'de Phillippa Lally (2009) encontraron que automatizar un hábito '
          'toma en promedio 66 días, con un rango real de 18 a 254 según la '
          'persona y el hábito.',
    ),
    TriviaQuestion(
      question: '¿Qué es más efectivo para sostener un hábito a largo '
          'plazo?',
      options: [
        'Depender solo de la fuerza de voluntad',
        'Reducir la fricción para hacerlo fácil',
        'Ponerse una meta enorme desde el día uno',
        'Castigarte si fallás un día',
      ],
      correctIndex: 1,
      explanation: 'La fuerza de voluntad se agota durante el día. Diseñar '
          'el entorno para que el hábito sea la opción más fácil (dejar la '
          'ropa de gimnasio lista, por ejemplo) funciona mejor y dura más.',
    ),
    TriviaQuestion(
      question: '¿Qué pasa si fallás un día en tu racha y la retomás al '
          'día siguiente, según la investigación sobre hábitos?',
      options: [
        'Tenés que empezar de cero mentalmente',
        'Un solo día perdido no afecta el hábito a largo plazo',
        'Perdiste el hábito para siempre',
        'Es mejor no volver a intentarlo esa semana',
      ],
      correctIndex: 1,
      explanation: 'Lally y su equipo encontraron que fallar un día '
          'ocasional no tiene un impacto medible en la formación del '
          'hábito a largo plazo — lo que sí importa es no dejar que un día '
          'se convierta en muchos.',
    ),
    TriviaQuestion(
      question: '¿Cuál de estas es una señal ("cue") típica que dispara un '
          'hábito automático?',
      options: [
        'Un lugar u hora específica del día',
        'Solo la fuerza de voluntad',
        'Un premio en efectivo',
        'Ninguna, los hábitos son al azar',
      ],
      correctIndex: 0,
      explanation: 'Los hábitos siguen un ciclo de señal → rutina → '
          'recompensa. Anclar un hábito nuevo a un lugar u hora fija (ej. '
          '"después de lavarme los dientes") es una de las técnicas más '
          'efectivas para automatizarlo.',
    ),
    TriviaQuestion(
      question: '¿Qué beneficio real tiene hacer un hábito en grupo o con '
          'un aliado, comparado con hacerlo en solitario?',
      options: [
        'Ninguno medible',
        'Aumenta la probabilidad de sostenerlo en el tiempo',
        'Solo sirve para hábitos de ejercicio',
        'Lo hace más lento de formar',
      ],
      correctIndex: 1,
      explanation: 'La responsabilidad social (que alguien más sepa si '
          'cumpliste o no) es uno de los refuerzos más estudiados para '
          'sostener un hábito — de ahí el valor real de una "tribu".',
    ),
    TriviaQuestion(
      question: '¿Cuántos vasos de agua al día se recomiendan '
          'generalmente para un adulto promedio?',
      options: ['2', '4', '8', '15'],
      correctIndex: 2,
      explanation: 'La recomendación general más citada es de unos 8 vasos '
          '(~2 litros) al día, aunque varía según el peso, el clima y la '
          'actividad física de cada persona.',
    ),
    TriviaQuestion(
      question: '¿Cuántas horas de sueño se recomiendan para un adulto '
          'promedio?',
      options: ['4-5 horas', '6-9 horas', '10-12 horas', 'No importa'],
      correctIndex: 1,
      explanation: 'La National Sleep Foundation recomienda entre 7 y 9 '
          'horas para la mayoría de los adultos, con un rango aceptable de '
          '6 a 9 según la persona.',
    ),
    TriviaQuestion(
      question: '¿Qué es el "apilamiento de hábitos" (habit stacking)?',
      options: [
        'Hacer varios hábitos nuevos a la vez',
        'Conectar un hábito nuevo a uno que ya hacés automáticamente',
        'Guardar hábitos para el año que viene',
        'Un tipo de ejercicio físico',
      ],
      correctIndex: 1,
      explanation: 'La técnica (popularizada por BJ Fogg y James Clear) '
          'consiste en usar un hábito ya automático como disparador del '
          'nuevo: "después de [hábito existente], voy a [hábito nuevo]".',
    ),
    TriviaQuestion(
      question: '¿Qué efecto tiene escribir o registrar tus hábitos en '
          'vez de solo tenerlos en mente?',
      options: [
        'Ninguno',
        'Aumenta la conciencia y la probabilidad de cumplirlos',
        'Genera más ansiedad siempre',
        'Solo sirve para hábitos financieros',
      ],
      correctIndex: 1,
      explanation: 'El simple acto de registrar (como hacer check-in en un '
          'círculo) aumenta la conciencia del comportamiento, un efecto '
          'bien documentado en programas de cambio de hábitos.',
    ),
    TriviaQuestion(
      question: '¿Qué es más realista al empezar un hábito nuevo?',
      options: [
        'Empezar en su versión más pequeña posible',
        'Empezar con la versión más exigente para "no perder tiempo"',
        'Esperar a sentir motivación total antes de empezar',
        'Cambiar 5 hábitos a la vez para aprovechar el impulso',
      ],
      correctIndex: 0,
      explanation: 'Empezar chico (2 minutos de meditación en vez de 30) '
          'baja la fricción inicial y facilita sostenerlo — se puede '
          'escalar después de que ya es automático.',
    ),
    TriviaQuestion(
      question: '¿Qué mide en realidad una "racha" (streak) en una app de '
          'hábitos?',
      options: [
        'Cuántos amigos tenés',
        'Días consecutivos sin fallar el hábito',
        'El total de hábitos creados',
        'El nivel de dificultad del hábito',
      ],
      correctIndex: 1,
      explanation: 'Una racha cuenta días consecutivos de cumplimiento — '
          'es una de las métricas más motivadoras porque hace visible el '
          'costo de romperla justo cuando más vale la pena mantenerla.',
    ),
    TriviaQuestion(
      question: '¿Cuál de estas frutas/verduras tiene más vitamina C por '
          'porción?',
      options: ['Manzana', 'Pimiento rojo', 'Plátano/banana', 'Papa'],
      correctIndex: 1,
      explanation: 'El pimiento (morrón) rojo tiene incluso más vitamina C '
          'por gramo que una naranja — una de las fuentes más '
          'subestimadas.',
    ),
    TriviaQuestion(
      question: '¿Qué tipo de meta suele funcionar mejor para sostener la '
          'motivación a largo plazo?',
      options: [
        'Metas basadas en identidad ("soy alguien que hace ejercicio")',
        'Metas basadas solo en un número final',
        'No tener ninguna meta',
        'Cambiar la meta cada semana',
      ],
      correctIndex: 0,
      explanation: 'James Clear (Hábitos Atómicos) argumenta que los '
          'cambios de identidad ("soy una persona constante") sostienen '
          'más la motivación que solo perseguir un resultado numérico.',
    ),
    TriviaQuestion(
      question: '¿Qué es la "fricción" en el diseño de hábitos?',
      options: [
        'El calor que genera el ejercicio',
        'Todo lo que hace más difícil empezar el hábito',
        'Un tipo de recompensa',
        'La velocidad a la que se olvida un hábito',
      ],
      correctIndex: 1,
      explanation: 'Fricción es cualquier obstáculo entre vos y el hábito: '
          'buscar la ropa de gimnasio, abrir 3 apps para anotar algo, etc. '
          'Reducirla es una de las palancas más efectivas para sostener '
          'un hábito.',
    ),
    TriviaQuestion(
      question: 'Además del movimiento físico, ¿qué otro beneficio real '
          'tiene el ejercicio regular?',
      options: [
        'Ninguno fuera de lo físico',
        'Mejora el estado de ánimo y reduce el estrés',
        'Solo sirve si es de alta intensidad',
        'Empeora la calidad del sueño',
      ],
      correctIndex: 1,
      explanation: 'El ejercicio libera endorfinas y reduce cortisol '
          '(la hormona del estrés), con efectos positivos documentados en '
          'el ánimo incluso con rutinas moderadas y cortas.',
    ),
    TriviaQuestion(
      question: '¿Qué pasa con un hábito cuando se vuelve "automático"?',
      options: [
        'Requiere el mismo esfuerzo mental que al principio',
        'Se ejecuta con menos esfuerzo consciente que al principio',
        'Deja de tener ningún efecto',
        'Se vuelve imposible de romper',
      ],
      correctIndex: 1,
      explanation: 'A medida que se repite, el cerebro delega el '
          'comportamiento a circuitos más automáticos (ganglios basales), '
          'lo que baja el esfuerzo consciente necesario para sostenerlo.',
    ),
    TriviaQuestion(
      question: '¿Qué rol cumple la recompensa inmediata en un hábito '
          'nuevo?',
      options: [
        'Ninguno, las recompensas son innecesarias',
        'Refuerza el comportamiento y ayuda a repetirlo',
        'Solo funciona en niños',
        'Hace que el hábito se vuelva adictivo siempre',
      ],
      correctIndex: 1,
      explanation: 'El cerebro aprende por refuerzo: una recompensa '
          'inmediata (aunque sea pequeña, como ver tu racha subir) ayuda a '
          'consolidar el comportamiento mucho más que un beneficio lejano '
          'en el tiempo.',
    ),
    TriviaQuestion(
      question: '¿Cuál de estas es considerada una técnica de respiración '
          'para reducir el estrés en el momento?',
      options: [
        'Respiración 4-7-8',
        'Contener la respiración 5 minutos',
        'Respirar lo más rápido posible',
        'No existe ninguna técnica probada',
      ],
      correctIndex: 0,
      explanation: 'La técnica 4-7-8 (inhalar 4 segundos, sostener 7, '
          'exhalar 8) es una de las más recomendadas para activar el '
          'sistema nervioso parasimpático y bajar el estrés rápido.',
    ),
    TriviaQuestion(
      question: '¿Qué significa realmente "constancia" a diferencia de '
          '"perfección"?',
      options: [
        'Nunca fallar ni un solo día',
        'Volver a intentarlo después de fallar, sin abandonar',
        'Hacer el hábito solo cuando hay motivación',
        'Cambiar de hábito apenas se pone difícil',
      ],
      correctIndex: 1,
      explanation: 'La constancia no es no fallar nunca — es la capacidad '
          'de retomar el hábito después de un tropiezo, sin que eso se '
          'convierta en abandono total.',
    ),
    TriviaQuestion(
      question: '¿Qué es más probable que ayude a mantener un hábito de '
          'lectura?',
      options: [
        'Ponerte la meta de "leer 1 hora todos los días" desde el día 1',
        'Dejar el libro visible cerca de donde te sentás siempre',
        'Comprar muchos libros nuevos',
        'Leer solo cuando estés muy motivado',
      ],
      correctIndex: 1,
      explanation: 'Hacer visible el disparador (el libro a la vista) '
          'reduce la fricción y aumenta la probabilidad de que el hábito '
          'ocurra sin depender de la fuerza de voluntad.',
    ),
    TriviaQuestion(
      question: '¿Qué tan importante es el sueño para consolidar hábitos '
          'y memoria?',
      options: [
        'Nada importante',
        'Bastante importante: el cerebro consolida aprendizajes al dormir',
        'Solo importa para hábitos físicos',
        'Dormir más de 6 horas es contraproducente',
      ],
      correctIndex: 1,
      explanation: 'Durante el sueño el cerebro consolida memoria y '
          'aprendizajes recientes — dormir mal afecta directamente la '
          'capacidad de sostener cualquier cambio de comportamiento.',
    ),
    TriviaQuestion(
      question: '¿Qué es un "hito" (milestone) en el contexto de una '
          'racha de hábitos?',
      options: [
        'Un error que rompe la racha',
        'Un número de días significativo que marca progreso (7, 21, 30...)',
        'El nombre de otro usuario',
        'Un tipo de notificación push',
      ],
      correctIndex: 1,
      explanation: 'Los hitos marcan puntos de progreso reconocibles '
          '(una semana, tres semanas, un mes) que ayudan a mantener la '
          'motivación visible en el camino largo.',
    ),
    TriviaQuestion(
      question: '¿Qué efecto tiene compartir tu progreso con otras '
          'personas (como en un círculo)?',
      options: [
        'Ninguno comprobado',
        'Genera responsabilidad social, que ayuda a sostener el hábito',
        'Solo funciona si son familiares',
        'Reduce la motivación siempre',
      ],
      correctIndex: 1,
      explanation: 'Saber que otra persona puede ver tu progreso (o su '
          'ausencia) activa mecanismos de responsabilidad social que '
          'muchos estudios asocian con mayor adherencia a los hábitos.',
    ),
    TriviaQuestion(
      question: '¿Qué tan seguido se recomienda hacer pausas activas si '
          'pasás muchas horas sentado?',
      options: [
        'Nunca hace falta',
        'Cada 30-60 minutos, levantarse un momento',
        'Solo una vez al día',
        'Solo los fines de semana',
      ],
      correctIndex: 1,
      explanation: 'Estudios sobre comportamiento sedentario recomiendan '
          'romper el tiempo sentado cada 30-60 minutos con al menos un par '
          'de minutos de pie o caminando.',
    ),
    TriviaQuestion(
      question: '¿Qué significa que un hábito sea "atómico", según el '
          'término popularizado por James Clear?',
      options: [
        'Que es explosivo y peligroso',
        'Que es una unidad pequeña y fácil de repetir todos los días',
        'Que requiere equipamiento científico',
        'Que solo se puede hacer una vez',
      ],
      correctIndex: 1,
      explanation: '"Atómico" se refiere a algo pequeño (como un átomo) '
          'pero que es la unidad básica de un sistema mayor — pequeños '
          'hábitos diarios que, sumados, generan cambios grandes.',
    ),
  ];
}
