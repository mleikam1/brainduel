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

class _StartupGateState extends ConsumerState<StartupGate> {
  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;
  String? _bootstrappedUid;
  Future<void>? _bootstrapFuture;
  Object? _bootstrapError;

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
      if (user == null) {
        _bootstrappedUid = null;
        _bootstrapFuture = null;
        _bootstrapError = null;
      }
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
      if (_bootstrappedUid == user.uid) {
        return;
      }
      _bootstrappedUid = user.uid;
      ref.read(userBootstrapReadyProvider.notifier).state = false;
      _bootstrapError = null;
      _bootstrapFuture = ref.read(guestAuthServiceProvider).bootstrapUser(user);
      ref.read(authUserIdProvider.notifier).state = user.uid;
      _bootstrapFuture!.catchError((error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _bootstrapError = error;
        });
        ref.read(userBootstrapReadyProvider.notifier).state = false;
      });
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    if (user == null) {
      return const GuestEntryPage();
    }
    if (_bootstrapError != null) {
      return const _StartupError();
    }
    final bootstrapFuture = _bootstrapFuture;
    if (bootstrapFuture == null) {
      return const _StartupLoading();
    }
    return FutureBuilder<void>(
      future: bootstrapFuture,
      builder: (context, bootstrapSnapshot) {
        if (bootstrapSnapshot.connectionState == ConnectionState.waiting) {
          return const _StartupLoading();
        }
        if (bootstrapSnapshot.hasError) {
          ref.read(userBootstrapReadyProvider.notifier).state = false;
          return const _StartupError();
        }
        ref.read(userBootstrapReadyProvider.notifier).state = true;
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
