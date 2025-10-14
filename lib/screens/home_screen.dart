import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tp_bank/screens/history_screen.dart';
import 'package:tp_bank/screens/info_account_screen.dart';
import 'package:tp_bank/screens/transfer_screen.dart';
import 'package:tp_bank/core/models/user_model.dart';
import 'package:tp_bank/screens/qr_screen.dart';
import 'package:tp_bank/screens/qr_scanner.dart';
import 'package:tp_bank/screens/3g_4g_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

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
  int _selectedIndex = 0;
  bool _balanceVisible = true;
  User? _apiUser;
  bool _isLoading = true;

  // MÀU SẮC
  final Color _primaryColor = const Color(0xFF7E57C2);
  final Color _accentColor = const Color.fromARGB(225, 184, 73, 232);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;

  late List<Map<String, dynamic>> _services;
  final List<Map<String, dynamic>> _features = [
    {'icon': Icons.receipt, 'label': 'Thanh toán', 'color': Color(0xFF4CAF50)},
    {
      'icon': Icons.phone_iphone,
      'label': 'Nạp tiền',
      'color': Color(0xFF2196F3),
    },
    {'icon': Icons.credit_card, 'label': 'Thẻ', 'color': Color(0xFFFF9800)},
    {'icon': Icons.savings, 'label': 'Tiết kiệm', 'color': Color(0xFF9C27B0)},
    {
      'icon': Icons.card_giftcard,
      'label': 'Đổi quà',
      'color': Color(0xFFE91E63),
    },
    {'icon': Icons.money, 'label': 'Khoản vay', 'color': Color(0xFF795548)},
    {'icon': Icons.search, 'label': 'Tra cứu', 'color': Color(0xFF607D8B)},
    {
      'icon': Icons.more_horiz,
      'label': 'Khác',
      'color': Color.fromARGB(255, 203, 68, 172),
    },
  ];

  @override
  void initState() {
    super.initState();

    _services = [
      {
        'icon': Icons.compare_arrows,
        'label': 'Chuyển tiền',
        'onTap': (BuildContext context, User user) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TransferScreen(user: user)),
          );
        },
      },
      {
        'icon': Icons.history,
        'label': 'Lịch sử GD',
        'color': Color.fromARGB(255, 13, 137, 239),
        'onTap': (BuildContext context, User user) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HistoryScreen()),
          );
        },
      },
      {
        'icon': Icons.qr_code,
        'label': 'QR của tôi',
        'color': Color(0xFFFF9800),
        'onTap': (BuildContext context, User user) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QrScreen(user: user)),
          );
        },
      },

      {
        'icon': Icons.help, // icon dấu chấm hỏi
        'label': 'Thông tin TK',
        'color': Color.fromARGB(255, 205, 63, 231),
        'onTap': (BuildContext context, User user) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InfoAccountScreen(user: _apiUser ?? user),
            ),
          );
        },
      },
    ];

    _fetchUserData();
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
                leading: Icon(
                  Icons.account_balance_wallet,
                  color: const Color(0xFF7E57C2),
                ),
                title: Text('Ví điện tử'),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'Ví điện tử');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.phone_android_outlined,
                  color: const Color(0xFF7E57C2),
                ),
                title: Text('Tiền điện thoại'),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'Tiền điện thoại');
                },
              ),
              ListTile(
                leading: Icon(Icons.wifi, color: const Color(0xFF7E57C2)),
                title: Text('Data 3G/4G'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WifiScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await Future.delayed(Duration(seconds: 1)); // giả lập API
      setState(() {
        _apiUser = widget.user;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _apiUser = widget.user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _apiUser ?? widget.user;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
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
                gradient: LinearGradient(
                  colors: [_primaryColor, Color(0xFF9575CD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(FontAwesomeIcons.solidBell, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 125, 75, 210),
                    Color.fromARGB(255, 109, 50, 211),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //tài khoản
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_border,
                        color: Colors.white70,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        user.stk,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.phone, color: Colors.white70, size: 16),
                      SizedBox(width: 6),
                      Text(
                        user.phone,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _balanceVisible
                              ? '${_formatCurrency(user.balance)} VND'
                              : '••••••••',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _balanceVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _balanceVisible = !_balanceVisible),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _services.map((service) {
                      return GestureDetector(
                        onTap: () => service['onTap'](context, user),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white30,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                service['icon'],
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              service['label'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // PROMO CARD
            _buildCard(
              margin: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.local_offer, color: _accentColor),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '95K/ 2 vế tại rạp CGV, BHD, Lotte',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Mở thẻ FEST để hưởng ưu đãi ngay!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),

            // GRID FEATURES
            _buildCard(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(20),
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
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
                        default:
                          _showComingSoon(context, feature['label']);
                      }
                    },
                  );
                },
              ),
            ),

            SizedBox(height: 16),
            _buildPromoSection('Quay ngay', 'Giao dịch trên App TPBank'),
            _buildPromoSection('SẢN VÉ EM XINH "SAY HI" CONCERT', ''),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey[600],
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apps_outlined),
              activeIcon: Icon(Icons.apps),
              label: 'Tiện ích',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_outlined),
              activeIcon: Icon(Icons.account_balance),
              label: 'Dịch vụ NH',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),

      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 109, 50, 211),
              Color.fromARGB(255, 146, 14, 235),
              Color.fromARGB(255, 125, 75, 210),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => QRScannerScreen()),
            );
          },
          child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  Widget _buildCard({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSection(String title, String subtitle) {
    return _buildCard(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
