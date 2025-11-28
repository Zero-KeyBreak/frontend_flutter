import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class InfoAccountScreen extends StatefulWidget {
  const InfoAccountScreen({super.key});

  @override
  State<InfoAccountScreen> createState() => _InfoAccountScreenState();
}

class _InfoAccountScreenState extends State<InfoAccountScreen> {
  final Color primaryColor = const Color(0xFF7E57C2);
  final Color cardColor = Colors.white;
  final Color accentColor = const Color.fromARGB(225, 184, 73, 232);

  bool _isLoading = true;
  String? _errorMessage;

  String _username = "";
  String _phone = "";
  String _stk = "";
  double _balance = 0;

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
    for (final base in apiUrls) {
      try {
        final res = await http
            .get(Uri.parse("$base$path"))
            .timeout(const Duration(seconds: 7));

        if (res.statusCode == 200) return res;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _loadUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        setState(() {
          _errorMessage = "Không tìm thấy user_id. Vui lòng đăng nhập lại.";
          _isLoading = false;
        });
        return;
      }

      final res = await _getWithFallback("/user/$userId");

      if (res == null) {
        setState(() {
          _errorMessage = "Không thể kết nối server!";
          _isLoading = false;
        });
        return;
      }

      final decoded = jsonDecode(res.body);

      Map<String, dynamic> data;

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is List && decoded.isNotEmpty) {
        data = decoded[0];
      } else {
        setState(() {
          _errorMessage = "Dữ liệu không hợp lệ!";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _username = data["username"] ?? "";
        _phone = data["phone"] ?? "";
        _stk = data["stk"] ?? "";
        _balance = double.tryParse(data["balance"].toString()) ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi: $e";
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final int value = amount.floor(); // ❌ không làm tròn, chỉ bỏ phần thập phân
  return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6D32D3),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Thông tin tài khoản",
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildUI(),
    );
  }

  Widget _buildUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  const Color.fromARGB(255, 170, 63, 203),
                  const Color.fromARGB(255, 91, 18, 217),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Số TK: $_stk",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Số dư: ${_formatCurrency(_balance)} VND",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildInfoCard(Icons.phone, "Số điện thoại", _phone),
          _buildInfoCard(Icons.credit_card, "Số tài khoản", _stk),
          _buildInfoCard(Icons.person, "Họ tên", _username),
          _buildInfoCard(
              Icons.account_balance_wallet,
              "Số dư",
              "${_formatCurrency(_balance)} VND"),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
