import 'package:flutter/material.dart';

class ConfessionTab extends StatelessWidget {
  const ConfessionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildHeader(),
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
          Icon(Icons.forum_rounded, color: Color(0xFF7B61FF), size: 38),
          SizedBox(height: 14),
          Text(
            'Confession nội bộ trường',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Sinh viên có thể đăng confession ẩn danh, comment và report bài vi phạm.',
            style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
          ),
        ],
      ),
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
      child: Column(
        children: [
          Icon(
            Icons.construction_rounded,
            color: Colors.grey.shade400,
            size: 46,
          ),
          const SizedBox(height: 12),
          const Text(
            'Confession sẽ làm ở bước sau',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bước này chỉ dựng tab trước để app chạy đúng navigation 5 mục.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}
