import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../state/challenge_providers.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_buttons.dart';
import '../widgets/bd_card.dart';
import '../widgets/bd_stat_pill.dart';

class ChallengeIntroScreen extends ConsumerWidget {
  const ChallengeIntroScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataAsync = ref.watch(challengeMetadataProvider(challengeId));
    final attemptState = ref.watch(challengeAttemptProvider);

    return BDAppScaffold(
      title: 'Challenge Ready',
      subtitle: 'Code $challengeId',
      child: metadataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(BrainDuelSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load challenge:\n$error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.refresh(challengeMetadataProvider(challengeId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (metadata) {
          final localExpiry = metadata.expiresAt.toLocal();
          final dateText = MaterialLocalizations.of(context).formatMediumDate(localExpiry);
          final timeText = MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(localExpiry),
          );
          final isPublic = metadata.id.startsWith('public_');
          final isExpired = isPublic && metadata.expiresAt.isBefore(DateTime.now().toUtc());
          final notice = attemptState.notice;
          final error = attemptState.error;

          return Padding(
            padding: const EdgeInsets.all(BrainDuelSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  metadata.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    BDStatPill(label: 'Topic', value: metadata.topic),
                    const SizedBox(width: 8),
                    BDStatPill(label: 'Difficulty', value: metadata.difficulty),
                  ],
                ),
                const SizedBox(height: 16),
                BDCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rules', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      ...metadata.rules.map(
                        (rule) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(
                                child: Text(
                                  rule,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                BDCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Taunt', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text(
                        metadata.taunt,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (notice != null) ...[
                  BDCard(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      notice,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (error != null) ...[
                  BDCard(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      error,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (isExpired) ...[
                  BDCard(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'This public challenge has expired.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.orangeAccent),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Expires $dateText at $timeText',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                BDPrimaryButton(
                  label: attemptState.loading
                      ? 'Starting...'
                      : notice != null
                          ? 'Resume Challenge'
                          : 'Start Challenge',
                  isExpanded: true,
                  onPressed: attemptState.loading || isExpired
                      ? null
                      : () async {
                          final notifier = ref.read(challengeAttemptProvider.notifier);
                          final attempt = await notifier.startAttempt(challengeId);
                          if (attempt == null || !context.mounted) return;
                          notifier.loadAttempt(attempt);
                          context.goNamed(
                            TriviaApp.nameQuestionFlow,
                            pathParameters: {'challengeId': challengeId},
                            extra: attempt,
                          );
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
