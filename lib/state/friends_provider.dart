import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_profile.dart';
import '../services/contacts_service.dart';
import '../services/friends_service.dart';

final friendsServiceProvider = Provider<FriendsService>((ref) {
  return FriendsService();
});

final contactsServiceProvider = Provider<ContactsService>((ref) {
  return ContactsService();
});

final followLinkProvider = FutureProvider.family<FriendProfile, String>((ref, code) {
  return ref.read(friendsServiceProvider).followByLink(code);
});

class ContactMatchState {
  const ContactMatchState({
    required this.optedIn,
    required this.loading,
    required this.matches,
    required this.lastHashCount,
    this.error,
  });

  final bool optedIn;
  final bool loading;
  final List<FriendProfile> matches;
  final int lastHashCount;
  final String? error;

  factory ContactMatchState.initial() => const ContactMatchState(
    optedIn: false,
    loading: false,
    matches: [],
    lastHashCount: 0,
    error: null,
  );

  ContactMatchState copyWith({
    bool? optedIn,
    bool? loading,
    List<FriendProfile>? matches,
    int? lastHashCount,
    String? error,
  }) {
    return ContactMatchState(
      optedIn: optedIn ?? this.optedIn,
      loading: loading ?? this.loading,
      matches: matches ?? this.matches,
      lastHashCount: lastHashCount ?? this.lastHashCount,
      error: error,
    );
  }
}

final contactMatchProvider =
StateNotifierProvider<ContactMatchNotifier, ContactMatchState>((ref) {
  return ContactMatchNotifier(ref);
});

class ContactMatchNotifier extends StateNotifier<ContactMatchState> {
  ContactMatchNotifier(this.ref) : super(ContactMatchState.initial());

  final Ref ref;

  Future<void> enableAndMatch() async {
    if (state.loading) return;
    state = state.copyWith(optedIn: true, loading: true, error: null);
    try {
      final contacts = await ref.read(contactsServiceProvider).loadPhoneNumbers();
      final hashes = ref.read(friendsServiceProvider).hashPhoneNumbers(contacts);
      final matches = await ref.read(friendsServiceProvider).matchContacts(hashes);
      state = state.copyWith(
        loading: false,
        matches: matches,
        lastHashCount: hashes.length,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
        matches: const [],
        lastHashCount: 0,
      );
    }
  }

  void disable() {
    state = ContactMatchState.initial();
  }
}
