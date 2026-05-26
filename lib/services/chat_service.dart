import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class FirestoreChatRoom {
  final String id;
  final List<String> userIds;
  final List<String> deletedFor;
  final String otherUserId;
  final String otherName;
  final String otherAvatarUrl;
  final String otherUniversity;
  final String otherMajor;
  final int otherYear;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FirestoreChatRoom({
    required this.id,
    required this.userIds,
    required this.deletedFor,
    required this.otherUserId,
    required this.otherName,
    required this.otherAvatarUrl,
    required this.otherUniversity,
    required this.otherMajor,
    required this.otherYear,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile get otherUser {
    return UserProfile(
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
    );
  }

  factory FirestoreChatRoom.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUserId,
  }) {
    final data = doc.data() ?? {};

    final userIds = _parseStringList(data['userIds']);
    final deletedFor = _parseStringList(data['deletedFor']);

    String otherUserId = '';
    for (final id in userIds) {
      if (id != currentUserId) {
        otherUserId = id;
        break;
      }
    }

    Map<String, dynamic> otherMember = {};
    final members = data['members'];
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
      deletedFor: deletedFor,
      otherUserId: otherUserId,
      otherName: otherMember['nickname']?.toString() ?? 'Người dùng UniVibe',
      otherAvatarUrl: otherMember['avatarUrl']?.toString() ?? '',
      otherUniversity: otherMember['university']?.toString() ?? '',
      otherMajor: otherMember['major']?.toString() ?? '',
      otherYear: _parseInt(otherMember['year']),
      lastMessage: data['lastMessage']?.toString() ?? '',
      lastMessageSenderId: data['lastMessageSenderId']?.toString() ?? '',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
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

  static CollectionReference<Map<String, dynamic>> get _chatRoomsRef {
    return _db.collection('chatRooms');
  }

  static String get currentUserId => _auth.currentUser?.uid ?? '';

  static String _directRoomId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return 'chat_${ids[0]}_${ids[1]}';
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

  static Stream<List<FirestoreChatRoom>> chatRoomsStream(String currentUserId) {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _chatRoomsRef
        .where('userIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map((doc) {
                return FirestoreChatRoom.fromDoc(
                  doc,
                  currentUserId: currentUserId,
                );
              })
              .where((room) => !room.deletedFor.contains(currentUserId))
              .toList();

          rooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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

      final room = FirestoreChatRoom.fromDoc(doc, currentUserId: uid);
      if (room.deletedFor.contains(uid)) return null;

      return room;
    });
  }

  static Stream<List<FirestoreChatMessage>> messagesStream(String chatRoomId) {
    return _chatRoomsRef
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return FirestoreChatMessage.fromDoc(doc);
          }).toList();
        });
  }

  static Future<String> createChatRoom({
    required UserProfile currentUser,
    required UserProfile otherUser,
  }) async {
    if (currentUser.id.isEmpty || otherUser.id.isEmpty) {
      return 'Không tạo được phòng chat vì thiếu user id.';
    }

    if (currentUser.id == otherUser.id) {
      return 'Không thể tự tạo phòng chat với chính mình.';
    }

    final roomId = _directRoomId(currentUser.id, otherUser.id);
    final roomRef = _chatRoomsRef.doc(roomId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);

      if (snapshot.exists) {
        transaction.update(roomRef, {
          'deletedFor': FieldValue.arrayRemove([currentUser.id, otherUser.id]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final sortedUserIds = [currentUser.id, otherUser.id]..sort();

      transaction.set(roomRef, {
        'id': roomId,
        'type': 'direct',
        'source': 'mutual_signal',
        'userIds': sortedUserIds,
        'members': {
          currentUser.id: _memberMap(currentUser),
          otherUser.id: _memberMap(otherUser),
        },
        'deletedFor': <String>[],
        'lastMessage': 'Hai bạn đã mutual signal 🎉',
        'lastMessageSenderId': 'system',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final messageRef = roomRef.collection('messages').doc();
      transaction.set(messageRef, {
        'id': messageRef.id,
        'chatRoomId': roomId,
        'senderId': 'system',
        'text': 'Hai bạn đã mutual signal 🎉',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return 'Đã mở phòng chat.';
  }

  static Future<void> sendMessage({
    required String chatRoomId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    final trimmedText = text.trim();

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    if (trimmedText.isEmpty) return;

    final now = Timestamp.fromDate(DateTime.now());
    final chatRoomRef = _chatRoomsRef.doc(chatRoomId);
    final messageRef = chatRoomRef.collection('messages').doc();

    final batch = _db.batch();

    batch.set(messageRef, {
      'id': messageRef.id,
      'chatRoomId': chatRoomId,
      'senderId': user.uid,
      'text': trimmedText,
      'createdAt': now,
    });

    batch.update(chatRoomRef, {
      'lastMessage': trimmedText,
      'lastMessageSenderId': user.uid,
      'deletedFor': FieldValue.arrayRemove([user.uid]),
      'updatedAt': now,
    });

    await batch.commit();
  }

  static Future<String> deleteChatRoomForCurrentUser(String chatRoomId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    await _chatRoomsRef.doc(chatRoomId).update({
      'deletedFor': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return 'Đã xoá đoạn chat khỏi danh sách của bạn.';
  }

  static Future<String> restoreChatRoomForCurrentUser(String chatRoomId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    await _chatRoomsRef.doc(chatRoomId).update({
      'deletedFor': FieldValue.arrayRemove([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return 'Đã hoàn tác xoá đoạn chat.';
  }
}
