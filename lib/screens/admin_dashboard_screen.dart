import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_content_detail_screen.dart';

import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color _primary = Color(0xFF7B61FF);
  static const Color _darkText = Color(0xFF2D1B69);
  static const Color _bg = Color(0xFFF7F3FF);

  late final Future<bool> _adminAccessFuture;

  int _selectedTabIndex = 0;

  final List<_AdminTabItem> _tabs = const [
    _AdminTabItem(title: 'Tổng quan', icon: Icons.dashboard_rounded),
    _AdminTabItem(title: 'Reports', icon: Icons.flag_rounded),
    _AdminTabItem(title: 'Users', icon: Icons.people_alt_rounded),
    _AdminTabItem(title: 'Nội dung', icon: Icons.article_rounded),
  ];

  String _contentType = 'confessions';
  String _reportFilter = 'all';
  String _userSearchKeyword = '';

  @override
  void initState() {
    super.initState();
    _adminAccessFuture = AdminService.hasAdminAccess();
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
          return Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              title: const Text('Admin Dashboard'),
              backgroundColor: Colors.white,
              foregroundColor: _darkText,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: _cardDecoration(),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Color(0xFFFFEBEE),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFFE53935),
                          size: 34,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Không có quyền truy cập',
                        style: TextStyle(
                          color: _darkText,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Chỉ tài khoản có role admin hoặc moderator mới mở được dashboard này.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: _darkText,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2),
                Text(
                  'Quản lý report, user, nội dung UniVibe',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(82),
              child: _buildAdminTabSelector(),
            ),
          ),
          body: IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildOverviewTab(),
              _buildReportsTab(),
              _buildUsersTab(),
              _buildContentTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminTabSelector() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final tab = _tabs[index];
            final isSelected = _selectedTabIndex == index;

            return _buildAdminTabButton(
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

  Widget _buildAdminTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color selectedBg = const Color(0xFFEDE7FF);
    final Color normalText = Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 25, color: isSelected ? _primary : normalText),
                const SizedBox(width: 11),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? _primary : normalText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        _buildWelcomeCard(),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, usersSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .snapshots(),
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

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: MediaQuery.of(context).size.width > 720
                          ? 4
                          : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      children: [
                        _buildStatCard(
                          title: 'Users',
                          value: users.length.toString(),
                          icon: Icons.people_alt_rounded,
                          color: _primary,
                        ),
                        _buildStatCard(
                          title: 'Pending reports',
                          value: pendingReports.toString(),
                          icon: Icons.flag_rounded,
                          color: const Color(0xFFE53935),
                        ),
                        _buildStatCard(
                          title: 'Market posts',
                          value: marketPosts.length.toString(),
                          icon: Icons.storefront_rounded,
                          color: const Color(0xFF00897B),
                        ),
                        _buildStatCard(
                          title: 'Admins',
                          value: adminCount.toString(),
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
        ),
        const SizedBox(height: 16),
        _buildGuideCard(),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFFEC5AA6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trung tâm quản trị UniVibe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Theo dõi report, đổi role, ẩn bài vi phạm và kiểm duyệt nội dung.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gợi ý quy trình kiểm duyệt',
            style: TextStyle(
              color: _darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _GuideRow(
            icon: Icons.flag_rounded,
            title: '1. Xem report mới',
            subtitle: 'Ưu tiên report có status pending.',
          ),
          _GuideRow(
            icon: Icons.visibility_off_rounded,
            title: '2. Ẩn nội dung vi phạm',
            subtitle: 'Bấm “Ẩn nội dung” để đổi status bài thành hidden.',
          ),
          _GuideRow(
            icon: Icons.check_circle_rounded,
            title: '3. Đánh dấu xử lý',
            subtitle: 'Resolve nếu report đúng, reject nếu report sai.',
          ),
          _GuideRow(
            icon: Icons.people_alt_rounded,
            title: '4. Quản lý role',
            subtitle: 'Chỉ admin mới được đổi role user.',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: _darkText,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          color: _bg,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildReportFilterChip('all', 'Tất cả'),
                const SizedBox(width: 8),
                _buildReportFilterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildReportFilterChip('resolved', 'Resolved'),
                const SizedBox(width: 8),
                _buildReportFilterChip('rejected', 'Rejected'),
              ],
            ),
          ),
        ),
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
                  final doc = reports[index];
                  return _buildReportCard(doc);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportFilterChip(String value, String label) {
    final bool selected = _reportFilter == value;

    return ChoiceChip(
      selected: selected,
      label: Text(label),
      selectedColor: const Color(0xFFEDE7FF),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? _primary : Colors.black54,
        fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? _primary.withOpacity(0.35) : Colors.purple.shade100,
      ),
      onSelected: (_) {
        setState(() {
          _reportFilter = value;
        });
      },
    );
  }

  Widget _buildReportCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final status = data['status']?.toString() ?? 'pending';
    final targetType = data['targetType']?.toString() ?? '';
    final targetId = data['targetId']?.toString() ?? '';
    final reason = data['reason']?.toString() ?? 'Không có lý do';
    final detail = data['detail']?.toString() ?? '';
    final reporterId = data['reporterId']?.toString() ?? '';
    final createdAt = _formatTimestamp(data['createdAt']);

    final bool canHide = targetType.isNotEmpty && targetId.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusPill(status),
              const Spacer(),
              Text(
                createdAt,
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reason,
            style: const TextStyle(
              color: _darkText,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              detail,
              style: const TextStyle(color: Colors.black87, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          _buildMiniInfo(
            'Reporter',
            reporterId.isEmpty ? 'Không rõ' : reporterId,
          ),
          _buildMiniInfo('Target', '$targetType / $targetId'),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
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
                  style: OutlinedButton.styleFrom(
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          color: _bg,
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
              fillColor: Colors.white,
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
        ),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
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
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email.isEmpty ? doc.id : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
                const SizedBox(height: 5),
                Text(
                  '$university • $major',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildRolePill(role),
              const SizedBox(height: 6),
              _buildStatusPill(status),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _showChangeRoleSheet(
                  userId: doc.id,
                  nickname: nickname,
                  currentRole: role,
                ),
                child: const Text('Đổi role'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTag({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FF),
        borderRadius: BorderRadius.circular(999),
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          color: _bg,
          child: DropdownButtonFormField<String>(
            value: _contentType,
            decoration: InputDecoration(
              labelText: 'Loại nội dung',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'confessions',
                child: Text('Confessions'),
              ),
              DropdownMenuItem(
                value: 'marketPosts',
                child: Text('Market posts'),
              ),
              DropdownMenuItem(value: 'moments', child: Text('UniMoments')),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _contentType = value;
              });
            },
          ),
        ),
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

  Widget _buildContentCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final title = data['title']?.toString().trim().isNotEmpty == true
        ? data['title'].toString()
        : data['content']?.toString().trim().isNotEmpty == true
        ? data['content'].toString()
        : data['description']?.toString().trim().isNotEmpty == true
        ? data['description'].toString()
        : 'Nội dung không có tiêu đề';

    final status = data['status']?.toString() ?? 'active';

    final authorId =
        data['authorId']?.toString() ??
        data['sellerId']?.toString() ??
        data['userId']?.toString() ??
        '';

    final createdAt = _formatTimestamp(data['createdAt']);

    final price = data['price'];
    final category = data['category']?.toString() ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusPill(status),
                const Spacer(),
                Text(
                  createdAt,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _darkText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.35,
              ),
            ),
            if (price != null || category.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (category.isNotEmpty)
                    _buildSmallTag(
                      icon: Icons.category_rounded,
                      text: category,
                    ),
                  if (price != null)
                    _buildSmallTag(
                      icon: Icons.payments_rounded,
                      text: '${price.toString()} đ',
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            _buildMiniInfo('ID', doc.id),
            _buildMiniInfo('Author', authorId.isEmpty ? 'Không rõ' : authorId),
            const SizedBox(height: 12),
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
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

  Widget _buildMiniInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
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
      default:
        color = const Color(0xFFFF9800);
        icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
    final bool isAdmin = role == 'admin';
    final Color color = isAdmin ? const Color(0xFFE53935) : _primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFE53935),
                size: 54,
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
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey.shade400, size: 54),
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
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.purple.withOpacity(0.07),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class _AdminTabItem {
  final String title;
  final IconData icon;

  const _AdminTabItem({required this.title, required this.icon});
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
