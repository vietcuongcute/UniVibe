import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/club.dart';

class ClubService {
  ClubService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _clubsRef {
    return _db.collection('clubs');
  }

  static Stream<List<UniClub>> clubsStream() {
    return _clubsRef
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(UniClub.fromDoc).toList();
        });
  }

  static Future<void> createClub({
    required String name,
    required String description,
    required String category,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    if (name.trim().isEmpty) {
      throw Exception('Vui lòng nhập tên CLB.');
    }

    final now = FieldValue.serverTimestamp();
    final clubRef = _clubsRef.doc();

    await clubRef.set({
      'id': clubRef.id,
      'name': name.trim(),
      'description': description.trim(),
      'leaderId': user.uid,
      'category': category.trim().isEmpty ? 'Khác' : category.trim(),
      'status': 'active',
      'memberIds': [user.uid],
      'createdAt': now,
      'updatedAt': now,
    });
  }

  static Future<void> joinClub(String clubId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    await _clubsRef.doc(clubId).update({
      'memberIds': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> leaveClub(String clubId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    await _clubsRef.doc(clubId).update({
      'memberIds': FieldValue.arrayRemove([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
