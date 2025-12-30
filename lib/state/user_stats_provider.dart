import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserStats {
  final int gamesPlayed;
  final int questionsAnswered;
  final int correctAnswers;

  const UserStats({
    required this.gamesPlayed,
    required this.questionsAnswered,
    required this.correctAnswers,
  });

  double get accuracy => questionsAnswered == 0 ? 0 : correctAnswers / questionsAnswered;

  UserStats copyWith({
    int? gamesPlayed,
    int? questionsAnswered,
    int? correctAnswers,
  }) {
    return UserStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
    );
  }

  factory UserStats.initial() => const UserStats(gamesPlayed: 0, questionsAnswered: 0, correctAnswers: 0);
}

final userStatsProvider = StateNotifierProvider<UserStatsNotifier, UserStats>((ref) {
  return UserStatsNotifier();
});

class UserStatsNotifier extends StateNotifier<UserStats> {
  UserStatsNotifier() : super(UserStats.initial());

  void recordGame({required int questions, required int correct}) {
    state = state.copyWith(
      gamesPlayed: state.gamesPlayed + 1,
      questionsAnswered: state.questionsAnswered + questions,
      correctAnswers: state.correctAnswers + correct,
    );
  }

  void reset() {
    state = UserStats.initial();
  }
}
