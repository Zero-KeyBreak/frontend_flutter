import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ChangePassWordScreen extends StatefulWidget {
  const ChangePassWordScreen({super.key});

  @override
  State<ChangePassWordScreen> createState() => _ChangePassWordScreenState();
}

class _ChangePassWordScreenState extends State<ChangePassWordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _oldPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // giống các screen khác
  final List<String> apiUrls = const [
    "https://df4b91vt-4000.asse.devtunnels.ms",
    "http://10.0.2.2:4000",
    "http://localhost:4000",
  ];

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt("user_id");

      if (userId == null) {
        setState(() => _isLoading = false);
        _showError("Không tìm thấy user_id. Vui lòng đăng nhập lại.");
        return;
      }

      http.Response? res;

      for (final base in apiUrls) {
        try {
          final uri = Uri.parse("$base/user/$userId/password");
          res = await http
              .put(
                uri,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "old_password": _oldPasswordController.text.trim(),
                  "new_password": _newPasswordController.text.trim(),
                }),
              )
              .timeout(const Duration(seconds: 10));

          debugPrint("PUT $uri → ${res.statusCode} ${res.body}");

          if (res.statusCode == 200 || res.statusCode == 400) break;
        } catch (e) {
          debugPrint("PUT /user/$userId/password error with $base: $e");
        }
      }

      setState(() => _isLoading = false);

      if (res == null) {
        _showError("Không thể kết nối server. Vui lòng thử lại sau.");
        return;
      }

      if (res.statusCode == 200) {
        // Đổi mật khẩu OK
        _showSuccess("Đổi mật khẩu thành công!");
      } else if (res.statusCode == 400) {
        // sai mật khẩu cũ, hoặc validate bị fail từ backend
        try {
          final decoded = jsonDecode(res.body);
          final msg =
              decoded is Map && decoded["message"] != null
                  ? decoded["message"].toString()
                  : "Yêu cầu không hợp lệ.";
          _showError(msg);
        } catch (_) {
          _showError("Yêu cầu không hợp lệ.");
        }
      } else if (res.statusCode == 404) {
        _showError("Không tìm thấy tài khoản.");
      } else {
        _showError("Lỗi server: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Có lỗi xảy ra: $e");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Lỗi",
          style: TextStyle(color: Colors.red),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ĐÓNG"),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          "Thành công",
          style: TextStyle(color: Colors.green),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // đóng dialog
              Navigator.pop(context, true); // quay lại PersonalScreen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6D32D3);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Đổi mật khẩu",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    label: "Mật khẩu hiện tại",
                    controller: _oldPasswordController,
                    obscureText: _obscureOld,
                    onToggle: () =>
                        setState(() => _obscureOld = !_obscureOld),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Vui lòng nhập mật khẩu hiện tại";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    label: "Mật khẩu mới",
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    onToggle: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Vui lòng nhập mật khẩu mới";
                      }
                      if (v.length < 6) {
                        return "Mật khẩu phải từ 6 ký tự";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    label: "Nhập lại mật khẩu mới",
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Vui lòng nhập lại mật khẩu mới";
                      }
                      if (v != _newPasswordController.text) {
                        return "Mật khẩu nhập lại không khớp";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "XÁC NHẬN",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
