import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../state/quiz_controller.dart';
import 'bd_answer_option_tile.dart';
import 'bd_card.dart';

class TriviaQuestionView extends StatelessWidget {
  const TriviaQuestionView({
    super.key,
    required this.session,
    required this.currentIndex,
    required this.phase,
    required this.selectedIndex,
    required this.onSelectAnswer,
  });

  final GameSession session;
  final int currentIndex;
  final QuestionPhase phase;
  final int? selectedIndex;
  final void Function(int answerIndex) onSelectAnswer;

  @override
  Widget build(BuildContext context) {
    final q = session.questionsSnapshot[currentIndex];
    final answers = q.choices;
    final showAnswers = phase != QuestionPhase.reading;
    final isAnswering = phase == QuestionPhase.answering;
    final isAnswered = phase == QuestionPhase.answered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BDCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                q.prompt,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: showAnswers
              ? Column(
                  key: const ValueKey('answers'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...answers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final choice = entry.value;
                      final isSelected = selectedIndex == index;
                      final state = isAnswered && isSelected
                          ? BDAnswerState.selected
                          : isAnswering
                              ? BDAnswerState.idle
                              : BDAnswerState.disabled;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BDAnswerOptionTile(
                          text: choice,
                          state: state,
                          onTap: isAnswering ? () => onSelectAnswer(index) : null,
                        ),
                      );
                    }),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('hidden')),
        ),
      ],
    );
  }
}
