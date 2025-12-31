import 'package:flutter/material.dart';
import '../models/home_challenge.dart';
import '../theme/brain_duel_theme.dart';
import 'bd_stat_pill.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onTap,
  });

  final HomeChallenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(BrainDuelRadii.md),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(BrainDuelRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boundedHeight = constraints.hasBoundedHeight;
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (challenge.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      challenge.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          challenge.badge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Chip(
                        label: Text(
                          challenge.timeRemaining,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      BDStatPill(label: 'Qs', value: '${challenge.questionCount}'),
                      BDStatPill(label: 'Pts', value: '${challenge.points}'),
                    ],
                  ),
                ],
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: BrainDuelColors.glacier.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.all(BrainDuelRadii.sm),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.bolt, size: 20, color: BrainDuelColors.glacier),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (boundedHeight)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: details,
                      ),
                    )
                  else
                    details,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
