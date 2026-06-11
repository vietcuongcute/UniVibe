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

  static const List<String> validUserStatus = ['active', 'blocked'];

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

    final role = data?['role']?.toString().trim();

    if (role == null || role.isEmpty) {
      return 'student';
    }

    return role;
  }

  static Future<bool> hasAdminAccess() async {
    final role = await getCurrentRole();
    return role == 'admin' || role == 'moderator';
  }

  static Future<bool> isAdmin() async {
    final role = await getCurrentRole();
    return role == 'admin';
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> reportsStream({
    String status = 'all',
  }) {
    Query<Map<String, dynamic>> query = reportsRef;

    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() {
    return usersRef.orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> resolveReport({
    required String reportId,
    String adminNote = '',
  }) async {
    await _requireAdminOrModerator();

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
    await _requireAdminOrModerator();

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
    await _requireAdminOrModerator();

    final uid = currentUid;

    if (uid == null) {
      throw Exception('User chưa đăng nhập');
    }

    final cleanTargetType = targetType.trim();
    final cleanTargetId = targetId.trim();

    if (cleanTargetId.isEmpty) {
      throw Exception('Thiếu targetId');
    }

    if (cleanTargetType == 'user' || cleanTargetType == 'users') {
      await blockReportedUser(
        reportId: reportId,
        userId: cleanTargetId,
        adminNote: adminNote,
      );
      return;
    }

    final collectionName = getCollectionNameFromTargetType(cleanTargetType);

    if (collectionName == null) {
      throw Exception('Chưa hỗ trợ ẩn loại nội dung: $targetType');
    }

    final batch = _db.batch();

    final targetRef = _db.collection(collectionName).doc(cleanTargetId);
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

  static Future<void> restoreReportedContent({
    required String reportId,
    required String targetType,
    required String targetId,
    String adminNote = '',
  }) async {
    await _requireAdminOrModerator();

    final uid = currentUid;

    if (uid == null) {
      throw Exception('User chưa đăng nhập');
    }

    final cleanTargetType = targetType.trim();
    final cleanTargetId = targetId.trim();

    if (cleanTargetId.isEmpty) {
      throw Exception('Thiếu targetId');
    }

    if (cleanTargetType == 'user' || cleanTargetType == 'users') {
      final batch = _db.batch();

      batch.update(usersRef.doc(cleanTargetId), {
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(reportsRef.doc(reportId), {
        'status': 'resolved',
        'action': 'restored_user',
        'adminNote': adminNote.trim(),
        'handledBy': uid,
        'handledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return;
    }

    final collectionName = getCollectionNameFromTargetType(cleanTargetType);

    if (collectionName == null) {
      throw Exception('Chưa hỗ trợ khôi phục loại nội dung: $targetType');
    }

    final batch = _db.batch();

    batch.update(_db.collection(collectionName).doc(cleanTargetId), {
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(reportsRef.doc(reportId), {
      'status': 'resolved',
      'action': 'restored_content',
      'adminNote': adminNote.trim(),
      'handledBy': uid,
      'handledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static Future<void> blockReportedUser({
    required String reportId,
    required String userId,
    String adminNote = '',
  }) async {
    await _requireAdminOrModerator();

    final uid = currentUid;

    if (uid == null) {
      throw Exception('User chưa đăng nhập');
    }

    if (userId.trim().isEmpty) {
      throw Exception('Thiếu userId');
    }

    final batch = _db.batch();

    batch.update(usersRef.doc(userId.trim()), {
      'status': 'blocked',
      'blockedBy': uid,
      'blockedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(reportsRef.doc(reportId), {
      'status': 'resolved',
      'action': 'blocked_user',
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

    final cleanRole = role.trim();

    if (!validRoles.contains(cleanRole)) {
      throw Exception('Role không hợp lệ');
    }

    await usersRef.doc(userId).update({
      'role': cleanRole,
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

    final cleanStatus = status.trim();

    if (!validUserStatus.contains(cleanStatus)) {
      throw Exception('Status không hợp lệ');
    }

    await usersRef.doc(userId).update({
      'status': cleanStatus,
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

      default:
        return null;
    }
  }

  static Future<void> _requireAdminOrModerator() async {
    final allowed = await hasAdminAccess();

    if (!allowed) {
      throw Exception('Bạn không có quyền xử lý report');
    }
  }
}
