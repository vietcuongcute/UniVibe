import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_room.dart';
import '../models/user_profile.dart';

class FirestoreChatRoom extends ChatRoom {
  final String otherUserId;
  final String otherName;
  final String otherAvatarUrl;
  final String otherUniversity;
  final String otherMajor;
  final int otherYear;
  final String type;
  final bool isRevealed;
  final List<String> revealRequests;

  FirestoreChatRoom({
    required String id,
    required List<String> userIds,
    required this.otherUserId,
    required this.otherName,
    required this.otherAvatarUrl,
    required this.otherUniversity,
    required this.otherMajor,
    required this.otherYear,
    required String lastMessage,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.type,
    required this.isRevealed,
    required this.revealRequests,
  }) : super(
         id: id,
         userIds: userIds,
         otherUser: UserProfile(
           id: otherUserId,
           nickname: otherName,
           avatarUrl: otherAvatarUrl,
           university: otherUniversity,
           major: otherMajor,
           year: otherYear,
           gender: '',
           interests: const [],
           goals: const [],
           vibeTags: const [],
           bio: '',
         ),
         lastMessage: lastMessage,
         createdAt: createdAt,
         updatedAt: updatedAt,
         messages: const [],
       );

  factory FirestoreChatRoom.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUserId,
  }) {
    final data = doc.data() ?? {};

    final userIds = (data['userIds'] as List? ?? [])
        .map((item) => item.toString())
        .toList();

    String otherUserId = '';
    for (final id in userIds) {
      if (id != currentUserId) {
        otherUserId = id;
        break;
      }
    }

    final members = data['members'];
    Map<String, dynamic> otherMember = {};

    if (members is Map && otherUserId.isNotEmpty) {
      final rawOther = members[otherUserId];
      if (rawOther is Map) {
        otherMember = rawOther.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }

    return FirestoreChatRoom(
      id: doc.id,
      userIds: userIds,
      otherUserId: otherUserId,
      otherName: otherMember['nickname']?.toString() ?? 'Người dùng UniVibe',
      otherAvatarUrl: otherMember['avatarUrl']?.toString() ?? '',
      otherUniversity: otherMember['university']?.toString() ?? '',
      otherMajor: otherMember['major']?.toString() ?? '',
      otherYear: _parseInt(otherMember['year']),
      type: data['type']?.toString() ?? 'normal',
      isRevealed: data['isRevealed'] == true,
      revealRequests: _parseStringList(data['revealRequests']),
      lastMessage: data['lastMessage']?.toString() ?? '',
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
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }
}

class FirestoreChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  FirestoreChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory FirestoreChatMessage.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return FirestoreChatMessage(
      id: doc.id,
      chatRoomId: data['chatRoomId']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
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

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final ValueNotifier<List<FirestoreChatRoom>> chatRoomsNotifier =
      ValueNotifier<List<FirestoreChatRoom>>([]);

  static CollectionReference<Map<String, dynamic>> get _chatRoomsRef {
    return _db.collection('chatRooms');
  }

  static String get currentUserId => _auth.currentUser?.uid ?? '';

  static Stream<List<FirestoreChatRoom>> chatRoomsStream(String currentUserId) {
    if (currentUserId.isEmpty) {
      chatRoomsNotifier.value = [];
      return Stream.value([]);
    }

    return _chatRoomsRef
        .where('userIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .where((doc) {
                final data = doc.data();

                final deletedFor = (data['deletedFor'] as List? ?? [])
                    .map((item) => item.toString())
                    .toList();

                final status = data['status']?.toString() ?? 'active';

                if (deletedFor.contains(currentUserId)) return false;
                if (status == 'ended') return false;

                return true;
              })
              .map((doc) {
                return FirestoreChatRoom.fromDoc(
                  doc,
                  currentUserId: currentUserId,
                );
              })
              .toList();

          rooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          chatRoomsNotifier.value = rooms;

          return rooms;
        });
  }

  static Stream<FirestoreChatRoom?> chatRoomStream(String chatRoomId) {
    final uid = currentUserId;

    if (uid.isEmpty) {
      return Stream.value(null);
    }

    return _chatRoomsRef.doc(chatRoomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return FirestoreChatRoom.fromDoc(doc, currentUserId: uid);
    });
  }

  static Stream<List<FirestoreChatMessage>> messagesStream(String chatRoomId) {
    return _chatRoomsRef.doc(chatRoomId).collection('messages').snapshots().map(
      (snapshot) {
        final messages = snapshot.docs
            .map((doc) => FirestoreChatMessage.fromDoc(doc))
            .toList();

        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return messages;
      },
    );
  }

  static ChatRoom? getChatRoomWith(String otherUserId) {
    for (final room in chatRoomsNotifier.value) {
      if (room.otherUserId == otherUserId) {
        return room;
      }
    }

    return null;
  }

  static Future<void> sendMessage({
    required String chatRoomId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    final trimmedText = text.trim();

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    if (trimmedText.isEmpty) return;

    final chatRoomRef = _chatRoomsRef.doc(chatRoomId);
    final chatRoomDoc = await chatRoomRef.get();

    if (!chatRoomDoc.exists) {
      throw Exception('Phòng chat không tồn tại');
    }

    final data = chatRoomDoc.data() ?? {};
    final userIds = (data['userIds'] as List? ?? [])
        .map((item) => item.toString())
        .toList();

    if (!userIds.contains(user.uid)) {
      throw Exception('Bạn không thuộc phòng chat này');
    }

    final now = DateTime.now();
    final messageRef = chatRoomRef.collection('messages').doc();

    final batch = _db.batch();

    batch.set(messageRef, {
      'id': messageRef.id,
      'chatRoomId': chatRoomId,
      'senderId': user.uid,
      'text': trimmedText,
      'createdAt': Timestamp.fromDate(now),
    });

    batch.update(chatRoomRef, {
      'lastMessage': trimmedText,
      'lastMessageSenderId': user.uid,
      'updatedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  static Future<String> deleteChatRoomForCurrentUser(String chatRoomId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    try {
      await _chatRoomsRef.doc(chatRoomId).update({
        'deletedFor': FieldValue.arrayUnion([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return 'Đã xoá đoạn chat khỏi danh sách của bạn.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Không có quyền xoá đoạn chat. Kiểm tra Firestore Rules.';
      }

      return 'Xoá đoạn chat thất bại: ${e.message ?? e.code}';
    } catch (e) {
      return 'Xoá đoạn chat thất bại: $e';
    }
  }

  static Future<String> restoreChatRoomForCurrentUser(String chatRoomId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    try {
      await _chatRoomsRef.doc(chatRoomId).update({
        'deletedFor': FieldValue.arrayRemove([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return 'Đã hoàn tác xoá đoạn chat.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Không có quyền hoàn tác. Kiểm tra Firestore Rules.';
      }

      return 'Hoàn tác thất bại: ${e.message ?? e.code}';
    } catch (e) {
      return 'Hoàn tác thất bại: $e';
    }
  }

  static Future<String> requestRevealProfile(String chatRoomId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    try {
      final chatRoomRef = _chatRoomsRef.doc(chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();

      if (!chatRoomDoc.exists) {
        return 'Phòng chat không tồn tại.';
      }

      final data = chatRoomDoc.data() ?? {};

      final type = data['type']?.toString() ?? 'normal';

      if (type != 'blind') {
        return 'Chỉ blind chat mới cần reveal.';
      }

      final userIds = (data['userIds'] as List? ?? [])
          .map((item) => item.toString())
          .toList();

      if (!userIds.contains(user.uid)) {
        return 'Bạn không thuộc phòng chat này.';
      }

      if (data['isRevealed'] == true) {
        return 'Hai bạn đã reveal profile rồi.';
      }

      final revealRequests = (data['revealRequests'] as List? ?? [])
          .map((item) => item.toString())
          .toList();

      if (revealRequests.contains(user.uid)) {
        return 'Bạn đã gửi yêu cầu reveal rồi. Chờ người kia đồng ý.';
      }

      String otherUserId = '';

      for (final id in userIds) {
        if (id != user.uid) {
          otherUserId = id;
          break;
        }
      }

      final newRevealRequests = {...revealRequests, user.uid}.toList();

      final shouldReveal = userIds.every(newRevealRequests.contains);

      final now = Timestamp.fromDate(DateTime.now());
      final batch = _db.batch();

      batch.update(chatRoomRef, {
        'revealRequests': FieldValue.arrayUnion([user.uid]),
        'isRevealed': shouldReveal,
        'updatedAt': now,
      });

      final messageRef = chatRoomRef.collection('messages').doc();

      if (shouldReveal) {
        batch.set(messageRef, {
          'id': messageRef.id,
          'chatRoomId': chatRoomId,
          'senderId': 'system',
          'text': 'Hai bạn đã đồng ý reveal profile 🎉',
          'createdAt': now,
        });

        batch.update(chatRoomRef, {
          'lastMessage': 'Hai bạn đã đồng ý reveal profile 🎉',
          'lastMessageSenderId': 'system',
          'updatedAt': now,
        });
      } else {
        batch.set(messageRef, {
          'id': messageRef.id,
          'chatRoomId': chatRoomId,
          'senderId': 'system',
          'targetUserId': otherUserId,
          'text':
              'Người kia muốn reveal profile 👀 Bấm Reveal nếu bạn cũng đồng ý.',
          'createdAt': now,
        });

        batch.update(chatRoomRef, {
          'lastMessage': 'Có yêu cầu reveal profile 👀',
          'lastMessageSenderId': 'system',
          'updatedAt': now,
        });
      }

      await batch.commit();

      if (shouldReveal) {
        return 'Reveal thành công! Hai bạn đã thấy profile thật.';
      }

      return 'Đã gửi yêu cầu reveal. Chờ người kia đồng ý.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Không có quyền reveal. Kiểm tra Firestore Rules.';
      }

      return 'Reveal thất bại: ${e.message ?? e.code}';
    } catch (e) {
      return 'Reveal thất bại: $e';
    }
  }

  static bool hasRequestedReveal(FirestoreChatRoom room) {
    final user = _auth.currentUser;

    if (user == null) return false;

    return room.revealRequests.contains(user.uid);
  }

  static bool otherUserRequestedReveal(FirestoreChatRoom room) {
    final user = _auth.currentUser;

    if (user == null) return false;

    return room.revealRequests.any((uid) => uid != user.uid);
  }
}
