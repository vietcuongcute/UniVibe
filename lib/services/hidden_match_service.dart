import 'package:flutter/material.dart';

import '../models/user_profile.dart';

class HiddenMatchService {
  static final ValueNotifier<Set<String>> hiddenUserIdsNotifier =
      ValueNotifier<Set<String>>({});

  static Set<String> get hiddenUserIds => hiddenUserIdsNotifier.value;

  static bool isHidden(String userId) {
    return hiddenUserIds.contains(userId);
  }

  static String hideUser(UserProfile user) {
    final updatedIds = Set<String>.from(hiddenUserIds);
    updatedIds.add(user.id);

    hiddenUserIdsNotifier.value = updatedIds;

    return 'Đã ẩn ${user.nickname} khỏi Daily Match.';
  }

  static String unhideUser(UserProfile user) {
    final updatedIds = Set<String>.from(hiddenUserIds);
    updatedIds.remove(user.id);

    hiddenUserIdsNotifier.value = updatedIds;

    return 'Đã hoàn tác ẩn ${user.nickname}.';
  }

  static void clearHiddenUsers() {
    hiddenUserIdsNotifier.value = {};
  }
}
