import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tp_bank/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // 🔥 3 URL ưu tiên
  final List<String> apiUrls = [
    "https://df4b91vt-4000.asse.devtunnels.ms", // devTunnel
    "http://10.0.2.2:4000",                    // Android emulator
    "http://localhost:4000"                     // PC / Web
  ];

  /// 🔥 Hàm login thử từng URL
  Future<http.Response?> _tryLogin(String phone, String password) async {
    for (String base in apiUrls) {
      final url = Uri.parse("$base/login");

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"phone": phone, "password": password}),
        );

        debugPrint("🔍 Thử URL: $url → ${response.statusCode}");

        // Nếu chạy thành công → return ngay
        if (response.statusCode == 200 || response.statusCode == 401) {
          return response;
        }
      } catch (e) {
        debugPrint("❌ URL lỗi: $base → $e");
      }
    }

    return null;
  }

  Future<void> _login() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await _tryLogin(
      _phoneController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể kết nối server")),
      );
      return;
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);
      await prefs.setInt("user_id", data["user"]["id"]);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Đăng nhập thất bại")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 109, 50, 211),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER giữ nguyên
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration:
                    const BoxDecoration(color: Color.fromARGB(255, 109, 50, 211)),
                child: Column(
                  children: const [
                    SizedBox(height: 40),
                    Text(
                      'TPBank',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Chúc bạn một ngày tốt lành',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    
                   
                    SizedBox(height: 35),
                  ],
                ),
              ),

              // LOGIN FORM giữ nguyên
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 125, 75, 210),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // PHONE
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon:
                            const Icon(Icons.phone, color: Color(0xFF7E57C2)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // PASSWORD
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon:
                            const Icon(Icons.lock, color: Color(0xFF7E57C2)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 125, 75, 210),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)
                            : const Text(
                                'ĐĂNG NHẬP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
