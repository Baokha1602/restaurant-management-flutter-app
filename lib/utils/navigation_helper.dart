import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screen/admin/adminhome_screen.dart';
import '../screen/login_register/staffhome_screen.dart';
import '../widgets/user_main_scaffold.dart';

class NavigationHelper {
  // Chuyển màn hình theo role trong SharedPreferences
  static Future<void> navigateByRole(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? '';

    Widget screen;

    switch (role) {
      case 'User':
        screen = const UserMainScaffold();
        break;
      case 'Admin':
        screen = const AdminHomeScreen();
        break;
      case 'Staff':
        screen = const StaffHomeScreen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không xác định được vai trò người dùng")),
        );
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}