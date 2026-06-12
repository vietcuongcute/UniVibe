import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UniReport {
  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String targetOwnerId;
  final String reason;
  final String detail;
  final String status;
  final String action;
  final String adminNote;
  final String handledBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? handledAt;

  const UniReport({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.targetOwnerId,
    required this.reason,
    required this.detail,
    required this.status,
    required this.action,
    required this.adminNote,
    required this.handledBy,
    required this.createdAt,
    required this.updatedAt,
    this.handledAt,
  });

  factory UniReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return UniReport(
      id: doc.id,
      reporterId: data['reporterId']?.toString() ?? '',
      targetType:
          data['targetType']?.toString() ??
          data['type']?.toString() ??
          'unknown',
      targetId:
          data['targetId']?.toString() ?? data['contentId']?.toString() ?? '',
      targetOwnerId: data['targetOwnerId']?.toString() ?? '',
      reason: data['reason']?.toString() ?? '',
      detail:
          data['detail']?.toString() ?? data['description']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      action: data['action']?.toString() ?? 'none',
      adminNote: data['adminNote']?.toString() ?? '',
      handledBy: data['handledBy']?.toString() ?? '',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      handledAt: _parseNullableDate(data['handledAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class ReportService {
  ReportService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _reportsRef {
    return _db.collection('reports');
  }

  static Future<String> createReport({
    required String targetType,
    required String targetId,
    required String reason,
    String targetOwnerId = '',
    String detail = '',
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    if (targetType.trim().isEmpty || targetId.trim().isEmpty) {
      return 'Thiếu thông tin nội dung cần report.';
    }

    if (reason.trim().isEmpty) {
      return 'Vui lòng chọn lý do report.';
    }

    if (targetOwnerId.trim().isNotEmpty && targetOwnerId == user.uid) {
      return 'Bạn không thể report nội dung của chính mình.';
    }

    try {
      final reportRef = _reportsRef.doc();
      final now = FieldValue.serverTimestamp();

      await reportRef.set({
        'id': reportRef.id,
        'reporterId': user.uid,
        'targetType': targetType.trim(),
        'targetId': targetId.trim(),
        'targetOwnerId': targetOwnerId.trim(),
        'reason': reason.trim(),
        'detail': detail.trim(),
        'status': 'pending',
        'action': 'none',
        'adminNote': '',
        'handledBy': '',
        'createdAt': now,
        'updatedAt': now,
        'handledAt': null,
      });

      return 'Đã gửi report. Admin/moderator sẽ kiểm tra sau.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Không có quyền gửi report. Kiểm tra Firestore Rules.';
      }
      return 'Gửi report thất bại: ${e.message ?? e.code}';
    } catch (e) {
      return 'Gửi report thất bại: $e';
    }
  }

  static Stream<List<UniReport>> reportsStream({
    String status = 'all',
    String targetType = 'all',
  }) {
    Query<Map<String, dynamic>> query = _reportsRef;

    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    if (targetType != 'all') {
      query = query.where('targetType', isEqualTo: targetType);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UniReport.fromDoc).toList());
  }

  static Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String action = 'none',
    String adminNote = '',
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    if (!['pending', 'reviewing', 'resolved', 'rejected'].contains(status)) {
      throw Exception('Trạng thái report không hợp lệ.');
    }

    await _reportsRef.doc(reportId).update({
      'status': status,
      'action': action,
      'adminNote': adminNote.trim(),
      'handledBy': user.uid,
      'handledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
