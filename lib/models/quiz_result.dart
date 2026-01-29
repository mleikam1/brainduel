import 'package:flutter/foundation.dart';

@immutable
class QuizResultAnswer {
  const QuizResultAnswer({
    required this.questionId,
    required this.selectedIndex,
    required this.correctIndex,
  });

  final String questionId;
  final int selectedIndex;
  final int correctIndex;
}

@immutable
class QuizResult {
  const QuizResult({
    required this.totalQuestions,
    required this.correctCount,
    required this.score,
    required List<QuizResultAnswer> answers,
  }) : answers = List.unmodifiable(answers);

  final int totalQuestions;
  final int correctCount;
  final int score;
  final List<QuizResultAnswer> answers;
}
