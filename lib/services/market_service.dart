import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/market_post.dart';
import '../models/user_profile.dart';
import 'report_service.dart';

class MarketService {
  MarketService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _marketPostsRef {
    return _db.collection('marketPosts');
  }

  static CollectionReference<Map<String, dynamic>> get _usersRef {
    return _db.collection('users');
  }

  static CollectionReference<Map<String, dynamic>> get _chatRoomsRef {
    return _db.collection('chatRooms');
  }

  static Stream<List<MarketPost>> marketPostsStream({
    String category = 'Tất cả',
    String keyword = '',
    bool includeSold = true,
  }) {
    return _marketPostsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final lowerKeyword = keyword.trim().toLowerCase();

          return snapshot.docs
              .map((doc) => MarketPost.fromDoc(doc))
              .where((post) => post.status != 'hidden')
              .where((post) => post.status != 'deleted')
              .where((post) => includeSold || post.status != 'sold')
              .where((post) {
                if (category == 'Tất cả' || category.trim().isEmpty) {
                  return true;
                }
                return post.category == category;
              })
              .where((post) {
                if (lowerKeyword.isEmpty) return true;

                return post.title.toLowerCase().contains(lowerKeyword) ||
                    post.description.toLowerCase().contains(lowerKeyword) ||
                    post.category.toLowerCase().contains(lowerKeyword);
              })
              .toList();
        });
  }

  static Future<void> createPost({
    required String title,
    required String description,
    required num price,
    required String category,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();

    if (trimmedTitle.isEmpty) {
      throw Exception('Vui lòng nhập tiêu đề bài đăng.');
    }

    if (trimmedDescription.isEmpty) {
      throw Exception('Vui lòng nhập mô tả bài đăng.');
    }

    if (price < 0) {
      throw Exception('Giá không hợp lệ.');
    }

    final now = FieldValue.serverTimestamp();

    await _marketPostsRef.add({
      'sellerId': user.uid,
      'title': trimmedTitle,
      'description': trimmedDescription,
      'price': price,
      'category': category,
      'imageUrls': [],
      'status': 'active',
      'isHidden': false,
      'reportCount': 0,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  static Future<void> markAsSold(String postId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final postRef = _marketPostsRef.doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw Exception('Bài đăng không tồn tại.');
    }

    final data = postDoc.data() ?? {};
    final sellerId = data['sellerId']?.toString() ?? '';

    if (sellerId != user.uid) {
      throw Exception('Bạn chỉ có thể đánh dấu đã bán bài của chính mình.');
    }

    await postRef.update({
      'status': 'sold',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<MarketPost?> marketPostStream(String postId) {
    return _marketPostsRef.doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;

      final post = MarketPost.fromDoc(doc);

      if (post.status == 'hidden' || post.status == 'deleted') {
        return null;
      }

      return post;
    });
  }

  static Future<void> updatePost({
    required String postId,
    required String title,
    required String description,
    required num price,
    required String category,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();

    if (trimmedTitle.isEmpty) {
      throw Exception('Vui lòng nhập tiêu đề bài đăng.');
    }

    if (trimmedDescription.isEmpty) {
      throw Exception('Vui lòng nhập mô tả bài đăng.');
    }

    if (price < 0) {
      throw Exception('Giá không hợp lệ.');
    }

    final postRef = _marketPostsRef.doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw Exception('Bài đăng không tồn tại.');
    }

    final data = postDoc.data() ?? {};
    final sellerId = data['sellerId']?.toString() ?? '';

    if (sellerId != user.uid) {
      throw Exception('Bạn chỉ có thể chỉnh sửa bài của chính mình.');
    }

    await postRef.update({
      'title': trimmedTitle,
      'description': trimmedDescription,
      'price': price,
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final postRef = _marketPostsRef.doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw Exception('Bài đăng không tồn tại.');
    }

    final data = postDoc.data() ?? {};
    final sellerId = data['sellerId']?.toString() ?? '';

    if (sellerId != user.uid) {
      throw Exception('Bạn chỉ có thể xoá bài của chính mình.');
    }

    await postRef.update({
      'status': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<String> startChatWithSeller(MarketPost post) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    if (post.sellerId.isEmpty) {
      throw Exception('Không tìm thấy người bán.');
    }

    if (post.sellerId == currentUser.uid) {
      throw Exception('Đây là bài đăng của bạn.');
    }

    final existingRoomId = await _findExistingDirectRoom(
      currentUserId: currentUser.uid,
      sellerId: post.sellerId,
    );

    if (existingRoomId != null) {
      return existingRoomId;
    }

    final currentProfile = await _getUserProfile(currentUser.uid);
    final sellerProfile = await _getUserProfile(post.sellerId);

    final pairId = _pairId(currentUser.uid, post.sellerId);
    final chatRoomId = 'chat_market_$pairId';
    final now = FieldValue.serverTimestamp();

    final chatRoomRef = _chatRoomsRef.doc(chatRoomId);
    final welcomeMessageRef = chatRoomRef.collection('messages').doc();

    final batch = _db.batch();

    batch.set(chatRoomRef, {
      'id': chatRoomId,
      'userIds': [currentUser.uid, post.sellerId],
      'pairId': pairId,
      'type': 'market',
      'marketPostId': post.id,
      'status': 'active',
      'deletedFor': [],
      'createdAt': now,
      'updatedAt': now,
      'lastMessage': 'Bắt đầu chat từ Market: ${post.title}',
      'lastMessageSenderId': 'system',
      'members': {
        currentUser.uid: _memberMap(currentProfile),
        post.sellerId: _memberMap(sellerProfile),
      },
    }, SetOptions(merge: true));

    batch.set(welcomeMessageRef, {
      'id': welcomeMessageRef.id,
      'chatRoomId': chatRoomId,
      'senderId': 'system',
      'text': 'Bạn đang chat về bài Market: ${post.title}',
      'createdAt': now,
    });

    await batch.commit();

    return chatRoomId;
  }

  static Future<String> reportMarketPost({
    required String postId,
    required String sellerId,
    required String reason,
    required String description,
  }) async {
    final message = await ReportService.createReport(
      targetType: 'marketPost',
      targetId: postId,
      targetOwnerId: sellerId,
      reason: reason,
      detail: description,
    );

    if (message.startsWith('Đã gửi report')) {
      await _marketPostsRef.doc(postId).update({
        'reportCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return message;
  }

  static Future<String?> _findExistingDirectRoom({
    required String currentUserId,
    required String sellerId,
  }) async {
    final snapshot = await _chatRoomsRef
        .where('userIds', arrayContains: currentUserId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final userIds = (data['userIds'] as List? ?? [])
          .map((item) => item.toString())
          .toList();

      final type = data['type']?.toString() ?? 'normal';
      final status = data['status']?.toString() ?? 'active';

      if (userIds.contains(sellerId) && type != 'blind' && status != 'ended') {
        return doc.id;
      }
    }

    return null;
  }

  static Future<UserProfile> getSellerProfile(String sellerId) async {
    if (sellerId.trim().isEmpty) {
      throw Exception('Không tìm thấy người bán.');
    }

    return _getUserProfile(sellerId);
  }

  static Future<UserProfile> _getUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    final data = doc.data();

    if (data == null) {
      return UserProfile(
        id: uid,
        nickname: 'Người dùng UniVibe',
        avatarUrl: '',
        coverUrl: '',
        university: '',
        major: '',
        year: 1,
        gender: '',
        interests: const [],
        goals: const [],
        vibeTags: const [],
        featuredImageUrls: const [],
        bio: '',
      );
    }

    return UserProfile.fromMap({...data, 'id': data['id'] ?? doc.id});
  }

  static Map<String, dynamic> _memberMap(UserProfile profile) {
    return {
      'id': profile.id,
      'nickname': profile.nickname,
      'avatarUrl': profile.avatarUrl,
      'university': profile.university,
      'major': profile.major,
      'year': profile.year,
    };
  }

  static String _pairId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
