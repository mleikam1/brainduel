import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/guest_auth_service.dart';
import 'auth_provider.dart';

class GuestAuthState {
  const GuestAuthState({
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;

  GuestAuthState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return GuestAuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class GuestAuthController extends StateNotifier<GuestAuthState> {
  GuestAuthController(this._authService, this._ref)
      : super(const GuestAuthState());

  final GuestAuthService _authService;
  final Ref _ref;

  Future<bool> bootstrap() async {
    final user = _authService.currentUser;
    if (user == null) {
      return false;
    }
    await _authService.bootstrapUser(user);
    _ref.read(authUserIdProvider.notifier).state = user.uid;
    return true;
  }

  Future<bool> signInAsGuest() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authService.signInAnonymously();
      _ref.read(authUserIdProvider.notifier).state = user.uid;
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign-in failed. Please try again.',
      );
      return false;
    }
  }
}

final guestAuthControllerProvider =
    StateNotifierProvider<GuestAuthController, GuestAuthState>((ref) {
  return GuestAuthController(ref.read(guestAuthServiceProvider), ref);
});
