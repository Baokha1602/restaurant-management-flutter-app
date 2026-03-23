import 'dart:convert';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/user_main_scaffold.dart';
import '../payment/user_confirmpayment.dart';


class PaymentStatusScreen extends StatefulWidget {
  final String momoUrl;
  final String callbackUrl;

  const PaymentStatusScreen({
    super.key,
    required this.momoUrl,
    required this.callbackUrl,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  final AppLinks _appLinks = AppLinks();
  String status = "🔄 Đang kiểm tra trạng thái thanh toán...";
  bool _isLoading = false;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinkHandling();
    _openMomoUrl(); // ✅ Tự động mở MoMo khi vào trang
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// 🟣 Lắng nghe deep link MoMo trả về
  Future<void> _initDeepLinkHandling() async {
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri == null) return;
      debugPrint("✅ [Flutter] Nhận dữ liệu từ MoMo: $uri");

      final queryParams = uri.queryParameters;
      for (var key in queryParams.keys) {
        debugPrint("🔹 $key = ${queryParams[key]}");
      }

      if (queryParams.isNotEmpty) {
        setState(() {
          status = "📩 Đang xử lý phản hồi từ MoMo...";
          _isLoading = true;
        });
        _callPaymentCallback(queryParams);
      }
    }, onError: (err) {
      debugPrint("❌ [Flutter] Lỗi khi lắng nghe deep link: $err");
    });

    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        debugPrint("🟢 [Flutter] App được mở bằng deep link: $initialUri");
        final queryParams = initialUri.queryParameters;
        _callPaymentCallback(queryParams);
      }
    } catch (e) {
      debugPrint("⚠️ [Flutter] Lỗi khi xử lý initial link: $e");
    }
  }

  /// 🔹 Gọi API callback BE
  Future<void> _callPaymentCallback(Map<String, String> momoData) async {
    try {
      final uri = Uri.parse(widget.callbackUrl).replace(queryParameters: momoData);

      debugPrint("📡 [Flutter] Gọi API callback: $uri");

      final res = await http.get(uri);
      debugPrint("📥 [Flutter] Status code: ${res.statusCode}");
      debugPrint("📦 [Flutter] Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          status = data['message'] ?? "✅ Thanh toán thành công!";
        });
      } else {
        setState(() {
          status = "⚠️ Không thể lấy trạng thái thanh toán (Code: ${res.statusCode})";
        });
      }
    } catch (e) {
      debugPrint("❌ [Flutter] Exception khi gọi callback: $e");
      setState(() {
        status = "❌ Lỗi khi gọi callback: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Mở trang thanh toán MoMo
  Future<void> _openMomoUrl() async {
    debugPrint("🚀 [Flutter] Mở MoMo URL: ${widget.momoUrl}");
    try {
      final uri = Uri.parse(widget.momoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          status = "⚠️ Không thể mở liên kết thanh toán MoMo.";
        });
      }
    } catch (e) {
      debugPrint("❌ [Flutter] Lỗi khi mở MoMo: $e");
      setState(() {
        status = "❌ Lỗi khi mở MoMo: $e";
      });
    }
  }

  /// 🔁 Tải lại trạng thái
  Future<void> _reloadStatus() async {
    setState(() => status = "🔄 Đang kiểm tra trạng thái thanh toán...");
  }

  /// 🔙 Quay lại trang ConfirmPayment
  void _goBackToConfirmPayment() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ConfirmPayment()),
    );
  }

  /// 🏠 Về trang chủ
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Trạng thái thanh toán"),
        backgroundColor: Colors.purple,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _goBackToConfirmPayment,
        ),
        actions: [
          IconButton(
            onPressed: _reloadStatus,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Tải lại trạng thái",
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment, size: 80, color: Colors.purple),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.purple),
              const SizedBox(height: 10),
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),

              // 🔹 Nút mở lại MoMo
              ElevatedButton.icon(
                onPressed: _openMomoUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.qr_code, color: Colors.white),
                label: const Text(
                  "Mở lại MoMo",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              const SizedBox(height: 15),

              // 🏠 Nút về trang chủ
              ElevatedButton.icon(
                onPressed: _goHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
