import 'package:flutter/material.dart';
import 'package:restaurantmanager/screen/login_register/register_screen.dart';
import 'package:restaurantmanager/screen/login_register/sendotp_screen.dart';

import '../../utils/auth.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/secure_storage.dart';
import '../../utils/biometric_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Gọi sau frame đầu tiên để tránh gọi quá sớm
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricLogin();
    });
  }

  Future<void> _checkBiometricLogin() async {
    final helper = BiometricHelper();
    await helper.authenticateAndLogin(context);
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Vui lòng nhập đầy đủ thông tin.";
      });
      return;
    }

    final result = await Auth.login(email, password);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      // ✅ Lưu cred để lần sau dùng sinh trắc học
      await SecureStorage.saveCredentials(email, password);

      // ✅ Điều hướng như cũ
      await NavigationHelper.navigateByRole(context);
    } else {
      setState(() {
        _errorMessage =
            result['message'] ?? "Đăng nhập thất bại. Vui lòng thử lại.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant, size: 80, color: Colors.orange),
              const SizedBox(height: 8),
              const Text(
                "Hutech Restaurant",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Đăng nhập",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordFlow()),
                    );
                  },
                  child: const Text("Quên mật khẩu?"),
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Đăng nhập", style: TextStyle(fontSize: 18)),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chưa có tài khoản? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      "Đăng ký ngay",
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              // (Tùy chọn) Nút test thủ công
              TextButton.icon(
                onPressed: () async {
                  final helper = BiometricHelper();
                  await helper.authenticateAndLogin(context);
                },
                icon: const Icon(Icons.fingerprint),
                label: const Text("Đăng nhập bằng vân tay"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
