import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../models/vibe_signal.dart';

class SignalService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int dailySignalLimit = 5;

  static CollectionReference<Map<String, dynamic>> get _signalsRef {
    return _db.collection('signals');
  }

  static CollectionReference<Map<String, dynamic>> get _chatRoomsRef {
    return _db.collection('chatRooms');
  }

  static String _pairId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static List<String> _sortedUserIds(String uid1, String uid2) {
    return [uid1, uid2]..sort();
  }

  static String _signalDocId({
    required String senderId,
    required String receiverId,
  }) {
    return '${senderId}_to_$receiverId';
  }

  static String chatRoomIdFor(String uid1, String uid2) {
    return 'chat_${_pairId(uid1, uid2)}';
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

  static Stream<List<VibeSignal>> receivedSignalsStream(String currentUserId) {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _signalsRef
        .where('receiverId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          final signals = snapshot.docs
              .map((doc) => VibeSignal.fromFirestore(doc))
              .toList();

          signals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return signals;
        });
  }

  static Stream<List<VibeSignal>> sentSignalsStream(String currentUserId) {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _signalsRef
        .where('senderId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          final signals = snapshot.docs
              .map((doc) => VibeSignal.fromFirestore(doc))
              .toList();

          signals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return signals;
        });
  }

  static Future<bool> hasSentSignalTo({
    required String currentUserId,
    required String receiverId,
  }) async {
    if (currentUserId.isEmpty || receiverId.isEmpty) {
      return false;
    }

    final docId = _signalDocId(senderId: currentUserId, receiverId: receiverId);

    final doc = await _signalsRef.doc(docId).get();
    return doc.exists;
  }

  static Future<bool> canSendSignal(String currentUserId) async {
    if (currentUserId.isEmpty) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snapshot = await _signalsRef
        .where('senderId', isEqualTo: currentUserId)
        .get();

    final todaySignals = snapshot.docs.where((doc) {
      final signal = VibeSignal.fromFirestore(doc);
      return signal.createdAt.isAtSameMomentAs(today) ||
          signal.createdAt.isAfter(today);
    }).length;

    return todaySignals < dailySignalLimit;
  }

  static Future<String> sendSignal({
    required UserProfile currentUser,
    required UserProfile receiver,
    String type = 'vibe',
    String message = 'Bạn có vẻ cùng vibe với mình!',
  }) async {
    if (currentUser.id.isEmpty || receiver.id.isEmpty) {
      return 'Không gửi được signal vì thiếu thông tin người dùng.';
    }

    if (currentUser.id == receiver.id) {
      return 'Bạn không thể tự gửi signal cho chính mình.';
    }

    final newSignalDocId = _signalDocId(
      senderId: currentUser.id,
      receiverId: receiver.id,
    );

    final newSignalRef = _signalsRef.doc(newSignalDocId);
    final existingSignal = await newSignalRef.get();

    if (existingSignal.exists) {
      return 'Bạn đã gửi signal cho ${receiver.nickname} rồi.';
    }

    final allowed = await canSendSignal(currentUser.id);
    if (!allowed) {
      return 'Hôm nay bạn đã dùng hết $dailySignalLimit signal.';
    }

    final oppositeSignalDocId = _signalDocId(
      senderId: receiver.id,
      receiverId: currentUser.id,
    );

    final oppositeSignalRef = _signalsRef.doc(oppositeSignalDocId);
    final oppositeSignal = await oppositeSignalRef.get();

    final now = DateTime.now();
    final pairId = _pairId(currentUser.id, receiver.id);
    final chatRoomId = chatRoomIdFor(currentUser.id, receiver.id);
    final userIds = _sortedUserIds(currentUser.id, receiver.id);
    final bool isMutual = oppositeSignal.exists;

    final newSignal = VibeSignal(
      id: newSignalDocId,
      senderId: currentUser.id,
      senderName: currentUser.nickname,
      receiverId: receiver.id,
      receiverName: receiver.nickname,
      type: type,
      message: message.trim().isEmpty
          ? 'Bạn có vẻ cùng vibe với mình!'
          : message.trim(),
      status: isMutual ? 'mutual' : 'pending',
      createdAt: now,
      updatedAt: now,
      chatRoomId: isMutual ? chatRoomId : null,
    );

    final batch = _db.batch();

    batch.set(newSignalRef, {
      ...newSignal.toFirestore(),
      'pairId': pairId,
      'userIds': userIds,
    });

    if (isMutual) {
      batch.update(oppositeSignalRef, {
        'status': 'mutual',
        'updatedAt': Timestamp.fromDate(now),
        'chatRoomId': chatRoomId,
      });

      final chatRoomRef = _chatRoomsRef.doc(chatRoomId);

      batch.set(chatRoomRef, {
        'id': chatRoomId,
        'type': 'direct',
        'source': 'mutual_signal',
        'userIds': userIds,
        'pairId': pairId,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'deletedFor': <String>[],
        'lastMessage': 'Hai bạn đã mutual signal 🎉',
        'lastMessageSenderId': 'system',
        'members': {
          currentUser.id: _memberMap(currentUser),
          receiver.id: _memberMap(receiver),
        },
      }, SetOptions(merge: true));

      final welcomeMessageRef = chatRoomRef.collection('messages').doc();

      batch.set(welcomeMessageRef, {
        'id': welcomeMessageRef.id,
        'chatRoomId': chatRoomId,
        'senderId': 'system',
        'text':
            'Hai bạn đã mutual signal 🎉 Bây giờ có thể trò chuyện với nhau rồi!',
        'createdAt': Timestamp.fromDate(now),
      });
    }

    await batch.commit();

    if (isMutual) {
      return 'Mutual signal với ${receiver.nickname}! Phòng chat đã được mở.';
    }

    return 'Đã gửi signal đến ${receiver.nickname}.';
  }

  static Future<String> signalBack({
    required UserProfile currentUser,
    required UserProfile sender,
    String message = 'Mình cũng thấy bạn hợp vibe, kết nối nhé!',
  }) async {
    return sendSignal(
      currentUser: currentUser,
      receiver: sender,
      message: message,
    );
  }
}
