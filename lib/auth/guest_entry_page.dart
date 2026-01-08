import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../state/guest_auth_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_buttons.dart';

class GuestEntryPage extends ConsumerStatefulWidget {
  const GuestEntryPage({super.key});

  @override
  ConsumerState<GuestEntryPage> createState() => _GuestEntryPageState();
}

class _GuestEntryPageState extends ConsumerState<GuestEntryPage> {
  Future<void> _handleGuestSignIn() async {
    final success = await ref.read(guestAuthControllerProvider.notifier).signInAsGuest();
    if (success && mounted) {
      context.goNamed(TriviaApp.nameTopicSelect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestAuthControllerProvider);

    return BDAppScaffold(
      title: 'Brain Battle',
      subtitle: 'Play instantly. No account required.',
      child: Padding(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.errorMessage != null) ...[
              Text(
                state.errorMessage!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            const Spacer(),
            BDPrimaryButton(
              label: state.isLoading ? 'Starting...' : 'Play as Guest',
              isExpanded: true,
              onPressed: state.isLoading ? null : _handleGuestSignIn,
            ),
          ],
        ),
      ),
    );
  }
}
