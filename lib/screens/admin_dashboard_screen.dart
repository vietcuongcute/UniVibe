import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_content_detail_screen.dart';
import 'auth_gate.dart';

import '../services/admin_service.dart';
import '../services/chat_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color _primary = Color(0xFF7B61FF);
  static const Color _secondary = Color(0xFFEC5AA6);
  static const Color _darkText = Color(0xFF2D1B69);
  static const Color _bg = Color(0xFFF7F3FF);

  late final Future<bool> _adminAccessFuture;

  int _selectedTabIndex = 0;
  String _contentType = 'confessions';
  String _reportFilter = 'all';
  String _userSearchKeyword = '';

  final List<_AdminTabItem> _tabs = const [
    _AdminTabItem(
      title: 'Tổng quan',
      subtitle: 'Số liệu hệ thống',
      icon: Icons.dashboard_rounded,
    ),
    _AdminTabItem(
      title: 'Reports',
      subtitle: 'Kiểm duyệt report',
      icon: Icons.flag_rounded,
    ),
    _AdminTabItem(
      title: 'Users',
      subtitle: 'Quản lý tài khoản',
      icon: Icons.people_alt_rounded,
    ),
    _AdminTabItem(
      title: 'Nội dung',
      subtitle: 'Bài đăng trong app',
      icon: Icons.article_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _adminAccessFuture = AdminService.hasAdminAccess();
  }

  String? _collectionFromTargetType(String targetType) {
    switch (targetType) {
      case 'marketPost':
      case 'marketPosts':
        return 'marketPosts';

      case 'confession':
      case 'confessions':
        return 'confessions';

      case 'moment':
      case 'moments':
        return 'moments';

      case 'user':
      case 'users':
        return 'users';

      default:
        return null;
    }
  }

  String _labelFromTargetType(String targetType) {
    switch (targetType) {
      case 'marketPost':
      case 'marketPosts':
        return 'Bài Market';

      case 'confession':
      case 'confessions':
        return 'Confession';

      case 'moment':
      case 'moments':
        return 'UniMoment';

      case 'user':
      case 'users':
        return 'Người dùng';

      default:
        return 'Nội dung';
    }
  }

  String _safeText(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _extractTargetTitle({
    required String targetType,
    required Map<String, dynamic> reportData,
    Map<String, dynamic>? targetData,
  }) {
    final fromReport = _safeText(reportData['targetTitle']);
    if (fromReport.isNotEmpty) {
      return fromReport;
    }

    if (targetData == null) {
      return _labelFromTargetType(targetType);
    }

    if (targetType == 'marketPost' || targetType == 'marketPosts') {
      return _safeText(
        targetData['title'],
        fallback: 'Bài Market không có tiêu đề',
      );
    }

    if (targetType == 'confession' || targetType == 'confessions') {
      return _safeText(
        targetData['content'],
        fallback: 'Confession không có nội dung',
      );
    }

    if (targetType == 'moment' || targetType == 'moments') {
      return _safeText(
        targetData['text'],
        fallback: 'UniMoment không có nội dung',
      );
    }

    if (targetType == 'user' || targetType == 'users') {
      return _safeText(
        targetData['nickname'],
        fallback: _safeText(targetData['email'], fallback: 'Người dùng'),
      );
    }

    return _labelFromTargetType(targetType);
  }

  String _extractTargetPreview({
    required String targetType,
    required Map<String, dynamic> reportData,
    Map<String, dynamic>? targetData,
  }) {
    final fromReport = _safeText(reportData['targetPreview']);
    if (fromReport.isNotEmpty) {
      return fromReport;
    }

    final detail = _safeText(reportData['detail']);
    if (detail.isNotEmpty) {
      return detail;
    }

    if (targetData == null) {
      return 'Chưa tải được nội dung gốc.';
    }

    if (targetType == 'marketPost' || targetType == 'marketPosts') {
      final description = _safeText(targetData['description']);
      final price = _safeText(targetData['price']);
      final category = _safeText(targetData['category']);

      final parts = <String>[
        if (description.isNotEmpty) description,
        if (price.isNotEmpty) 'Giá: $price',
        if (category.isNotEmpty) 'Danh mục: $category',
      ];

      return parts.isEmpty ? 'Bài Market chưa có mô tả.' : parts.join('\n');
    }

    if (targetType == 'confession' || targetType == 'confessions') {
      return _safeText(
        targetData['content'],
        fallback: 'Confession chưa có nội dung.',
      );
    }

    if (targetType == 'moment' || targetType == 'moments') {
      return _safeText(
        targetData['text'],
        fallback: 'Moment chưa có nội dung.',
      );
    }

    if (targetType == 'user' || targetType == 'users') {
      final bio = _safeText(targetData['bio']);
      final major = _safeText(targetData['major']);
      final university = _safeText(targetData['university']);

      final parts = <String>[
        if (bio.isNotEmpty) bio,
        if (major.isNotEmpty) 'Ngành: $major',
        if (university.isNotEmpty) 'Trường: $university',
      ];

      return parts.isEmpty ? 'User chưa có thông tin hồ sơ.' : parts.join('\n');
    }

    return 'Không có nội dung xem trước.';
  }

  Future<Map<String, dynamic>?> _loadTargetDataFromReport(
    Map<String, dynamic> reportData,
  ) async {
    final targetType = _safeText(reportData['targetType']);
    final targetId = _safeText(reportData['targetId']);

    if (targetType.isEmpty || targetId.isEmpty) {
      return null;
    }

    final collectionName = _collectionFromTargetType(targetType);

    if (collectionName == null) {
      return null;
    }

    final doc = await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(targetId)
        .get();

    return doc.data();
  }

  String _contentLabel(String collectionName) {
    switch (collectionName) {
      case 'marketPosts':
        return 'Bài Market';
      case 'moments':
        return 'UniMoment';
      case 'confessions':
      default:
        return 'Confession';
    }
  }

  String _contentTitleFromData({
    required String collectionName,
    required Map<String, dynamic> data,
  }) {
    if (collectionName == 'marketPosts') {
      return _safeText(data['title'], fallback: 'Bài Market không có tiêu đề');
    }

    if (collectionName == 'moments') {
      return _safeText(data['text'], fallback: 'UniMoment không có nội dung');
    }

    return _safeText(data['content'], fallback: 'Confession không có nội dung');
  }

  String _contentPreviewFromData({
    required String collectionName,
    required Map<String, dynamic> data,
  }) {
    if (collectionName == 'marketPosts') {
      final description = _safeText(data['description']);
      final category = _safeText(data['category']);
      final price = _safeText(data['price']);

      final parts = <String>[
        if (description.isNotEmpty) description,
        if (category.isNotEmpty) 'Danh mục: $category',
        if (price.isNotEmpty) 'Giá: $price đ',
      ];

      return parts.isEmpty ? 'Bài Market chưa có mô tả.' : parts.join('\n');
    }

    if (collectionName == 'moments') {
      return _safeText(data['text'], fallback: 'Moment chưa có nội dung.');
    }

    return _safeText(data['content'], fallback: 'Confession chưa có nội dung.');
  }

  String _authorIdFromContent(Map<String, dynamic> data) {
    return _safeText(
      data['authorId'],
      fallback: _safeText(
        data['sellerId'],
        fallback: _safeText(data['userId']),
      ),
    );
  }

  Future<String> _loadUserDisplayName(String userId) async {
    if (userId.trim().isEmpty) {
      return 'Không rõ';
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId.trim())
        .get();

    final data = doc.data();

    if (data == null) {
      return 'Không rõ';
    }

    return _safeText(
      data['nickname'],
      fallback: _safeText(data['email'], fallback: 'Không rõ'),
    );
  }

  Widget _buildReportedContentBox(Map<String, dynamic> reportData) {
    final targetType = _safeText(reportData['targetType']);
    final targetId = _safeText(reportData['targetId']);
    final reporterName = _safeText(
      reportData['reporterName'],
      fallback: _safeText(reportData['reporterId'], fallback: 'Không rõ'),
    );

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadTargetDataFromReport(reportData),
      builder: (context, snapshot) {
        final targetData = snapshot.data;

        final title = _extractTargetTitle(
          targetType: targetType,
          reportData: reportData,
          targetData: targetData,
        );

        final preview = _extractTargetPreview(
          targetType: targetType,
          reportData: reportData,
          targetData: targetData,
        );

        final targetLabel = _labelFromTargetType(targetType);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F7FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primary.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMiniInfoRow(
                icon: Icons.person_rounded,
                label: 'Người report',
                value: reporterName,
              ),
              const SizedBox(height: 9),
              _buildMiniInfoRow(
                icon: Icons.category_rounded,
                label: 'Loại nội dung',
                value: targetLabel,
              ),
              const SizedBox(height: 14),
              const Text(
                'Nội dung bị report',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                preview,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.38,
                ),
              ),
              if (targetId.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Mã nội dung: $targetId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black26,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _primary, size: 17),
        const SizedBox(width: 7),
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentPreviewBox({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String title,
    required String preview,
    required String authorId,
  }) {
    return FutureBuilder<String>(
      future: _loadUserDisplayName(authorId),
      builder: (context, snapshot) {
        final authorName = snapshot.data ?? 'Đang tải...';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F7FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primary.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMiniInfoRow(
                icon: Icons.account_circle_rounded,
                label: 'Người đăng',
                value: authorName,
              ),
              const SizedBox(height: 9),
              _buildMiniInfoRow(
                icon: _contentIcon(_contentType),
                label: 'Loại bài',
                value: _contentLabel(_contentType),
              ),
              const SizedBox(height: 14),
              const Text(
                'Bài đăng',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                preview,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.38,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Mã bài: ${doc.id}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black26,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      ChatService.chatRoomsNotifier.value = [];
      await AdminService.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      _showSnack('Đăng xuất thất bại: $e');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Đăng xuất admin?',
            style: TextStyle(color: _darkText, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Bạn có chắc muốn đăng xuất khỏi UniVibe Admin Center không?',
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _logout();
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardAction(Future<void> Function() action) async {
    try {
      await action();
      _showSnack('Đã cập nhật');
    } catch (e) {
      _showSnack('Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminAccessFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(child: CircularProgressIndicator(color: _primary)),
          );
        }

        final allowed = snapshot.data == true;

        if (!allowed) {
          return _buildNoPermissionScreen();
        }

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabSelector(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      _buildOverviewTab(),
                      _buildReportsTab(),
                      _buildUsersTab(),
                      _buildContentTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoPermissionScreen() {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: _darkText,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showLogoutDialog,
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(26),
            decoration: _cardDecoration(),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFFE53935),
                    size: 38,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Không có quyền truy cập',
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Chỉ tài khoản có role admin hoặc moderator mới mở được dashboard này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final currentTab = _tabs[_selectedTabIndex];

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.24),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: AdminService.currentUserStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};

          final nickname =
              data['nickname']?.toString().trim().isNotEmpty == true
              ? data['nickname'].toString()
              : 'Admin UniVibe';

          final role = data['role']?.toString() ?? 'admin';
          final email = data['email']?.toString() ?? '';
          final avatarUrl = data['avatarUrl']?.toString() ?? '';

          final firstLetter = nickname.trim().isEmpty
              ? 'A'
              : nickname.trim()[0].toUpperCase();

          return Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white.withOpacity(0.22),
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        firstLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UniVibe Admin Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${currentTab.title} • ${currentTab.subtitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.84),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildHeaderPill(
                          icon: Icons.person_rounded,
                          text: nickname,
                        ),
                        _buildHeaderPill(
                          icon: Icons.verified_user_rounded,
                          text: role,
                        ),
                        if (email.isNotEmpty)
                          _buildHeaderPill(
                            icon: Icons.mail_rounded,
                            text: email,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildLogoutButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showLogoutDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.26)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 18),
              SizedBox(width: 7),
              Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final tab = _tabs[index];
            final isSelected = _selectedTabIndex == index;

            return _buildTabButton(
              label: tab.title,
              icon: tab.icon,
              isSelected: isSelected,
              onTap: () {
                if (_selectedTabIndex == index) return;

                setState(() {
                  _selectedTabIndex = index;
                });
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final selectedBg = const Color(0xFFEDE7FF);
    final normalText = Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? _primary.withOpacity(0.18)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 21, color: isSelected ? _primary : normalText),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? _primary : normalText,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
        _buildWelcomeCard(),
        const SizedBox(height: 16),
        _buildOverviewStats(),
        const SizedBox(height: 16),
        _buildQuickAdminGuide(),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EAFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.space_dashboard_rounded,
              color: _primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảng điều khiển quản trị',
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Theo dõi user, report, bài đăng và xử lý nội dung vi phạm trong UniVibe.',
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

  Widget _buildOverviewStats() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('reports').snapshots(),
          builder: (context, reportsSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('marketPosts')
                  .snapshots(),
              builder: (context, marketSnapshot) {
                final users = usersSnapshot.data?.docs ?? [];
                final reports = reportsSnapshot.data?.docs ?? [];
                final marketPosts = marketSnapshot.data?.docs ?? [];

                final pendingReports = reports.where((doc) {
                  final data = doc.data();
                  return (data['status'] ?? 'pending') == 'pending';
                }).length;

                final adminCount = users.where((doc) {
                  final data = doc.data();
                  return data['role'] == 'admin';
                }).length;

                final width = MediaQuery.of(context).size.width;
                final crossAxisCount = width >= 1000
                    ? 4
                    : width >= 640
                    ? 2
                    : 1;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: crossAxisCount == 1 ? 3.2 : 1.45,
                  children: [
                    _buildStatCard(
                      title: 'Users',
                      value: users.length.toString(),
                      subtitle: 'Tài khoản sinh viên',
                      icon: Icons.people_alt_rounded,
                      color: _primary,
                    ),
                    _buildStatCard(
                      title: 'Pending reports',
                      value: pendingReports.toString(),
                      subtitle: 'Report chờ xử lý',
                      icon: Icons.flag_rounded,
                      color: const Color(0xFFE53935),
                    ),
                    _buildStatCard(
                      title: 'Market posts',
                      value: marketPosts.length.toString(),
                      subtitle: 'Bài đăng mua bán',
                      icon: Icons.storefront_rounded,
                      color: const Color(0xFF00897B),
                    ),
                    _buildStatCard(
                      title: 'Admins',
                      value: adminCount.toString(),
                      subtitle: 'Tài khoản quản trị',
                      icon: Icons.admin_panel_settings_rounded,
                      color: const Color(0xFFFF9800),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAdminGuide() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.checklist_rounded,
            title: 'Quy trình kiểm duyệt nhanh',
          ),
          SizedBox(height: 14),
          _GuideRow(
            icon: Icons.flag_rounded,
            title: '1. Xem report mới',
            subtitle: 'Ưu tiên xử lý report có trạng thái pending.',
          ),
          _GuideRow(
            icon: Icons.visibility_off_rounded,
            title: '2. Ẩn nội dung vi phạm',
            subtitle: 'Ẩn bài đăng trước nếu nội dung có rủi ro.',
          ),
          _GuideRow(
            icon: Icons.check_circle_rounded,
            title: '3. Đánh dấu đã xử lý',
            subtitle: 'Resolve nếu report đúng, reject nếu report sai.',
          ),
          _GuideRow(
            icon: Icons.people_alt_rounded,
            title: '4. Quản lý role user',
            subtitle: 'Chỉ admin mới nên đổi role cho tài khoản khác.',
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        _buildReportFilters(),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AdminService.reportsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _primary),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final allReports = snapshot.data?.docs ?? [];

              final reports = allReports.where((doc) {
                if (_reportFilter == 'all') return true;

                final data = doc.data();
                final status = data['status']?.toString() ?? 'pending';

                return status == _reportFilter;
              }).toList();

              if (reports.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.flag_outlined,
                  title: 'Không có report phù hợp',
                  subtitle: _reportFilter == 'all'
                      ? 'Khi sinh viên report nội dung, report sẽ hiện ở đây.'
                      : 'Không có report trạng thái $_reportFilter.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  return _buildReportCard(reports[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportFilters() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildReportFilterChip('all', 'Tất cả', Icons.list_rounded),
            const SizedBox(width: 8),
            _buildReportFilterChip(
              'pending',
              'Pending',
              Icons.schedule_rounded,
            ),
            const SizedBox(width: 8),
            _buildReportFilterChip(
              'resolved',
              'Resolved',
              Icons.check_circle_rounded,
            ),
            const SizedBox(width: 8),
            _buildReportFilterChip(
              'rejected',
              'Rejected',
              Icons.cancel_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportFilterChip(String value, String label, IconData icon) {
    final selected = _reportFilter == value;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _reportFilter = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEDE7FF) : const Color(0xFFF9F7FF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _primary.withOpacity(0.32)
                  : Colors.purple.shade100,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? _primary : Colors.black45, size: 17),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? _primary : Colors.black54,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final status = data['status']?.toString() ?? 'pending';
    final targetType = data['targetType']?.toString() ?? '';
    final targetId = data['targetId']?.toString() ?? '';
    final reason = data['reason']?.toString() ?? 'Không có lý do';
    final detail = data['detail']?.toString() ?? '';
    final createdAt = _formatTimestamp(data['createdAt']);

    final canHide = targetType.isNotEmpty && targetId.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusPill(status),
              const Spacer(),
              _buildDatePill(createdAt),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            reason,
            style: const TextStyle(
              color: _darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detail,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
          ],
          const SizedBox(height: 14),
          _buildReportedContentBox(data),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: status == 'resolved'
                    ? null
                    : () => _showAdminNoteSheet(
                        title: 'Resolve report',
                        onConfirm: (note) {
                          return AdminService.resolveReport(
                            reportId: doc.id,
                            adminNote: note,
                          );
                        },
                      ),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Resolve'),
                style: _primaryButtonStyle(),
              ),
              OutlinedButton.icon(
                onPressed: status == 'rejected'
                    ? null
                    : () => _showAdminNoteSheet(
                        title: 'Reject report',
                        onConfirm: (note) {
                          return AdminService.rejectReport(
                            reportId: doc.id,
                            adminNote: note,
                          );
                        },
                      ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Reject'),
                style: _outlineButtonStyle(),
              ),
              if (canHide)
                OutlinedButton.icon(
                  onPressed: status == 'resolved'
                      ? null
                      : () => _showAdminNoteSheet(
                          title: 'Ẩn nội dung bị report',
                          onConfirm: (note) {
                            return AdminService.hideReportedContent(
                              reportId: doc.id,
                              targetType: targetType,
                              targetId: targetId,
                              adminNote: note,
                            );
                          },
                        ),
                  icon: const Icon(Icons.visibility_off_rounded, size: 18),
                  label: const Text('Ẩn nội dung'),
                  style: _outlineButtonStyle(
                    foregroundColor: const Color(0xFFE53935),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        _buildUserSearchBox(),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AdminService.usersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _primary),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final allUsers = snapshot.data?.docs ?? [];

              final users = allUsers.where((doc) {
                if (_userSearchKeyword.isEmpty) return true;

                final data = doc.data();

                final nickname =
                    data['nickname']?.toString().toLowerCase() ?? '';
                final email = data['email']?.toString().toLowerCase() ?? '';
                final major = data['major']?.toString().toLowerCase() ?? '';
                final role = data['role']?.toString().toLowerCase() ?? '';
                final university =
                    data['university']?.toString().toLowerCase() ?? '';

                final searchText = [
                  nickname,
                  email,
                  major,
                  role,
                  university,
                  doc.id.toLowerCase(),
                ].join(' ');

                return searchText.contains(_userSearchKeyword);
              }).toList();

              if (users.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'Không tìm thấy user',
                  subtitle: _userSearchKeyword.isEmpty
                      ? 'User trong collection users sẽ hiện ở đây.'
                      : 'Không có user nào khớp từ khóa "$_userSearchKeyword".',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return _buildUserCard(users[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserSearchBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _userSearchKeyword = value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm user theo tên, email, ngành, role...',
          prefixIcon: const Icon(Icons.search_rounded, color: _primary),
          filled: true,
          fillColor: const Color(0xFFF9F7FF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final nickname = data['nickname']?.toString() ?? 'Chưa có tên';
    final email = data['email']?.toString() ?? '';
    final university = data['university']?.toString() ?? '';
    final major = data['major']?.toString() ?? '';
    final role = data['role']?.toString() ?? 'student';
    final status = data['status']?.toString() ?? 'active';
    final avatarUrl = data['avatarUrl']?.toString() ?? '';

    final firstLetter = nickname.trim().isEmpty
        ? 'U'
        : nickname.trim()[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          final avatar = CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFEDE7FF),
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? Text(
                    firstLetter,
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                    ),
                  )
                : null,
          );

          final info = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? doc.id : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (university.isNotEmpty)
                      _buildSmallTag(
                        icon: Icons.school_rounded,
                        text: university,
                      ),
                    if (major.isNotEmpty)
                      _buildSmallTag(
                        icon: Icons.menu_book_rounded,
                        text: major,
                      ),
                  ],
                ),
              ],
            ),
          );

          final actions = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [_buildRolePill(role), _buildStatusPill(status)],
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: () => _showChangeRoleSheet(
                  userId: doc.id,
                  nickname: nickname,
                  currentRole: role,
                ),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 17),
                label: const Text('Đổi role'),
                style: _outlineButtonStyle(),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [avatar, const SizedBox(width: 13), info]),
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 13),
              info,
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildContentTab() {
    return Column(
      children: [
        _buildContentTypeSelector(),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(_contentType)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _primary),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.article_outlined,
                  title: 'Chưa có nội dung',
                  subtitle: 'Collection $_contentType chưa có dữ liệu.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  return _buildContentCard(docs[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentTypeSelector() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: DropdownButtonFormField<String>(
        value: _contentType,
        decoration: InputDecoration(
          labelText: 'Loại nội dung',
          prefixIcon: Icon(_contentIcon(_contentType), color: _primary),
          filled: true,
          fillColor: const Color(0xFFF9F7FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'confessions', child: Text('Confessions')),
          DropdownMenuItem(value: 'marketPosts', child: Text('Market posts')),
          DropdownMenuItem(value: 'moments', child: Text('UniMoments')),
        ],
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            _contentType = value;
          });
        },
      ),
    );
  }

  Widget _buildContentCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final title = _contentTitleFromData(
      collectionName: _contentType,
      data: data,
    );

    final preview = _contentPreviewFromData(
      collectionName: _contentType,
      data: data,
    );

    final status = _safeText(data['status'], fallback: 'active');
    final authorId = _authorIdFromContent(data);
    final createdAt = _formatTimestamp(data['createdAt']);
    final price = data['price'];
    final category = _safeText(data['category']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusPill(status),
              const Spacer(),
              _buildDatePill(createdAt),
            ],
          ),
          const SizedBox(height: 14),
          _buildContentPreviewBox(
            doc: doc,
            title: title,
            preview: preview,
            authorId: authorId,
          ),
          if (price != null || category.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (category.isNotEmpty)
                  _buildSmallTag(icon: Icons.category_rounded, text: category),
                if (price != null)
                  _buildSmallTag(
                    icon: Icons.payments_rounded,
                    text: '${price.toString()} đ',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminContentDetailScreen(
                          collectionName: _contentType,
                          documentId: doc.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Xem chi tiết'),
                  style: _outlineButtonStyle(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: status == 'hidden'
                    ? null
                    : () => _guardAction(() async {
                        await FirebaseFirestore.instance
                            .collection(_contentType)
                            .doc(doc.id)
                            .update({
                              'status': 'hidden',
                              'hiddenBy': AdminService.currentUid,
                              'hiddenAt': FieldValue.serverTimestamp(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                      }),
                icon: const Icon(Icons.visibility_off_rounded, size: 18),
                label: const Text('Ẩn'),
                style: _outlineButtonStyle(
                  foregroundColor: const Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdminNoteSheet({
    required String title,
    required Future<void> Function(String note) onConfirm,
  }) {
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Ghi chú admin, có thể bỏ trống...',
                        filled: true,
                        fillColor: const Color(0xFFF7F3FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                try {
                                  setSheetState(() {
                                    isSaving = true;
                                  });

                                  await onConfirm(noteController.text.trim());

                                  if (!mounted) return;

                                  Navigator.pop(bottomSheetContext);
                                  _showSnack('Đã xử lý');
                                } catch (e) {
                                  _showSnack('Lỗi: $e');
                                } finally {
                                  if (mounted) {
                                    setSheetState(() {
                                      isSaving = false;
                                    });
                                  }
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(isSaving ? 'Đang lưu...' : 'Xác nhận'),
                        style: _primaryButtonStyle(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(noteController.dispose);
  }

  void _showChangeRoleSheet({
    required String userId,
    required String nickname,
    required String currentRole,
  }) {
    String selectedRole = AdminService.validRoles.contains(currentRole)
        ? currentRole
        : 'student';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Đổi role cho $nickname',
                      style: const TextStyle(
                        color: _darkText,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      filled: true,
                      fillColor: const Color(0xFFF7F3FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: AdminService.validRoles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setSheetState(() {
                        selectedRole = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                setSheetState(() {
                                  isSaving = true;
                                });

                                await AdminService.updateUserRole(
                                  userId: userId,
                                  role: selectedRole,
                                );

                                if (!mounted) return;

                                Navigator.pop(bottomSheetContext);
                                _showSnack('Đã đổi role thành $selectedRole');
                              } catch (e) {
                                _showSnack('Lỗi đổi role: $e');
                              } finally {
                                if (mounted) {
                                  setSheetState(() {
                                    isSaving = false;
                                  });
                                }
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.admin_panel_settings_rounded),
                      label: Text(isSaving ? 'Đang lưu...' : 'Lưu role'),
                      style: _primaryButtonStyle(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDatePill(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 15,
            color: Colors.black45,
          ),
          const SizedBox(width: 5),
          Text(
            date,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'resolved':
        color = const Color(0xFF00897B);
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        color = const Color(0xFF757575);
        icon = Icons.cancel_rounded;
        break;
      case 'hidden':
        color = const Color(0xFFE53935);
        icon = Icons.visibility_off_rounded;
        break;
      case 'active':
        color = _primary;
        icon = Icons.public_rounded;
        break;
      default:
        color = const Color(0xFFFF9800);
        icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePill(String role) {
    Color color;

    switch (role) {
      case 'admin':
        color = const Color(0xFFE53935);
        break;
      case 'moderator':
        color = const Color(0xFF00897B);
        break;
      case 'clubLeader':
        color = const Color(0xFF8E24AA);
        break;
      case 'eventManager':
        color = const Color(0xFFFF9800);
        break;
      default:
        color = _primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSmallTag({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.purple.shade50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFE53935),
                size: 56,
              ),
              const SizedBox(height: 12),
              const Text(
                'Không tải được dữ liệu',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey.shade400, size: 56),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle({EdgeInsetsGeometry? padding}) {
    return ElevatedButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: padding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  ButtonStyle _outlineButtonStyle({Color? foregroundColor}) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor ?? _primary,
      side: BorderSide(color: (foregroundColor ?? _primary).withOpacity(0.28)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  IconData _contentIcon(String type) {
    switch (type) {
      case 'marketPosts':
        return Icons.storefront_rounded;
      case 'moments':
        return Icons.auto_awesome_rounded;
      case 'confessions':
      default:
        return Icons.forum_rounded;
    }
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return 'Chưa rõ';
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withOpacity(0.7)),
      boxShadow: [
        BoxShadow(
          color: Colors.purple.withOpacity(0.07),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class _AdminTabItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AdminTabItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF7B61FF), size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2D1B69),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _GuideRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF7B61FF), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2D1B69),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
