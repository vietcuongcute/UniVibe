import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class BlindChatMatchResult {
  final bool success;
  final bool waiting;
  final String message;
  final String? chatRoomId;

  const BlindChatMatchResult({
    required this.success,
    required this.waiting,
    required this.message,
    this.chatRoomId,
  });
}

class BlindChatMatchService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _usersRef {
    return _db.collection('users');
  }

  static CollectionReference<Map<String, dynamic>> get _blindQueueRef {
    return _db.collection('blindQueue');
  }

  static CollectionReference<Map<String, dynamic>> get _chatRoomsRef {
    return _db.collection('chatRooms');
  }

  static String _newBlindRoomId() {
    final user = _auth.currentUser;
    final uid = user?.uid ?? 'unknown';
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'blind_${now}_$uid';
  }

  static Map<String, dynamic> _memberMap(UserProfile user) {
    return {
      'id': user.id,
      'nickname': user.nickname,
      'avatarUrl': user.avatarUrl,
      'university': user.university,
      'major': user.major,
      'year': user.year,
    };
  }

  static Future<UserProfile?> _getUserProfileById(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    final data = doc.data();

    if (data == null) return null;

    return UserProfile.fromMap({...data, 'id': data['id'] ?? doc.id});
  }

  static Future<UserProfile?> _getCurrentProfile() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    return _getUserProfileById(user.uid);
  }

  static Future<void> _clearMyQueue() async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _blindQueueRef.doc(user.uid).delete().catchError((_) {});
  }

  static Future<void> _hideMyOldBlindRooms() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final snapshot = await _chatRoomsRef
        .where('type', isEqualTo: 'blind')
        .where('userIds', arrayContains: user.uid)
        .limit(20)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status']?.toString() ?? 'active';

      if (status == 'active') {
        batch.update(doc.reference, {
          'status': 'ended',
          'deletedFor': FieldValue.arrayUnion([user.uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  static Future<BlindChatMatchResult> startMatching() async {
    final user = _auth.currentUser;

    if (user == null) {
      return const BlindChatMatchResult(
        success: false,
        waiting: false,
        message: 'Bạn chưa đăng nhập.',
      );
    }

    final currentProfile = await _getCurrentProfile();

    if (currentProfile == null) {
      return const BlindChatMatchResult(
        success: false,
        waiting: false,
        message: 'Không tìm thấy profile của bạn.',
      );
    }

    try {
      await _clearMyQueue();

      // Không reuse blind chat cũ nữa. Mỗi lần tìm sẽ tạo session mới.
      // Room cũ được ẩn khỏi user hiện tại để tránh lẫn dữ liệu.
      await _hideMyOldBlindRooms();

      final waitingSnapshot = await _blindQueueRef
          .where('status', isEqualTo: 'waiting')
          .limit(10)
          .get();

      QueryDocumentSnapshot<Map<String, dynamic>>? matchedDoc;

      for (final doc in waitingSnapshot.docs) {
        final otherUserId = doc.id;

        if (otherUserId != user.uid) {
          matchedDoc = doc;
          break;
        }
      }

      if (matchedDoc == null) {
        await _blindQueueRef.doc(user.uid).set({
          'userId': user.uid,
          'nickname': currentProfile.nickname,
          'avatarUrl': currentProfile.avatarUrl,
          'university': currentProfile.university,
          'major': currentProfile.major,
          'year': currentProfile.year,
          'status': 'waiting',
          'chatRoomId': null,
          'matchedWith': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return const BlindChatMatchResult(
          success: true,
          waiting: true,
          message: 'Bạn đang trong hàng chờ blind chat.',
        );
      }

      final otherUserId = matchedDoc.id;
      final otherProfile = await _getUserProfileById(otherUserId);

      if (otherProfile == null) {
        await matchedDoc.reference.delete();

        await _blindQueueRef.doc(user.uid).set({
          'userId': user.uid,
          'nickname': currentProfile.nickname,
          'avatarUrl': currentProfile.avatarUrl,
          'university': currentProfile.university,
          'major': currentProfile.major,
          'year': currentProfile.year,
          'status': 'waiting',
          'chatRoomId': null,
          'matchedWith': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return const BlindChatMatchResult(
          success: true,
          waiting: true,
          message: 'Đang chờ một người khác vào blind chat...',
        );
      }

      final roomId = _newBlindRoomId();
      final roomRef = _chatRoomsRef.doc(roomId);
      final messageRef = roomRef.collection('messages').doc();

      final now = FieldValue.serverTimestamp();

      final batch = _db.batch();

      batch.set(roomRef, {
        'id': roomId,
        'type': 'blind',
        'source': 'blind_chat',
        'status': 'active',
        'isRevealed': false,
        'revealRequests': [],
        'userIds': [user.uid, otherUserId],
        'members': {
          currentProfile.id: _memberMap(currentProfile),
          otherProfile.id: _memberMap(otherProfile),
        },
        'deletedFor': [],
        'lastMessage': 'Blind chat đã bắt đầu 🎭',
        'lastMessageSenderId': 'system',
        'createdAt': now,
        'updatedAt': now,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });

      batch.set(messageRef, {
        'id': messageRef.id,
        'chatRoomId': roomId,
        'senderId': 'system',
        'text':
            'Blind chat đã bắt đầu 🎭 Hãy trò chuyện trước, reveal sau nếu cả hai đồng ý.',
        'createdAt': now,
      });

      // Quan trọng: Không xoá queue của người đang chờ.
      // Mình update status = matched để màn người đó poll thấy room mới.
      batch.update(matchedDoc.reference, {
        'status': 'matched',
        'chatRoomId': roomId,
        'matchedWith': user.uid,
        'updatedAt': now,
      });

      // User hiện tại là người bấm tìm sau, có room luôn nên không cần queue.
      batch.delete(_blindQueueRef.doc(user.uid));

      await batch.commit();

      return BlindChatMatchResult(
        success: true,
        waiting: false,
        message: 'Đã ghép blind chat!',
        chatRoomId: roomId,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const BlindChatMatchResult(
          success: false,
          waiting: false,
          message:
              'permission-denied: Firestore Rules chưa cho phép blindQueue/chatRooms.',
        );
      }

      return BlindChatMatchResult(
        success: false,
        waiting: false,
        message: 'Firebase lỗi: ${e.code} - ${e.message}',
      );
    } catch (e) {
      return BlindChatMatchResult(
        success: false,
        waiting: false,
        message: 'Blind chat thất bại: $e',
      );
    }
  }

  static Future<BlindChatMatchResult> checkWaitingResult() async {
    final user = _auth.currentUser;

    if (user == null) {
      return const BlindChatMatchResult(
        success: false,
        waiting: false,
        message: 'Bạn chưa đăng nhập.',
      );
    }

    try {
      final doc = await _blindQueueRef.doc(user.uid).get();

      if (!doc.exists) {
        return const BlindChatMatchResult(
          success: true,
          waiting: false,
          message: 'Bạn chưa ở trong hàng chờ.',
        );
      }

      final data = doc.data() ?? {};
      final status = data['status']?.toString() ?? 'waiting';
      final chatRoomId = data['chatRoomId']?.toString();

      if (status == 'matched' && chatRoomId != null && chatRoomId.isNotEmpty) {
        return BlindChatMatchResult(
          success: true,
          waiting: false,
          message: 'Đã ghép blind chat!',
          chatRoomId: chatRoomId,
        );
      }

      return const BlindChatMatchResult(
        success: true,
        waiting: true,
        message: 'Bạn đang trong hàng chờ blind chat.',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const BlindChatMatchResult(
          success: false,
          waiting: false,
          message: 'permission-denied: Không đọc được blindQueue.',
        );
      }

      return BlindChatMatchResult(
        success: false,
        waiting: false,
        message: 'Firebase lỗi: ${e.code} - ${e.message}',
      );
    } catch (e) {
      return BlindChatMatchResult(
        success: false,
        waiting: false,
        message: 'Kiểm tra hàng chờ thất bại: $e',
      );
    }
  }

  static Future<String> cleanupMyQueueAfterOpen() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    await _blindQueueRef.doc(user.uid).delete();
    return 'Đã dọn hàng chờ blind chat.';
  }

  static Future<String> cancelWaiting() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    final doc = await _blindQueueRef.doc(user.uid).get();

    if (!doc.exists) {
      return 'Bạn không ở trong hàng chờ.';
    }

    final data = doc.data() ?? {};
    final status = data['status']?.toString() ?? 'waiting';

    if (status == 'matched') {
      return 'Bạn đã được ghép phòng, không thể huỷ lúc này.';
    }

    await _blindQueueRef.doc(user.uid).delete();
    return 'Đã huỷ chờ blind chat.';
  }
}
