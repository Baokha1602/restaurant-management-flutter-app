import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

import '../../services/cart_service.dart';
import '../../services/qr_scan_service.dart';
import '../menu/menuorder_screen.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({Key? key}) : super(key: key);

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> with WidgetsBindingObserver {
  bool _isScanning = true;
  final QRCodeDartScanController _controller = QRCodeDartScanController();
  final QrScanService _qrScanService = QrScanService();

  // ✅ Khởi tạo CartService để dùng sau khi quét QR
  final CartService _cartService = CartService();

  Future<void> _handleScan(String qrUrl) async {
    if (!_isScanning) return;
    setState(() => _isScanning = false);

    try {
      // 🔴 1. Validate QR + lưu table_id
      await _qrScanService.validTableTokenFromQr(qrUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Xác thực bàn thành công!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 🔴 2. Tạo giỏ hàng
      await _cartService.createCart();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏳ Đang chuyển hướng đến trang đặt món..."),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 2),
        ),
      );

      // 🔴 3. Dừng camera
      await _controller.stopScan();

      // 🔴 4. Delay UX
      await Future.delayed(const Duration(seconds: 2));

      // 🔴 5. Điều hướng
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuOrderScreen()),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isScanning = true);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _scanFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final decoder = QRCodeDartScanDecoder.new(
        formats: QRCodeDartScanDecoder.acceptedFormats,
      );
      final result = await decoder.decodeFile(picked);
      decoder.dispose();

      if (result != null && result.text.isNotEmpty) {
        _handleScan(result.text);
      } else {
        _showError("Không đọc được mã QR từ ảnh.");
      }
    } catch (e) {
      _showError("Lỗi khi đọc mã QR từ ảnh: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double cameraBoxHeight = size.height * 0.75;
    final double cameraBoxWidth = size.width * 0.9;

    return Scaffold(
      backgroundColor: const Color(0xFFFF9800),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 20,
              child: Container(
                width: cameraBoxWidth,
                height: cameraBoxHeight,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: QRCodeDartScanView(
                      controller: _controller,
                      typeCamera: TypeCamera.back,
                      typeScan: TypeScan.live,
                      intervalScan: const Duration(milliseconds: 800),
                      onCapture: (result) {
                        if (_isScanning && result.text.isNotEmpty) {
                          _handleScan(result.text);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.08,
              child: TextButton.icon(
                onPressed: _scanFromGallery,
                icon: const Icon(Icons.photo_library, color: Colors.white),
                label: const Text(
                  "Chọn ảnh",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white, width: 1.5),
                  ),
                  overlayColor: Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
