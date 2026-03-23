import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_core/signalr_core.dart';

import '../config/config_url.dart';

class OrderService {
  late HubConnection _hubConnection;
  HubConnection get hubConnection => _hubConnection;

  // ✅ Callback cho các socket event
  Function(Map<String, dynamic>)? onNewOrder; // Nhận đơn mới (Admin/Staff)
  Function(Map<String, dynamic>)? onOrderStatusChanged; // Cập nhật trạng thái đơn (User)

  // 🟠 Hàm lấy token từ SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // 🟢 Lấy danh sách tất cả đơn hàng (Admin/Staff)
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final url = Uri.parse('${Config_URL.baseApiUrl}/OrderApi/GetAllOrders');
    try {
      final token = await _getToken();
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        debugPrint("❌ [OrderService] Lỗi khi lấy danh sách đơn hàng: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("🚨 [OrderService] Lỗi khi gọi API getAllOrders: $e");
      return [];
    }
  }

  // 🔹 Lấy chi tiết đơn hàng theo OrderId
  Future<List<Map<String, dynamic>>> getOrderDetails(int orderId) async {
    final token = await _getToken();
    final url = Uri.parse('${Config_URL.baseApiUrl}/OrderApi/GetOrderDetails/$orderId');
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        debugPrint("❌ [OrderService] Lỗi khi lấy chi tiết đơn: ${response.statusCode}");
        debugPrint("🧾 [OrderService] Phản hồi: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("🚨 [OrderService] Lỗi: $e");
      return [];
    }
  }

  // 🔹 Cập nhật trạng thái đơn hàng (dành cho Staff/Admin)
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    final token = await _getToken();
    final url = Uri.parse(
        '${Config_URL.baseApiUrl}/OrderApi/UpdateOrderStatus/$orderId?newStatus=$newStatus');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [OrderService] Cập nhật trạng thái đơn thành công');
        return true;
      } else {
        debugPrint('❌ [OrderService] Lỗi cập nhật trạng thái: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('🚨 [OrderService] Lỗi khi gọi API cập nhật: $e');
      return false;
    }
  }

  // 🔹 Gọi API lấy danh sách đơn hàng của user (Customer)
  Future<List<Map<String, dynamic>>> getMyOrders() async {
    try {
      final token = await _getToken();

      if (token == null) {
        debugPrint("⚠️ [GetMyOrders] Không tìm thấy token trong SharedPreferences");
        return [];
      }

      final url = Uri.parse('${Config_URL.baseApiUrl}/OrderApi/GetMyOrders');
      debugPrint("🌐 [GetMyOrders] Gọi API: $url");
      debugPrint("🔑 [GetMyOrders] Token: $token");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("📦 [GetMyOrders] Status Code: ${response.statusCode}");
      debugPrint("🧾 [GetMyOrders] Body: ${response.body}");

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        debugPrint("✅ [GetMyOrders] Nhận ${data.length} đơn hàng.");
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        debugPrint("❌ [GetMyOrders] Lỗi: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("🚨 [GetMyOrders] Exception: $e");
      return [];
    }
  }


  // 🔗 Kết nối tới SignalR Hub (dùng chung cho Admin, Staff, User)
  Function(Map<String, dynamic>)? onPaymentByCashResult;
  Future<void> connect() async {
    final token = await _getToken();

    if (token == null) {
      debugPrint("⚠️ [SignalR] Không tìm thấy token trong SharedPreferences");
      return;
    }

    final hubUrl = '${Config_URL.baseUrl}/orderHub?token=$token';

    _hubConnection = HubConnectionBuilder()
        .withUrl(
      hubUrl,
      HttpConnectionOptions(
        transport: HttpTransportType.webSockets,
        skipNegotiation: true,
      ),
    )
        .withAutomaticReconnect()
        .build();

    _hubConnection.onclose((error) {
      debugPrint("⚠️ [SignalR] Mất kết nối Hub: $error");
    });

    // 🆕 Nhận đơn mới (Admin/Staff)
    _hubConnection.on('ReceiveNewOrder', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final orderData = Map<String, dynamic>.from(arguments[0]);
        debugPrint('🆕 [SignalR] Nhận đơn mới từ socket: $orderData');
        if (onNewOrder != null) onNewOrder!(orderData);
      } else {
        debugPrint('⚠️ [SignalR] Nhận event ReceiveNewOrder nhưng không có dữ liệu');
      }
    });

    // 🔔 Nhận cập nhật trạng thái đơn hàng (User)
    _hubConnection.on('OrderStatusChanged', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final statusData = Map<String, dynamic>.from(arguments[0]);
        final orderId = statusData['orderId'] ?? statusData['OrderId'];
        final newStatus = statusData['newStatus'] ?? statusData['NewStatus'];
        debugPrint('🔔 [SignalR] Đơn hàng #$orderId cập nhật trạng thái → $newStatus');
        if (onOrderStatusChanged != null) {
          onOrderStatusChanged!({
            'OrderId': orderId,
            'NewStatus': newStatus,
          });
        }
      } else {
        debugPrint('⚠️ [SignalR] Nhận event OrderStatusChanged nhưng không có dữ liệu');
      }
    });

    // 🔔 Nhận thông báo thanh toán tiền mặt (User)
    _hubConnection.on('PaymentByCashResult', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = Map<String, dynamic>.from(arguments[0]);
        debugPrint('💰 [SignalR] Nhận PaymentByCashResult: $data');

        if (onPaymentByCashResult != null) {
          onPaymentByCashResult!(data); // ✅ Gọi callback về UI
        }
      } else {
        debugPrint('⚠️ [SignalR] Nhận event PaymentByCashResult nhưng không có dữ liệu');
      }
    });

    try {
      await _hubConnection.start();
      debugPrint('✅ [SignalR] Đã kết nối đến OrderHub thành công');
    } catch (e) {
      debugPrint('❌ [SignalR] Lỗi khi kết nối Hub: $e');
    }
  }

  // 🔌 Ngắt kết nối socket
  Future<void> disconnect() async {
    try {
      await _hubConnection.stop();
      debugPrint('🔌 [SignalR] Đã ngắt kết nối');
    } catch (e) {
      debugPrint('⚠️ [SignalR] Lỗi khi ngắt kết nối: $e');
    }
  }

  // 🔹 Gửi yêu cầu thanh toán (User)
  Future<Map<String, dynamic>> requestPayment(int orderId) async {
    final token = await _getToken();
    final url = Uri.parse('${Config_URL.baseApiUrl}/OrderApi/RequestPayment/$orderId');

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        debugPrint('✅ [OrderService] Gửi yêu cầu thanh toán thành công');
        return {"isSuccess": true, "message": data["message"] ?? "Thành công"};
      } else {
        debugPrint('❌ [OrderService] Lỗi khi gửi yêu cầu thanh toán');
        return {"isSuccess": false, "message": data["message"] ?? "Thất bại"};
      }
    } catch (e) {
      debugPrint("🚨 [OrderService] Lỗi khi gọi RequestPayment: $e");
      return {"isSuccess": false, "message": "Không thể kết nối đến máy chủ."};
    }
  }

  // 🟢 Lấy danh sách đơn hàng đã thanh toán của người dùng
  Future<List<Map<String, dynamic>>> getOrderHistoryHasPayment() async {
    try {
      final token = await _getToken();

      if (token == null) {
        debugPrint("⚠️ [getOrderHistoryHasPayment] Không tìm thấy token");
        return [];
      }

      final url = Uri.parse('${Config_URL.baseApiUrl}/OrderApi/GetOrderHasPayment');
      debugPrint("🌐 [getOrderHistoryHasPayment] Gọi API: $url");
      debugPrint("🔑 [getOrderHistoryHasPayment] Token: $token");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("📦 [getOrderHistoryHasPayment] Status Code: ${response.statusCode}");
      debugPrint("🧾 [getOrderHistoryHasPayment] Body: ${response.body}");

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        debugPrint("✅ [getOrderHistoryHasPayment] Nhận ${data.length} đơn hàng đã thanh toán.");
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        debugPrint("❌ [getOrderHistoryHasPayment] Lỗi: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("🚨 [getOrderHistoryHasPayment] Exception: $e");
      return [];
    }
  }
}
