import 'package:cloud_firestore/cloud_firestore.dart';

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
  final DateTime? updatedAt;
  final String? chatRoomId;

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
    this.updatedAt,
    this.chatRoomId,
  });

  factory VibeSignal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return VibeSignal(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? '',
      receiverId: data['receiverId']?.toString() ?? '',
      receiverName: data['receiverName']?.toString() ?? '',
      type: data['type']?.toString() ?? 'vibe',
      message: data['message']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: data['updatedAt'] == null
          ? null
          : _parseDateTime(data['updatedAt']),
      chatRoomId: data['chatRoomId']?.toString(),
    );
  }

  factory VibeSignal.fromMap(Map<String, dynamic> map) {
    return VibeSignal(
      id: map['id']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      receiverId: map['receiverId']?.toString() ?? '',
      receiverName: map['receiverName']?.toString() ?? '',
      type: map['type']?.toString() ?? 'vibe',
      message: map['message']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] == null
          ? null
          : _parseDateTime(map['updatedAt']),
      chatRoomId: map['chatRoomId']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'type': type,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'chatRoomId': chatRoomId,
    };
  }

  Map<String, dynamic> toMap() => toFirestore();

  VibeSignal copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? receiverName,
    String? type,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? chatRoomId,
  }) {
    return VibeSignal(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      type: type ?? this.type,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chatRoomId: chatRoomId ?? this.chatRoomId,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
