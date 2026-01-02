import 'dart:math';
import '../models/trivia_answer.dart';
import '../models/trivia_pack.dart';
import '../models/trivia_question.dart';
import '../models/trivia_session.dart';

const int kTriviaQuestionCount = 10;

class TriviaSessionBuilder {
  TriviaSession buildSession({
    required TriviaPack pack,
    String mode = 'classic',
    int? seed,
  }) {
    final r = (seed == null) ? Random() : Random(seed);
    final questions = List.of(pack.questions);
    questions.shuffle(r);

    final selected = questions.take(kTriviaQuestionCount).map((question) {
      final shuffledAnswers = List<TriviaAnswer>.from(question.answers)..shuffle(r);
      return TriviaQuestion(
        id: question.id,
        question: question.question,
        answers: List<TriviaAnswer>.from(question.answers),
        sessionAnswers: shuffledAnswers,
        explanation: question.explanation,
        mediaUrl: question.mediaUrl,
      );
    }).toList();

    return TriviaSession(
      sessionId: '${pack.categoryId}_${DateTime.now().millisecondsSinceEpoch}',
      categoryId: pack.categoryId,
      mode: mode,
      questions: selected,
      startedAt: DateTime.now(),
    );
  }
}
