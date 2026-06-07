import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import 'auth_gate.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color _primary = Color(0xFF7B61FF);
  static const Color _darkText = Color(0xFF2D1B69);
  static const Color _bg = Color(0xFFF7F3FF);

  int _currentIndex = 0;

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _logout() async {
    await AdminService.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  Future<void> _resolveReport(String reportId) async {
    try {
      await AdminService.resolveReport(
        reportId: reportId,
        adminNote: 'Đã xử lý report.',
      );
      _showMessage('Đã xử lý report.');
    } catch (e) {
      _showMessage('Lỗi: $e');
    }
  }

  Future<void> _rejectReport(String reportId) async {
    try {
      await AdminService.rejectReport(
        reportId: reportId,
        adminNote: 'Report không hợp lệ hoặc chưa đủ bằng chứng.',
      );
      _showMessage('Đã từ chối report.');
    } catch (e) {
      _showMessage('Lỗi: $e');
    }
  }

  Future<void> _hideContent({
    required String reportId,
    required String targetType,
    required String targetId,
  }) async {
    try {
      await AdminService.hideReportedContent(
        reportId: reportId,
        targetType: targetType,
        targetId: targetId,
        adminNote: 'Đã ẩn nội dung vi phạm.',
      );
      _showMessage('Đã ẩn nội dung.');
    } catch (e) {
      _showMessage('Lỗi: $e');
    }
  }

  Future<void> _updateRole({
    required String userId,
    required String role,
  }) async {
    try {
      await AdminService.updateUserRole(userId: userId, role: role);
      _showMessage('Đã cập nhật role: $role');
    } catch (e) {
      _showMessage('Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: AdminService.currentUserStream(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final role = data?['role']?.toString() ?? 'student';

        final isAdmin = role == 'admin';
        final isModerator = role == 'moderator';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(child: CircularProgressIndicator(color: _primary)),
          );
        }

        if (!isAdmin && !isModerator) {
          return Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: _primary,
                          size: 52,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Không có quyền Admin',
                          style: TextStyle(
                            color: _darkText,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tài khoản hiện tại có role: $role',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Đăng xuất'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final pages = [
          _buildOverviewPage(role),
          _buildReportsPage(),
          if (isAdmin) _buildUsersPage(),
        ];

        final titles = ['Tổng quan', 'Reports', if (isAdmin) 'Users & Roles'];

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: _darkText,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UniVibe Admin',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                ),
                Text(
                  '${titles[_currentIndex]} • role: $role',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: pages[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFEDE7FF),
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: _primary),
                label: 'Tổng quan',
              ),
              const NavigationDestination(
                icon: Icon(Icons.report_gmailerrorred_outlined),
                selectedIcon: Icon(
                  Icons.report_gmailerrorred_rounded,
                  color: _primary,
                ),
                label: 'Reports',
              ),
              if (isAdmin)
                const NavigationDestination(
                  icon: Icon(Icons.manage_accounts_outlined),
                  selectedIcon: Icon(
                    Icons.manage_accounts_rounded,
                    color: _primary,
                  ),
                  label: 'Users',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewPage(String role) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard quản trị',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                role == 'admin'
                    ? 'Bạn đang đăng nhập bằng tài khoản admin. Bạn có thể xử lý report và gán role cho user.'
                    : 'Bạn đang đăng nhập bằng tài khoản moderator. Bạn có thể xử lý report nhưng không được gán role.',
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: AdminService.reportsStream(),
          builder: (context, snapshot) {
            final reports = snapshot.data?.docs ?? [];
            final pendingCount = reports.where((doc) {
              final data = doc.data();
              return (data['status']?.toString() ?? 'pending') == 'pending';
            }).length;

            return Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'Reports',
                    value: reports.length.toString(),
                    icon: Icons.report_gmailerrorred_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: 'Chờ xử lý',
                    value: pendingCount.toString(),
                    icon: Icons.pending_actions_rounded,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: AdminService.usersStream(),
          builder: (context, snapshot) {
            final users = snapshot.data?.docs ?? [];

            return _statCard(
              title: 'Tổng user',
              value: users.length.toString(),
              icon: Icons.people_alt_rounded,
            );
          },
        ),
      ],
    );
  }

  Widget _buildReportsPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AdminService.reportsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }

        if (snapshot.hasError) {
          return _emptyBox(
            icon: Icons.error_outline_rounded,
            title: 'Lỗi tải reports',
            message: snapshot.error.toString(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptyBox(
            icon: Icons.verified_rounded,
            title: 'Chưa có report',
            message: 'Khi user report bài đăng, dữ liệu sẽ hiện ở đây.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final targetType = data['targetType']?.toString() ?? '';
            final targetId = data['targetId']?.toString() ?? '';
            final targetOwnerId = data['targetOwnerId']?.toString() ?? '';
            final reporterId = data['reporterId']?.toString() ?? '';
            final reason = data['reason']?.toString() ?? 'Không rõ lý do';
            final description = data['description']?.toString() ?? '';
            final status = data['status']?.toString() ?? 'pending';
            final action = data['action']?.toString() ?? '';
            final adminNote = data['adminNote']?.toString() ?? '';

            final isPending = status == 'pending';

            return _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statusChip(status),
                      const Spacer(),
                      Text(
                        targetType.isEmpty ? 'unknown' : targetType,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reason,
                    style: const TextStyle(
                      color: _darkText,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _infoLine('Reporter', reporterId),
                  _infoLine('Target ID', targetId),
                  _infoLine('Owner ID', targetOwnerId),
                  if (action.isNotEmpty) _infoLine('Action', action),
                  if (adminNote.isNotEmpty) _infoLine('Admin note', adminNote),
                  const SizedBox(height: 14),
                  if (isPending)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _hideContent(
                            reportId: doc.id,
                            targetType: targetType,
                            targetId: targetId,
                          ),
                          icon: const Icon(
                            Icons.visibility_off_rounded,
                            size: 18,
                          ),
                          label: const Text('Ẩn nội dung'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _resolveReport(doc.id),
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                          ),
                          label: const Text('Đã xử lý'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _rejectReport(doc.id),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Từ chối'),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Report này đã được xử lý.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
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

  Widget _buildUsersPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AdminService.usersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }

        if (snapshot.hasError) {
          return _emptyBox(
            icon: Icons.error_outline_rounded,
            title: 'Lỗi tải users',
            message: snapshot.error.toString(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptyBox(
            icon: Icons.people_outline_rounded,
            title: 'Chưa có user',
            message: 'Collection users đang trống.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final nickname = data['nickname']?.toString() ?? 'Người dùng';
            final email = data['email']?.toString() ?? '';
            final university = data['university']?.toString() ?? '';
            final major = data['major']?.toString() ?? '';
            final currentRole = data['role']?.toString() ?? 'student';

            String selectedRole = AdminService.validRoles.contains(currentRole)
                ? currentRole
                : 'student';

            return StatefulBuilder(
              builder: (context, setCardState) {
                return _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      if (university.isNotEmpty)
                        Text(
                          university,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      if (major.isNotEmpty)
                        Text(
                          major,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                filled: true,
                                fillColor: const Color(0xFFF9F7FF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              items: AdminService.validRoles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;

                                setCardState(() {
                                  selectedRole = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: selectedRole == currentRole
                                ? null
                                : () => _updateRole(
                                    userId: doc.id,
                                    role: selectedRole,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: const Text('Lưu'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return _card(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEDE7FF),
            child: Icon(icon, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(title, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'resolved':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'Đã xử lý';
        break;
      case 'rejected':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        label = 'Từ chối';
        break;
      default:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        label = 'Chờ xử lý';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.black54, fontSize: 13),
      ),
    );
  }

  Widget _emptyBox({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _primary, size: 52),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
