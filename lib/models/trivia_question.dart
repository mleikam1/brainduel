import 'trivia_answer.dart';

class TriviaQuestion {
  final String id;
  final String question;
  final List<TriviaAnswer> answers;
  final List<TriviaAnswer>? sessionAnswers;
  final String? explanation;
  final String? mediaUrl;

  const TriviaQuestion({
    required this.id,
    required this.question,
    required this.answers,
    this.sessionAnswers,
    this.explanation,
    this.mediaUrl,
  });

  List<TriviaAnswer> get displayAnswers => sessionAnswers ?? answers;

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    final answersJson = (json['answers'] as List).cast<Map<String, dynamic>>();
    final answers = answersJson.map(TriviaAnswer.fromJson).toList();

    // Minimal validation
    if (answers.length < 2 || answers.length > 4) {
      throw FormatException('Question ${json['id']} must have 2–4 answers.');
    }
    final correctCount = answers.where((a) => a.correct).length;
    if (correctCount != 1) {
      throw FormatException('Question ${json['id']} must have exactly 1 correct answer.');
    }

    return TriviaQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      answers: answers,
      explanation: json['explanation'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
    );
  }
}
