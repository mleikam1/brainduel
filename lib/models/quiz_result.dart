import 'package:flutter/foundation.dart';

@immutable
class QuizResultAnswer {
  const QuizResultAnswer({
    required this.questionId,
    required this.selectedAnswerId,
    required this.correctAnswerId,
  });

  final String questionId;
  final String selectedAnswerId;
  final String correctAnswerId;
}

@immutable
class QuizResult {
  QuizResult({
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
