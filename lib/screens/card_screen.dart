import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tp_bank/screens/add_2in1_card_sceen.dart';
import 'package:tp_bank/screens/add_credit_card_screen.dart';
import 'package:tp_bank/screens/card_detail_screen.dart';

class CardScreen extends StatefulWidget {
  final List<Map<String, String>> cards;

  const CardScreen({super.key, required this.cards});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  List<Map<String, String>> _cards = [];

  @override
  void initState() {
    super.initState();
    // ✅ Hiển thị trước dữ liệu mặc định
    _cards = widget.cards;
    // ✅ Load dữ liệu thật ở nền (không chặn UI)
    _loadCards();
  }

  Future<void> _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('cards');
    if (stored != null) {
      final List decoded = jsonDecode(stored);
      setState(() {
        _cards = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cards', jsonEncode(_cards));
  }

  void _navigateToAddCard() async {
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
                  final exists = _cards.any(
                    (c) => c['name'] == newCard['name'],
                  );
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bạn đã có thẻ "${newCard['name']}" rồi!',
                        ),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                  } else {
                    setState(() {
                      _cards.add(Map<String, String>.from(newCard));
                    });
                    _saveCards();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Thêm thẻ "${newCard['name']}" thành công!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
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
          const SizedBox(height: 12),
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
        if (index != -1) _cards[index] = updatedCard;
      });
      _saveCards();
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            const Text(
              'Thẻ của tôi',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: _cards.isEmpty
                  ? const Center(child: Text('Chưa có thẻ nào'))
                  : ListView.builder(
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        final isActive = card['status'] == 'Đang hoạt động';

                        return GestureDetector(
                          onTap: () => _navigateToCardDetail(card),
                          child: Hero(
                            tag: card['name']!,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 238, 230, 251),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
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
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              isActive
                                                  ? Icons.check_circle
                                                  : Icons.lock,
                                              color: isActive
                                                  ? Colors.green
                                                  : Colors.redAccent,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              card['status']!,
                                              style: TextStyle(
                                                color: isActive
                                                    ? Colors.green
                                                    : Colors.redAccent,
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
                                    color: Color.fromARGB(255, 121, 29, 234),
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
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
