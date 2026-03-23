import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import 'secure_storage.dart';
import '../utils/navigation_helper.dart';

class BiometricHelper with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();

  BiometricHelper() {
    // 👇 Theo dõi vòng đời ứng dụng (pause/resume)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ Khi app quay lại foreground hoặc hot reload, reset trạng thái sinh trắc học
    if (state == AppLifecycleState.resumed) {
      auth.stopAuthentication();
    }
  }

  /// Kiểm tra xem thiết bị có hỗ trợ vân tay hoặc Face ID không
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      print("⚠️ Lỗi kiểm tra sinh trắc học: $e");
      return false;
    }
  }

  /// ✅ Hàm xác thực và tự động đăng nhập
  Future<void> authenticateAndLogin(BuildContext context) async {
    try {
      // 🧩 Luôn reset session trước khi xác thực mới
      await auth.stopAuthentication();

      final creds = await SecureStorage.getCredentials();
      final email = creds['email'];
      final password = creds['password'];
      final enabled = creds['enabled'] == 'true';

      if (enabled != true || email == null || password == null) {
        print("⚠️ Không có dữ liệu để tự đăng nhập sinh trắc học");
        return;
      }

      final available = await isBiometricAvailable();
      if (!available) {
        print("⚠️ Thiết bị không hỗ trợ vân tay/Face ID");
        return;
      }

      print("📱 Bắt đầu xác thực sinh trắc học...");
      final didAuth = await auth.authenticate(
        localizedReason: 'Xác thực để đăng nhập nhanh bằng vân tay / Face ID',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );

      if (didAuth) {
        print("✅ Xác thực thành công, tiến hành đăng nhập bằng AuthService...");
        final result = await AuthService().login(email, password);

        if (result['success'] == true) {
          print("🎉 Đăng nhập tự động thành công!");
          await NavigationHelper.navigateByRole(context);
        } else {
          print("❌ Đăng nhập thất bại: ${result['message']}");
        }
      } else {
        print("❌ Người dùng huỷ hoặc không xác thực được");
      }
    } on PlatformException catch (e) {
      // 🔸 Lỗi “auth_in_progress” sẽ được reset ngay tại đây
      if (e.code == 'auth_in_progress') {
        print("⚠️ Đang có xác thực trước đó, reset lại...");
        await auth.stopAuthentication();
      } else {
        print("🚨 PlatformException: ${e.code} - ${e.message}");
      }
    } catch (e) {
      print("🚨 Lỗi khi xác thực sinh trắc học: $e");
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
