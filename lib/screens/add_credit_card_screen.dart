// lib/screens/add_credit_card_screen.dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AddCreditCardScreen extends StatefulWidget {
  const AddCreditCardScreen({super.key});

  @override
  State<AddCreditCardScreen> createState() => _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends State<AddCreditCardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<String> apiUrls = const [
    "https://df4b91vt-4000.asse.devtunnels.ms",
    "http://10.0.2.2:4000",
    "http://localhost:4000",
  ];

  /// Mỗi thẻ có 1 designCode riêng
  final List<Map<String, dynamic>> _creditCards = [
    {
      'image': 'assets/credit_card_2.png',
      'badge': 'Thẻ Ẩm thực hời nhất!',
      'name': 'JCB CASHBACK',
      'typeCode': 'Credit',   // trùng ENUM DB
      'designCode': 'JCB',    // 🔥 lưu xuống DB
      'features': [
        {'icon': Icons.flight, 'text': 'Đặc quyền sân bay, khách sạn'},
        {'icon': Icons.restaurant, 'text': 'Hoàn tới 12 triệu/năm cho ẩm thực'},
        {'icon': Icons.percent, 'text': 'Trả góp 0% mọi giao dịch'},
      ],
    },
    {
      'image': 'assets/credit_card_1.png',
      'badge': 'Thẻ giải trí HOT nhất!',
      'name': 'TPBANK MASTERCARD FEST',
      'typeCode': 'Credit',
      'designCode': 'FEST',   // 🔥
      'features': [
        {'icon': Icons.music_note, 'text': 'Ưu đãi mua vé Concert'},
        {
          'icon': Icons.airplanemode_active,
          'text': 'Ưu đãi vé máy bay, khách sạn đi "Du Idol"',
        },
        {'icon': Icons.movie, 'text': 'Ưu đãi xem phim quanh năm'},
      ],
    },
  ];

  Future<void> _createCardOnServer(Map<String, dynamic> card) async {
  try {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      setState(() => _isLoading = false);
      _showError('Không tìm thấy user_id. Vui lòng đăng nhập lại.');
      return;
    }

    final String numberCard = _generateRandomCardNumber();

    http.Response? res;

    for (final base in apiUrls) {
      try {
        final uri = Uri.parse('$base/card');

        res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                "number_card": numberCard,
                "issue_date": null,
                "expiry_date": null,
                "card_type": card['typeCode'],        // 'Credit'
                "user_id": userId,
                "image": card['image'],               // ✅ gửi path asset
              }),
            )
            .timeout(const Duration(seconds: 8));

        debugPrint("POST $uri → ${res.statusCode} ${res.body}");

        if (res.statusCode == 200 || res.statusCode == 201) break;
      } catch (e) {
        debugPrint("POST exception (/card, base=$base): $e");
      }
    }

    setState(() => _isLoading = false);

    if (res == null) {
      _showError('Không thể kết nối server. Thử lại sau.');
      return;
    }

    if (res.statusCode != 200 && res.statusCode != 201) {
      String msg = 'Tạo thẻ thất bại (${res.statusCode})';
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'].toString();
        }
      } catch (_) {}
      _showError(msg);
      return;
    }

    // Trả card về CardScreen – dùng đúng ảnh đang chọn
    final newCard = {
      'name': card['name'] as String,
      'status': 'Đang hoạt động',
      'image': card['image'] as String,
      'type': card['typeCode'] as String,
      'number': numberCard,
      'expiry': '12/30',
    };

    if (!mounted) return;
    Navigator.pop(context, newCard);
  } catch (e) {
    setState(() => _isLoading = false);
    _showError('Có lỗi xảy ra khi tạo thẻ: $e');
  }
}

  String _generateRandomCardNumber() {
    final rand = Random();
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      buffer.write(rand.nextInt(10));
      if ((i + 1) % 4 == 0 && i != 15) buffer.write(' ');
    }
    return buffer.toString();
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _creditCards.length,
                  itemBuilder: (context, index) {
                    final card = _creditCards[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 25),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    card['image'],
                                    width: 300,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    card['badge'],
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            card['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: card['features'].map<Widget>((f) {
                              return Column(
                                children: [
                                  Icon(f['icon'], color: Colors.deepPurple),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      f['text'],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _createCardOnServer(card),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6D32D3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text(
                                  'Nhận Thẻ ngay',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Xem biểu phí ?',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _creditCards.length,
                              (i) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _currentPage
                                      ? Colors.deepPurple
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
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
}
