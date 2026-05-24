import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../models/user_report.dart';

class ReportService {
  static final ValueNotifier<List<UserReport>> reportsNotifier =
      ValueNotifier<List<UserReport>>([]);

  static List<UserReport> get reports {
    return reportsNotifier.value;
  }

  static String reportUser({
    required UserProfile currentUser,
    required UserProfile targetUser,
    required String reason,
    String detail = '',
  }) {
    final newReport = UserReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reporterId: currentUser.id,
      targetUserId: targetUser.id,
      targetUserName: targetUser.nickname,
      reason: reason,
      detail: detail,
      createdAt: DateTime.now(),
    );

    reportsNotifier.value = [newReport, ...reportsNotifier.value];

    return 'Đã gửi report về ${targetUser.nickname}.';
  }

  static void clearReports() {
    reportsNotifier.value = [];
  }
}
