import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:restaurantmanager/screen/admin/adminhome_screen.dart';
import 'package:restaurantmanager/screen/login_register/login_screen.dart';
import 'package:restaurantmanager/screen/menu/menuorder_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await dotenv.load(fileName: ".env");

  // 🔐 Kiểm tra token để quyết định màn hình khởi đầu
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final Widget startScreen =
  (token != null && token.isNotEmpty) ? const AdminHomeScreen() : const LoginScreen();

  runApp(MyApp(startScreen: startScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Hutech Restaurant",
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
      ),

      // ✅ Trang khởi đầu tùy theo token
      home: startScreen,

      // ✅ Đăng ký các route
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminHomeScreen(),
        '/menu': (context) => const MenuOrderScreen(),
        // sau này bạn có thể thêm: '/customer': (context) => const CustomerListScreen(),
      },

      // ✅ Hỗ trợ ngôn ngữ
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
    );
  }
}
