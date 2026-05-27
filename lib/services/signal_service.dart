import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../models/vibe_signal.dart';

class SignalService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int dailySignalLimit = 5;

  static final ValueNotifier<List<VibeSignal>> receivedSignalsNotifier =
      ValueNotifier<List<VibeSignal>>([]);

  static final ValueNotifier<List<VibeSignal>> sentSignalsNotifier =
      ValueNotifier<List<VibeSignal>>([]);

  static CollectionReference<Map<String, dynamic>> get _signalsRef {
    return _db.collection('signals');
  }

  static CollectionReference<Map<String, dynamic>> get _chatRoomsRef {
    return _db.collection('chatRooms');
  }

  static CollectionReference<Map<String, dynamic>> get _usersRef {
    return _db.collection('users');
  }

  static String _pairId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
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

  static Future<bool> hasSentSignalTo({
    required String currentUserId,
    required String receiverId,
  }) async {
    final cached = sentSignalsNotifier.value.any(
      (signal) =>
          signal.senderId == currentUserId &&
          signal.receiverId == receiverId &&
          signal.status != 'declined',
    );

    if (cached) return true;

    final signalDocId = _signalDocId(
      senderId: currentUserId,
      receiverId: receiverId,
    );

    final doc = await _signalsRef.doc(signalDocId).get();

    if (!doc.exists) return false;

    final signal = VibeSignal.fromFirestore(doc);
    return signal.status != 'declined';
  }

  static Stream<List<VibeSignal>> receivedSignalsStream(String currentUserId) {
    if (currentUserId.isEmpty) {
      receivedSignalsNotifier.value = [];
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
          receivedSignalsNotifier.value = signals;

          return signals;
        });
  }

  static Stream<List<VibeSignal>> sentSignalsStream(String currentUserId) {
    if (currentUserId.isEmpty) {
      sentSignalsNotifier.value = [];
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
          sentSignalsNotifier.value = signals;

          return signals;
        });
  }

  static Future<void> loadCurrentUserSignals() async {
    final user = _auth.currentUser;

    if (user == null) {
      receivedSignalsNotifier.value = [];
      sentSignalsNotifier.value = [];
      return;
    }

    final receivedSnapshot = await _signalsRef
        .where('receiverId', isEqualTo: user.uid)
        .get();

    final sentSnapshot = await _signalsRef
        .where('senderId', isEqualTo: user.uid)
        .get();

    final receivedSignals = receivedSnapshot.docs
        .map((doc) => VibeSignal.fromFirestore(doc))
        .toList();

    final sentSignals = sentSnapshot.docs
        .map((doc) => VibeSignal.fromFirestore(doc))
        .toList();

    receivedSignals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    sentSignals.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    receivedSignalsNotifier.value = receivedSignals;
    sentSignalsNotifier.value = sentSignals;
  }

  static Future<bool> canSendSignal(String currentUserId) async {
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

  static Future<UserProfile?> _getUserProfileById(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    final data = doc.data();

    if (data == null) return null;

    return UserProfile.fromMap({...data, 'id': data['id'] ?? doc.id});
  }

  static Future<String> sendSignal({
    required UserProfile currentUser,
    required UserProfile receiver,
    String type = 'vibe',
    String message = 'Bạn có vẻ cùng vibe với mình!',
  }) async {
    try {
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
      final isMutual = oppositeSignal.exists;

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
        pairId: pairId,
        userIds: [currentUser.id, receiver.id],
      );

      final batch = _db.batch();

      batch.set(newSignalRef, newSignal.toFirestore());

      if (isMutual) {
        batch.update(oppositeSignalRef, {
          'status': 'mutual',
          'updatedAt': Timestamp.fromDate(now),
          'chatRoomId': chatRoomId,
        });

        final chatRoomRef = _chatRoomsRef.doc(chatRoomId);

        batch.set(chatRoomRef, {
          'id': chatRoomId,
          'userIds': [currentUser.id, receiver.id],
          'pairId': pairId,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'lastMessage': 'Hai bạn đã mutual signal 🎉',
          'lastMessageSenderId': 'system',
          'members': {
            currentUser.id: {
              'id': currentUser.id,
              'nickname': currentUser.nickname,
              'avatarUrl': currentUser.avatarUrl,
              'university': currentUser.university,
              'major': currentUser.major,
              'year': currentUser.year,
            },
            receiver.id: {
              'id': receiver.id,
              'nickname': receiver.nickname,
              'avatarUrl': receiver.avatarUrl,
              'university': receiver.university,
              'major': receiver.major,
              'year': receiver.year,
            },
          },
        }, SetOptions(merge: true));

        final welcomeMessageRef = chatRoomRef
            .collection('messages')
            .doc('welcome');

        batch.set(welcomeMessageRef, {
          'id': welcomeMessageRef.id,
          'chatRoomId': chatRoomId,
          'senderId': 'system',
          'text':
              'Hai bạn đã mutual signal 🎉 Bây giờ có thể trò chuyện với nhau rồi!',
          'createdAt': Timestamp.fromDate(now),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      await loadCurrentUserSignals();

      if (isMutual) {
        return 'Mutual signal với ${receiver.nickname}! Phòng chat đã được mở.';
      }

      return 'Đã gửi signal đến ${receiver.nickname}.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'permission-denied: Firestore Rules chưa cho phép ghi signals/chatRooms/messages.',
        );
      }

      throw Exception('Firebase lỗi khi gửi signal: ${e.code} - ${e.message}');
    } catch (e) {
      throw Exception('Gửi signal thất bại: $e');
    }
  }

  static Future<String> signalBack({
    required UserProfile currentUser,
    UserProfile? sender,
    String? senderId,
    String message = 'Mình cũng thấy bạn hợp vibe, kết nối nhé!',
  }) async {
    UserProfile? targetSender = sender;

    if (targetSender == null && senderId != null) {
      targetSender = await _getUserProfileById(senderId);
    }

    if (targetSender == null) {
      return 'Không tìm thấy người gửi signal.';
    }

    return sendSignal(
      currentUser: currentUser,
      receiver: targetSender,
      message: message,
    );
  }

  static Future<String> declineSignal(String signalId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Bạn chưa đăng nhập.';
    }

    try {
      final signalRef = _signalsRef.doc(signalId);
      final signalDoc = await signalRef.get();

      if (!signalDoc.exists) {
        return 'Signal không tồn tại.';
      }

      final data = signalDoc.data() ?? {};
      final receiverId = data['receiverId']?.toString() ?? '';

      if (receiverId != user.uid) {
        return 'Bạn không có quyền từ chối signal này.';
      }

      await signalRef.update({
        'status': 'declined',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await loadCurrentUserSignals();

      return 'Đã từ chối signal.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'permission-denied: Firestore Rules chưa cho phép update signals.',
        );
      }

      throw Exception('Firebase lỗi khi từ chối signal: ${e.code}');
    }
  }
}
