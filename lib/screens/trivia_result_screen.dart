import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/challenge_result.dart';
import '../models/leaderboard_entry.dart';
import '../models/solo_pack_leaderboard.dart';
import '../state/challenge_providers.dart';
import '../state/share_providers.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_avatar.dart';
import '../widgets/bd_buttons.dart';
import '../widgets/bd_card.dart';
import '../widgets/bd_stat_pill.dart';
import '../widgets/score_summary.dart';

class TriviaResultScreen extends ConsumerWidget {
  const TriviaResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?)?.cast<String, dynamic>() ?? {};
    final challengeResult = args['challengeResult'] as ChallengeResult?;
    if (challengeResult != null) {
      return ChallengeResultView(result: challengeResult);
    }
    final categoryId = (args['categoryId'] as String?) ?? 'sports';
    final correct = (args['correct'] as int?) ?? 0;
    final total = (args['total'] as int?) ?? 0;
    final points = (args['points'] as int?) ?? (correct * 100);
    final startedAt = DateTime.tryParse(args['startedAt'] as String? ?? '');
    final timeTaken = startedAt == null ? const Duration(seconds: 0) : DateTime.now().difference(startedAt);
    final triviaPackId = args['triviaPackId'] as String?;
    final leaderboardJson = args['leaderboard'] as Map?;
    final leaderboard = leaderboardJson == null
        ? null
        : SoloPackLeaderboard.fromJson(Map<String, dynamic>.from(leaderboardJson));

    final List<LeaderboardEntry> participants;
    if (leaderboard == null) {
      participants = [
        LeaderboardEntry(name: 'You', points: points, time: timeTaken, rank: 2),
        const LeaderboardEntry(
          name: 'Renata M.',
          points: 1840,
          time: Duration(minutes: 1, seconds: 12),
          rank: 1,
        ),
        const LeaderboardEntry(
          name: 'Mike S.',
          points: 1650,
          time: Duration(minutes: 1, seconds: 26),
          rank: 3,
        ),
        const LeaderboardEntry(
          name: 'John M.',
          points: 1240,
          time: Duration(minutes: 1, seconds: 45),
          rank: 4,
        ),
        const LeaderboardEntry(
          name: 'Dinny K.',
          points: 1180,
          time: Duration(minutes: 1, seconds: 54),
          rank: 5,
        ),
      ];
    } else {
      participants = leaderboard.entries.map((entry) {
        final isYou = entry.rank == leaderboard.userRank;
        final duration = Duration(seconds: entry.durationSeconds ?? 0);
        return LeaderboardEntry(
          name: isYou ? 'You' : 'Player ${entry.rank}',
          points: entry.score,
          time: duration,
          rank: entry.rank,
        );
      }).toList();
    }
    participants.sort((a, b) => a.rank.compareTo(b.rank));

    return BDAppScaffold(
      title: 'Scoreboard',
      child: Padding(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScoreSummary(correct: correct, total: total, points: points, timeTaken: timeTaken),
                    const SizedBox(height: 16),
                    Text('Top Rankings', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: participants.take(3).map((entry) {
                        final columns = constraints.maxWidth < 420 ? 2 : 3;
                        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
                        return SizedBox(
                          width: width,
                          child: BDCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                BDAvatar(name: entry.name, radius: 18),
                                const SizedBox(height: 8),
                                Text(
                                  '#${entry.rank}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(entry.name, style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text('${entry.points} pts', style: Theme.of(context).textTheme.labelLarge),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    ...participants.map((entry) {
                      final minutes = entry.time.inMinutes;
                      final seconds = entry.time.inSeconds.remainder(60);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BDCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Text('#${entry.rank}', style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(width: 12),
                              BDAvatar(name: entry.name, radius: 18),
                              const SizedBox(width: 12),
                              Expanded(child: Text(entry.name, style: Theme.of(context).textTheme.bodyLarge)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${entry.points} pts', style: Theme.of(context).textTheme.bodyLarge),
                                  Text('${minutes}m ${seconds}s', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    BDPrimaryButton(
                      label: 'Share Results',
                      icon: Icons.share,
                      isExpanded: true,
                      onPressed: triviaPackId == null || triviaPackId.isEmpty
                          ? null
                          : () => ref.read(shareServiceProvider).shareTriviaPack(
                                context: context,
                                triviaPackId: triviaPackId,
                                topicId: categoryId,
                                score: points,
                              ),
                    ),
                    const SizedBox(height: 10),
                    BDSecondaryButton(
                      label: 'Play Again',
                      isExpanded: true,
                      onPressed: () => context.goNamed(
                        TriviaApp.nameGame,
                        extra: categoryId,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.goNamed(TriviaApp.nameCategories),
                      child: const Text('Back to Categories'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChallengeResultView extends ConsumerStatefulWidget {
  const ChallengeResultView({super.key, required this.result});

  final ChallengeResult result;

  @override
  ConsumerState<ChallengeResultView> createState() => _ChallengeResultViewState();
}

class _ChallengeResultViewState extends ConsumerState<ChallengeResultView> with TickerProviderStateMixin {
  late final AnimationController _pointsController;
  late final AnimationController _percentileController;
  late final Animation<int> _pointsAnimation;
  late final Animation<double> _percentileAnimation;
  bool _percentileReady = false;
  bool get _hasPercentile => widget.result.percentile >= 0;

  @override
  void initState() {
    super.initState();
    _pointsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _pointsAnimation = IntTween(begin: 0, end: widget.result.points).animate(
      CurvedAnimation(parent: _pointsController, curve: Curves.easeOutCubic),
    );

    _percentileController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _percentileAnimation = Tween<double>(begin: 0, end: widget.result.percentile).animate(
      CurvedAnimation(parent: _percentileController, curve: Curves.easeOutCubic),
    );

    if (_hasPercentile) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() => _percentileReady = true);
        _percentileController.forward();
      });
    }
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _percentileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = widget.result.completionTime.inMinutes;
    final seconds = widget.result.completionTime.inSeconds.remainder(60);
    final rankDelta = widget.result.rankDelta;
    final metadataAsync = ref.watch(challengeMetadataProvider(widget.result.challengeId));
    final rematchState = ref.watch(rematchProvider(widget.result.challengeId));

    return BDAppScaffold(
      title: 'Results',
      child: Padding(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BDCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Challenge Score', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _pointsAnimation,
                    builder: (context, _) => Text(
                      '${_pointsAnimation.value} pts',
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Completed in ${minutes}m ${seconds}s'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      BDStatPill(
                        label: 'Rank',
                        value: '#${widget.result.rank}',
                        icon: Icons.emoji_events,
                      ),
                      BDStatPill(
                        label: 'Delta',
                        value: _deltaLabel(rankDelta),
                        icon: _deltaIcon(rankDelta),
                      ),
                      AnimatedBuilder(
                        animation: _percentileAnimation,
                        builder: (context, _) => BDStatPill(
                          label: 'Percentile',
                          value: _hasPercentile && _percentileReady
                              ? '${_percentileAnimation.value.toStringAsFixed(1)}%'
                              : 'Forming...',
                          icon: Icons.percent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Friends Rank', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: widget.result.friends.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = widget.result.friends[index];
                  return BDCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Text('#${entry.rank}', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(width: 12),
                        BDAvatar(name: entry.name, radius: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.name, style: Theme.of(context).textTheme.bodyLarge)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${entry.points} pts', style: Theme.of(context).textTheme.bodyLarge),
                            Row(
                              children: [
                                Icon(_deltaIcon(entry.delta), size: 16),
                                const SizedBox(width: 4),
                                Text(_deltaLabel(entry.delta), style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            BDPrimaryButton(
              label: 'Share Results',
              icon: Icons.share,
              isExpanded: true,
              onPressed: metadataAsync.when(
                data: (metadata) => () => ref.read(shareServiceProvider).shareChallengeResult(
                      context: context,
                      result: widget.result,
                      metadata: metadata,
                    ),
                loading: () => null,
                error: (_, __) => () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to load share details.')),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _RematchPanel(
              state: rematchState,
              challengeId: widget.result.challengeId,
            ),
            const SizedBox(height: 10),
            BDSecondaryButton(
              label: 'Back to Home',
              isExpanded: true,
              onPressed: () => context.goNamed(TriviaApp.nameHome),
            ),
          ],
        ),
      ),
    );
  }
}

String _deltaLabel(int delta) {
  if (delta == 0) return '0';
  final sign = delta > 0 ? '+' : '';
  return '$sign$delta';
}

IconData _deltaIcon(int delta) {
  if (delta == 0) return Icons.remove;
  return delta > 0 ? Icons.arrow_upward : Icons.arrow_downward;
}

class _RematchPanel extends ConsumerWidget {
  const _RematchPanel({required this.state, required this.challengeId});

  final RematchState state;
  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(rematchProvider(challengeId).notifier);
    final request = state.request;
    final challengerAccepted = request?.challengerAccepted ?? false;
    final opponentAccepted = request?.opponentAccepted ?? false;
    final isReady = state.status == RematchStatus.ready;

    return BDCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Rematch', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Both players must accept to start a fresh challenge.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (state.status == RematchStatus.idle) ...[
            BDPrimaryButton(
              label: 'Request Rematch',
              isExpanded: true,
              onPressed: notifier.requestRematch,
            ),
          ] else if (state.status == RematchStatus.requesting) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (state.status == RematchStatus.error) ...[
            Text(
              state.error ?? 'Unable to start a rematch.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            BDSecondaryButton(
              label: 'Try Again',
              isExpanded: true,
              onPressed: notifier.requestRematch,
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  challengerAccepted ? Icons.check_circle : Icons.hourglass_bottom,
                  color: challengerAccepted ? Colors.green : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('You')),
                Text(challengerAccepted ? 'Accepted' : 'Pending'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  opponentAccepted ? Icons.check_circle : Icons.hourglass_bottom,
                  color: opponentAccepted ? Colors.green : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('Opponent')),
                Text(opponentAccepted ? 'Accepted' : 'Pending'),
              ],
            ),
            const SizedBox(height: 12),
            if (!opponentAccepted)
              BDSecondaryButton(
                label: 'Simulate Opponent Accept',
                isExpanded: true,
                onPressed: notifier.acceptForOpponent,
              ),
            if (isReady) ...[
              const SizedBox(height: 8),
              BDPrimaryButton(
                label: 'Start Rematch',
                isExpanded: true,
                onPressed: () {
                  final rematchId = notifier.consumeReadyRematchId();
                  if (rematchId == null) return;
                  context.goNamed(
                    TriviaApp.nameChallengeIntro,
                    pathParameters: {'challengeId': rematchId},
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}
