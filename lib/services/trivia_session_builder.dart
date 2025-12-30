import 'dart:math';
import '../models/trivia_pack.dart';
import '../models/trivia_session.dart';

class TriviaSessionBuilder {
  TriviaSession buildSession({
    required TriviaPack pack,
    required int sessionSize,
    String mode = 'classic',
    int? seed,
  }) {
    final r = (seed == null) ? Random() : Random(seed);
    final questions = List.of(pack.questions);
    questions.shuffle(r);

    final selected = questions.take(sessionSize.clamp(1, questions.length)).toList();

    return TriviaSession(
      sessionId: '${pack.categoryId}_${DateTime.now().millisecondsSinceEpoch}',
      categoryId: pack.categoryId,
      mode: mode,
      questions: selected,
      startedAt: DateTime.now(),
    );
  }
}
