import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class AdminContentDetailScreen extends StatefulWidget {
  final String collectionName;
  final String documentId;

  const AdminContentDetailScreen({
    super.key,
    required this.collectionName,
    required this.documentId,
  });

  @override
  State<AdminContentDetailScreen> createState() =>
      _AdminContentDetailScreenState();
}

class _AdminContentDetailScreenState extends State<AdminContentDetailScreen> {
  static const Color _primary = Color(0xFF7B61FF);
  static const Color _darkText = Color(0xFF2D1B69);
  static const Color _bg = Color(0xFFF7F3FF);

  bool _isSaving = false;

  DocumentReference<Map<String, dynamic>> get _docRef {
    return FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(widget.documentId);
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _hideContent() async {
    final confirm = await _showConfirmDialog(
      title: 'Ẩn nội dung này?',
      message:
          'Nội dung sẽ được đổi status thành hidden. Người dùng thường sẽ không nên thấy bài này nữa.',
      confirmText: 'Ẩn nội dung',
      confirmColor: const Color(0xFFE53935),
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _docRef.update({
        'status': 'hidden',
        'hiddenBy': AdminService.currentUid,
        'hiddenAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnack('Đã ẩn nội dung');
    } catch (e) {
      _showSnack('Lỗi ẩn nội dung: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _restoreContent() async {
    final confirm = await _showConfirmDialog(
      title: 'Khôi phục nội dung?',
      message: 'Nội dung sẽ được đổi status lại thành active.',
      confirmText: 'Khôi phục',
      confirmColor: _primary,
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _docRef.update({
        'status': 'active',
        'restoredBy': AdminService.currentUid,
        'restoredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnack('Đã khôi phục nội dung');
    } catch (e) {
      _showSnack('Lỗi khôi phục nội dung: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              color: _darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminService.hasAdminAccess(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(child: CircularProgressIndicator(color: _primary)),
          );
        }

        final allowed = adminSnapshot.data == true;

        if (!allowed) {
          return Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: _darkText,
              title: const Text('Chi tiết nội dung'),
            ),
            body: const Center(
              child: Text('Bạn không có quyền xem màn hình này.'),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _docRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: _bg,
                body: Center(child: CircularProgressIndicator(color: _primary)),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: _bg,
                appBar: _buildAppBar(),
                body: _buildErrorState(snapshot.error.toString()),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Scaffold(
                backgroundColor: _bg,
                appBar: _buildAppBar(),
                body: _buildEmptyState(),
              );
            }

            final data = snapshot.data!.data() ?? {};

            return Scaffold(
              backgroundColor: _bg,
              appBar: _buildAppBar(),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  _buildHeaderCard(data),
                  const SizedBox(height: 14),
                  _buildMainContentCard(data),
                  const SizedBox(height: 14),
                  _buildImageUrlsCard(data),
                  const SizedBox(height: 14),
                  _buildAuthorCard(data),
                  const SizedBox(height: 14),
                  _buildRawDataCard(data),
                  const SizedBox(height: 18),
                  _buildActionButtons(data),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: _darkText,
      title: const Text(
        'Chi tiết nội dung',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'active';
    final createdAt = _formatValue(data['createdAt']);
    final updatedAt = _formatValue(data['updatedAt']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusPill(status),
              const Spacer(),
              _buildCollectionPill(widget.collectionName),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Thông tin document',
            style: TextStyle(
              color: _darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Collection', widget.collectionName),
          _buildInfoRow('Document ID', widget.documentId),
          _buildInfoRow('Created at', createdAt),
          _buildInfoRow('Updated at', updatedAt),
        ],
      ),
    );
  }

  Widget _buildMainContentCard(Map<String, dynamic> data) {
    final title = _firstNotEmpty([
      data['title'],
      data['caption'],
      data['question'],
    ]);

    final content = _firstNotEmpty([
      data['content'],
      data['description'],
      data['body'],
      data['text'],
      data['message'],
      data['caption'],
    ]);

    final price = data['price'];
    final category = data['category']?.toString() ?? '';
    final condition = data['condition']?.toString() ?? '';
    final location = data['location']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nội dung bài đăng',
            style: TextStyle(
              color: _darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),

          if (title.isNotEmpty) ...[
            const Text(
              'Tiêu đề',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: _darkText,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
          ],

          const Text(
            'Nội dung đầy đủ',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              content.isEmpty ? 'Không có nội dung text.' : content,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),

          if (price != null || category.isNotEmpty || condition.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Thông tin phụ',
              style: TextStyle(
                color: _darkText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            if (price != null) _buildInfoRow('Giá', _formatPrice(price)),
            if (category.isNotEmpty) _buildInfoRow('Danh mục', category),
            if (condition.isNotEmpty) _buildInfoRow('Tình trạng', condition),
            if (location.isNotEmpty) _buildInfoRow('Địa điểm', location),
          ],
        ],
      ),
    );
  }

  Widget _buildImageUrlsCard(Map<String, dynamic> data) {
    final imageUrls = _extractStringList(data['imageUrls']);
    final featuredImageUrls = _extractStringList(data['featuredImageUrls']);
    final allImages = [...imageUrls, ...featuredImageUrls];

    if (allImages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hình ảnh',
              style: TextStyle(
                color: _darkText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Bài này chưa có ảnh hoặc imageUrls đang rỗng.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hình ảnh (${allImages.length})',
            style: const TextStyle(
              color: _darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final url = allImages[index];

                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    url,
                    width: 170,
                    height: 170,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 170,
                        height: 170,
                        color: const Color(0xFFF7F3FF),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: Colors.black38,
                          size: 38,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ...allImages.map((url) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                url,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAuthorCard(Map<String, dynamic> data) {
    final authorId =
        data['authorId']?.toString() ??
        data['sellerId']?.toString() ??
        data['userId']?.toString() ??
        data['uid']?.toString() ??
        '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Người đăng',
            style: TextStyle(
              color: _darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (authorId.isEmpty)
            const Text(
              'Không tìm thấy field authorId/sellerId/userId.',
              style: TextStyle(color: Colors.black54),
            )
          else
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(authorId)
                  .get(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data();

                final nickname =
                    userData?['nickname']?.toString() ?? 'Không rõ tên';
                final email = userData?['email']?.toString() ?? '';
                final role = userData?['role']?.toString() ?? 'student';
                final major = userData?['major']?.toString() ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('User ID', authorId),
                    _buildInfoRow('Nickname', nickname),
                    if (email.isNotEmpty) _buildInfoRow('Email', email),
                    if (major.isNotEmpty) _buildInfoRow('Ngành', major),
                    _buildInfoRow('Role', role),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRawDataCard(Map<String, dynamic> data) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toàn bộ field Firestore',
            style: TextStyle(
              color: _darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Phần này để admin/debug xem dữ liệu thật trong document.',
            style: TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 14),
          ...entries.map((entry) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SelectableText(
                    _formatValue(entry.value),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      height: 1.35,
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

  Widget _buildActionButtons(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'active';
    final isHidden = status == 'hidden';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSaving
                ? null
                : isHidden
                ? _restoreContent
                : _hideContent,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isHidden
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
            label: Text(
              _isSaving
                  ? 'Đang xử lý...'
                  : isHidden
                  ? 'Khôi phục nội dung'
                  : 'Ẩn nội dung',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isHidden ? _primary : const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
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
            child: SelectableText(
              value.isEmpty ? 'Không có' : value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
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
      case 'hidden':
        color = const Color(0xFFE53935);
        icon = Icons.visibility_off_rounded;
        break;
      case 'sold':
        color = const Color(0xFF00897B);
        icon = Icons.check_circle_rounded;
        break;
      case 'pending':
        color = const Color(0xFFFF9800);
        icon = Icons.schedule_rounded;
        break;
      default:
        color = _primary;
        icon = Icons.public_rounded;
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

  Widget _buildCollectionPill(String collectionName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        collectionName,
        style: const TextStyle(
          color: _primary,
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
                'Không tải được nội dung',
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
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.article_outlined, color: Colors.black38, size: 54),
              SizedBox(height: 12),
              Text(
                'Document không tồn tại',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Có thể bài này đã bị xoá khỏi Firestore.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _firstNotEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return '';
  }

  List<String> _extractStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    return [];
  }

  String _formatPrice(dynamic value) {
    if (value == null) return 'Không có';

    final number = num.tryParse(value.toString());

    if (number == null) {
      return value.toString();
    }

    final raw = number.toStringAsFixed(0);
    final buffer = StringBuffer();

    for (int i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} đ';
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';

    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    if (value is GeoPoint) {
      return 'GeoPoint(${value.latitude}, ${value.longitude})';
    }

    if (value is List) {
      if (value.isEmpty) return '[]';

      return value.map((item) => '- ${_formatValue(item)}').join('\n');
    }

    if (value is Map) {
      if (value.isEmpty) return '{}';

      return value.entries
          .map((entry) => '${entry.key}: ${_formatValue(entry.value)}')
          .join('\n');
    }

    return value.toString();
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
