import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_progress.dart';

final categoryProgressServiceProvider = Provider<CategoryProgressService>((ref) {
  return CategoryProgressService(FirebaseFirestore.instance);
});

class CategoryProgressService {
  CategoryProgressService(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<Map<String, CategoryProgress>> watchProgress(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('categoryProgress')
        .snapshots()
        .map((snapshot) {
      final progressByCategory = <String, CategoryProgress>{};
      for (final doc in snapshot.docs) {
        progressByCategory[doc.id] = CategoryProgress.fromJson(doc.data());
      }
      return progressByCategory;
    });
  }
}
