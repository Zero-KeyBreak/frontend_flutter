// lib/screens/home_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tp_bank/screens/card_screen.dart';
import 'package:tp_bank/screens/history_screen.dart';
import 'package:tp_bank/screens/info_account_screen.dart';
import 'package:tp_bank/screens/login_screen.dart';
import 'package:tp_bank/screens/number_phone_pay_screen.dart';
import 'package:tp_bank/screens/personal_screen.dart';
import 'package:tp_bank/screens/transfer_screen.dart';
import 'package:tp_bank/screens/qr_screen.dart';
import 'package:tp_bank/screens/qr_scanner.dart';
import 'package:tp_bank/screens/3g_4g_screen.dart';
import 'package:tp_bank/screens/wallet_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature đang được phát triển'),
      duration: Duration(seconds: 2),
    ),
  );
}

class _HomeScreenState extends State<HomeScreen> {
  int? user_id = 0;
  String username = "";
  String phone = "";
  String stk = "";
  String user_balance = "0";
  int _selectedIndex = 0;
  bool _balanceVisible = true;
  bool _isLoading = true;
  String token = "";

  final Color _primaryColor = const Color(0xFF7E57C2);
  final Color _accentColor = const Color.fromARGB(225, 184, 73, 232);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;

  late List<Map<String, dynamic>> _services;
  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.phone_iphone,
      'label': 'Nạp tiền',
      'color': Color(0xFF2196F3),
    },
    {'icon': Icons.credit_card, 'label': 'Thẻ', 'color': Color(0xFFFF9800)},
  ];

  @override
  void initState() {
    super.initState();
   _services = [
  {
    'icon': Icons.compare_arrows,
    'label': 'Chuyển tiền',
    'onTap': (BuildContext context) async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransferScreen()),
      );

      if (result == true) {
        // Giao dịch thành công -> load lại số dư từ backend
        fetchUser();   // dùng đúng hàm bạn đã có trong HomeScreen
      }
    },
  },
  {
    'icon': Icons.history,
    'label': 'Lịch sử GD',
    'onTap': (BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HistoryScreen()),
      );
    },
  },
  {
    'icon': Icons.qr_code,
    'label': 'QR của tôi',
    'onTap': (BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QrScreen()),
      );
    },
  },
  {
    'icon': Icons.help,
    'label': 'Thông tin TK',
    'onTap': (BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => InfoAccountScreen()),
      );
    },
  },
];


    loadToken();
    fetchUser(); // tải user khi khởi tạo
  }

  // Lưu ý: nếu chạy Android emulator -> dùng 10.0.2.2 thay vì localhost
  Future<Map<String, dynamic>?> loadUserData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final int? id = prefs.getInt('user_id');

    if (id == null) return null;
    user_id = id;

    // ƯU TIÊN THEO THỨ TỰ:
    const tunnelUrl  = "https://df4b91vt-4000.asse.devtunnels.ms";
    const androidUrl = "http://10.0.2.2:4000";   // Android emulator
    const localUrl   = "http://localhost:4000";  // PC browser

    // Danh sách URL thử lần lượt
    final List<String> endpoints = [
      "$tunnelUrl/user/$id",
      "$androidUrl/user/$id",
      "$localUrl/user/$id",
    ];

    for (final endpoint in endpoints) {
      try {
        final url = Uri.parse(endpoint);
        debugPrint("🔍 Thử gọi API: $endpoint");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);

          // Trường hợp API trả về 1 object
          if (decoded is Map<String, dynamic>) return decoded;

          // Trường hợp API trả về 1 list
          if (decoded is List &&
              decoded.isNotEmpty &&
              decoded[0] is Map<String, dynamic>) {
            return decoded[0] as Map<String, dynamic>;
          }

          return null;
        } else {
          debugPrint("❌ Lỗi API $endpoint: "
              "${response.statusCode} ${response.body}");
        }
      } catch (e) {
        debugPrint("⚠️ Không gọi được $endpoint: $e");
      }
    }

    // Nếu cả 3 endpoint đều fail
    return null;
  } catch (e) {
    debugPrint("Exception loadUserData: $e");
    return null;
  }
}


  Future<void> fetchUser() async {
    setState(() => _isLoading = true);
    final data = await loadUserData();

    if (data != null) {
      setState(() {
        username = data['username']?.toString() ?? '';
        phone = data['phone']?.toString() ?? '';
        stk = data['stk']?.toString() ?? '';
        user_balance = (data['balance'] != null) ? data['balance'].toString() : '0';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token") ?? "";
    });
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("user_id");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showDepositOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn phương thức nạp tiền',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.phone_android_outlined, color: const Color(0xFF7E57C2)),
                title: Text('Tiền điện thoại'),
               onTap: () async {
  Navigator.pop(context);

  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const NumberPhonePayScreen()),
  );

  // Nếu nạp thành công -> reload user
  if (result == true) {
    fetchUser(); // <-- giống TransferScreen
  }
},

              ),
              ListTile(
                leading: Icon(Icons.wifi, color: const Color(0xFF7E57C2)),
                title: Text('Data 3G/4G'),
                onTap: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WifiScreen()),
  );

  if (result == true) {
     fetchUser(); // hàm đã có ở Home để reload số dư
  }
}

              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeContent() {
    // sử dụng các biến username, phone, stk, user_balance
    final double balanceDouble = double.tryParse(user_balance.replaceAll(',', '')) ?? 0.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 125, 75, 210), Color.fromARGB(255, 109, 50, 211)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // tài khoản
                Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(stk, style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(width: 16),
                    Icon(Icons.phone, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(phone, style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _balanceVisible ? '${_formatCurrency(balanceDouble)} VND' : '••••••••',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_balanceVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white70, size: 20),
                      onPressed: () => setState(() => _balanceVisible = !_balanceVisible),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _services.map((service) {
                    return GestureDetector(
                      onTap: () => service['onTap'](context),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white30, width: 1),
                            ),
                            child: Icon(service['icon'], color: Colors.white, size: 24),
                          ),
                          SizedBox(height: 8),
                          Text(service['label'], style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Promo card
          _buildCard(
            margin: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.local_offer, color: _accentColor)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('95K/ 2 vế tại rạp CGV, BHD, Lotte', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800])),
                      SizedBox(height: 2),
                      Text('Mở thẻ FEST để hưởng ưu đãi ngay!', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),

          // Grid features
          _buildCard(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(20),
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2, crossAxisSpacing: 2, mainAxisSpacing: 2),
              itemCount: _features.length,
              itemBuilder: (context, index) {
                final feature = _features[index];
                return _buildFeatureButton(
                  icon: feature['icon'],
                  label: feature['label'],
                  color: feature['color'],
                  onTap: () {
                    switch (feature['label']) {
                      case 'Nạp tiền':
                        _showDepositOptions();
                        break;
                      case 'Thẻ':
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CardScreen(cards: [])));
                        break;
                      default:
                        _showComingSoon(context, feature['label']);
                    }
                  },
                );
              },
            ),
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_primaryColor))),
      );
    }

    final List<Widget> pages = [
      // Home page
      Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 109, 50, 211),
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primaryColor, Color(0xFF9575CD)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xin chào', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Text(username, style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          
        ),
        body: _buildHomeContent(),
      ),

      // Personal page
      const PersonalScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey[600],
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outlined), activeIcon: Icon(Icons.person), label: 'Cá nhân'),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color.fromARGB(255, 109, 50, 211), Color.fromARGB(255, 146, 14, 235), Color.fromARGB(255, 125, 75, 210)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: _accentColor.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen())),
          child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  String _formatCurrency(double amount) {
    final int value = amount.floor(); // ❌ không làm tròn, chỉ bỏ phần thập phân
  return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? margin, EdgeInsetsGeometry? padding}) {
    return Container(margin: margin, padding: padding ?? EdgeInsets.all(16), decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]), child: child);
  }

  Widget _buildFeatureButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
        SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
