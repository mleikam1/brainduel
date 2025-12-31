import 'dart:math';
import '../models/trivia_pack.dart';
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

    final selected = questions.take(kTriviaQuestionCount).toList();

    return TriviaSession(
      sessionId: '${pack.categoryId}_${DateTime.now().millisecondsSinceEpoch}',
      categoryId: pack.categoryId,
      mode: mode,
      questions: selected,
      startedAt: DateTime.now(),
    );
  }
}
