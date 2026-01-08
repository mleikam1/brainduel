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

class _StartupGateState extends ConsumerState<StartupGate> {
  String? _bootstrappedUid;
  Future<void>? _bootstrapFuture;

  Future<void> _ensureBootstrap(User user) {
    if (_bootstrappedUid != user.uid) {
      _bootstrappedUid = user.uid;
      _bootstrapFuture = ref.read(guestAuthServiceProvider).bootstrapUser(user);
      ref.read(authUserIdProvider.notifier).state = user.uid;
    }
    return _bootstrapFuture!;
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(guestAuthServiceProvider);
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StartupLoading();
        }
        final user = snapshot.data;
        if (user == null) {
          _bootstrappedUid = null;
          _bootstrapFuture = null;
          ref.read(authUserIdProvider.notifier).state = null;
          return const GuestEntryPage();
        }
        return FutureBuilder<void>(
          future: _ensureBootstrap(user),
          builder: (context, bootstrapSnapshot) {
            if (bootstrapSnapshot.connectionState == ConnectionState.waiting) {
              return const _StartupLoading();
            }
            if (bootstrapSnapshot.hasError) {
              return const _StartupError();
            }
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
