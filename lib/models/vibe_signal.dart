class VibeSignal {
  final String id;
  final String senderId;
  final String receiverId;
  final String receiverName;
  final String type;
  final String message;
  final String status;
  final DateTime createdAt;

  VibeSignal({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
    required this.type,
    required this.message,
    required this.status,
    required this.createdAt,
  });
}
