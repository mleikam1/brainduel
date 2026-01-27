class ChallengeMetadata {
  final String id;
  final String title;
  final String topic;
  final String difficulty;
  final List<String> rules;
  final String taunt;
  final DateTime expiresAt;

  const ChallengeMetadata({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.rules,
    required this.taunt,
    required this.expiresAt,
  });

  factory ChallengeMetadata.fromJson(Map<String, dynamic> json) {
    final rawRules = json['rules'];
    List<String> rulesJson;
    if (rawRules == null) {
      rulesJson = <String>[];
    } else if (rawRules is List) {
      rulesJson = List<String>.from(rawRules);
    } else {
      throw StateError('Invalid challenge rules payload.');
    }
    return ChallengeMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      topic: json['topic'] as String,
      difficulty: json['difficulty'] as String,
      rules: rulesJson,
      taunt: json['taunt'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'topic': topic,
        'difficulty': difficulty,
        'rules': rules,
        'taunt': taunt,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
      };
}

class ChallengeChoice {
  final String id;
  final String text;

  const ChallengeChoice({
    required this.id,
    required this.text,
  });

  factory ChallengeChoice.fromJson(Map<String, dynamic> json) {
    return ChallengeChoice(
      id: json['id'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
      };
}

class ChallengeQuestion {
  final String id;
  final String prompt;
  final List<ChallengeChoice> choices;

  const ChallengeQuestion({
    required this.id,
    required this.prompt,
    required this.choices,
  });

  factory ChallengeQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'];
    if (rawChoices is! List) {
      throw StateError('Invalid challenge choices payload.');
    }
    final choicesJson = List<Map<String, dynamic>>.from(
      rawChoices.map((choice) {
        if (choice is! Map) {
          throw StateError('Invalid challenge choice payload.');
        }
        return Map<String, dynamic>.from(choice);
      }),
    );
    final choices = choicesJson.map(ChallengeChoice.fromJson).toList();
    if (choices.length < 2) {
      throw FormatException('Challenge question ${json['id']} must have at least 2 choices.');
    }
    return ChallengeQuestion(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      choices: choices,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'choices': choices.map((choice) => choice.toJson()).toList(),
      };
}

class ChallengeDefinition {
  final ChallengeMetadata metadata;
  final List<ChallengeQuestion> questions;

  const ChallengeDefinition({
    required this.metadata,
    required this.questions,
  });

  factory ChallengeDefinition.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    if (rawQuestions is! List) {
      throw StateError('Invalid challenge questions payload.');
    }
    final questionsJson = List<Map<String, dynamic>>.from(
      rawQuestions.map((question) {
        if (question is! Map) {
          throw StateError('Invalid challenge question payload.');
        }
        return Map<String, dynamic>.from(question);
      }),
    );
    return ChallengeDefinition(
      metadata: ChallengeMetadata.fromJson(json),
      questions: questionsJson.map(ChallengeQuestion.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        ...metadata.toJson(),
        'questions': questions.map((question) => question.toJson()).toList(),
      };
}

class ChallengeAttempt {
  final String id;
  final String challengeId;
  final DateTime startedAt;
  final List<ChallengeQuestion> questions;

  const ChallengeAttempt({
    required this.id,
    required this.challengeId,
    required this.startedAt,
    required this.questions,
  });
}
