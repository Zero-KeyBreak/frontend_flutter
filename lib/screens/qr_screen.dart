// lib/screens/qr_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // ✅ để format tiền

class QrScreen extends StatefulWidget {
  final double defaultAmount;

  const QrScreen({super.key, this.defaultAmount = 50000});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen>
    with SingleTickerProviderStateMixin {
  late double displayedAmount;
  late TextEditingController amountController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> apiUrls = const [
    "https://df4b91vt-4000.asse.devtunnels.ms",
    "http://10.0.2.2:4000",
    "http://localhost:4000",
  ];

  bool _isLoadingUser = true;
  String? _errorUser;
  String _username = "";
  String _stk = "";
  int? _userId;

  // ✅ formatter tiền Việt, dùng dấu chấm
  final NumberFormat _vnFormat = NumberFormat("#,###", "vi_VN");

  @override
  void initState() {
    super.initState();

    displayedAmount =
        widget.defaultAmount >= 1000 ? widget.defaultAmount : 1000;
    amountController = TextEditingController(
      text: _vnFormat.format(widget.defaultAmount >= 1000
          ? widget.defaultAmount
          : 1000),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_fadeController);

    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      setState(() {
        _isLoadingUser = true;
        _errorUser = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt("user_id");

      if (id == null) {
        setState(() {
          _isLoadingUser = false;
          _errorUser = "Không tìm thấy user_id. Vui lòng đăng nhập lại.";
        });
        return;
      }

      _userId = id;

      http.Response? res;
      for (final base in apiUrls) {
        try {
          final uri = Uri.parse("$base/user/$id");
          res = await http.get(uri).timeout(const Duration(seconds: 8));
          if (res.statusCode == 200) break;
        } catch (_) {}
      }

      if (res == null || res.statusCode != 200) {
        setState(() {
          _isLoadingUser = false;
          _errorUser = "Không tải được thông tin tài khoản.";
        });
        return;
      }

      final decoded = jsonDecode(res.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded);

      setState(() {
        _username = data["username"]?.toString() ?? "";
        _stk = data["stk"]?.toString() ?? "";
        _isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
        _errorUser = "Lỗi load thông tin: $e";
      });
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ✅ payload QR: stk + amount (số nguyên, không dấu)
  String get qrData {
    if (_stk.isEmpty) return "";
    final payload = {
      "to_account": _stk,
      "amount": displayedAmount.toInt(),
    };
    return jsonEncode(payload);
  }

  // ================== BOTTOM SHEET NHẬP TIỀN ==================
  void _showChangeAmountSheet() {
    amountController.text = _vnFormat.format(displayedAmount.toInt());

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nhập số tiền muốn nhận',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Số tiền (VND)',
                ),
                // ✅ format có dấu chấm trong lúc gõ
                onChanged: (value) {
                  final digits =
                      value.replaceAll(RegExp(r'[^0-9]'), ''); // chỉ giữ số

                  if (digits.isEmpty) {
                    amountController.value = const TextEditingValue(
                      text: '',
                      selection: TextSelection.collapsed(offset: 0),
                    );
                    return;
                  }

                  final number = int.parse(digits);
                  final newText = _vnFormat.format(number);

                  if (newText == value) return; // tránh loop

                  amountController.value = TextEditingValue(
                    text: newText,
                    selection:
                        TextSelection.collapsed(offset: newText.length),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // ✅ parse lại: bỏ dấu . , rồi convert
                  final raw =
                      amountController.text.replaceAll('.', '').replaceAll(',', '');
                  final value = double.tryParse(raw);

                  if (value == null || value < 1000 || value > 10000000000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vui lòng nhập số hợp lệ từ 1.000 đến 10.000.000.000',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await _fadeController.forward();
                  setState(() {
                    displayedAmount = value;
                  });
                  await _fadeController.reverse();

                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================== UI CHÍNH ==================
  @override
  Widget build(BuildContext context) {
    final titleName = _username.isNotEmpty
        ? _username
        : (_isLoadingUser ? "Đang tải..." : "---");
    final titleStk =
        _stk.isNotEmpty ? _stk : (_isLoadingUser ? "" : "---");

    final formattedDisplay =
        _vnFormat.format(displayedAmount.toInt()); // ✅ 50.000

    return Scaffold(
      backgroundColor: const Color(0xFF7E57C2),
      appBar: AppBar(
        title: const Text('QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF7E57C2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titleName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                titleStk,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              if (_errorUser != null)
                Text(
                  _errorUser!,
                  style: const TextStyle(color: Colors.red),
                )
              else
                FadeTransition(
                  opacity: _fadeAnimation.drive(
                    Tween(begin: 1.0, end: 1.0),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                  ),
                ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '$formattedDisplay VND', // ✅ hiển thị 50.000 VND
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                onPressed: _showChangeAmountSheet,
                child: const Text(
                  'Thay đổi số tiền',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
