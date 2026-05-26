import 'package:flutter/material.dart';

class MarketTab extends StatelessWidget {
  const MarketTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          _buildCategoryGrid(),
          const SizedBox(height: 18),
          _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storefront_rounded, color: Color(0xFF00A86B), size: 40),
          SizedBox(height: 14),
          Text(
            'UniVibe Market',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Mua bán đồ cũ, tài liệu học tập, phòng trọ và đồ sinh viên.',
            style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      _MarketCategory('Đồ cũ', Icons.shopping_bag_rounded),
      _MarketCategory('Tài liệu', Icons.menu_book_rounded),
      _MarketCategory('Phòng trọ', Icons.home_work_rounded),
      _MarketCategory('Khác', Icons.more_horiz_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final item = categories[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: const Color(0xFF00A86B), size: 28),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Column(
        children: [
          Icon(Icons.construction_rounded, color: Colors.grey, size: 46),
          SizedBox(height: 12),
          Text(
            'Market sẽ nối Firestore sau',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Collection dự kiến: marketPosts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _MarketCategory {
  final String title;
  final IconData icon;

  const _MarketCategory(this.title, this.icon);
}
