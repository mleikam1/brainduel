import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../state/trivia_session_provider.dart';
import '../state/user_stats_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/trivia_question_view.dart';

class TriviaGameScreen extends ConsumerStatefulWidget {
  const TriviaGameScreen({super.key});

  @override
  ConsumerState<TriviaGameScreen> createState() => _TriviaGameScreenState();
}

class _TriviaGameScreenState extends ConsumerState<TriviaGameScreen> {
  String? categoryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    categoryId ??= ModalRoute.of(context)?.settings.arguments as String?;
    if (categoryId != null) {
      ref.read(triviaSessionProvider.notifier).startGame(categoryId!);
    }
  }

  void _finishGameAndGoToResults() {
    final state = ref.read(triviaSessionProvider);
    final session = state.session!;
    final correct = state.score;
    final total = session.questions.length;

    ref.read(userStatsProvider.notifier).recordGame(questions: total, correct: correct);

    Navigator.of(context).pushReplacementNamed(
      TriviaApp.routeResults,
      arguments: {
        'categoryId': session.categoryId,
        'correct': correct,
        'total': total,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(triviaSessionProvider);

    return AppScaffold(
      title: 'Trivia',
      child: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to start game:\n${state.error}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (categoryId != null) {
                  ref.read(triviaSessionProvider.notifier).startGame(categoryId!);
                }
              },
              child: const Text('Retry'),
            )
          ],
        ),
      )
          : state.session == null
          ? const Center(child: Text('No session.'))
          : TriviaQuestionView(
        session: state.session!,
        currentIndex: state.currentIndex,
        selectedAnswerId: state.selectedAnswerId,
        isAnswered: state.isAnswered,
        onSelectAnswer: (id) => ref.read(triviaSessionProvider.notifier).selectAnswer(id),
        onNext: () {
          final notifier = ref.read(triviaSessionProvider.notifier);
          if (notifier.isLastQuestion) {
            _finishGameAndGoToResults();
          } else {
            notifier.nextQuestion();
          }
        },
      ),
    );
  }
}
