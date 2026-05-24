import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _users {
    return _db.collection('users');
  }

  static Future<void> createProfile({
    required String nickname,
    required String university,
    required String major,
    required int year,
    required String gender,
    required String bio,
    required List<String> interests,
    required List<String> goals,
    required List<String> vibeTags,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User chưa đăng nhập');
    }

    await _users.doc(user.uid).set({
      'id': user.uid,
      'email': user.email,
      'nickname': nickname.trim(),
      'avatarUrl': '',
      'university': university.trim(),
      'major': major.trim(),
      'year': year,
      'gender': gender,
      'bio': bio.trim(),
      'interests': interests,
      'goals': goals,
      'vibeTags': vibeTags,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<bool> hasProfile() async {
    final user = _auth.currentUser;

    if (user == null) return false;

    final doc = await _users.doc(user.uid).get();

    return doc.exists;
  }

  static Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc = await _users.doc(user.uid).get();
    final data = doc.data();

    if (data == null) return null;

    return UserProfile.fromMap(data);
  }

  static Future<List<UserProfile>> getAllUsers() async {
    final snapshot = await _users.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return UserProfile.fromMap({...data, 'id': data['id'] ?? doc.id});
    }).toList();
  }

  static Future<List<UserProfile>> getOtherUsers() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User chưa đăng nhập');
    }

    final users = await getAllUsers();

    return users.where((user) => user.id != currentUser.uid).toList();
  }

  static Future<void> updateProfile({
    required Map<String, dynamic> data,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User chưa đăng nhập');
    }

    await _users.doc(user.uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
