import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final guestAuthServiceProvider = Provider<GuestAuthService>((ref) {
  return GuestAuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

class GuestAuthService {
  GuestAuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> bootstrapUser(User user) async {
    await ensureUserDocument(user);
    await updateLastActive(user.uid);
  }

  Future<User> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Anonymous sign-in failed.');
    }
    debugPrint('[auth] anonymous uid=${user.uid}');
    await ensureUserDocument(user);
    await updateLastActive(user.uid);
    return user;
  }

  Future<void> ensureUserDocument(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'isAnonymous': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'tier': 'rookie',
        'totalXp': 0,
        'topicsSelected': false,
      });
      debugPrint('[auth] created user document for ${user.uid}');
    }
  }

  Future<void> updateLastActive(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);
    await docRef.update({'lastActiveAt': FieldValue.serverTimestamp()});
    debugPrint('[auth] updated lastActiveAt for $uid');
  }
}
