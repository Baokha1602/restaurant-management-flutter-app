import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/config_url.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../customer/customer_edit_screen_user.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final CustomerService _customerService = CustomerService();
  late Future<CustomerDTO> _customerFuture;

  @override
  void initState() {
    super.initState();
    _customerFuture = _customerService.getCustomerById();
  }

  Future<void> _refreshCustomer() async {
    setState(() {
      _customerFuture = _customerService.getCustomerById();
    });
  }

  void _goToEdit(CustomerDTO customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerEditScreen(customer: customer, ranks: []),
      ),
    );
    if (result == true) _refreshCustomer();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Chưa cập nhật";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return "Không hợp lệ";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<CustomerDTO>(
        future: _customerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          final customer = snapshot.data!;
          // Ghép baseUrl với fullImageUrl nếu chưa có "http"
          final imageUrl = customer.fullImageUrl.startsWith("http")
              ? customer.fullImageUrl
              : "${Config_URL.baseUrl}/${customer.fullImageUrl}";

          return RefreshIndicator(
            onRefresh: _refreshCustomer,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(imageUrl),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 20, // giảm từ 22 xuống 20
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _infoRow(Icons.email, "Email", customer.email),
                          _infoRow(Icons.phone, "Số điện thoại", customer.phoneNumber),
                          _infoRow(Icons.cake, "Ngày sinh", _formatDate(customer.dateOfBirth)),
                          _infoRow(Icons.person, "Giới tính", customer.gender == 1 ? "Nam" : "Nữ"),
                          _infoRow(Icons.star, "Điểm tích lũy", customer.point?.toString() ?? "0"),
                          _infoRow(Icons.workspace_premium, "Hạng thành viên", customer.rankName ?? "Chưa có"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _goToEdit(customer),
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text(
                      "Chỉnh sửa thông tin",
                      style: TextStyle(fontSize: 14), // giảm từ 16 xuống 14
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight, // canh phải giá trị
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13, // giảm nhẹ để vừa hàng
                ),
                overflow: TextOverflow.ellipsis, // nếu quá dài -> hiển thị ...
                maxLines: 1, // chỉ cho phép 1 dòng
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
