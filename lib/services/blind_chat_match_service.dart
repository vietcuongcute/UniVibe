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

  static String _pairId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static String _blindRoomId(String uid1, String uid2) {
    return 'blind_${_pairId(uid1, uid2)}';
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

  static Future<UserProfile?> _getCurrentProfile() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc = await _usersRef.doc(user.uid).get();
    final data = doc.data();

    if (data == null) return null;

    return UserProfile.fromMap({...data, 'id': data['id'] ?? doc.id});
  }

  static Future<UserProfile?> _getUserProfileById(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    final data = doc.data();

    if (data == null) return null;

    return UserProfile.fromMap({...data, 'id': data['id'] ?? doc.id});
  }

  static Future<BlindChatMatchResult> findOrWait() async {
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
      final result = await _db.runTransaction<BlindChatMatchResult>((
        transaction,
      ) async {
        final currentQueueRef = _blindQueueRef.doc(user.uid);
        final currentQueueDoc = await transaction.get(currentQueueRef);

        if (currentQueueDoc.exists) {
          return const BlindChatMatchResult(
            success: true,
            waiting: true,
            message: 'Bạn đang trong hàng chờ blind chat.',
          );
        }

        final waitingSnapshot = await _blindQueueRef
            .where('status', isEqualTo: 'waiting')
            .limit(10)
            .get();

        QueryDocumentSnapshot<Map<String, dynamic>>? matchedDoc;

        for (final doc in waitingSnapshot.docs) {
          if (doc.id != user.uid) {
            matchedDoc = doc;
            break;
          }
        }

        if (matchedDoc == null) {
          transaction.set(currentQueueRef, {
            'userId': user.uid,
            'nickname': currentProfile.nickname,
            'avatarUrl': currentProfile.avatarUrl,
            'university': currentProfile.university,
            'major': currentProfile.major,
            'year': currentProfile.year,
            'status': 'waiting',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          return const BlindChatMatchResult(
            success: true,
            waiting: true,
            message: 'Đang chờ một người khác vào blind chat...',
          );
        }

        final otherUserId = matchedDoc.id;
        final otherProfile = await _getUserProfileById(otherUserId);

        if (otherProfile == null) {
          transaction.delete(matchedDoc.reference);

          transaction.set(currentQueueRef, {
            'userId': user.uid,
            'nickname': currentProfile.nickname,
            'avatarUrl': currentProfile.avatarUrl,
            'university': currentProfile.university,
            'major': currentProfile.major,
            'year': currentProfile.year,
            'status': 'waiting',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          return const BlindChatMatchResult(
            success: true,
            waiting: true,
            message: 'Đang chờ một người khác vào blind chat...',
          );
        }

        final roomId = _blindRoomId(user.uid, otherUserId);
        final roomRef = _chatRoomsRef.doc(roomId);
        final messageRef = roomRef.collection('messages').doc();

        transaction.set(roomRef, {
          'id': roomId,
          'type': 'blind',
          'source': 'blind_chat',
          'status': 'active',
          'isRevealed': false,
          'revealRequests': [],
          'userIds': [user.uid, otherUserId]..sort(),
          'members': {
            currentProfile.id: _memberMap(currentProfile),
            otherProfile.id: _memberMap(otherProfile),
          },
          'deletedFor': [],
          'lastMessage': 'Blind chat đã bắt đầu 🎭',
          'lastMessageSenderId': 'system',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(minutes: 10)),
          ),
        }, SetOptions(merge: true));

        transaction.set(messageRef, {
          'id': messageRef.id,
          'chatRoomId': roomId,
          'senderId': 'system',
          'text':
              'Blind chat đã bắt đầu 🎭 Hãy trò chuyện trước, reveal sau nếu cả hai đồng ý.',
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.delete(matchedDoc.reference);
        transaction.delete(currentQueueRef);

        return BlindChatMatchResult(
          success: true,
          waiting: false,
          message: 'Đã ghép blind chat!',
          chatRoomId: roomId,
        );
      });

      return result;
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

  static Future<String> cancelWaiting() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    await _blindQueueRef.doc(user.uid).delete();
    return 'Đã huỷ chờ blind chat.';
  }
}
