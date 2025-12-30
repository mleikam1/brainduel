import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/categories_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BDAppScaffold(
      title: 'Settings',
      subtitle: 'Preferences & privacy',
      child: ListView(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        children: [
          BDCard(
            child: ListTile(
              title: const Text('Clear Cached Content'),
              subtitle: const Text('Clears the local in-memory cache (demo).'),
              onTap: () async {
                await ref.read(contentCacheServiceProvider).clearAllCachedContent();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          const BDCard(
            child: ListTile(
              title: Text('Privacy Policy'),
              subtitle: Text('Add your policy link later.'),
            ),
          ),
          const SizedBox(height: 10),
          const BDCard(
            child: ListTile(
              title: Text('Terms of Service'),
              subtitle: Text('Add your terms link later.'),
            ),
          ),
        ],
      ),
    );
  }
}
