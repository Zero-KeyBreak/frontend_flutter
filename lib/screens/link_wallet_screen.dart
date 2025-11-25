// lib/screens/link_wallet_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LinkWalletScreen extends StatefulWidget {
  int walletId;
  String walletName;
  String walletLogo;

  LinkWalletScreen({
    super.key,
    required this.walletId,
    required this.walletName,
    required this.walletLogo,
  });

  @override
  State<LinkWalletScreen> createState() => _LinkWalletScreenState();
}

class _LinkWalletScreenState extends State<LinkWalletScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // base URL giống login/home
  final List<String> apiUrls = const [
    "https://df4b91vt-4000.asse.devtunnels.ms",
    "http://10.0.2.2:4000",
    "http://localhost:4000",
  ];

  final List<Map<String, dynamic>> wallets = const [
    {'id': 1, 'name': 'Momo', 'logo': 'assets/momo.png'},
    {'id': 2, 'name': 'ZaloPay', 'logo': 'assets/zalo.png'},
    {'id': 3, 'name': 'FPTPay', 'logo': 'assets/fpt.png'},
    {'id': 4, 'name': 'GHTKPay', 'logo': 'assets/ghtk.png'},
    {'id': 5, 'name': 'Payoo', 'logo': 'assets/payoo.png'},
    {'id': 6, 'name': 'ShopeePay', 'logo': 'assets/shopeepay.png'},
    {'id': 7, 'name': 'Payme', 'logo': 'assets/payme.png'},
    {'id': 8, 'name': 'VNPay', 'logo': 'assets/vnpay.png'},
    {'id': 9, 'name': 'SenPay', 'logo': 'assets/senpay.png'},
    {'id': 10, 'name': 'VNPT', 'logo': 'assets/vnpt.png'},
    {'id': 11, 'name': 'VTCPay', 'logo': 'assets/vtc.png'},
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {});
    });
  }

  // ================== chọn ví khác ==================
  void _showWalletSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Chọn ví điện tử',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                final item = wallets[index];
                return ListTile(
                  leading: Image.asset(item['logo'] as String, width: 36),
                  title: Text(item['name'] as String),
                  onTap: () {
                    setState(() {
                      widget.walletId = item['id'] as int;
                      widget.walletName = item['name'] as String;
                      widget.walletLogo = item['logo'] as String;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================== GỌI API POST /userwallet ==================
  Future<void> _submitLinkWallet() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt("user_id");

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Không tìm thấy user_id, vui lòng đăng nhập lại.";
        });
        return;
      }

      final body = {
        "user_id": userId,
        "wallet_id": widget.walletId,
        "linked_phone": phone,
        "account_name": null,
        "status": "LINKED",
      };

      http.Response? res;
      for (final base in apiUrls) {
        try {
          final uri = Uri.parse("$base/userwallet");
          final r = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 8));
          debugPrint("POST $uri → ${r.statusCode} ${r.body}");
          if (r.statusCode == 201) {
            res = r;
            break;
          } else {
            // lưu response cuối cùng để show lỗi, nhưng vẫn thử base khác
            res = r;
          }
        } catch (e) {
          debugPrint("POST /userwallet error with base: $e");
        }
      }

      if (res == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Không thể kết nối server.";
        });
        return;
      }

      if (res.statusCode != 201) {
        String msg = "Lỗi liên kết ví: ${res.statusCode}";
        try {
          final data = jsonDecode(res.body);
          if (data["message"] != null) msg = data["message"];
        } catch (_) {}
        setState(() {
          _isLoading = false;
          _errorMessage = msg;
        });
        return;
      }

      // Thành công: pop về WalletScreen + báo true để reload
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Lỗi: $e";
      });
    }
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final isPhoneValid = _phoneController.text.length == 10;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 109, 50, 211),
        title: const Text(
          'Thêm Liên Kết Ví',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nguồn tiền (mock giống code cũ)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Image.asset('assets/tpbanklogo.png', width: 40),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Nguồn Tiền',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '06437082701',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            FontAwesomeIcons.heartCircleCheck,
                            color: Color.fromARGB(255, 109, 50, 211),
                            size: 16,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '491,367 VND',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 29),
              child: Column(
                children: const [
                  Icon(
                    FontAwesomeIcons.chevronDown,
                    size: 10,
                    color: Colors.grey,
                  ),
                  Icon(
                    FontAwesomeIcons.chevronDown,
                    size: 10,
                    color: Colors.black54,
                  ),
                  Icon(
                    FontAwesomeIcons.chevronDown,
                    size: 10,
                    color: Colors.black,
                  ),
                ],
              ),
            ),

            // Thông tin ví
            InkWell(
              onTap: _showWalletSelector,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Image.asset(widget.walletLogo, width: 40),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ví điện tử',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.walletName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(
                      FontAwesomeIcons.chevronRight,
                      size: 18,
                      color: Color.fromARGB(255, 109, 50, 211),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'THÔNG TIN VÍ',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Số điện thoại liên kết ví',
                hintText: 'Nhập số điện thoại liên kết ví',
                prefixIcon: const Icon(
                  FontAwesomeIcons.phone,
                  color: Color.fromARGB(255, 109, 50, 211),
                  size: 16,
                ),
                errorText: _phoneController.text.isEmpty
                    ? null
                    : (!isPhoneValid ? 'Số điện thoại phải đủ 10 số' : null),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 109, 50, 211),
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: (!isPhoneValid || _isLoading) ? null : _submitLinkWallet,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 109, 50, 211),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Tiếp tục',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
