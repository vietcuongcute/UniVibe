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
  final DateTime updatedAt;
  final String? chatRoomId;
  final String pairId;
  final List<String> userIds;

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
    required this.updatedAt,
    this.chatRoomId,
    required this.pairId,
    required this.userIds,
  });

  factory VibeSignal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return VibeSignal.fromMap({...data, 'id': data['id'] ?? doc.id});
  }

  factory VibeSignal.fromMap(Map<String, dynamic> map) {
    final senderId = map['senderId']?.toString() ?? '';
    final receiverId = map['receiverId']?.toString() ?? '';

    return VibeSignal(
      id: map['id']?.toString() ?? '',
      senderId: senderId,
      senderName: map['senderName']?.toString() ?? '',
      receiverId: receiverId,
      receiverName: map['receiverName']?.toString() ?? '',
      type: map['type']?.toString() ?? 'vibe',
      message: map['message']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      chatRoomId: map['chatRoomId']?.toString(),
      pairId: map['pairId']?.toString() ?? _pairId(senderId, receiverId),
      userIds: _parseStringList(map['userIds']).isNotEmpty
          ? _parseStringList(map['userIds'])
          : [senderId, receiverId],
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
      'updatedAt': Timestamp.fromDate(updatedAt),
      'chatRoomId': chatRoomId,
      'pairId': pairId,
      'userIds': userIds,
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
    String? pairId,
    List<String>? userIds,
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
      pairId: pairId ?? this.pairId,
      userIds: userIds ?? this.userIds,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  static String _pairId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
