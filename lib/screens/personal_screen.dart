import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'change_password_screen.dart';

import 'package:tp_bank/screens/login_screen.dart';
import 'change_password_screen.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  final Color primaryColor = const Color(0xFF6D32D3);
  final Color accentColor = const Color(0xFF8B47E0);

  bool _isLoading = true;
  String? _errorMessage;

  String _username = '';
  String _cif = ''; // mã KH (có thể lấy từ API hoặc user_id)

  // Giống InfoAccount / Home / Transfer
  final List<String> apiUrls = const [
    "https://df4b91vt-4000.asse.devtunnels.ms",
    "http://10.0.2.2:4000",
    "http://localhost:4000",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<http.Response?> _getWithFallback(String path) async {
    http.Response? lastRes;

    for (final base in apiUrls) {
      try {
        final uri = Uri.parse('$base$path');
        final res = await http.get(uri).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200 || res.statusCode == 201) {
          return res;
        } else {
          debugPrint('GET $uri lỗi: ${res.statusCode} ${res.body}');
          lastRes = res;
        }
      } catch (e) {
        debugPrint('GET exception ($path, $base): $e');
      }
    }

    return lastRes;
  }

  Future<void> _loadUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final int? id = prefs.getInt('user_id');

      if (id == null) {
        setState(() {
          _errorMessage = "Không tìm thấy user_id. Vui lòng đăng nhập lại.";
          _isLoading = false;
        });
        return;
      }

      final res = await _getWithFallback('/user/$id');

      if (res == null) {
        setState(() {
          _errorMessage = "Không thể kết nối server.";
          _isLoading = false;
        });
        return;
      }

      if (res.statusCode != 200) {
        setState(() {
          _errorMessage = "Lỗi server: ${res.statusCode}";
          _isLoading = false;
        });
        return;
      }

      final decoded = jsonDecode(res.body);

      Map<String, dynamic>? data;
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is List &&
          decoded.isNotEmpty &&
          decoded[0] is Map<String, dynamic>) {
        data = decoded[0] as Map<String, dynamic>;
      }

      if (data == null) {
        setState(() {
          _errorMessage = "Dữ liệu tài khoản không hợp lệ.";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _username = data?['username']?.toString() ?? '---';

        // Nếu backend có cột 'cif' hoặc 'cif_code' thì lấy, không thì dùng user_id
        _cif = data?['cif']?.toString() ??
            data?['cif_code']?.toString() ??
            id.toString();

        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Load user info error: $e");
      setState(() {
        _errorMessage = "Có lỗi xảy ra khi tải thông tin tài khoản.";
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("user_id");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã đăng xuất!")),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Cá nhân',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadUserInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6D32D3),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadUserInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6D32D3),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Thử lại"),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ẢNH + TÊN
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.account_circle,
                              size: 70,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tên lấy từ API
                          Text(
                            _username.isNotEmpty ? _username : '---',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2E266F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Mã KH (CIF): ${_cif.isNotEmpty ? _cif : '---'}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Chỉ còn Đổi mật khẩu
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildFeature(
                              context: context,
                              icon: Icons.lock,
                              label: "Đặt lại\nmật khẩu",
                              color: accentColor,
                              nextScreen: const ChangePassWordScreen(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ĐĂNG XUẤT
                      GestureDetector(
                        onTap: _logout,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                "Đăng xuất",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFeature({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Widget nextScreen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
