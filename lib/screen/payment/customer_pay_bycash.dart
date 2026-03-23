import 'package:flutter/material.dart';

import '../../services/order_service.dart';
import '../../widgets/user_main_scaffold.dart';

class CustomerPayByCash extends StatefulWidget {
  const CustomerPayByCash({super.key});

  @override
  State<CustomerPayByCash> createState() => _CustomerPayByCashState();
}

class _CustomerPayByCashState extends State<CustomerPayByCash> {
  final OrderService _socketService = OrderService(); // ✅ service của bạn
  String message = "💬 Chờ xác nhận phía nhà hàng..."; // Mặc định khi vào trang
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToSocket();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  /// 🔗 Kết nối SignalR & lắng nghe event "PaymentByCashResult"
  Future<void> _connectToSocket() async {
    await _socketService.connect();

    setState(() {
      _isConnected = true;
    });

    // ✅ Lắng nghe socket khi Admin xác nhận
    _socketService.hubConnection.on("PaymentByCashResult", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final raw = arguments[0];
        debugPrint("📩 [SignalR] Dữ liệu nhận từ server: $raw");

        // 🔹 Biến chứa kết quả cuối cùng hiển thị ra màn hình
        String msg = "";

        if (raw is Map) {
          // Trường hợp server trả object JSON
          msg = raw["Message"]?.toString() ?? "";
        } else if (raw is String) {
          // Trường hợp server trả chuỗi kiểu "{ Message = Thanh toán thành công đơn hàng #62 }"
          final regex = RegExp(r'Message\s*=\s*(.+?)\s*\}?$');
          final match = regex.firstMatch(raw);
          msg = match != null ? match.group(1)! : raw;
        } else {
          msg = raw.toString();
        }

        // 🔹 Gỡ bỏ khoảng trắng thừa nếu có
        msg = msg.trim();

        debugPrint("💬 [SignalR] Tin nhắn cuối cùng: $msg");
        setState(() => message = msg);
      } else {
        debugPrint("⚠️ [SignalR] Nhận event PaymentByCashResult nhưng không có dữ liệu");
      }
    });
  }

  /// 🏠 Quay về trang chủ
  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UserMainScaffold()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        title: const Text(
          "Thanh toán bằng tiền mặt",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          if (_isConnected)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.wifi, color: Colors.white),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.wifi_off, color: Colors.white),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.attach_money, size: 100, color: Colors.orange),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: message.contains("thành công")
                      ? Colors.green
                      : Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              if (message.contains("thành công"))
                ElevatedButton.icon(
                  onPressed: _goHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.home, color: Colors.white),
                  label: const Text(
                    "Về trang chủ",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
