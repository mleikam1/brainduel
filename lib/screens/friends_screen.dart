import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/friends_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_avatar.dart';
import '../widgets/bd_card.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(contactMatchProvider);
    final notifier = ref.read(contactMatchProvider.notifier);

    return BDAppScaffold(
      title: 'Friends',
      subtitle: 'Follow links and find contacts',
      child: ListView(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        children: [
          BDCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Follow by link', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Open a Brain Duel follow link to add a friend instantly.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Example: brainduel.app/f/your-code',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BDCard(
            child: SwitchListTile(
              title: const Text('Match contacts'),
              subtitle: const Text('Opt in to hash contacts on device and find friends.'),
              value: matchState.optedIn,
              onChanged: matchState.loading
                  ? null
                  : (value) {
                if (value) {
                  notifier.enableAndMatch();
                } else {
                  notifier.disable();
                }
              },
            ),
          ),
          if (matchState.loading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (matchState.optedIn && !matchState.loading) ...[
            const SizedBox(height: 12),
            Text(
              'Hashed ${matchState.lastHashCount} contacts on device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (matchState.error != null) ...[
            const SizedBox(height: 12),
            BDCard(
              padding: const EdgeInsets.all(12),
              child: Text('Unable to match contacts: ${matchState.error}'),
            ),
          ],
          if (matchState.matches.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Matches', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...matchState.matches.map(
              (friend) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BDCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      BDAvatar(name: friend.displayName, radius: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(friend.displayName, style: Theme.of(context).textTheme.titleSmall),
                            if (friend.handle.isNotEmpty)
                              Text('@${friend.handle}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
