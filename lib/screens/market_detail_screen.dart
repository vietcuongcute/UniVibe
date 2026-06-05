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

  late String _title;
  late String _description;
  late num _price;
  late String _category;

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
    _title = widget.post.title;
    _description = widget.post.description;
    _price = widget.post.price;
    _category = widget.post.category;
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

  Future<void> _openEditSheet() async {
    if (!_isMine || _isSold) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _EditMarketPostSheet(
          postId: widget.post.id,
          initialTitle: _title,
          initialDescription: _description,
          initialPrice: _price,
          initialCategory: _category,
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _title = result['title']?.toString() ?? _title;
      _description = result['description']?.toString() ?? _description;
      _price = result['price'] is num ? result['price'] as num : _price;
      _category = result['category']?.toString() ?? _category;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật bài đăng Market.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: const Text('Chi tiết bài đăng'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D1B69),
        elevation: 0,
        actions: [
          if (_isMine && !_isSold)
            IconButton(
              tooltip: 'Chỉnh sửa bài đăng',
              onPressed: _openEditSheet,
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF7B61FF)),
            ),
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
          _buildMainInfo(),
          const SizedBox(height: 14),
          _buildDescription(),
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

  Widget _buildMainInfo() {
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
              _buildBadge(_category, const Color(0xFF00A86B)),
              _buildBadge(
                _isSold ? 'Đã bán' : 'Đang bán',
                _isSold ? Colors.grey : const Color(0xFF7B61FF),
              ),
              if (_isMine) _buildBadge('Bài của bạn', const Color(0xFFE91E63)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
              decoration: _isSold ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatPrice(_price),
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

  Widget _buildDescription() {
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
            _description,
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

class _EditMarketPostSheet extends StatefulWidget {
  final String postId;
  final String initialTitle;
  final String initialDescription;
  final num initialPrice;
  final String initialCategory;

  const _EditMarketPostSheet({
    required this.postId,
    required this.initialTitle,
    required this.initialDescription,
    required this.initialPrice,
    required this.initialCategory,
  });

  @override
  State<_EditMarketPostSheet> createState() => _EditMarketPostSheetState();
}

class _EditMarketPostSheetState extends State<_EditMarketPostSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  final List<String> _categories = const [
    'Đồ cũ',
    'Tài liệu',
    'Phòng trọ',
    'Vé sự kiện',
    'Khác',
  ];

  late String _category;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _priceController = TextEditingController(
      text: widget.initialPrice.round().toString(),
    );

    _category = _categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'Khác';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  num _parsePrice() {
    final raw = _priceController.text.trim();
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) return 0;

    return num.tryParse(digitsOnly) ?? 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final price = _parsePrice();

    setState(() {
      _isSaving = true;
    });

    try {
      await MarketService.updatePost(
        postId: widget.postId,
        title: _titleController.text,
        description: _descriptionController.text,
        price: price,
        category: _category,
      );

      if (!mounted) return;

      Navigator.pop(context, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'category': _category,
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật thất bại: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F3FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chỉnh sửa bài đăng',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _titleController,
                  label: 'Tiêu đề',
                  hint: 'Ví dụ: Bán giáo trình CSDL',
                  icon: Icons.title_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nhập tiêu đề nha.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Mô tả',
                  hint: 'Tình trạng, liên hệ, địa điểm nhận...',
                  icon: Icons.description_rounded,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nhập mô tả nha.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _priceController,
                  label: 'Giá',
                  hint: 'Ví dụ: 50000',
                  icon: Icons.payments_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

                    if (digitsOnly.isEmpty) {
                      return 'Nhập giá nha.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _category = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Danh mục',
                    prefixIcon: const Icon(Icons.category_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
