import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/categories_provider.dart';
import '../widgets/app_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
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
          const Card(
            child: ListTile(
              title: Text('Privacy Policy'),
              subtitle: Text('Add your policy link later.'),
            ),
          ),
          const Card(
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
