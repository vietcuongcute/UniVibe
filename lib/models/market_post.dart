import 'package:cloud_firestore/cloud_firestore.dart';

class MarketPost {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final num price;
  final String category;
  final List<String> imageUrls;
  final String status;
  final bool isHidden;
  final int reportCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketPost({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrls,
    required this.status,
    required this.isHidden,
    required this.reportCount,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSold => status == 'sold';

  bool get visibleToUser {
    return !isHidden && status != 'hidden' && status != 'deleted';
  }

  factory MarketPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return MarketPost(
      id: doc.id,
      sellerId: data['sellerId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: _parsePrice(data['price']),
      category: data['category']?.toString() ?? 'Khác',
      imageUrls: _parseStringList(data['imageUrls']),
      status: data['status']?.toString() ?? 'active',
      isHidden: data['isHidden'] == true,
      reportCount: _parseInt(data['reportCount']),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  static num _parsePrice(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }
}
