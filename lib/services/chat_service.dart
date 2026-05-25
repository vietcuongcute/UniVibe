import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreChatRoom {
  final String id;
  final List<String> userIds;
  final String otherUserId;
  final String otherName;
  final String otherAvatarUrl;
  final String otherUniversity;
  final String otherMajor;
  final int otherYear;
  final String lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  FirestoreChatRoom({
    required this.id,
    required this.userIds,
    required this.otherUserId,
    required this.otherName,
    required this.otherAvatarUrl,
    required this.otherUniversity,
    required this.otherMajor,
    required this.otherYear,
    required this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FirestoreChatRoom.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUserId,
  }) {
    final data = doc.data() ?? {};

    final userIds = (data['userIds'] as List<dynamic>? ?? [])
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

  static Stream<List<FirestoreChatRoom>> chatRoomsStream(String currentUserId) {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _chatRoomsRef
        .where('userIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs.map((doc) {
            return FirestoreChatRoom.fromDoc(doc, currentUserId: currentUserId);
          }).toList();

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

    final now = DateTime.now();
    final chatRoomRef = _chatRoomsRef.doc(chatRoomId);
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
}
