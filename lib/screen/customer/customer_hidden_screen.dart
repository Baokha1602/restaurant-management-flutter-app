import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';

class CustomerHiddenScreen extends StatefulWidget {
  const CustomerHiddenScreen({super.key});

  @override
  State<CustomerHiddenScreen> createState() => _CustomerHiddenScreenState();
}

class _CustomerHiddenScreenState extends State<CustomerHiddenScreen> {
  final CustomerService _customerService = CustomerService();
  List<CustomerDTO> _lockedCustomers = [];
  bool _isLoading = false;

  final Color primaryColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    _fetchLockedCustomers();
  }


  Future<void> _fetchLockedCustomers() async { // Đổi tên phương thức
    setState(() => _isLoading = true);
    try {
      final lockedCustomers = await _customerService.getLockedCustomers(); // Gọi API mới
      setState(() => _lockedCustomers = lockedCustomers);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải danh sách khách hàng bị vô hiệu hoá: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unhideCustomer(String customerId) async {
    try {
      final success = await _customerService.unlockUser(customerId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Khách hàng đã được khôi phục.")),
        );
        await _fetchLockedCustomers(); // Tải lại danh sách khách hàng bị khóa sau khi mở khóa
        Navigator.pop(context, true); // Quay lại màn hình trước và báo hiệu cần làm mới
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Không thể khôi phục khách hàng.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80), Color(0xFFFFB74D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔸 AppBar tùy chỉnh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  ),
                  const Text(
                    "Khách hàng bị vô hiệu hoá",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _lockedCustomers.isEmpty // Sử dụng _lockedCustomers
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 100, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(height: 12),
                    const Text(
                      'Không có khách hàng bị vô hiệu hoá',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lockedCustomers.length, // Sử dụng _lockedCustomers
                  itemBuilder: (context, index) {
                    final customer = _lockedCustomers[index]; // Sử dụng _lockedCustomers
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor:
                          Colors.orangeAccent.withOpacity(0.2),
                          backgroundImage:
                          NetworkImage(customer.fullImageUrl),
                          onBackgroundImageError: (_, __) {},
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Email: ${customer.email}\n'
                                'Hạng: ${customer.rankName ?? "Chưa có"}\n'
                                'Điểm: ${customer.point ?? 0}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                        trailing: Tooltip(
                          message: "Khôi phục khách hàng",
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text("Khôi phục"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                _unhideCustomer(customer.customerId ?? ''),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}