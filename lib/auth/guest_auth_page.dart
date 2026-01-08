import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../state/guest_auth_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_buttons.dart';

class GuestAuthPage extends ConsumerStatefulWidget {
  const GuestAuthPage({super.key});

  @override
  ConsumerState<GuestAuthPage> createState() => _GuestAuthPageState();
}

class _GuestAuthPageState extends ConsumerState<GuestAuthPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final shouldSkip = await ref.read(guestAuthControllerProvider.notifier).bootstrap();
    if (shouldSkip && mounted) {
      context.goNamed(TriviaApp.nameHome);
    }
  }

  Future<void> _handleGuestSignIn() async {
    final success = await ref.read(guestAuthControllerProvider.notifier).signInAsGuest();
    if (success && mounted) {
      context.goNamed(TriviaApp.nameHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestAuthControllerProvider);

    return BDAppScaffold(
      title: 'Welcome',
      child: Padding(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome to Brain Battle',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Jump into quick trivia battles as a guest. You can sign up later.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            BDPrimaryButton(
              label: state.isLoading ? 'Signing In...' : 'Continue as Guest',
              isExpanded: true,
              onPressed: state.isLoading ? null : _handleGuestSignIn,
            ),
          ],
        ),
      ),
    );
  }
}
