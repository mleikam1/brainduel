import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService(FirebaseFirestore.instance);
});

class UserProfileService {
  UserProfileService(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<bool?> watchTopicsSelected(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) return null;
        final data = snapshot.data();
        return data?['topicsSelected'] as bool?;
      },
    );
  }

  Future<void> markTopicsSelected(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'topicsSelected': true,
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }
}
