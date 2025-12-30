import 'trivia_question.dart';

class TriviaPack {
  final String categoryId;
  final int version;
  final List<TriviaQuestion> questions;

  const TriviaPack({
    required this.categoryId,
    required this.version,
    required this.questions,
  });

  factory TriviaPack.fromJson(Map<String, dynamic> json) {
    final qJson = (json['questions'] as List).cast<Map<String, dynamic>>();
    return TriviaPack(
      categoryId: json['categoryId'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      questions: qJson.map(TriviaQuestion.fromJson).toList(),
    );
  }
}
