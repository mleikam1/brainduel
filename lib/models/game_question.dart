class GameQuestion {
  final String id;
  final String prompt;
  final List<String> choices;
  final String difficulty;
  final int correctIndex;

  const GameQuestion({
    required this.id,
    required this.prompt,
    required this.choices,
    required this.difficulty,
    required this.correctIndex,
  });

  factory GameQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'];
    if (rawChoices is! List) {
      throw StateError('Missing choices for game question payload.');
    }
    return GameQuestion(
      id: json['questionId'] as String,
      prompt: json['prompt'] as String,
      choices: List<String>.from(rawChoices),
      difficulty: json['difficulty'] as String,
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
