import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'report_service.dart';

class FirestoreMoment {
  final String id;
  final String authorId;
  final String authorNickname;
  final String imageUrl;
  final String caption;
  final String audience;
  final bool isHidden;
  final Map<String, List<String>> reactions;
  final int reportCount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status;

  const FirestoreMoment({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    required this.imageUrl,
    required this.caption,
    required this.audience,
    required this.isHidden,
    required this.reactions,
    required this.reportCount,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
  });

  factory FirestoreMoment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawReactions = data['reactions'];

    final parsedReactions = <String, List<String>>{};

    if (rawReactions is Map) {
      rawReactions.forEach((key, value) {
        parsedReactions[key.toString()] = (value as List? ?? [])
            .map((item) => item.toString())
            .toList();
      });
    }

    return FirestoreMoment(
      id: doc.id,
      authorId: data['authorId']?.toString() ?? '',
      authorNickname: data['authorNickname']?.toString() ?? 'Sinh viên UniVibe',
      imageUrl: data['imageUrl']?.toString() ?? '',
      caption: data['caption']?.toString() ?? '',
      audience: data['audience']?.toString() ?? 'campus',
      isHidden: data['isHidden'] == true,
      status: data['status']?.toString() ?? 'active',
      reactions: parsedReactions,
      reportCount: _parseInt(data['reportCount']),
      createdAt: _parseDate(data['createdAt']),
      expiresAt: _parseDate(data['expiresAt']),
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

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  bool get visibleToUser {
    return !isHidden &&
        status != 'hidden' &&
        status != 'deleted' &&
        expiresAt.isAfter(DateTime.now());
  }

  int get reactionCount {
    int total = 0;
    for (final userIds in reactions.values) {
      total += userIds.length;
    }
    return total;
  }

  String? myReaction(String uid) {
    for (final entry in reactions.entries) {
      if (entry.value.contains(uid)) {
        return entry.key;
      }
    }
    return null;
  }

  String get displayAudience {
    switch (audience) {
      case 'department':
        return 'Theo khoa';
      case 'club':
        return 'CLB';
      case 'event':
        return 'Sự kiện';
      case 'campus':
      default:
        return 'Toàn trường';
    }
  }
}

class MomentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static CollectionReference<Map<String, dynamic>> get _momentsRef {
    return _db.collection('moments');
  }

  static CollectionReference<Map<String, dynamic>> get _reportsRef {
    return _db.collection('reports');
  }

  static String get currentUserId {
    return _auth.currentUser?.uid ?? '';
  }

  static Stream<List<FirestoreMoment>> momentsStream() {
    return _momentsRef.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(FirestoreMoment.fromDoc)
          .where((moment) => moment.visibleToUser)
          .toList();
    });
  }

  static Future<String> createMoment({
    required XFile image,
    required String caption,
    required String audience,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    try {
      final bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        return 'Ảnh không hợp lệ.';
      }

      final authorNickname = await _getCurrentUserNickname(user.uid);
      final momentRef = _momentsRef.doc();

      final extension = _getFileExtension(image.name);
      final contentType = _getContentType(extension);

      final storageRef = _storage.ref().child(
        'moments/${user.uid}/${momentRef.id}.$extension',
      );

      final uploadTask = await storageRef.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: contentType),
      );

      final imageUrl = await uploadTask.ref.getDownloadURL();

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      await momentRef.set({
        'id': momentRef.id,
        'authorId': user.uid,
        'authorNickname': authorNickname,
        'imageUrl': imageUrl,
        'caption': caption.trim(),
        'audience': audience,
        'isHidden': false,
        'reactions': <String, List<String>>{
          '❤️': <String>[],
          '😂': <String>[],
          '🔥': <String>[],
          '😮': <String>[],
          '👏': <String>[],
        },
        'status': 'active',
        'isHidden': false,
        'reportCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return 'Đã đăng UniMoment.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Không có quyền đăng UniMoment. Kiểm tra Firebase Rules.';
      }
      return 'Đăng UniMoment thất bại: ${e.message ?? e.code}';
    } catch (e) {
      return 'Đăng UniMoment thất bại: $e';
    }
  }

  static Future<String> toggleReaction({
    required String momentId,
    required String emoji,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    try {
      final momentRef = _momentsRef.doc(momentId);

      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(momentRef);

        if (!snapshot.exists) {
          throw Exception('Moment không tồn tại.');
        }

        final data = snapshot.data() ?? {};
        final rawReactions = data['reactions'];

        final reactions = <String, List<String>>{
          '❤️': <String>[],
          '😂': <String>[],
          '🔥': <String>[],
          '😮': <String>[],
          '👏': <String>[],
        };

        if (rawReactions is Map) {
          rawReactions.forEach((key, value) {
            reactions[key.toString()] = (value as List? ?? [])
                .map((item) => item.toString())
                .toList();
          });
        }

        final oldReaction = _findMyReaction(reactions, user.uid);

        for (final entry in reactions.entries) {
          entry.value.remove(user.uid);
        }

        if (oldReaction != emoji) {
          reactions.putIfAbsent(emoji, () => <String>[]);
          reactions[emoji]!.add(user.uid);
        }

        transaction.update(momentRef, {
          'reactions': reactions,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return 'Đã cập nhật reaction.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Không có quyền reaction. Kiểm tra Firebase Rules.';
      }
      return 'Reaction thất bại: ${e.message ?? e.code}';
    } catch (e) {
      return 'Reaction thất bại: $e';
    }
  }

  static Future<String> reportMoment({
    required String momentId,
    required String reason,
    String detail = '',
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    try {
      final momentDoc = await _momentsRef.doc(momentId).get();
      final momentData = momentDoc.data() ?? {};
      final authorId = momentData['authorId']?.toString() ?? '';

      final message = await ReportService.createReport(
        targetType: 'moment',
        targetId: momentId,
        targetOwnerId: authorId,
        reason: reason,
        detail: detail,
      );

      if (message.startsWith('Đã gửi report')) {
        await _momentsRef.doc(momentId).update({
          'reportCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return message;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Không có quyền report. Kiểm tra Firebase Rules.';
      }
      return 'Report thất bại: ${e.message ?? e.code}';
    } catch (e) {
      return 'Report thất bại: $e';
    }
  }

  static String? _findMyReaction(
    Map<String, List<String>> reactions,
    String uid,
  ) {
    for (final entry in reactions.entries) {
      if (entry.value.contains(uid)) {
        return entry.key;
      }
    }
    return null;
  }

  static String _getFileExtension(String fileName) {
    final lowerName = fileName.toLowerCase();

    if (lowerName.endsWith('.png')) return 'png';
    if (lowerName.endsWith('.webp')) return 'webp';
    if (lowerName.endsWith('.jpeg')) return 'jpg';
    if (lowerName.endsWith('.jpg')) return 'jpg';

    return 'jpg';
  }

  static String _getContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      default:
        return 'image/jpeg';
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
