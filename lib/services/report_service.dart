import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class ReportService {
  ReportService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get reportsRef {
    return _db.collection('reports');
  }

  static String? get currentUid => _auth.currentUser?.uid;

  static String get _currentUserName {
    final user = _auth.currentUser;
    final displayName = user?.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user?.email?.trim();

    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Ẩn danh';
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

  static Stream<QuerySnapshot<Map<String, dynamic>>> myReportsStream() {
    final uid = currentUid;

    if (uid == null) {
      throw Exception('User chưa đăng nhập');
    }

    return reportsRef
        .where('reporterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<String> createReport({
    required String targetType,
    required String targetId,
    required String reason,
    String targetOwnerId = '',
    String targetTitle = '',
    String targetPreview = '',
    String detail = '',
  }) async {
    final uid = currentUid;

    if (uid == null) {
      throw Exception('Bạn cần đăng nhập để gửi report.');
    }

    final cleanTargetType = targetType.trim();
    final cleanTargetId = targetId.trim();
    final cleanReason = reason.trim();
    final cleanDetail = detail.trim();

    if (cleanTargetType.isEmpty) {
      throw Exception('Thiếu loại nội dung cần report.');
    }

    if (cleanTargetId.isEmpty) {
      throw Exception('Thiếu ID nội dung cần report.');
    }

    if (cleanReason.isEmpty) {
      throw Exception('Vui lòng chọn lý do report.');
    }

    final existed = await reportsRef
        .where('reporterId', isEqualTo: uid)
        .where('targetType', isEqualTo: cleanTargetType)
        .where('targetId', isEqualTo: cleanTargetId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existed.docs.isNotEmpty) {
      return 'Bạn đã report nội dung này rồi. Admin sẽ xem xét sớm.';
    }

    final docRef = reportsRef.doc();

    await docRef.set({
      'id': docRef.id,
      'reporterId': uid,
      'reporterName': _currentUserName,
      'targetType': cleanTargetType,
      'targetId': cleanTargetId,
      'targetOwnerId': targetOwnerId.trim(),
      'targetTitle': targetTitle.trim(),
      'targetPreview': targetPreview.trim(),
      'reason': cleanReason,
      'detail': cleanDetail,
      'status': 'pending',
      'action': 'none',
      'adminNote': '',
      'handledBy': '',
      'handledAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return 'Đã gửi report. Admin sẽ xem xét nội dung này.';
  }

  static Future<String> reportUser({
    required UserProfile currentUser,
    required UserProfile targetUser,
    required String reason,
    String detail = '',
  }) async {
    return createReport(
      targetType: 'user',
      targetId: targetUser.id,
      targetOwnerId: targetUser.id,
      targetTitle: targetUser.nickname,
      targetPreview: targetUser.bio,
      reason: reason,
      detail: detail,
    );
  }

  static Future<String> reportConfession({
    required String confessionId,
    required String authorId,
    required String content,
    required String reason,
    String detail = '',
  }) async {
    return createReport(
      targetType: 'confession',
      targetId: confessionId,
      targetOwnerId: authorId,
      targetTitle: 'Confession',
      targetPreview: content,
      reason: reason,
      detail: detail,
    );
  }

  static Future<String> reportMarketPost({
    required String postId,
    required String sellerId,
    required String title,
    required String description,
    required String reason,
    String detail = '',
  }) async {
    return createReport(
      targetType: 'marketPost',
      targetId: postId,
      targetOwnerId: sellerId,
      targetTitle: title,
      targetPreview: description,
      reason: reason,
      detail: detail,
    );
  }

  static Future<String> reportMoment({
    required String momentId,
    required String authorId,
    required String text,
    required String reason,
    String detail = '',
  }) async {
    return createReport(
      targetType: 'moment',
      targetId: momentId,
      targetOwnerId: authorId,
      targetTitle: 'UniMoment',
      targetPreview: text,
      reason: reason,
      detail: detail,
    );
  }

  static Future<String> reportComment({
    required String commentId,
    required String authorId,
    required String content,
    required String reason,
    String detail = '',
  }) async {
    return createReport(
      targetType: 'comment',
      targetId: commentId,
      targetOwnerId: authorId,
      targetTitle: 'Bình luận',
      targetPreview: content,
      reason: reason,
      detail: detail,
    );
  }

  static Future<String> reportChatMessage({
    required String messageId,
    required String senderId,
    required String content,
    required String reason,
    String detail = '',
  }) async {
    return createReport(
      targetType: 'chatMessage',
      targetId: messageId,
      targetOwnerId: senderId,
      targetTitle: 'Tin nhắn chat',
      targetPreview: content,
      reason: reason,
      detail: detail,
    );
  }
}
