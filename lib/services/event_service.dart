import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/uni_event.dart';

class EventService {
  EventService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _eventsRef {
    return _db.collection('events');
  }

  static Stream<List<UniEvent>> upcomingEventsStream() {
    return _eventsRef
        .where('status', isEqualTo: 'active')
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();

          return snapshot.docs
              .map(UniEvent.fromDoc)
              .where((event) => event.endAt.isAfter(now))
              .toList();
        });
  }

  static Future<void> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startAt,
    required DateTime endAt,
    String clubId = '',
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    if (title.trim().isEmpty) {
      throw Exception('Vui lòng nhập tên sự kiện.');
    }

    if (!endAt.isAfter(startAt)) {
      throw Exception('Thời gian kết thúc phải sau thời gian bắt đầu.');
    }

    final now = FieldValue.serverTimestamp();
    final eventRef = _eventsRef.doc();

    await eventRef.set({
      'id': eventRef.id,
      'clubId': clubId.trim(),
      'creatorId': user.uid,
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'status': 'active',
      'attendeeIds': [],
      'createdAt': now,
      'updatedAt': now,
    });
  }

  static Future<void> joinEvent(String eventId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    await _eventsRef.doc(eventId).update({
      'attendeeIds': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> leaveEvent(String eventId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    await _eventsRef.doc(eventId).update({
      'attendeeIds': FieldValue.arrayRemove([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
