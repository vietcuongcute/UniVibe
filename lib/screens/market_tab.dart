import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/market_post.dart';
import '../services/market_service.dart';
import 'chat_detail_screen.dart';
import 'market_detail_screen.dart';

class MarketTab extends StatefulWidget {
  const MarketTab({super.key});

  @override
  State<MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<MarketTab> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = const [
    'Tất cả',
    'Đồ cũ',
    'Tài liệu',
    'Phòng trọ',
    'Vé sự kiện',
    'Khác',
  ];

  final List<String> _statusFilters = const [
    'Tất cả',
    'Đang bán',
    'Đã bán',
    'Bài của tôi',
  ];

  String _selectedCategory = 'Tất cả';
  String _selectedStatusFilter = 'Đang bán';
  String _searchKeyword = '';
  bool _isOpeningChat = false;

  String get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchKeyword = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MarketPost> _filterPosts(List<MarketPost> posts) {
    var result = posts;

    if (_selectedCategory != 'Tất cả') {
      result = result
          .where((post) => post.category == _selectedCategory)
          .toList();
    }

    if (_selectedStatusFilter == 'Đang bán') {
      result = result.where((post) => !post.isSold).toList();
    } else if (_selectedStatusFilter == 'Đã bán') {
      result = result.where((post) => post.isSold).toList();
    } else if (_selectedStatusFilter == 'Bài của tôi') {
      result = result.where((post) => post.sellerId == _currentUserId).toList();
    }

    if (_searchKeyword.isNotEmpty) {
      result = result.where((post) {
        final title = post.title.toLowerCase();
        final description = post.description.toLowerCase();
        final category = post.category.toLowerCase();

        return title.contains(_searchKeyword) ||
            description.contains(_searchKeyword) ||
            category.contains(_searchKeyword);
      }).toList();
    }

    return result;
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

  Future<void> _openCreatePostSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateMarketPostSheet(),
    );
  }

  Future<void> _markAsSold(MarketPost post) async {
    try {
      await MarketService.markAsSold(post.id);

      if (!mounted) return;

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
    }
  }

  Future<void> _messageSeller(MarketPost post) async {
    if (_isOpeningChat) return;

    setState(() {
      _isOpeningChat = true;
    });

    try {
      final chatRoomId = await MarketService.startChatWithSeller(post);

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

  void _openDetail(MarketPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MarketDetailScreen(postId: post.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePostSheet,
        backgroundColor: const Color(0xFF00A86B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Đăng bán'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<MarketPost>>(
          stream: MarketService.marketPostsStream(),
          builder: (context, snapshot) {
            final allPosts = snapshot.data ?? [];
            final posts = _filterPosts(allPosts);

            return RefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 350));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                children: [
                  _buildHeader(allPosts.length),
                  const SizedBox(height: 16),
                  _buildSearchBox(),
                  const SizedBox(height: 12),
                  _buildStatusFilters(),
                  const SizedBox(height: 12),
                  _buildCategoryChips(),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    _buildErrorState(snapshot.error.toString())
                  else if (posts.isEmpty)
                    _buildEmptyState()
                  else
                    ...posts.map(_buildPostCard),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int totalPosts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A86B), Color(0xFF7B61FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.storefront_rounded, color: Colors.white, size: 42),
          const SizedBox(height: 14),
          const Text(
            'UniVibe Market',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mua bán đồ cũ, tài liệu học tập, phòng trọ và đồ sinh viên trong trường.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$totalPosts bài đăng',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Tìm đồ cũ, tài liệu, phòng trọ...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchKeyword.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final selected = filter == _selectedStatusFilter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            selectedColor: const Color(0xFF7B61FF).withOpacity(0.16),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? const Color(0xFF7B61FF) : Colors.transparent,
            ),
            labelStyle: TextStyle(
              color: selected ? const Color(0xFF7B61FF) : Colors.black54,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
            onSelected: (_) {
              setState(() {
                _selectedStatusFilter = filter;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            selectedColor: const Color(0xFF00A86B).withOpacity(0.16),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? const Color(0xFF00A86B) : Colors.transparent,
            ),
            labelStyle: TextStyle(
              color: selected ? const Color(0xFF00875A) : Colors.black54,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard(MarketPost post) {
    final isMine = post.sellerId == _currentUserId;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _openDetail(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: post.isSold
              ? Border.all(color: Colors.grey.shade300)
              : Border.all(color: Colors.transparent),
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
            Row(
              children: [
                _buildImagePlaceholder(post),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildBadge(post.category, const Color(0xFF00A86B)),
                          if (post.isSold)
                            _buildBadge('Đã bán', Colors.grey)
                          else
                            _buildBadge('Đang bán', const Color(0xFF7B61FF)),
                          if (isMine)
                            _buildBadge('Của tôi', const Color(0xFFE91E63)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          decoration: post.isSold
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatPrice(post.price),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: post.isSold
                              ? Colors.black45
                              : const Color(0xFFE91E63),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Colors.black38),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (isMine && !post.isSold)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markAsSold(post),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Đã bán'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00A86B),
                        side: const BorderSide(color: Color(0xFF00A86B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                if (isMine && !post.isSold) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isMine || post.isSold || _isOpeningChat
                        ? null
                        : () => _messageSeller(post),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                    label: Text(
                      isMine
                          ? 'Bài của bạn'
                          : post.isSold
                          ? 'Đã bán'
                          : 'Nhắn người bán',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B61FF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(MarketPost post) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: post.imageUrls.isEmpty
          ? const Icon(
              Icons.image_not_supported_rounded,
              color: Color(0xFF00A86B),
              size: 34,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(post.imageUrls.first, fit: BoxFit.cover),
            ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter =
        _selectedCategory != 'Tất cả' ||
        _selectedStatusFilter != 'Tất cả' ||
        _searchKeyword.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Icon(Icons.storefront_outlined, color: Colors.grey, size: 46),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'Không tìm thấy bài phù hợp'
                : 'Chưa có bài đăng Market',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Thử đổi từ khoá, danh mục hoặc bộ lọc nha.'
                : 'Bấm “Đăng bán” để tạo bài đầu tiên.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 46,
          ),
          const SizedBox(height: 12),
          const Text(
            'Không tải được Market',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CreateMarketPostSheet extends StatefulWidget {
  const _CreateMarketPostSheet();

  @override
  State<_CreateMarketPostSheet> createState() => _CreateMarketPostSheetState();
}

class _CreateMarketPostSheetState extends State<_CreateMarketPostSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final List<String> _categories = const [
    'Đồ cũ',
    'Tài liệu',
    'Phòng trọ',
    'Vé sự kiện',
    'Khác',
  ];

  String _category = 'Đồ cũ';
  bool _isSaving = false;

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

    setState(() {
      _isSaving = true;
    });

    try {
      await MarketService.createPost(
        title: _titleController.text,
        description: _descriptionController.text,
        price: _parsePrice(),
        category: _category,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo bài đăng Market.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tạo bài thất bại: $e'),
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
                        'Tạo bài đăng Market',
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.image_not_supported_rounded,
                        color: Color(0xFF00A86B),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Upload ảnh để sau. Hiện tại imageUrls sẽ lưu mảng rỗng.',
                          style: TextStyle(color: Colors.black54, height: 1.4),
                        ),
                      ),
                    ],
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
                      : const Icon(Icons.add_business_rounded),
                  label: Text(_isSaving ? 'Đang đăng...' : 'Đăng bài'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A86B),
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
