class TriviaAnswer {
  final String id;
  final String text;
  final bool correct;

  const TriviaAnswer({
    required this.id,
    required this.text,
    this.correct = false,
  });

  factory TriviaAnswer.fromJson(Map<String, dynamic> json) {
    return TriviaAnswer(
      id: json['id'] as String,
      text: json['text'] as String,
      correct: (json['correct'] as bool?) ?? false,
    );
  }
}
