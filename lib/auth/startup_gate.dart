import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/bottom_nav_shell.dart';
import '../screens/topic_select_screen.dart';
import '../services/guest_auth_service.dart';
import '../services/user_profile_service.dart';
import '../state/auth_provider.dart';
import 'guest_entry_page.dart';

class StartupGate extends ConsumerStatefulWidget {
  const StartupGate({super.key});

  @override
  ConsumerState<StartupGate> createState() => _StartupGateState();
}

final bootstrapUserProvider = FutureProvider.autoDispose.family<void, User>(
  (ref, user) async {
    await ref.read(guestAuthServiceProvider).bootstrapUser(user);
  },
);

class _StartupGateState extends ConsumerState<StartupGate> {
  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    final authService = ref.read(guestAuthServiceProvider);
    _authSubscription = authService.authStateChanges.listen(_handleAuthChange);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _handleAuthChange(User? user) {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUser = user;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (user == null) {
        ref.read(authUserIdProvider.notifier).state = null;
        ref.read(userBootstrapReadyProvider.notifier).state = false;
        return;
      }
      ref.read(authUserIdProvider.notifier).state = user.uid;
      ref.read(userBootstrapReadyProvider.notifier).state = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    if (user == null) {
      return const GuestEntryPage();
    }
    // IMPORTANT: Provider mutations must not occur during build.
    ref.listen<AsyncValue<void>>(bootstrapUserProvider(user), (previous, next) {
      if (next is AsyncData<void>) {
        ref.read(userBootstrapReadyProvider.notifier).state = true;
      } else if (next is AsyncError<void>) {
        ref.read(userBootstrapReadyProvider.notifier).state = false;
      }
    });
    final bootstrapState = ref.watch(bootstrapUserProvider(user));
    return bootstrapState.when(
      loading: () => const _StartupLoading(),
      error: (_, __) => const _StartupError(),
      data: (_) {
        final profileService = ref.watch(userProfileServiceProvider);
        return StreamBuilder<bool?>(
          stream: profileService.watchTopicsSelected(user.uid),
          builder: (context, topicsSnapshot) {
            if (topicsSnapshot.connectionState == ConnectionState.waiting) {
              return const _StartupLoading();
            }
            final topicsSelected = topicsSnapshot.data ?? false;
            if (!topicsSelected) {
              return const TopicSelectScreen();
            }
            return const BottomNavShell();
          },
        );
      },
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Unable to start Brain Battle. Please retry.')),
    );
  }
}
