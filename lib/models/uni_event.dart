import 'package:cloud_firestore/cloud_firestore.dart';

class UniEvent {
  final String id;
  final String clubId;
  final String creatorId;
  final String title;
  final String description;
  final String location;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final List<String> attendeeIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UniEvent({
    required this.id,
    required this.clubId,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.location,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.attendeeIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UniEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return UniEvent(
      id: doc.id,
      clubId: data['clubId']?.toString() ?? '',
      creatorId: data['creatorId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      startAt: _parseDate(data['startAt']),
      endAt: _parseDate(data['endAt']),
      status: data['status']?.toString() ?? 'active',
      attendeeIds: (data['attendeeIds'] as List? ?? [])
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
