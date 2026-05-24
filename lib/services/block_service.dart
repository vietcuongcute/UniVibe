import 'package:flutter/material.dart';

import '../models/user_profile.dart';

class BlockService {
  static final ValueNotifier<List<String>> blockedUserIdsNotifier =
      ValueNotifier<List<String>>([]);

  static List<String> get blockedUserIds {
    return blockedUserIdsNotifier.value;
  }

  static bool isBlocked(String userId) {
    return blockedUserIds.contains(userId);
  }

  static String blockUser(UserProfile user) {
    if (isBlocked(user.id)) {
      return 'Bạn đã block ${user.nickname} rồi.';
    }

    blockedUserIdsNotifier.value = [user.id, ...blockedUserIdsNotifier.value];

    return 'Đã block ${user.nickname}. Người này sẽ không còn hiện trong Daily Match.';
  }

  static String unblockUser(UserProfile user) {
    if (!isBlocked(user.id)) {
      return '${user.nickname} chưa bị block.';
    }

    blockedUserIdsNotifier.value = blockedUserIds
        .where((blockedUserId) => blockedUserId != user.id)
        .toList();

    return 'Đã bỏ block ${user.nickname}.';
  }

  static void clearBlockedUsers() {
    blockedUserIdsNotifier.value = [];
  }
}
