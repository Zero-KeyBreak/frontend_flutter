// lib/screens/card_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'add_2in1_card_sceen.dart';
import 'add_credit_card_screen.dart';
import 'card_detail_screen.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key, required this.cards});

  final List<Map<String, String>> cards;

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  List<Map<String, String>> _cards = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> apiUrls = const [
    "https://df4b91vt-4000.asse.devtunnels.ms",
    "http://10.0.2.2:4000",
    "http://localhost:4000",
  ];

  @override
  void initState() {
    super.initState();
    _cards = widget.cards;
    _loadCardsFromApi();
  }

  Future<void> _loadCardsFromApi() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không tìm thấy user_id. Vui lòng đăng nhập lại.';
        });
        return;
      }

      http.Response? res;

      for (final base in apiUrls) {
        try {
          final uri = Uri.parse('$base/card?user_id=$userId');
          res = await http.get(uri).timeout(const Duration(seconds: 8));
          debugPrint('GET $uri → ${res.statusCode}');
          if (res.statusCode == 200) break;
        } catch (e) {
          debugPrint('GET /card error with $base: $e');
        }
      }

      if (res == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể kết nối server.';
        });
        return;
      }

      if (res.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi server: ${res?.statusCode}';
        });
        return;
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Dữ liệu /card không hợp lệ.';
        });
        return;
      }

      final List<Map<String, String>> loaded = [];
      for (final row in decoded) {
        final mapRow = Map<String, dynamic>.from(row);

        final String cardType = '${mapRow['card_type'] ?? ''}';
final String numberCard = '${mapRow['number_card'] ?? ''}';
final String expiry = '${mapRow['expiry_date'] ?? ''}';

String name = 'Thẻ TPBank';
String image = (mapRow['image'] ?? '') as String;

// nếu DB có image => dùng luôn
if (image.isNotEmpty) {
  // đặt name đẹp theo type (tuỳ thích)
  if (cardType == 'Credit') {
    name = 'Thẻ tín dụng TPBank';
  } else if (cardType == 'Debit') {
    name = 'Thẻ ghi nợ TPBank';
  } else if (cardType == 'ATM') {
    name = 'Thẻ ATM TPBank';
  }
} else {
  // fallback khi image = NULL (dữ liệu cũ)
  if (cardType == 'Credit') {
    name = 'Thẻ tín dụng TPBank';
    image = 'assets/credit_card_1.png';
  } else if (cardType == 'ATM') {
    name = 'Thẻ ATM TPBank';
    image = 'assets/atm_card.png';
  } else if (cardType == 'Debit') {
    name = 'Thẻ ghi nợ TPBank';
    image = 'assets/ca_2in1_card.png';
  }
}

   loaded.add({
  'name': name,
  'status': 'Đang hoạt động',
  'image': image,
  'type': cardType,
  'number': numberCard,
  'expiry': expiry,
});

      }

      setState(() {
        _cards = loaded;
        _isLoading = false;
      });

      await prefs.setString('cards', jsonEncode(_cards));
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi load thẻ: $e';
      });
    }
  }

  void _navigateToAddCard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAddCardSheet(),
    );
  }

  Widget _buildAddCardSheet() {
    final List<Map<String, String>> newCardOptions = [
      {
        'title': 'Thẻ Flash 2in1',
        'subtitle':
            'Tích hợp thẻ tín dụng và ghi nợ.\nKhông in số thẻ, bảo mật tuyệt đối.',
        'image': 'assets/2in1.png',
        'type': '2in1',
      },
      {
        'title': 'Thẻ tín dụng',
        'subtitle': 'Không cần chứng minh thu nhập.\nThủ tục online 100%.',
        'image': 'assets/creditcard.png',
        'type': 'credit',
      },
    ];

    return Padding(
      // UI giữ nguyên như code của Đại Ka
      // ...
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Mở thẻ mới",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          ...newCardOptions.map(
            (option) => GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                dynamic newCard;
                if (option['type'] == 'credit') {
                  newCard = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddCreditCardScreen(),
                    ),
                  );
                } else {
                  newCard = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Add2in1CardScreen(),
                    ),
                  );
                }

                if (newCard != null) {
                  setState(() {
                    _cards.add(Map<String, String>.from(newCard));
                  });

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('cards', jsonEncode(_cards));

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Thêm thẻ "${newCard['name']}" thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              // ... phần container như cũ
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['title']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['subtitle']!,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        option['image']!,
                        width: 70,
                        height: 45,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCardDetail(Map<String, String> card) async {
    final updatedCard = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CardDetailScreen(card: card),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

    if (updatedCard != null) {
      setState(() {
        final index = _cards.indexWhere(
          (c) => c['name'] == updatedCard['name'],
        );
        if (index != -1) {
          _cards[index] = Map<String, String>.from(updatedCard);
        }
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cards', jsonEncode(_cards));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(FontAwesomeIcons.solidCreditCard, color: Color(0xFFFF9800)),
            SizedBox(width: 12),
            Text(
              'Thẻ',
              style: TextStyle(
                color: Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      const Text(
                        'Thẻ của tôi',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 20),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: _cards.isEmpty
                            ? const Center(child: Text('Chưa có thẻ nào'))
                            : ListView.builder(
                                itemCount: _cards.length,
                                itemBuilder: (context, index) {
                                  final card = _cards[index];
                                  final isActive =
                                      card['status'] == 'Đang hoạt động';

                                  return GestureDetector(
                                    onTap: () => _navigateToCardDetail(card),
                                    child: Hero(
                                      tag: card['name']!,
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 238, 230, 251),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.asset(
                                                card['image']!,
                                                width: 120,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    card['name']!,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        isActive
                                                            ? Icons
                                                                .check_circle
                                                            : Icons.lock,
                                                        color: isActive
                                                            ? Colors.green
                                                            : Colors
                                                                .redAccent,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        card['status']!,
                                                        style: TextStyle(
                                                          color: isActive
                                                              ? Colors.green
                                                              : Colors
                                                                  .redAccent,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Color.fromARGB(
                                                  255, 121, 29, 234),
                                              size: 32,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Center(
                          child: GestureDetector(
                            onTap: _navigateToAddCard,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 115, 41, 242),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              height: 45,
                              width: 200,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.plus,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Mở thêm thẻ',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                ],
                              ),
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
