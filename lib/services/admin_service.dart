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

  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final uid = currentUid;
    if (uid == null) return null;

    final doc = await usersRef.doc(uid).get();
    return doc.data();
  }

  static Future<String> getCurrentRole() async {
    final data = await getCurrentUserData();
    return data?['role']?.toString() ?? 'student';
  }

  static Future<String> getCurrentStatus() async {
    final data = await getCurrentUserData();
    return data?['status']?.toString() ?? 'active';
  }

  static Future<bool> isCurrentUserBlocked() async {
    final status = await getCurrentStatus();
    return status == 'blocked';
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
    await _requireModeratorOrAdmin();

    final uid = currentUid!;
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
    await _requireModeratorOrAdmin();

    final uid = currentUid!;
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
    String targetType = '',
    String targetId = '',
    String adminNote = '',
  }) async {
    await _requireModeratorOrAdmin();

    final uid = currentUid!;

    final reportRef = reportsRef.doc(reportId);
    final reportSnap = await reportRef.get();

    if (!reportSnap.exists) {
      throw Exception('Report không tồn tại.');
    }

    final reportData = reportSnap.data() ?? {};

    // Hỗ trợ cả schema mới và schema cũ
    final fixedTargetType = targetType.trim().isNotEmpty
        ? targetType.trim()
        : (reportData['targetType'] ??
                  reportData['type'] ??
                  reportData['contentType'] ??
                  '')
              .toString()
              .trim();

    final fixedTargetId = targetId.trim().isNotEmpty
        ? targetId.trim()
        : (reportData['targetId'] ??
                  reportData['contentId'] ??
                  reportData['postId'] ??
                  '')
              .toString()
              .trim();

    if (fixedTargetType.isEmpty) {
      throw Exception(
        'Report thiếu targetType/type nên không biết ẩn loại nội dung nào.',
      );
    }

    if (fixedTargetId.isEmpty) {
      throw Exception(
        'Report thiếu targetId/contentId nên không biết ẩn bài nào.',
      );
    }

    final collectionName = getCollectionNameFromTargetType(fixedTargetType);

    if (collectionName == null) {
      throw Exception('Chưa hỗ trợ ẩn loại nội dung: $fixedTargetType');
    }

    final targetRef = _db.collection(collectionName).doc(fixedTargetId);
    final targetSnap = await targetRef.get();

    if (!targetSnap.exists) {
      await reportRef.update({
        'status': 'resolved',
        'action': 'target_not_found',
        'adminNote': adminNote.trim().isEmpty
            ? 'Không tìm thấy nội dung gốc để ẩn.'
            : adminNote.trim(),
        'handledBy': uid,
        'handledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      throw Exception(
        'Không tìm thấy nội dung gốc. Report đã được đánh dấu xử lý.',
      );
    }

    final batch = _db.batch();

    batch.update(targetRef, {
      'status': 'hidden',
      'isHidden': true,
      'hiddenBy': uid,
      'hiddenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(reportRef, {
      // chuẩn hóa lại schema report cũ luôn
      'targetType': fixedTargetType,
      'targetId': fixedTargetId,
      'status': 'resolved',
      'action': 'hidden_content',
      'adminNote': adminNote.trim(),
      'handledBy': uid,
      'handledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static Future<void> restoreContent({
    required String targetType,
    required String targetId,
  }) async {
    await _requireModeratorOrAdmin();

    final collectionName = getCollectionNameFromTargetType(targetType);

    if (collectionName == null) {
      throw Exception('Chưa hỗ trợ khôi phục targetType: $targetType');
    }

    await _db.collection(collectionName).doc(targetId).update({
      'status': 'active',
      'isHidden': false,
      'hiddenBy': '',
      'hiddenAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    final type = targetType.trim();

    switch (type) {
      case 'marketPost':
      case 'marketPosts':
      case 'market':
        return 'marketPosts';

      case 'confession':
      case 'confessions':
        return 'confessions';

      case 'moment':
      case 'moments':
      case 'uniMoment':
      case 'unimoment':
        return 'moments';

      case 'user':
      case 'users':
        return 'users';

      default:
        return null;
    }
  }

  static Future<Map<String, dynamic>?> getTargetContent({
    required String targetType,
    required String targetId,
  }) async {
    final collectionName = getCollectionNameFromTargetType(targetType);

    if (collectionName == null || targetId.trim().isEmpty) {
      return null;
    }

    final doc = await _db.collection(collectionName).doc(targetId).get();

    if (!doc.exists) {
      return null;
    }

    return {'id': doc.id, 'collection': collectionName, ...?doc.data()};
  }

  static Future<void> _requireModeratorOrAdmin() async {
    final allowed = await hasAdminAccess();

    if (!allowed) {
      throw Exception('Bạn không có quyền admin/moderator');
    }

    if (currentUid == null) {
      throw Exception('User chưa đăng nhập');
    }
  }
}
