import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/login_register/login_screen.dart' show LoginScreen;
import '../screen/user/discount_screen.dart';
import '../screen/user/scanqr_screen.dart';
import '../screen/user/historyorder_screen.dart';
import '../screen/user/account_screen.dart';
import '../screen/user/userhome_screen.dart';

/// Widget vỏ cho user sau khi đăng nhập:
/// - Chứa BottomNavigationBar 5 tab theo thứ tự yêu cầu
/// - Tab 1 là Trang chủ: dùng chính UserHomeScreen()
class UserMainScaffold extends StatefulWidget {
  const UserMainScaffold({super.key});

  @override
  State<UserMainScaffold> createState() => _UserMainScaffoldState();
}

class _UserMainScaffoldState extends State<UserMainScaffold> {
  int _currentIndex = 0;

  // Thứ tự đúng: Trang chủ, Ưu đãi, ScanQR, Lịch sử, Tôi
  late final List<Widget> _screens = const [
    HomeRestaurantScreen(),
    DiscountScreen(),
    ScanQRScreen(),
    OrderHistoryScreen(),
    AccountScreen(),
  ];

  // Tiêu đề AppBar tương ứng từng tab
  final List<String> _titles = const [
    "Trang chủ",
    "Ưu đãi của tôi",
    "Quét mã QR",
    "Lịch sử đơn hàng",
    "Thông tin cá nhân",
  ];

  // Hàm xử lý logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("🚪 Đã xóa toàn bộ dữ liệu đăng nhập (token, user info).");

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Đăng xuất",
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text("Xác nhận đăng xuất"),
                  content: const Text("Bạn có chắc muốn đăng xuất khỏi tài khoản này?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Hủy"),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text("Đăng xuất"),
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // Giữ nguyên trạng thái từng tab
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: mainColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle:
        const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: Colors.orange),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer, color: Colors.orange),
            label: 'Ưu đãi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner, color: Colors.orange),
            label: 'Scan QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history, color: Colors.orange),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: Colors.orange),
            label: 'Tôi',
          ),
        ],
      ),
    );
  }
}
