import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/config_url.dart';
import '../../services/order_service.dart';
import '../../services/discount_service.dart';
import '../../services/payment_service.dart';
import 'customer_pay_byMomo.dart';
import 'customer_pay_bycash.dart';

class ConfirmPayment extends StatefulWidget {
  const ConfirmPayment({super.key});

  @override
  State<ConfirmPayment> createState() => _ConfirmPaymentState();
}

class _ConfirmPaymentState extends State<ConfirmPayment> {
  final OrderService _orderService = OrderService();
  final DiscountService _discountService = DiscountService();
  final PaymentService _paymentService = PaymentService();

  Map<String, dynamic>? _order;
  Map<String, dynamic>? _selectedDiscount;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _selectedPaymentMethod = 'Tiền mặt';

  @override
  void initState() {
    super.initState();
    _fetchOrderData();
  }

  Future<void> _fetchOrderData() async {
    final orders = await _orderService.getMyOrders();
    debugPrint("📘 [ConfirmPayment] Tổng số đơn nhận: ${orders.length}");

    if (orders.isNotEmpty) {
      setState(() {
        _order = orders.firstWhere(
              (o) => o['paymentStatus'] == "Yêu cầu thanh toán",
          orElse: () => orders.last,
        );
        debugPrint("📘 [ConfirmPayment] Order được chọn: $_order");
        _isLoading = false;
      });
    } else {
      debugPrint("⚠️ [ConfirmPayment] Không có đơn hàng nào.");
      setState(() => _isLoading = false);
    }
  }

  num _roundToNearestThousand(num value) {
    final remainder = value % 1000;
    return remainder >= 500 ? (value - remainder) + 1000 : value - remainder;
  }

  String formatCurrency(num value) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);

  /// 🔹 Popup chọn mã giảm giá
  Future<void> _selectDiscount() async {
    final discounts = await _discountService.getAvailableDiscounts();
    if (discounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không có mã giảm giá khả dụng."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(15),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: discounts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 5),
          itemBuilder: (context, index) {
            final discount = discounts[index]['discount'] ?? {};
            return GestureDetector(
              onTap: () {
                Navigator.pop(context, discount);
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.orangeAccent, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🎟️ Mã: ${discount['discountId'] ?? ''}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("Tên: ${discount['discountName'] ?? ''}",
                        style:
                        const TextStyle(fontSize: 14, color: Colors.black)),
                    Text("Loại: ${discount['discountCategory'] ?? ''}",
                        style:
                        const TextStyle(fontSize: 14, color: Colors.black)),
                    Text(
                        "Giá trị: ${discount['discountCategory'] == 'Phần trăm' ? '${discount['discountPrice']}%' : formatCurrency(discount['discountPrice'] ?? 0)}",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black)),
                    Text(
                      "HSD: ${discount['dateEnd'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(discount['dateEnd'])) : 'Không rõ'}",
                      style:
                      const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedDiscount = selected;
      });
    }
  }

  /// 🔹 Gửi xác nhận thanh toán
  Future<void> _confirmPayment() async {
    if (_order == null) return;
    setState(() => _isSubmitting = true);

    final total = _order!['totalAmount'] ?? 0;
    final discountRate = (_order!['customerDiscout'] ?? 0).toDouble();
    final discountMember = _roundToNearestThousand(total * discountRate / 100);

    num discountVoucher = 0;
    if (_selectedDiscount != null) {
      final category = _selectedDiscount!['discountCategory'] ?? "";
      final price = (_selectedDiscount!['discountPrice'] ?? 0).toDouble();
      if (category == "Phần trăm") {
        discountVoucher = _roundToNearestThousand(total * price / 100);
      } else if (category == "Tiền mặt") {
        discountVoucher = price;
      }
    }

    final totalPay = total - discountMember - discountVoucher;
    final orderId = _order!['orderId'];
    final discountId = _selectedDiscount?['discountId'] ?? "";

    debugPrint(
        "🟧 [ConfirmPayment] Gửi cập nhật thanh toán: order=$orderId, total=$totalPay, method=$_selectedPaymentMethod, discount=$discountId");

    final result = await _paymentService.updatePaymentInfo(
      orderId: orderId,
      total: totalPay.toDouble(),
      paymentMethod: _selectedPaymentMethod,
      discountId: discountId,
    );

    if (!(result['isSuccess'] ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Cập nhật thất bại')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    if (_selectedPaymentMethod == "Tiền mặt") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerPayByCash()),
      );
    // } else if (_selectedPaymentMethod == "Chuyển khoản VNPay") {
    //   final url = await _paymentService.createVnPayPayment(
    //     orderId: orderId,
    //     name: _order!['customerName'],
    //     amount: totalPay.toDouble(),
    //   );
    //
    //   if (url != null) {
    //     Navigator.pushReplacement(
    //       context,
    //       MaterialPageRoute(builder: (_) => CustomerPayVnpay(url: url)),
    //     );
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text("Lỗi khi tạo URL thanh toán VNPay.")),
    //     );
    //   }
    // }
    } else if (_selectedPaymentMethod == "Chuyển khoản MoMo") {
      final url = await _paymentService.createMomoPayment(
        orderId: orderId,
        fullName: _order!['customerName'],
        amount: totalPay.toDouble(),
      );

      if (url != null) {
        debugPrint("✅ [MoMo] URL tạo thành công: $url");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đang mở trạng thái thanh toán MoMo..."),
            backgroundColor: Colors.purple,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        final callbackUrl = "${Config_URL.baseApiUrl}/PaymentApi/PaymentCallback";

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentStatusScreen(
                momoUrl: url,
                callbackUrl: callbackUrl,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi khi tạo URL thanh toán MoMo.")),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        title: const Text(
          "Xác nhận thanh toán",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Tải lại dữ liệu",
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchOrderData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _order == null
          ? _buildEmptyState()
          : _buildOrderDetails(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, color: Colors.orange, size: 80),
          const SizedBox(height: 16),
          const Text("Không có đơn hàng cần xác nhận thanh toán.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchOrderData,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Tải lại dữ liệu",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    final total = _order!['totalAmount'] ?? 0;
    final discountRate = (_order!['customerDiscout'] ?? 0).toDouble();
    final discountMember = _roundToNearestThousand(total * discountRate / 100);
    num discountVoucher = 0;
    if (_selectedDiscount != null) {
      final category = _selectedDiscount!['discountCategory'] ?? "";
      final price = (_selectedDiscount!['discountPrice'] ?? 0).toDouble();
      if (category == "Phần trăm") {
        discountVoucher = _roundToNearestThousand(total * price / 100);
      } else if (category == "Tiền mặt") {
        discountVoucher = price;
      }
    }
    final totalPay = total - discountMember - discountVoucher;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("Khách hàng:", _order!['customerName']),
          _buildInfoRow("Bàn:", _order!['tableName']),
          _buildInfoRow(
            "Ngày đặt:",
            DateFormat('dd/MM/yyyy HH:mm').format(
              DateTime.parse(_order!['orderDate']),
            ),
          ),
          const Divider(height: 30, color: Colors.orange),

          _buildInfoRow("Tổng tiền:", formatCurrency(total), isBold: true),
          _buildInfoRow("Giảm theo hạng:",
              "- ${formatCurrency(discountMember)}",
              valueColor: Colors.red),

          // 🔹 Giảm theo mã + nút chọn mã ở dưới
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Giảm theo mã:",
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  Text(
                    _selectedDiscount == null
                        ? "(Chưa chọn mã)"
                        : "- ${formatCurrency(discountVoucher)}",
                    style: const TextStyle(color: Colors.red, fontSize: 15),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _selectDiscount,
                  icon: const Icon(Icons.local_offer, color: Colors.orangeAccent, size: 18),
                  label: const Text(
                    "Chọn mã giảm giá",
                    style: TextStyle(fontSize: 15, color: Colors.orangeAccent),
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 10, color: Colors.orange),
          _buildInfoRow("Tổng thanh toán:", formatCurrency(totalPay),
              isBold: true, valueColor: Colors.green),

          const SizedBox(height: 30),

          const Text("Chọn hình thức thanh toán:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Column(
            children: [
              RadioListTile<String>(
                title: const Text("Tiền mặt"),
                value: "Tiền mặt",
                groupValue: _selectedPaymentMethod,
                onChanged: (value) =>
                    setState(() => _selectedPaymentMethod = value!),
                activeColor: Colors.orange,
              ),
              RadioListTile<String>(
                title: const Text("Chuyển khoản MoMo"),
                value: "Chuyển khoản MoMo",
                groupValue: _selectedPaymentMethod,
                onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                activeColor: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 30),
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Xác nhận thanh toán",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 15, color: Colors.black54))),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      color: valueColor ?? Colors.black))),
        ],
      ),
    );
  }
}
