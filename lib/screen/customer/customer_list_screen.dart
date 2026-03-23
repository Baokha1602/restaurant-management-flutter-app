import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/customer.dart';
import '../../../services/customer_service.dart';
import 'customer_add_screen.dart';
import 'customer_detail_screen.dart';
import 'customer_edit_screen.dart';
import 'customer_hidden_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();

  List<CustomerDTO> _customers = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;
  String _searchQuery = "";
  Timer? _debounce;

  final Color primaryColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.trim();
      if (query != _searchQuery) {
        _searchCustomers(query);
      }
    });
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final allCustomers = await _customerService.getAllCustomers(
        search: _searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
      );

      // Lọc ra các khách hàng KHÔNG bị khóa (isLocked == false)
      final visibleCustomers =
      allCustomers.where((c) => !c.isLocked).toList();

      // Cần tính lại totalItems và totalPages dựa trên số lượng khách hàng hiển thị
      int totalItems = visibleCustomers.length;
      int totalPages = (totalItems / _pageSize).ceil();

      setState(() {
        _customers = visibleCustomers;
        _totalPages = totalPages;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải khách hàng: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchCustomers(String query) async {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    await _fetchCustomers();
  }

  Future<void> _softDeleteCustomer(String customerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Bạn có chắc muốn vô hiệu hoá tài khoản này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _customerService.lockUser(customerId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Tài khoản đã bị vô hiệu hoá.")),
          );
          await _fetchCustomers(); // Tải lại danh sách để ẩn khách hàng vừa khóa
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Không thể vô hiệu hoá tài khoản.")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e")),
        );
      }
    }
  }

  void _navigateToEdit(CustomerDTO customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerEditScreen(customer: customer, ranks: const []), // ranks có thể cần được lấy động
      ),
    );
    if (result == true) await _fetchCustomers(); // Cập nhật lại danh sách sau khi sửa
  }

  void _navigateToDetail(CustomerDTO customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customer: customer),
      ),
    );
  }

  Future<void> _navigateToAddCustomer() async {
    try {
      final ranks = await _customerService.getRanks();
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerAddScreen(ranks: ranks),
        ),
      );
      if (result == true) await _fetchCustomers(); // Cập nhật lại danh sách sau khi thêm
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải danh sách hạng: $e')));
    }
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        spacing: 6,
        children: List.generate(_totalPages, (i) {
          final index = i + 1;
          final isActive = index == _currentPage;
          return ElevatedButton(
            onPressed: isActive
                ? null
                : () {
              setState(() => _currentPage = index);
              _fetchCustomers();
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor:
              isActive ? primaryColor : Colors.orange.shade50,
              foregroundColor:
              isActive ? Colors.white : Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(index.toString()),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: const Text(
          "Quản lý khách hàng",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_off_outlined, color: Colors.white),
            tooltip: 'Khách hàng bị vô hiệu hoá',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerHiddenScreen()),
              ).then((result) async {
                // Khi quay lại từ CustomerHiddenScreen, cần làm mới danh sách
                // để hiển thị khách hàng đã được mở khóa (nếu có)
                if (result == true) { // result == true nếu có sự thay đổi (mở khóa)
                  await _fetchCustomers();
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add),
        label: const Text("Thêm khách hàng"),
        onPressed: _navigateToAddCustomer,
      ),
      body: Column(
        children: [
          // 🔍 Thanh tìm kiếm hiện đại
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm khách hàng...",
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _searchCustomers('');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // 📋 Danh sách khách hàng
          Expanded(
            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(color: Colors.orange))
                : _customers.isEmpty
                ? const Center(
              child: Text(
                "Không có khách hàng nào",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : RefreshIndicator(
              color: primaryColor,
              onRefresh: _fetchCustomers,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final customer = _customers[index];
                  final imageUrl =
                      '${customer.fullImageUrl}?v=${DateTime.now().millisecondsSinceEpoch}';

                  return Dismissible(
                    key: Key(customer.customerId ?? 'cus_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                      child:
                      const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      // Logic soft delete (khóa tài khoản)
                      await _softDeleteCustomer(
                          customer.customerId ?? '');
                      return false; // Không tự động xóa khỏi danh sách ngay lập tức,
                      // mà đợi _fetchCustomers() tải lại để cập nhật
                    },
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor:
                          Colors.orangeAccent.withOpacity(0.15),
                          backgroundImage: NetworkImage(imageUrl),
                        ),
                        title: Text(
                          customer.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${customer.email}\nHạng: ${customer.rankName ?? "Chưa có"} | Điểm: ${customer.point ?? 0}',
                            style: const TextStyle(
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline,
                              color: Colors.orange),
                          onPressed: () =>
                              _navigateToDetail(customer),
                        ),
                        onLongPress: () => _navigateToEdit(customer),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 🔸 Thanh phân trang
          if (!_isLoading && _customers.isNotEmpty) _buildPagination(),
        ],
      ),
    );
  }
}