import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UniNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String targetType;
  final String targetId;
  final bool isRead;
  final DateTime createdAt;

  const UniNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.targetType,
    required this.targetId,
    required this.isRead,
    required this.createdAt,
  });

  factory UniNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return UniNotification(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      targetType: data['targetType']?.toString() ?? '',
      targetId: data['targetId']?.toString() ?? '',
      isRead: data['isRead'] == true,
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

class NotificationService {
  NotificationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _notificationsRef {
    return _db.collection('notifications');
  }

  static Stream<List<UniNotification>> myNotificationsStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _notificationsRef
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(UniNotification.fromDoc).toList();
        });
  }

  static Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String targetType = '',
    String targetId = '',
  }) async {
    final notificationRef = _notificationsRef.doc();

    await notificationRef.set({
      'id': notificationRef.id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'targetType': targetType,
      'targetId': targetId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markAllAsRead() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final snapshot = await _notificationsRef
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
