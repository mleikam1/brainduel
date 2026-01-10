import 'game_question.dart';

class GameSession {
  final String gameId;
  final String topicId;
  final List<GameQuestion> questions;

  const GameSession({
    required this.gameId,
    required this.topicId,
    required this.questions,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final questionsJson = (json['questions'] as List).cast<Map<String, dynamic>>();
    final questions = questionsJson.map(GameQuestion.fromJson).toList();
    return GameSession(
      gameId: json['gameId'] as String,
      topicId: json['topicId'] as String,
      questions: questions,
    );
  }
}
