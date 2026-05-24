import 'package:flutter/material.dart';

import '../data/mock_users.dart';
import '../models/user_profile.dart';
import '../models/vibe_signal.dart';
import 'chat_service.dart';

class SignalService {
  static final ValueNotifier<List<VibeSignal>> sentSignalsNotifier =
      ValueNotifier<List<VibeSignal>>([]);

  static final ValueNotifier<List<VibeSignal>> receivedSignalsNotifier =
      ValueNotifier<List<VibeSignal>>([
        VibeSignal(
          id: 'received_1',
          senderId: 'u1',
          senderName: 'Minh Anh',
          receiverId: 'u_current',
          receiverName: 'Bạn',
          type: 'vibe',
          message:
              'Mình thấy bạn cũng đang học Flutter, kết nối học chung nhé!',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        ),
        VibeSignal(
          id: 'received_2',
          senderId: 'u4',
          senderName: 'Hoàng Nam',
          receiverId: 'u_current',
          receiverName: 'Bạn',
          type: 'vibe',
          message: 'Bạn có vẻ cùng vibe coding với mình!',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ]);

  static const int dailySignalLimit = 5;

  static List<VibeSignal> get sentSignals {
    return sentSignalsNotifier.value;
  }

  static List<VibeSignal> get receivedSignals {
    return receivedSignalsNotifier.value;
  }

  static bool hasSentSignalTo(String receiverId) {
    return sentSignals.any((signal) => signal.receiverId == receiverId);
  }

  static bool hasReceivedSignalFrom(String senderId) {
    return receivedSignals.any((signal) => signal.senderId == senderId);
  }

  static bool canSendSignal() {
    return sentSignals.length < dailySignalLimit;
  }

  static String sendSignal({
    required UserProfile currentUser,
    required UserProfile receiver,
    String type = 'vibe',
    String message = 'Bạn có vẻ cùng vibe với mình!',
  }) {
    if (hasSentSignalTo(receiver.id)) {
      return 'Bạn đã gửi signal cho ${receiver.nickname} rồi.';
    }

    if (!canSendSignal()) {
      return 'Hôm nay bạn đã dùng hết $dailySignalLimit signal.';
    }

    final now = DateTime.now();

    final newSignal = VibeSignal(
      id: 'sent_${now.millisecondsSinceEpoch}',
      senderId: currentUser.id,
      senderName: currentUser.nickname,
      receiverId: receiver.id,
      receiverName: receiver.nickname,
      type: type,
      message: message,
      status: 'pending',
      createdAt: now,
    );

    sentSignalsNotifier.value = [newSignal, ...sentSignalsNotifier.value];

    final isMutual = hasReceivedSignalFrom(receiver.id);

    if (isMutual) {
      _markMutualWith(receiver.id);

      ChatService.createChatRoom(currentUser: currentUser, otherUser: receiver);

      return 'Mutual signal với ${receiver.nickname}! Phòng chat đã được mở.';
    }

    return 'Đã gửi signal đến ${receiver.nickname}.';
  }

  static String signalBack({
    required UserProfile currentUser,
    required String senderId,
    String message = 'Mình cũng thấy bạn hợp vibe, kết nối nhé!',
  }) {
    final sender = _findUserById(senderId);

    if (sender == null) {
      return 'Không tìm thấy người dùng này.';
    }

    return sendSignal(
      currentUser: currentUser,
      receiver: sender,
      message: message,
    );
  }

  static void _markMutualWith(String otherUserId) {
    sentSignalsNotifier.value = sentSignalsNotifier.value.map((signal) {
      if (signal.receiverId == otherUserId || signal.senderId == otherUserId) {
        return signal.copyWith(status: 'mutual');
      }

      return signal;
    }).toList();

    receivedSignalsNotifier.value = receivedSignalsNotifier.value.map((signal) {
      if (signal.senderId == otherUserId || signal.receiverId == otherUserId) {
        return signal.copyWith(status: 'mutual');
      }

      return signal;
    }).toList();
  }

  static UserProfile? _findUserById(String userId) {
    if (currentUser.id == userId) {
      return currentUser;
    }

    try {
      return mockUsers.firstWhere((user) => user.id == userId);
    } catch (_) {
      return null;
    }
  }

  static void clearSignals() {
    sentSignalsNotifier.value = [];

    receivedSignalsNotifier.value = [];
  }
}
