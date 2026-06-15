import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminChatManagementScreen extends StatefulWidget {
  const AdminChatManagementScreen({super.key});

  @override
  State<AdminChatManagementScreen> createState() =>
      _AdminChatManagementScreenState();
}

class _AdminChatManagementScreenState extends State<AdminChatManagementScreen> {
  static const Color _primary = Color(0xFF7B61FF);
  static const Color _secondary = Color(0xFFEC5AA6);
  static const Color _darkText = Color(0xFF2D1B69);
  static const Color _bg = Color(0xFFF7F3FF);

  String _searchKeyword = '';

  String _safeText(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _formatTime(dynamic value) {
    final date = _toDateTime(value);
    if (date == null) return 'Chưa rõ thời gian';

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  List<String> _extractUserIds(Map<String, dynamic> data) {
    final rawUserIds = data['userIds'];

    if (rawUserIds is List) {
      return rawUserIds
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    final rawParticipants = data['participants'];
    if (rawParticipants is List) {
      return rawParticipants
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    final rawMembers = data['members'];
    if (rawMembers is Map) {
      return rawMembers.keys
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    return [];
  }

  String _extractLastMessage(Map<String, dynamic> data) {
    return _safeText(
      data['lastMessage'],
      fallback: _safeText(
        data['lastMessageText'],
        fallback: _safeText(data['preview'], fallback: 'Chưa có tin nhắn'),
      ),
    );
  }

  dynamic _extractLastMessageTime(Map<String, dynamic> data) {
    return data['lastMessageAt'] ??
        data['updatedAt'] ??
        data['createdAt'] ??
        data['lastUpdatedAt'];
  }

  Future<Map<String, Map<String, dynamic>>> _loadUsersMap(
    List<String> userIds,
  ) async {
    final result = <String, Map<String, dynamic>>{};

    for (final userId in userIds.toSet()) {
      if (userId.trim().isEmpty) continue;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      result[userId] = doc.data() ?? {};
    }

    return result;
  }

  String _userDisplayName(String userId, Map<String, dynamic> userData) {
    return _safeText(
      userData['nickname'],
      fallback: _safeText(
        userData['displayName'],
        fallback: _safeText(userData['email'], fallback: userId),
      ),
    );
  }

  String _chatRoomTitle(
    Map<String, dynamic> chatRoomData,
    Map<String, Map<String, dynamic>> usersMap,
  ) {
    final roomName = _safeText(chatRoomData['name']);
    if (roomName.isNotEmpty) return roomName;

    final userIds = _extractUserIds(chatRoomData);
    if (userIds.isEmpty) return 'Phòng chat không rõ thành viên';

    final names = userIds.map((id) {
      return _userDisplayName(id, usersMap[id] ?? {});
    }).toList();

    return names.join(' ↔ ');
  }

  bool _matchSearch({
    required String roomId,
    required Map<String, dynamic> chatRoomData,
    required Map<String, Map<String, dynamic>> usersMap,
  }) {
    final keyword = _searchKeyword.trim().toLowerCase();
    if (keyword.isEmpty) return true;

    final title = _chatRoomTitle(chatRoomData, usersMap).toLowerCase();
    final lastMessage = _extractLastMessage(chatRoomData).toLowerCase();

    return roomId.toLowerCase().contains(keyword) ||
        title.contains(keyword) ||
        lastMessage.contains(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        children: [
          _buildIntroCard(),
          const SizedBox(height: 14),
          _buildSearchBox(),
          const SizedBox(height: 14),
          _buildChatRoomsList(),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, _secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý đoạn chat',
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Admin có thể xem tất cả phòng chat, thành viên và nội dung tin nhắn để kiểm duyệt khi cần.',
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: _cardDecoration(),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchKeyword = value;
          });
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search_rounded, color: _primary),
          hintText:
              'Tìm theo tên user, nội dung tin nhắn hoặc mã phòng chat...',
          hintStyle: TextStyle(
            color: Colors.black38,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildChatRoomsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chatRooms')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildStateCard(
            icon: Icons.error_outline_rounded,
            title: 'Không tải được chatRooms',
            subtitle: snapshot.error.toString(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(color: _primary),
            ),
          );
        }

        final rooms = snapshot.data?.docs ?? [];

        if (rooms.isEmpty) {
          return _buildStateCard(
            icon: Icons.forum_outlined,
            title: 'Chưa có phòng chat',
            subtitle:
                'Khi user mutual signal hoặc blind chat, phòng chat sẽ hiện ở đây.',
          );
        }

        final allUserIds = <String>[];
        for (final room in rooms) {
          allUserIds.addAll(_extractUserIds(room.data()));
        }

        return FutureBuilder<Map<String, Map<String, dynamic>>>(
          future: _loadUsersMap(allUserIds),
          builder: (context, userSnapshot) {
            final usersMap = userSnapshot.data ?? {};

            final filteredRooms = rooms.where((room) {
              return _matchSearch(
                roomId: room.id,
                chatRoomData: room.data(),
                usersMap: usersMap,
              );
            }).toList();

            if (filteredRooms.isEmpty) {
              return _buildStateCard(
                icon: Icons.search_off_rounded,
                title: 'Không tìm thấy đoạn chat',
                subtitle:
                    'Thử tìm bằng tên user, email, nội dung tin nhắn hoặc mã phòng.',
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tổng ${filteredRooms.length} phòng chat',
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (userSnapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...filteredRooms.map((room) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildChatRoomCard(room: room, usersMap: usersMap),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildChatRoomCard({
    required QueryDocumentSnapshot<Map<String, dynamic>> room,
    required Map<String, Map<String, dynamic>> usersMap,
  }) {
    final data = room.data();
    final userIds = _extractUserIds(data);
    final title = _chatRoomTitle(data, usersMap);
    final lastMessage = _extractLastMessage(data);
    final lastTime = _extractLastMessageTime(data);
    final type = _safeText(
      data['type'],
      fallback: _safeText(data['roomType'], fallback: 'normal'),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminChatDetailScreen(
              chatRoomId: room.id,
              chatRoomData: data,
              usersMap: usersMap,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoomAvatar(userIds, usersMap),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black38,
                  size: 26,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPill(
                  icon: Icons.schedule_rounded,
                  text: _formatTime(lastTime),
                ),
                _buildPill(
                  icon: Icons.people_alt_rounded,
                  text: '${userIds.length} thành viên',
                ),
                _buildPill(
                  icon: Icons.category_rounded,
                  text: type == 'blind' ? 'Blind Chat' : 'Chat thường',
                ),
                _buildPill(icon: Icons.tag_rounded, text: room.id),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomAvatar(
    List<String> userIds,
    Map<String, Map<String, dynamic>> usersMap,
  ) {
    final firstUserId = userIds.isEmpty ? '' : userIds.first;
    final firstUser = usersMap[firstUserId] ?? {};
    final avatarUrl = _safeText(firstUser['avatarUrl']);
    final name = _userDisplayName(firstUserId, firstUser);
    final firstLetter = name.trim().isEmpty
        ? '?'
        : name.trim()[0].toUpperCase();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: const Color(0xFFEDE7FF),
          backgroundImage: avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl.isEmpty
              ? Text(
                  firstLetter,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _secondary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Colors.white,
              size: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _primary.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _primary, size: 15),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _darkText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: _primary, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.7)),
      boxShadow: [
        BoxShadow(
          color: Colors.purple.withOpacity(0.06),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class AdminChatDetailScreen extends StatelessWidget {
  const AdminChatDetailScreen({
    super.key,
    required this.chatRoomId,
    required this.chatRoomData,
    required this.usersMap,
  });

  final String chatRoomId;
  final Map<String, dynamic> chatRoomData;
  final Map<String, Map<String, dynamic>> usersMap;

  static const Color _primary = Color(0xFF7B61FF);
  static const Color _secondary = Color(0xFFEC5AA6);
  static const Color _darkText = Color(0xFF2D1B69);
  static const Color _bg = Color(0xFFF7F3FF);

  String _safeText(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _formatTime(dynamic value) {
    final date = _toDateTime(value);
    if (date == null) return 'Chưa rõ thời gian';

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  List<String> _extractUserIds(Map<String, dynamic> data) {
    final rawUserIds = data['userIds'];

    if (rawUserIds is List) {
      return rawUserIds
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    final rawParticipants = data['participants'];
    if (rawParticipants is List) {
      return rawParticipants
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    final rawMembers = data['members'];
    if (rawMembers is Map) {
      return rawMembers.keys
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    return [];
  }

  String _userDisplayName(String userId, Map<String, dynamic> userData) {
    return _safeText(
      userData['nickname'],
      fallback: _safeText(
        userData['displayName'],
        fallback: _safeText(userData['email'], fallback: userId),
      ),
    );
  }

  String _messageText(Map<String, dynamic> data) {
    return _safeText(
      data['text'],
      fallback: _safeText(
        data['message'],
        fallback: _safeText(data['content'], fallback: '[Tin nhắn trống]'),
      ),
    );
  }

  String _senderId(Map<String, dynamic> data) {
    return _safeText(
      data['senderId'],
      fallback: _safeText(data['userId'], fallback: _safeText(data['fromId'])),
    );
  }

  dynamic _messageCreatedAt(Map<String, dynamic> data) {
    return data['createdAt'] ?? data['sentAt'] ?? data['timestamp'];
  }

  String _chatRoomTitle() {
    final roomName = _safeText(chatRoomData['name']);
    if (roomName.isNotEmpty) return roomName;

    final userIds = _extractUserIds(chatRoomData);
    if (userIds.isEmpty) return 'Chi tiết phòng chat';

    return userIds
        .map((id) {
          return _userDisplayName(id, usersMap[id] ?? {});
        })
        .join(' ↔ ');
  }

  @override
  Widget build(BuildContext context) {
    final userIds = _extractUserIds(chatRoomData);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkText,
        elevation: 0,
        title: Text(
          _chatRoomTitle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          _buildRoomInfo(userIds),
          Expanded(child: _buildMessagesList()),
        ],
      ),
    );
  }

  Widget _buildRoomInfo(List<String> userIds) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin phòng chat',
            style: TextStyle(
              color: _darkText,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPill(icon: Icons.tag_rounded, text: chatRoomId),
              _buildPill(
                icon: Icons.people_alt_rounded,
                text: '${userIds.length} thành viên',
              ),
              _buildPill(
                icon: Icons.schedule_rounded,
                text: 'Tạo: ${_formatTime(chatRoomData['createdAt'])}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...userIds.map((userId) {
            final data = usersMap[userId] ?? {};
            final name = _userDisplayName(userId, data);
            final email = _safeText(data['email'], fallback: 'Chưa có email');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFFEDE7FF),
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '$name • $email',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Không tải được messages: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }

        final messages = snapshot.data?.docs ?? [];

        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'Phòng này chưa có tin nhắn.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            final data = doc.data();

            final senderId = _senderId(data);
            final senderData = usersMap[senderId] ?? {};
            final senderName = senderId == 'system'
                ? 'Hệ thống'
                : _userDisplayName(senderId, senderData);

            final text = _messageText(data);
            final createdAt = _messageCreatedAt(data);

            return _buildMessageItem(
              senderName: senderName,
              senderId: senderId,
              text: text,
              time: _formatTime(createdAt),
              messageId: doc.id,
            );
          },
        );
      },
    );
  }

  Widget _buildMessageItem({
    required String senderName,
    required String senderId,
    required String text,
    required String time,
    required String messageId,
  }) {
    final isSystem = senderId == 'system';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSystem ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSystem
              ? const Color(0xFFFFC107).withOpacity(0.22)
              : _primary.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSystem
                    ? Icons.auto_awesome_rounded
                    : Icons.account_circle_rounded,
                color: isSystem ? const Color(0xFFFF9800) : _primary,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Message ID: $messageId',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black26,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _primary, size: 15),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _darkText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.purple.withOpacity(0.06),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
