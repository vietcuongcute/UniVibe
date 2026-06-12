import 'package:cloud_firestore/cloud_firestore.dart';

class UniClub {
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final String category;
  final String status;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UniClub({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.category,
    required this.status,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UniClub.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return UniClub(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      leaderId: data['leaderId']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Khác',
      status: data['status']?.toString() ?? 'active',
      memberIds: (data['memberIds'] as List? ?? [])
          .map((item) => item.toString())
          .toList(),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
