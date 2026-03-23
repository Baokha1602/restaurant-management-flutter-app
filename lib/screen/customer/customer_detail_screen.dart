import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerDTO customer;

  const CustomerDetailScreen({super.key, required this.customer});

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Chưa cập nhật";
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');
      return formatter.format(date);
    } catch (e) {
      return "Không hợp lệ";
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.deepOrangeAccent;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F5),
      body: Column(
        children: [
          // 🔶 Header Gradient
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.only(top: 50, bottom: 30),
            child: Column(
              children: [
                // Avatar
                Hero(
                  tag: customer.customerId ?? customer.email,
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(customer.fullImageUrl),
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  customer.email,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),

                // Rank card nổi
                if (customer.rankName != null || customer.point != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium,
                            color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          customer.rankName ?? "Chưa có hạng",
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (customer.point != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              "${customer.point} điểm",
                              style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Nội dung chi tiết
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoItem(
                          icon: Icons.phone_rounded,
                          label: "Số điện thoại",
                          value: customer.phoneNumber,
                          color: primaryColor,
                        ),
                        _divider(),
                        _buildInfoItem(
                          icon: Icons.cake_rounded,
                          label: "Ngày sinh",
                          value: _formatDate(customer.dateOfBirth),
                          color: primaryColor,
                        ),
                        _divider(),
                        _buildInfoItem(
                          icon: Icons.person_outline_rounded,
                          label: "Giới tính",
                          value:
                          customer.gender == 1 ? "Nam" : "Nữ",
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Nút quay lại
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    label: const Text(
                      "Quay lại",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget thông tin cá nhân
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Divider(
      color: Colors.orangeAccent,
      thickness: 0.6,
    ),
  );
}
