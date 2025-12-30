import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../state/friends_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_avatar.dart';
import '../widgets/bd_buttons.dart';
import '../widgets/bd_card.dart';

class FollowLinkScreen extends ConsumerWidget {
  const FollowLinkScreen({super.key, required this.followCode});

  final String followCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followAsync = ref.watch(followLinkProvider(followCode));

    return BDAppScaffold(
      title: 'Following',
      subtitle: 'Confirming friend link',
      child: Padding(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        child: followAsync.when(
          data: (friend) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BDCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    BDAvatar(name: friend.displayName, radius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(friend.displayName, style: Theme.of(context).textTheme.titleMedium),
                          if (friend.handle.isNotEmpty)
                            Text('@${friend.handle}', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          const Text('You are now following each other.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BDPrimaryButton(
                label: 'Back to Home',
                isExpanded: true,
                onPressed: () => context.goNamed(TriviaApp.nameHome),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BDCard(
                padding: const EdgeInsets.all(16),
                child: Text('Unable to follow link: $error'),
              ),
              const SizedBox(height: 12),
              BDPrimaryButton(
                label: 'Try Again',
                isExpanded: true,
                onPressed: () => ref.refresh(followLinkProvider(followCode)),
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
      ),
    );
  }
}
