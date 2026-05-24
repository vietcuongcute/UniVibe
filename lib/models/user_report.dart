class UserReport {
  final String id;
  final String reporterId;
  final String targetUserId;
  final String targetUserName;
  final String reason;
  final String detail;
  final DateTime createdAt;

  UserReport({
    required this.id,
    required this.reporterId,
    required this.targetUserId,
    required this.targetUserName,
    required this.reason,
    required this.detail,
    required this.createdAt,
  });
}
