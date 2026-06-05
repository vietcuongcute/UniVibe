import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/market_post.dart';
import '../services/market_service.dart';
import 'chat_detail_screen.dart';

class MarketDetailScreen extends StatefulWidget {
  final MarketPost post;

  const MarketDetailScreen({super.key, required this.post});

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  bool _isOpeningChat = false;
  bool _isMarkingSold = false;
  bool _isDeleting = false;
  late bool _isSold;

  String get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  bool get _isMine {
    return widget.post.sellerId == _currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _isSold = widget.post.isSold;
  }

  String _formatPrice(num price) {
    final value = price.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      final reverseIndex = value.length - i;
      buffer.write(value[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()}đ';
  }

  Future<void> _messageSeller() async {
    if (_isOpeningChat) return;

    setState(() {
      _isOpeningChat = true;
    });

    try {
      final chatRoomId = await MarketService.startChatWithSeller(widget.post);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(chatRoomId: chatRoomId),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở chat: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningChat = false;
        });
      }
    }
  }

  Future<void> _markAsSold() async {
    if (_isMarkingSold) return;

    setState(() {
      _isMarkingSold = true;
    });

    try {
      await MarketService.markAsSold(widget.post.id);

      if (!mounted) return;

      setState(() {
        _isSold = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu bài đăng là đã bán.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể đánh dấu đã bán: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingSold = false;
        });
      }
    }
  }

  Future<void> _deletePost() async {
    if (_isDeleting) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xoá bài đăng?'),
          content: const Text(
            'Bài đăng sẽ bị xoá khỏi Market. Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xoá'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await MarketService.deletePost(widget.post.id);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xoá bài đăng Market.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xoá bài đăng: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showUploadComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload ảnh Market sẽ làm sau khi bật Firebase Storage.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: const Text('Chi tiết bài đăng'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D1B69),
        elevation: 0,
        actions: [
          if (_isMine)
            IconButton(
              tooltip: 'Xoá bài đăng',
              onPressed: _isDeleting ? null : _deletePost,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
        children: [
          _buildImageBox(),
          const SizedBox(height: 18),
          _buildMainInfo(post),
          const SizedBox(height: 14),
          _buildDescription(post),
          const SizedBox(height: 14),
          _buildSellerNote(),
        ],
      ),
    );
  }

  Widget _buildImageBox() {
    final imageUrls = widget.post.imageUrls;

    return GestureDetector(
      onTap: imageUrls.isEmpty ? _showUploadComingSoon : null,
      child: Container(
        height: 230,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF8F1),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: imageUrls.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_rounded,
                    color: Color(0xFF00A86B),
                    size: 54,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có ảnh',
                    style: TextStyle(
                      color: Color(0xFF00A86B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Upload ảnh sẽ làm sau',
                    style: TextStyle(color: Colors.black45),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(imageUrls.first, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _buildMainInfo(MarketPost post) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(post.category, const Color(0xFF00A86B)),
              _buildBadge(
                _isSold ? 'Đã bán' : 'Đang bán',
                _isSold ? Colors.grey : const Color(0xFF7B61FF),
              ),
              if (_isMine) _buildBadge('Bài của bạn', const Color(0xFFE91E63)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
              decoration: _isSold ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatPrice(post.price),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _isSold ? Colors.black45 : const Color(0xFFE91E63),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(MarketPost post) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            post.description,
            style: const TextStyle(
              color: Colors.black87,
              height: 1.45,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded, color: Color(0xFF00A86B)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'UniVibe Market đang dùng nội bộ sinh viên. Khi giao dịch, nên hẹn ở khu vực an toàn trong trường.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_isMine)
              SizedBox(
                height: 48,
                width: 48,
                child: OutlinedButton(
                  onPressed: _isDeleting ? null : _deletePost,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                ),
              ),
            if (_isMine) const SizedBox(width: 10),
            if (_isMine && !_isSold)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isMarkingSold ? null : _markAsSold,
                  icon: _isMarkingSold
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_isMarkingSold ? 'Đang lưu...' : 'Đã bán'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00A86B),
                    side: const BorderSide(color: Color(0xFF00A86B)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            if (_isMine && !_isSold) const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isMine || _isSold || _isOpeningChat
                    ? null
                    : _messageSeller,
                icon: _isOpeningChat
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chat_bubble_rounded),
                label: Text(
                  _isMine
                      ? 'Bài của bạn'
                      : _isSold
                      ? 'Đã bán'
                      : _isOpeningChat
                      ? 'Đang mở chat...'
                      : 'Nhắn người bán',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
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
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
