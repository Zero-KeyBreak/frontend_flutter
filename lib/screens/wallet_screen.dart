// lib/screens/wallet_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tp_bank/screens/link_wallet_screen.dart';
import 'package:http/http.dart' as http;

// Cấu hình ví: wallet_id ↔ name + logo
const Map<int, Map<String, String>> kWalletConfig = {
  1: {'name': 'Momo', 'logo': 'assets/momo.png'},
  2: {'name': 'ZaloPay', 'logo': 'assets/zalo.png'},
  3: {'name': 'FPTPay', 'logo': 'assets/fpt.png'},
  4: {'name': 'GHTKPay', 'logo': 'assets/ghtk.png'},
  5: {'name': 'Payoo', 'logo': 'assets/payoo.png'},
  6: {'name': 'ShopeePay', 'logo': 'assets/shopeepay.png'},
  7: {'name': 'Payme', 'logo': 'assets/payme.png'},
  8: {'name': 'VNPay', 'logo': 'assets/vnpay.png'},
  9: {'name': 'SenPay', 'logo': 'assets/senpay.png'},
  10: {'name': 'VNPT', 'logo': 'assets/vnpt.png'},
  11: {'name': 'VTCPay', 'logo': 'assets/vtc.png'},
};

class UserWallet {
  final int id;          // user_wallet_id
  final int userId;
  final int walletId;
  final String walletName;
  final String walletLogo;
  final String linkedPhone;
  final String? accountName;
  final String status;

  UserWallet({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.walletName,
    required this.walletLogo,
    required this.linkedPhone,
    required this.status,
    this.accountName,
  });

  factory UserWallet.fromJson(Map<String, dynamic> json) {
    final int walletId = json["wallet_id"] ?? 0;
    final meta = kWalletConfig[walletId] ?? {};

    return UserWallet(
      id: json["user_wallet_id"] ?? 0,
      userId: json["user_id"] ?? 0,
      walletId: walletId,
      walletName: meta["name"] ?? "Wallet $walletId",
      walletLogo: meta["logo"] ?? "assets/momo.png", // fallback
      linkedPhone: json["linked_phone"]?.toString() ?? "",
      accountName: json["account_name"]?.toString(),
      status: json["status"]?.toString() ?? "LINKED",
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<UserWallet> _linkedWallets = [];

  // Y chang login + home
  final List<String> apiUrls = const [
    "https://df4b91vt-4000.asse.devtunnels.ms",
    "http://10.0.2.2:4000",
    "http://localhost:4000",
  ];

  @override
  void initState() {
    super.initState();
    _loadLinkedWalletsFromApi();
  }

  // ================== CALL API GET /userwallet ==================
  Future<void> _loadLinkedWalletsFromApi() async {
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

      http.Response? res;

      for (final base in apiUrls) {
        try {
          final uri = Uri.parse("$base/userwallet");
          final r = await http.get(uri).timeout(const Duration(seconds: 8));
          debugPrint("GET $uri → ${r.statusCode}");

          if (r.statusCode == 200) {
            res = r;
            break;
          }
        } catch (e) {
          debugPrint("GET /userwallet lỗi với $base: $e");
        }
      }

      if (res == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Không thể kết nối server.";
        });
        return;
      }

      if (res.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Lỗi server: ${res?.statusCode}";
        });
        return;
      }

      final List<dynamic> data = jsonDecode(res.body);
      final allWallets = data.map((e) => UserWallet.fromJson(e)).toList();

      // Lọc ví theo user hiện tại
      final userWallets = allWallets
          .where((w) => w.userId == userId)
          .toList();

      setState(() {
        _linkedWallets = userWallets;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("load wallets error: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Lỗi tải dữ liệu: $e";
      });
    }
  }

  // ================== SHOW BOTTOM SHEET CHỌN VÍ ==================
  void _showWalletOptions(BuildContext context) {
    final wallets = <Map<String, dynamic>>[];
    kWalletConfig.forEach((id, meta) {
      wallets.add({
        "id": id,
        "name": meta["name"],
        "logo": meta["logo"],
      });
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, scrollController) => Column(
            children: [
              const SizedBox(height: 12),
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
                'Chọn ví điện tử để liên kết',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: wallets.length,
                  itemBuilder: (context, index) {
                    final item = wallets[index];
                    return ListTile(
                      leading: Image.asset(item['logo'] as String, width: 36),
                      title: Text(
                        item['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final bool? added = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LinkWalletScreen(
                              walletId: item['id'] as int,
                              walletName: item['name'] as String,
                              walletLogo: item['logo'] as String,
                            ),
                          ),
                        );

                        // Nếu LinkWalletScreen trả về true -> reload lại từ API
                        if (added == true && mounted) {
                          await _loadLinkedWalletsFromApi();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ví điện tử',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF6D32D3),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _linkedWallets.isEmpty
                            ? const Center(
                                child: Text(
                                  'Chưa có ví nào được liên kết',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _linkedWallets.length,
                                itemBuilder: (context, index) {
                                  final wallet = _linkedWallets[index];
                                  return Card(
                                    elevation: 0,
                                    color: Colors.grey[100],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: Image.asset(
                                        wallet.walletLogo,
                                        width: 50,
                                        height: 50,
                                      ),
                                      title: Text(
                                        wallet.walletName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        wallet.linkedPhone,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6D32D3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _showWalletOptions(context),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Thêm liên kết ví điện tử',
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
    );
  }
}
