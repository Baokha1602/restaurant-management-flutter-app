import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ForgotPasswordFlow extends StatefulWidget {
  const ForgotPasswordFlow({super.key});

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

enum _StepIndex { email, otp, reset }

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  final AuthService _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _StepIndex _step = _StepIndex.email;
  bool _loading = false;
  bool _showNewPass = false;
  bool _showConfirm = false;
  String? _userId;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _showSnack(String msg, [bool success = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendOTP() async {
    if (_emailCtrl.text.isEmpty) return _showSnack('Vui lòng nhập email');
    setState(() => _loading = true);

    final res = await _auth.sendOTP(_emailCtrl.text.trim());
    setState(() => _loading = false);

    if (res['success']) {
      _userId = res['userId'];
      _startCountdown();
      _showSnack(res['message'] ?? 'Đã gửi OTP', true);
      setState(() => _step = _StepIndex.otp);
    } else {
      _showSnack(res['message'] ?? 'Gửi OTP thất bại');
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpCtrl.text.isEmpty) return _showSnack('Vui lòng nhập mã OTP');
    if (_userId == null) return _showSnack('Thiếu userId, vui lòng gửi lại OTP');

    setState(() => _loading = true);
    final res = await _auth.verifyOTP(_userId!, _otpCtrl.text.trim());
    setState(() => _loading = false);

    if (res['success']) {
      _showSnack('Xác minh OTP thành công', true);
      setState(() => _step = _StepIndex.reset);
    } else {
      _showSnack(res['message'] ?? 'OTP không hợp lệ');
    }
  }

  Future<void> _resetPassword() async {
    if (_newPassCtrl.text != _confirmCtrl.text) {
      _showSnack('Mật khẩu xác nhận không khớp');
      return;
    }
    if (_userId == null) return _showSnack('Thiếu userId, vui lòng gửi lại OTP');

    setState(() => _loading = true);
    final res = await _auth.changePassword(_userId!, _newPassCtrl.text, _confirmCtrl.text);
    setState(() => _loading = false);

    if (res['success']) {
      _showSnack('Đổi mật khẩu thành công', true);
      Navigator.pop(context);
    } else {
      _showSnack(res['message'] ?? 'Đổi mật khẩu thất bại');
    }
  }

  // ===== UI =====
  InputDecoration _input(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.orange),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.orange),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.deepOrange),
    ),
  );

  Widget _button(String text, VoidCallback onPressed) => Container(
    width: double.infinity,
    height: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
      ],
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ),
  );

  Widget _buildEmailStep() => Column(
    key: const ValueKey('emailStep'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Nhập email để nhận mã OTP',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      TextField(controller: _emailCtrl, decoration: _input('Email', Icons.email_outlined)),
      const SizedBox(height: 28),
      _button('Gửi mã OTP', _sendOTP),
    ],
  );

  Widget _buildOtpStep() => Column(
    key: const ValueKey('otpStep'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Nhập mã OTP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 18),
      TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        decoration: _input('Mã OTP', Icons.lock_clock_outlined),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _countdown > 0
              ? Text('Gửi lại sau $_countdown s', style: const TextStyle(color: Colors.grey))
              : TextButton(onPressed: _sendOTP, child: const Text('Gửi lại OTP')),
          TextButton(
            onPressed: () => setState(() => _step = _StepIndex.email),
            child: const Text('Thay email'),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _button('Xác minh mã', _verifyOTP),
    ],
  );

  Widget _buildResetStep() => Column(
    key: const ValueKey('resetStep'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Đặt mật khẩu mới',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      const SizedBox(height: 18),
      TextField(
        controller: _newPassCtrl,
        obscureText: !_showNewPass,
        decoration: _input('Mật khẩu mới', Icons.lock_outline).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
                _showNewPass ? Icons.visibility_off : Icons.visibility,
                color: Colors.orange),
            onPressed: () => setState(() => _showNewPass = !_showNewPass),
          ),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _confirmCtrl,
        obscureText: !_showConfirm,
        decoration: _input('Xác nhận mật khẩu', Icons.lock_reset_outlined).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
                _showConfirm ? Icons.visibility_off : Icons.visibility,
                color: Colors.orange),
            onPressed: () => setState(() => _showConfirm = !_showConfirm),
          ),
        ),
      ),
      const SizedBox(height: 28),
      _button('Đổi mật khẩu', _resetPassword),
    ],
  );

  Widget _buildStepContent() {
    switch (_step) {
      case _StepIndex.email:
        return _buildEmailStep();
      case _StepIndex.otp:
        return _buildOtpStep();
      case _StepIndex.reset:
        return _buildResetStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE0B2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9800),
        centerTitle: true,
        elevation: 0,
        title: const Text('Quên mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Container(
                    key: ValueKey(_step),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))
                      ],
                    ),
                    child: _buildStepContent(),
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
