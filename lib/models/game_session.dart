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
    final topicId = json['topicId'] ?? json['categoryId'];
    if (topicId == null) {
      throw StateError('Missing topicId for game session payload.');
    }
    return GameSession(
      gameId: (json['gameId'] ?? json['quizId'] ?? json['sessionId']) as String,
      topicId: topicId as String,
      questionsSnapshot: questions,
    );
  }
}
