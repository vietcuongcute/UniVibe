import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  AdminService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<String> validRoles = [
    'student',
    'moderator',
    'clubLeader',
    'eventManager',
    'admin',
  ];

  static String? get currentUid => _auth.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> get usersRef {
    return _db.collection('users');
  }

  static CollectionReference<Map<String, dynamic>> get reportsRef {
    return _db.collection('reports');
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> currentUserStream() {
    final uid = currentUid;

    if (uid == null) {
      throw Exception('User chưa đăng nhập');
    }

    return usersRef.doc(uid).snapshots();
  }

  static Future<String> getCurrentRole() async {
    final uid = currentUid;

    if (uid == null) {
      return 'student';
    }

    final doc = await usersRef.doc(uid).get();
    final data = doc.data();

    return data?['role']?.toString() ?? 'student';
  }

  static Future<bool> hasAdminAccess() async {
    final role = await getCurrentRole();

    return role == 'admin' || role == 'moderator';
  }

  static Future<bool> isAdmin() async {
    final role = await getCurrentRole();

    return role == 'admin';
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> reportsStream() {
    return reportsRef.orderBy('createdAt', descending: true).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() {
    return usersRef.orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> resolveReport({
    required String reportId,
    String adminNote = '',
  }) async {
    final allowed = await hasAdminAccess();

    if (!allowed) {
      throw Exception('Bạn không có quyền xử lý report');
    }

    final uid = currentUid;

    if (uid == null) {
      throw Exception('User chưa đăng nhập');
    }

    await reportsRef.doc(reportId).update({
      'status': 'resolved',
      'action': 'resolved',
      'adminNote': adminNote.trim(),
      'handledBy': uid,
      'handledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> rejectReport({
    required String reportId,
    String adminNote = '',
  }) async {
    final allowed = await hasAdminAccess();

    if (!allowed) {
      throw Exception('Bạn không có quyền xử lý report');
    }

    final uid = currentUid;

    if (uid == null) {
      throw Exception('User chưa đăng nhập');
    }

    await reportsRef.doc(reportId).update({
      'status': 'rejected',
      'action': 'rejected',
      'adminNote': adminNote.trim(),
      'handledBy': uid,
      'handledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> hideReportedContent({
    required String reportId,
    required String targetType,
    required String targetId,
    String adminNote = '',
  }) async {
    final allowed = await hasAdminAccess();

    if (!allowed) {
      throw Exception('Bạn không có quyền ẩn nội dung');
    }

    final uid = currentUid;

    if (uid == null) {
      throw Exception('User chưa đăng nhập');
    }

    final collectionName = getCollectionNameFromTargetType(targetType);

    if (collectionName == null) {
      throw Exception('Chưa hỗ trợ ẩn targetType: $targetType');
    }

    if (targetId.trim().isEmpty) {
      throw Exception('Thiếu targetId');
    }

    final batch = _db.batch();

    final targetRef = _db.collection(collectionName).doc(targetId);
    final reportRef = reportsRef.doc(reportId);

    batch.update(targetRef, {
      'status': 'hidden',
      'hiddenBy': uid,
      'hiddenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(reportRef, {
      'status': 'resolved',
      'action': 'hidden_content',
      'adminNote': adminNote.trim(),
      'handledBy': uid,
      'handledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    final admin = await isAdmin();

    if (!admin) {
      throw Exception('Chỉ admin mới được gán role');
    }

    if (!validRoles.contains(role)) {
      throw Exception('Role không hợp lệ');
    }

    await usersRef.doc(userId).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    final admin = await isAdmin();

    if (!admin) {
      throw Exception('Chỉ admin mới được khóa/mở khóa user');
    }

    if (!['active', 'blocked'].contains(status)) {
      throw Exception('Status không hợp lệ');
    }

    await usersRef.doc(userId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static String? getCollectionNameFromTargetType(String targetType) {
    switch (targetType) {
      case 'marketPost':
      case 'marketPosts':
        return 'marketPosts';

      case 'confession':
      case 'confessions':
        return 'confessions';

      case 'moment':
      case 'moments':
        return 'moments';

      case 'comment':
      case 'comments':
        return 'comments';

      case 'user':
      case 'users':
        return 'users';

      default:
        return null;
    }
  }
}
