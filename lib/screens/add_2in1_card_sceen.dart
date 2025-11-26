import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Add2in1CardScreen extends StatefulWidget {
  const Add2in1CardScreen({super.key});

  @override
  State<Add2in1CardScreen> createState() => _Add2in1CardScreenState();
}

class _Add2in1CardScreenState extends State<Add2in1CardScreen> {
  int? _selectedIndex;
  bool _isLoading = false;

  final List<String> apiUrls = const [
    "https://df4b91vt-4000.asse.devtunnels.ms",
    "http://10.0.2.2:4000",
    "http://localhost:4000",
  ];

  final List<Map<String, String>> cards = [
    {
      'image': 'assets/ca_2in1_card.png',
      'name': 'Thẻ Cá Chép Phát Tài',
      'price': 'Phí phát hành: 99.000đ',
      'design_code': 'CA_CHEP',
    },
    {
      'image': 'assets/meo_2in1_card.png',
      'name': 'Thẻ Mèo May Mắn',
      'price': 'Miễn phí phát hành',
      'design_code': 'MEO',
    },
    {
      'image': 'assets/rong_2in1_card.png',
      'name': 'Thẻ Rồng Vàng Thịnh Vượng',
      'price': 'Phí phát hành: 129.000đ',
      'design_code': 'RONG',
    },
  ];

  Future<void> _createCardOnServer() async {
  if (_selectedIndex == null) return;

  try {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      setState(() => _isLoading = false);
      _showError('Không tìm thấy user_id. Vui lòng đăng nhập lại.');
      return;
    }

    final selected = cards[_selectedIndex!];
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
                "card_type": "Debit",           // hoặc 'ATM' tùy DB
                "user_id": userId,
                "image": selected['image'],     // ✅ gửi path asset
              }),
            )
            .timeout(const Duration(seconds: 8));

        debugPrint("POST $uri → ${res.statusCode} ${res.body}");

        if (res.statusCode == 200 || res.statusCode == 201) break;
      } catch (e) {
        debugPrint("POST /card error with $base: $e");
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

    final newCard = {
      'name': selected['name']!,
      'status': 'Đang hoạt động',
      'image': selected['image']!, // đúng hình đã chọn
      'type': 'Debit',
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
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: const Text(
          'Bộ Sưu Tập Thẻ Flash 2In1',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    itemCount: cards.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 0.68,
                    ),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final isSelected = _selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF6D32D3)
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.purple
                                                .withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    card['image']!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              card['name']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card['price']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        (_selectedIndex != null && !_isLoading)
                            ? _createCardOnServer
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D32D3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Thêm thẻ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
