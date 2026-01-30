class GameQuestion {
  final String id;
  final String prompt;
  final List<String> choices;
  final List<String> choiceIds;
  final String difficulty;
  final String correctAnswerId;

  const GameQuestion({
    required this.id,
    required this.prompt,
    required this.choices,
    required this.choiceIds,
    required this.difficulty,
    required this.correctAnswerId,
  });

  static String buildChoiceId(String questionId, String choiceText) {
    return '$questionId::${choiceText.trim()}';
  }

  factory GameQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'];
    if (rawChoices is! List) {
      throw StateError('Missing choices for game question payload.');
    }
    final questionId = json['questionId'] as String;
    final parsedChoices = <String>[];
    final parsedChoiceIds = <String>[];
    for (final choice in rawChoices) {
      if (choice is Map) {
        final mapped = Map<String, dynamic>.from(choice);
        final text = mapped['text'] as String? ?? '';
        final id = mapped['id'] as String? ?? buildChoiceId(questionId, text);
        parsedChoices.add(text);
        parsedChoiceIds.add(id);
      } else {
        final text = choice.toString();
        parsedChoices.add(text);
        parsedChoiceIds.add(buildChoiceId(questionId, text));
      }
    }
    final correctAnswerId = json['correctAnswerId'] as String? ??
        (() {
          final correctIndex = (json['correctIndex'] as num?)?.toInt() ?? 0;
          if (parsedChoiceIds.isEmpty) return '';
          final boundedIndex = correctIndex.clamp(0, parsedChoiceIds.length - 1);
          return parsedChoiceIds[boundedIndex];
        })();
    return GameQuestion(
      id: questionId,
      prompt: json['prompt'] as String,
      choices: parsedChoices,
      choiceIds: parsedChoiceIds,
      difficulty: json['difficulty'] as String,
      correctAnswerId: correctAnswerId,
    );
  }
}
