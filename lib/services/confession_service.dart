import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreConfession {
  final String id;
  final String authorId;
  final String authorNickname;
  final String content;
  final String category;
  final bool isAnonymous;
  final bool isHidden;
  final List<String> likeUserIds;
  final int commentCount;
  final int reportCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirestoreConfession({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    required this.content,
    required this.category,
    required this.isAnonymous,
    required this.isHidden,
    required this.likeUserIds,
    required this.commentCount,
    required this.reportCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FirestoreConfession.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return FirestoreConfession(
      id: doc.id,
      authorId: data['authorId']?.toString() ?? '',
      authorNickname: data['authorNickname']?.toString() ?? 'Sinh viên UniVibe',
      content: data['content']?.toString() ?? '',
      category: data['category']?.toString() ?? 'confession',
      isAnonymous: data['isAnonymous'] == true,
      isHidden: data['isHidden'] == true,
      likeUserIds: (data['likeUserIds'] as List? ?? [])
          .map((item) => item.toString())
          .toList(),
      commentCount: _parseInt(data['commentCount']),
      reportCount: _parseInt(data['reportCount']),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String get displayAuthor {
    if (isAnonymous) return 'Ẩn danh';
    return authorNickname.isEmpty ? 'Sinh viên UniVibe' : authorNickname;
  }

  bool likedBy(String uid) {
    return likeUserIds.contains(uid);
  }
}

class FirestoreConfessionComment {
  final String id;
  final String confessionId;
  final String authorId;
  final String authorNickname;
  final String text;
  final bool isHidden;
  final DateTime createdAt;

  const FirestoreConfessionComment({
    required this.id,
    required this.confessionId,
    required this.authorId,
    required this.authorNickname,
    required this.text,
    required this.isHidden,
    required this.createdAt,
  });

  factory FirestoreConfessionComment.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return FirestoreConfessionComment(
      id: doc.id,
      confessionId: data['confessionId']?.toString() ?? '',
      authorId: data['authorId']?.toString() ?? '',
      authorNickname: data['authorNickname']?.toString() ?? 'Sinh viên UniVibe',
      text: data['text']?.toString() ?? '',
      isHidden: data['isHidden'] == true,
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

class ConfessionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _confessionsRef {
    return _db.collection('confessions');
  }

  static CollectionReference<Map<String, dynamic>> get _reportsRef {
    return _db.collection('reports');
  }

  static String get currentUserId {
    return _auth.currentUser?.uid ?? '';
  }

  static Stream<List<FirestoreConfession>> confessionsStream() {
    return _confessionsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map(FirestoreConfession.fromDoc)
              .where((item) => !item.isHidden)
              .toList();

          return items;
        });
  }

  static Stream<List<FirestoreConfessionComment>> commentsStream(
    String confessionId,
  ) {
    return _confessionsRef
        .doc(confessionId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(FirestoreConfessionComment.fromDoc)
              .where((item) => !item.isHidden)
              .toList();
        });
  }

  static Future<String> createConfession({
    required String content,
    required String category,
    required bool isAnonymous,
  }) async {
    final user = _auth.currentUser;
    final trimmedContent = content.trim();

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    if (trimmedContent.length < 5) {
      return 'Confession cần ít nhất 5 ký tự.';
    }

    try {
      final authorNickname = await _getCurrentUserNickname(user.uid);
      final docRef = _confessionsRef.doc();
      final now = FieldValue.serverTimestamp();

      await docRef.set({
        'id': docRef.id,
        'authorId': user.uid,
        'authorNickname': authorNickname,
        'content': trimmedContent,
        'category': category,
        'isAnonymous': isAnonymous,
        'isHidden': false,
        'likeUserIds': <String>[],
        'commentCount': 0,
        'reportCount': 0,
        'createdAt': now,
        'updatedAt': now,
      });

      return 'Đã đăng confession.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Không có quyền đăng confession. Kiểm tra Firestore Rules.';
      }
      return 'Đăng confession thất bại: ${e.message ?? e.code}';
    } catch (e) {
      return 'Đăng confession thất bại: $e';
    }
  }

  static Future<String> toggleLike(String confessionId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    try {
      final ref = _confessionsRef.doc(confessionId);

      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data() ?? {};

        final likeUserIds = (data['likeUserIds'] as List? ?? [])
            .map((item) => item.toString())
            .toList();

        if (likeUserIds.contains(user.uid)) {
          transaction.update(ref, {
            'likeUserIds': FieldValue.arrayRemove([user.uid]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(ref, {
            'likeUserIds': FieldValue.arrayUnion([user.uid]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return 'Đã cập nhật thả tim.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Không có quyền thả tim. Kiểm tra Firestore Rules.';
      }
      return 'Thả tim thất bại: ${e.message ?? e.code}';
    } catch (e) {
      return 'Thả tim thất bại: $e';
    }
  }

  static Future<String> addComment({
    required String confessionId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    final trimmedText = text.trim();

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    if (trimmedText.length < 2) {
      return 'Bình luận cần ít nhất 2 ký tự.';
    }

    try {
      final authorNickname = await _getCurrentUserNickname(user.uid);
      final confessionRef = _confessionsRef.doc(confessionId);
      final commentRef = confessionRef.collection('comments').doc();

      final batch = _db.batch();

      batch.set(commentRef, {
        'id': commentRef.id,
        'confessionId': confessionId,
        'authorId': user.uid,
        'authorNickname': authorNickname,
        'text': trimmedText,
        'isHidden': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(confessionRef, {
        'commentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return 'Đã bình luận.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Không có quyền bình luận. Kiểm tra Firestore Rules.';
      }
      return 'Bình luận thất bại: ${e.message ?? e.code}';
    } catch (e) {
      return 'Bình luận thất bại: $e';
    }
  }

  static Future<String> reportConfession({
    required String confessionId,
    required String reason,
    String detail = '',
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    try {
      final reportRef = _reportsRef.doc();

      final batch = _db.batch();

      batch.set(reportRef, {
        'id': reportRef.id,
        'type': 'confession',
        'contentId': confessionId,
        'reporterId': user.uid,
        'reason': reason,
        'detail': detail.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(_confessionsRef.doc(confessionId), {
        'reportCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return 'Đã gửi report. Admin/moderator sẽ kiểm tra sau.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Không có quyền report. Kiểm tra Firestore Rules.';
      }
      return 'Report thất bại: ${e.message ?? e.code}';
    } catch (e) {
      return 'Report thất bại: $e';
    }
  }

  static Future<String> _getCurrentUserNickname(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final data = userDoc.data() ?? {};
      final nickname = data['nickname']?.toString().trim() ?? '';

      if (nickname.isNotEmpty) return nickname;

      final currentUser = _auth.currentUser;
      final emailName = currentUser?.email?.split('@').first.trim() ?? '';

      if (emailName.isNotEmpty) return emailName;

      return 'Sinh viên UniVibe';
    } catch (_) {
      return 'Sinh viên UniVibe';
    }
  }
}
