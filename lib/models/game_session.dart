import 'game_question.dart';

class GameSession {
  final String gameId;
  final String topicId;
  final List<GameQuestion> questionsSnapshot;

  const GameSession({
    required this.gameId,
    required this.topicId,
    required this.questionsSnapshot,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questionsSnapshot'] ?? json['questions'];
    final questionsJson = (rawQuestions as List).cast<Map<String, dynamic>>();
    final questions = questionsJson.map(GameQuestion.fromJson).toList();
    return GameSession(
      gameId: json['gameId'] as String,
      topicId: json['topicId'] as String,
      questionsSnapshot: questions,
    );
  }
}
