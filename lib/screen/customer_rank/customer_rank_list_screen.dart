import 'package:flutter/material.dart';
import '../../../models/customer_rank.dart';
import '../../../services/customer_service.dart';
import '../../../services/customer_rank_service.dart';
import '../../../services/token_service.dart';
import 'customer_rank_form.dart';

class CustomerRankScreen extends StatefulWidget {
  const CustomerRankScreen({super.key});

  @override
  State<CustomerRankScreen> createState() => _CustomerRankScreenState();
}

class _CustomerRankScreenState extends State<CustomerRankScreen> {
  final TokenService _tokenService = TokenService();
  late final CustomerRankService _customerRankService;
  late final CustomerService _customerService;

  List<CustomerRank> _customerRanks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final Color primaryOrange = const Color(0xFFFF6F00);

  @override
  void initState() {
    super.initState();
    _customerRankService = CustomerRankService(_tokenService);
    _customerService = CustomerService();
    _fetchCustomerRanks();
  }

  /// Gọi API lấy danh sách hạng + số lượng khách hàng từng hạng
  Future<void> _fetchCustomerRanks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final ranks = await _customerRankService.getAllCustomerRanks();
      final customers = await _customerService.getAllCustomers();

      // Gắn số lượng khách hàng theo rankId
      for (var rank in ranks) {
        rank.customerCount =
            customers.where((c) => c.rankId == rank.rankId).length;
      }

      setState(() {
        _customerRanks = ranks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải dữ liệu: ${e.toString()}';
        _isLoading = false;
      });
      _showSnackBar(_errorMessage, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : primaryOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRankForm({CustomerRank? rank}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: CustomerRankForm(
            initialRank: rank,
            onSave: (newRank) async {
              try {
                bool success;
                if (newRank.rankId == null) {
                  success = await _customerRankService.createCustomerRank(newRank);
                } else {
                  success = await _customerRankService.updateCustomerRank(newRank);
                }

                if (success) {
                  _showSnackBar(
                    newRank.rankId == null
                        ? 'Thêm hạng thành công!'
                        : 'Cập nhật hạng thành công!',
                  );
                  _fetchCustomerRanks();
                } else {
                  _showSnackBar('Thao tác thất bại!', isError: true);
                }
              } catch (e) {
                _showSnackBar('Lỗi: ${e.toString()}', isError: true);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteRank(int rankId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Xác nhận xóa'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn xóa hạng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _customerRankService.deleteCustomerRank(rankId);
        if (success) {
          _showSnackBar('Xóa hạng thành công!');
          _fetchCustomerRanks();
        } else {
          _showSnackBar('Xóa thất bại!', isError: true);
        }
      } catch (e) {
        _showSnackBar('Lỗi: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF6),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        elevation: 2,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.emoji_events, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Quản lý Hạng Khách Hàng',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _fetchCustomerRanks,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        color: primaryOrange,
        onRefresh: _fetchCustomerRanks,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _customerRanks.length,
          itemBuilder: (context, index) {
            final rank = _customerRanks[index];
            return Card(
              elevation: 4,
              shadowColor: Colors.orange.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.military_tech,
                      color: Colors.deepOrange),
                ),
                title: Text(
                  rank.rankName,
                  style: TextStyle(
                    color: primaryOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text('Điểm: ${rank.rankPoint}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.percent,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                              'Chiết khấu: ${rank.rankDiscount ?? 0}%'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text(
                              'Số khách hàng: ${rank.customerCount ?? 0}'),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: Colors.orangeAccent),
                      onPressed: () => _showRankForm(rank: rank),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.redAccent),
                      onPressed: () =>
                          _deleteRank(rank.rankId!),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryOrange,
        onPressed: () => _showRankForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Hạng'),
      ),
    );
  }
}
