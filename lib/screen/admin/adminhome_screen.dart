import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 📦 Các màn hình quản lý
import 'package:restaurantmanager/screen/employee/employee_list_screen.dart';
import 'package:restaurantmanager/screen/menu_category/menu_category_list_screen.dart';
import 'package:restaurantmanager/screen/food_size/food_size_list_screen.dart';
import 'package:restaurantmanager/screen/menu/menu_list_screen.dart';
import 'package:restaurantmanager/screen/inventory/inventory_list_screen.dart';
import 'package:restaurantmanager/screen/discount/discount_list_screen.dart';
import 'package:restaurantmanager/screen/discount/discount_assign_screen.dart';
import 'package:restaurantmanager/screen/table/table_list_screen.dart';
import 'package:restaurantmanager/screen/customer/customer_list_screen.dart';
import 'package:restaurantmanager/screen/customer_rank/customer_rank_list_screen.dart';
import '../order/order_received_screen.dart';
import '../payment/confirm_order_pay_bycash.dart';
import '../statistics/statistics_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('jwt_token');
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = Colors.orange;

    final List<Map<String, dynamic>> adminItems = [
      {
        'title': 'Xác thực đơn hàng',
        'icon': Icons.verified_rounded,
        'desc': 'Xác nhận và duyệt các đơn hàng thanh toán tiền mặt',
        'route': const ConfirmOrderPayByCash(),
      },
      {
        'title': 'Theo dõi đơn hàng',
        'icon': Icons.receipt_long_rounded,
        'desc': 'Giám sát các đơn hàng đang xử lý và đã hoàn tất',
        'route': const OrderReceivedScreen(),
      },
      {
        'title': 'Quản lý khách hàng',
        'icon': Icons.people_alt_rounded,
        'desc': 'Xem, chỉnh sửa hoặc vô hiệu hóa tài khoản khách hàng',
        'route': const CustomerListScreen(),
      },
      {
        'title': 'Quản lý hạng thành viên',
        'icon': Icons.workspace_premium_rounded,
        'desc': 'Cấu hình cấp bậc, điểm thưởng và quyền lợi khách hàng',
        'route': const CustomerRankScreen(),
      },
      {
        'title': 'Quản lý nhân viên',
        'icon': Icons.badge_rounded,
        'desc': 'Theo dõi và phân quyền nhân viên trong hệ thống',
        'route': const EmployeeListScreen(),
      },
      {
        'title': 'Quản lý loại món ăn',
        'icon': Icons.category_rounded,
        'desc': 'Tạo và sắp xếp các nhóm loại món ăn trong menu',
        'route': const MenuCategoryListScreen(),
      },
      {
        'title': 'Quản lý kích cỡ món',
        'icon': Icons.rice_bowl_rounded,
        'desc': 'Thêm hoặc chỉnh sửa các kích cỡ và giá theo size',
        'route': const FoodSizeListScreen(),
      },
      {
        'title': 'Quản lý thực đơn',
        'icon': Icons.restaurant_menu_rounded,
        'desc': 'Thêm, chỉnh sửa món ăn và hình ảnh hiển thị',
        'route': const MenuListScreen(),
      },
      {
        'title': 'Quản lý bàn ăn',
        'icon': Icons.table_restaurant_rounded,
        'desc': 'Tạo, cập nhật mã QR và trạng thái bàn ăn',
        'route': const TableListScreen(),
      },
      {
        'title': 'Quản lý kho hàng',
        'icon': Icons.inventory_2_rounded,
        'desc': 'Kiểm tra tồn kho, nhập hàng hoặc cập nhật số lượng',
        'route': const InventoryListScreen(),
      },
      {
        'title': 'Quản lý khuyến mãi',
        'icon': Icons.discount_outlined,
        'desc': 'Tạo và theo dõi các mã giảm giá, chương trình ưu đãi',
        'route': const DiscountListScreen(),
      },
      {
        'title': 'Gán mã giảm giá',
        'icon': Icons.card_giftcard_rounded,
        'desc': 'Tặng mã giảm giá cho khách hàng cụ thể',
        'route': const DiscountAssignScreen(),
      },
      {
        'title': 'Báo cáo & thống kê',
        'icon': Icons.bar_chart_rounded,
        'desc': 'Thống kê doanh thu, lượt đặt món, hiệu suất hoạt động',
        'route': const StatisticsScreen(),
      },
      {
        'title': 'Cài đặt hệ thống',
        'icon': Icons.settings_rounded,
        'desc': 'Cấu hình các thông tin chung và quyền truy cập',
        'route': null,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trang Quản Trị',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: mainColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: adminItems.length,
        itemBuilder: (context, index) {
          final item = adminItems[index];
          return GestureDetector(
            onTap: () {
              if (item['route'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item['route']),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Tính năng "${item['title']}" đang được phát triển',
                    ),
                  ),
                );
              }
            },
            child: Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: mainColor.withOpacity(0.15),
                  radius: 28,
                  child: Icon(item['icon'], color: mainColor, size: 28),
                ),
                title: Text(
                  item['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    item['desc'],
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ),
                trailing:
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
