import 'trivia_question.dart';

class TriviaSession {
  final String sessionId;
  final String categoryId;
  final String mode;
  final List<TriviaQuestion> questions;
  final DateTime startedAt;

  const TriviaSession({
    required this.sessionId,
    required this.categoryId,
    required this.mode,
    required this.questions,
    required this.startedAt,
  });
}
