import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../models/vibe_signal.dart';

class SignalService {
  static final ValueNotifier<List<VibeSignal>> sentSignalsNotifier =
      ValueNotifier<List<VibeSignal>>([]);

  static const int dailySignalLimit = 5;

  static List<VibeSignal> get sentSignals {
    return sentSignalsNotifier.value;
  }

  static bool hasSentSignalTo(String receiverId) {
    return sentSignals.any((signal) => signal.receiverId == receiverId);
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

    final newSignal = VibeSignal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUser.id,
      receiverId: receiver.id,
      receiverName: receiver.nickname,
      type: type,
      message: message,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    sentSignalsNotifier.value = [newSignal, ...sentSignalsNotifier.value];

    return 'Đã gửi signal đến ${receiver.nickname}.';
  }

  static void clearSignals() {
    sentSignalsNotifier.value = [];
  }
}
