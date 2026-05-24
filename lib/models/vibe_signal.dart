class VibeSignal {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String type;
  final String message;
  final String status;
  final DateTime createdAt;

  VibeSignal({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.type,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  VibeSignal copyWith({String? status}) {
    return VibeSignal(
      id: id,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      receiverName: receiverName,
      type: type,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
