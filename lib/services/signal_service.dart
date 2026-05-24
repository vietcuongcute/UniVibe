import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../models/vibe_signal.dart';
import 'chat_service.dart';
import 'user_profile_service.dart';

class SignalService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final ValueNotifier<List<VibeSignal>> sentSignalsNotifier =
      ValueNotifier<List<VibeSignal>>([]);

  static final ValueNotifier<List<VibeSignal>> receivedSignalsNotifier =
      ValueNotifier<List<VibeSignal>>([]);

  static const int dailySignalLimit = 5;

  static CollectionReference<Map<String, dynamic>> get _signals {
    return _db.collection('signals');
  }

  static List<VibeSignal> get sentSignals {
    return sentSignalsNotifier.value;
  }

  static List<VibeSignal> get receivedSignals {
    return receivedSignalsNotifier.value;
  }

  static String? get _currentUserId {
    return _auth.currentUser?.uid;
  }

  static Future<void> loadCurrentUserSignals() async {
    final userId = _currentUserId;

    if (userId == null) return;

    final sentSnapshot = await _signals
        .where('senderId', isEqualTo: userId)
        .get();

    final receivedSnapshot = await _signals
        .where('receiverId', isEqualTo: userId)
        .get();

    final sentList = sentSnapshot.docs.map((doc) {
      final data = doc.data();

      return VibeSignal.fromMap({...data, 'id': data['id'] ?? doc.id});
    }).toList();

    final receivedList = receivedSnapshot.docs.map((doc) {
      final data = doc.data();

      return VibeSignal.fromMap({...data, 'id': data['id'] ?? doc.id});
    }).toList();

    sentList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    receivedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    sentSignalsNotifier.value = sentList;
    receivedSignalsNotifier.value = receivedList;
  }

  static Future<void> listenCurrentUserSignals() async {
    final userId = _currentUserId;

    if (userId == null) return;

    _signals.where('senderId', isEqualTo: userId).snapshots().listen((
      snapshot,
    ) {
      final sentList = snapshot.docs.map((doc) {
        final data = doc.data();

        return VibeSignal.fromMap({...data, 'id': data['id'] ?? doc.id});
      }).toList();

      sentList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      sentSignalsNotifier.value = sentList;
    });

    _signals.where('receiverId', isEqualTo: userId).snapshots().listen((
      snapshot,
    ) {
      final receivedList = snapshot.docs.map((doc) {
        final data = doc.data();

        return VibeSignal.fromMap({...data, 'id': data['id'] ?? doc.id});
      }).toList();

      receivedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      receivedSignalsNotifier.value = receivedList;
    });
  }

  static bool hasSentSignalTo(String receiverId) {
    return sentSignals.any((signal) => signal.receiverId == receiverId);
  }

  static bool hasReceivedSignalFrom(String senderId) {
    return receivedSignals.any((signal) => signal.senderId == senderId);
  }

  static bool canSendSignal() {
    return _getTodaySentSignalCount() < dailySignalLimit;
  }

  static int _getTodaySentSignalCount() {
    final now = DateTime.now();

    return sentSignals.where((signal) {
      final createdAt = signal.createdAt;

      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).length;
  }

  static Future<String> sendSignal({
    required UserProfile currentUser,
    required UserProfile receiver,
    String type = 'vibe',
    String message = 'Bạn có vẻ cùng vibe với mình!',
  }) async {
    await loadCurrentUserSignals();

    final alreadySent = await _hasSentSignalToInFirestore(
      senderId: currentUser.id,
      receiverId: receiver.id,
    );

    if (alreadySent) {
      return 'Bạn đã gửi signal cho ${receiver.nickname} rồi.';
    }

    if (!canSendSignal()) {
      return 'Hôm nay bạn đã dùng hết $dailySignalLimit signal.';
    }

    final now = DateTime.now();
    final docRef = _signals.doc();

    final newSignal = VibeSignal(
      id: docRef.id,
      senderId: currentUser.id,
      senderName: currentUser.nickname,
      receiverId: receiver.id,
      receiverName: receiver.nickname,
      type: type,
      message: message,
      status: 'pending',
      createdAt: now,
    );

    await docRef.set(newSignal.toMap());

    await loadCurrentUserSignals();

    final isMutual = await _hasPendingSignalInOppositeDirection(
      currentUserId: currentUser.id,
      otherUserId: receiver.id,
    );

    if (isMutual) {
      await _markMutualWith(
        currentUserId: currentUser.id,
        otherUserId: receiver.id,
      );

      ChatService.createChatRoom(currentUser: currentUser, otherUser: receiver);

      await loadCurrentUserSignals();

      return 'Mutual signal với ${receiver.nickname}! Phòng chat đã được mở.';
    }

    return 'Đã gửi signal đến ${receiver.nickname}.';
  }

  static Future<String> signalBack({
    required UserProfile currentUser,
    required String senderId,
    String message = 'Mình cũng thấy bạn hợp vibe, kết nối nhé!',
  }) async {
    final sender = await _findUserById(senderId);

    if (sender == null) {
      return 'Không tìm thấy người dùng này.';
    }

    return sendSignal(
      currentUser: currentUser,
      receiver: sender,
      message: message,
    );
  }

  static Future<String> declineSignal(String signalId) async {
    await _signals.doc(signalId).update({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await loadCurrentUserSignals();

    return 'Đã từ chối signal.';
  }

  static Future<bool> _hasSentSignalToInFirestore({
    required String senderId,
    required String receiverId,
  }) async {
    final snapshot = await _signals
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  static Future<bool> _hasPendingSignalInOppositeDirection({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final snapshot = await _signals
        .where('senderId', isEqualTo: otherUserId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  static Future<void> _markMutualWith({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final sentSnapshot = await _signals
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: otherUserId)
        .get();

    final receivedSnapshot = await _signals
        .where('senderId', isEqualTo: otherUserId)
        .where('receiverId', isEqualTo: currentUserId)
        .get();

    final batch = _db.batch();

    for (final doc in sentSnapshot.docs) {
      batch.update(doc.reference, {
        'status': 'mutual',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    for (final doc in receivedSnapshot.docs) {
      batch.update(doc.reference, {
        'status': 'mutual',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  static Future<UserProfile?> _findUserById(String userId) async {
    final currentUser = await UserProfileService.getCurrentUserProfile();

    if (currentUser != null && currentUser.id == userId) {
      return currentUser;
    }

    final users = await UserProfileService.getAllUsers();

    try {
      return users.firstWhere((user) => user.id == userId);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSignals() async {
    sentSignalsNotifier.value = [];
    receivedSignalsNotifier.value = [];
  }
}
