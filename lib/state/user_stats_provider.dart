import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recent_game.dart';

class UserStats {
  final int gamesPlayed;
  final int questionsAnswered;
  final int correctAnswers;
  final int bestStreak;
  final List<RecentGame> recentGames;

  const UserStats({
    required this.gamesPlayed,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.bestStreak,
    required this.recentGames,
  });

  double get accuracy => questionsAnswered == 0 ? 0 : correctAnswers / questionsAnswered;
  int get totalPoints => correctAnswers * 100;

  UserStats copyWith({
    int? gamesPlayed,
    int? questionsAnswered,
    int? correctAnswers,
    int? bestStreak,
    List<RecentGame>? recentGames,
  }) {
    return UserStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      bestStreak: bestStreak ?? this.bestStreak,
      recentGames: recentGames ?? this.recentGames,
    );
  }

  factory UserStats.initial() => const UserStats(
    gamesPlayed: 0,
    questionsAnswered: 0,
    correctAnswers: 0,
    bestStreak: 0,
    recentGames: [],
  );
}

final userStatsProvider = StateNotifierProvider<UserStatsNotifier, UserStats>((ref) {
  return UserStatsNotifier();
});

class UserStatsNotifier extends StateNotifier<UserStats> {
  UserStatsNotifier() : super(UserStats.initial());

  void recordGame({
    required int questions,
    required int correct,
    required String categoryId,
  }) {
    final newGame = RecentGame(
      categoryId: categoryId,
      playedAt: DateTime.now(),
      correct: correct,
      total: questions,
    );

    final updatedRecent = [
      newGame,
      ...state.recentGames,
    ].take(5).toList();

    state = state.copyWith(
      gamesPlayed: state.gamesPlayed + 1,
      questionsAnswered: state.questionsAnswered + questions,
      correctAnswers: state.correctAnswers + correct,
      bestStreak: correct > state.bestStreak ? correct : state.bestStreak,
      recentGames: updatedRecent,
    );
  }

  void reset() {
    state = UserStats.initial();
  }
}
