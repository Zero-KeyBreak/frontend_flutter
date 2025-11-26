import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class WifiScreen extends StatefulWidget {
  const WifiScreen({super.key});

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  Map<String, String>? selectedPackage;
  final TextEditingController phoneController = TextEditingController();
  String? selectedNetwork;

  bool _isLoading = false;

  int? _userId;
  String _stk = "";
  double _balance = 0;

  // Fallback URL giống login / transfer / phone
  final List<String> apiUrls = [
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
    http.Response? last;
    for (final base in apiUrls) {
      try {
        final uri = Uri.parse('$base$path');
        final res = await http.get(uri).timeout(const Duration(seconds: 8));
        debugPrint("GET $uri -> ${res.statusCode}");
        if (res.statusCode == 200) return res;
        last = res;
      } catch (e) {
        debugPrint("GET $path error with $base: $e");
      }
    }
    return last;
  }

  Future<http.Response?> _postWithFallback(
      String path, Map<String, dynamic> body) async {
    http.Response? last;
    for (final base in apiUrls) {
      try {
        final uri = Uri.parse('$base$path');
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 10));
        debugPrint("POST $uri -> ${res.statusCode} ${res.body}");
        if (res.statusCode == 201 || res.statusCode == 200) return res;
        last = res;
      } catch (e) {
        debugPrint("POST $path error with $base: $e");
      }
    }
    return last;
  }

  // ===== Load user (STK + balance) =====
  Future<void> _loadUserInfo() async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id');
      if (id == null) {
        _showError('Không tìm thấy user_id. Vui lòng đăng nhập lại.');
        setState(() => _isLoading = false);
        return;
      }
      _userId = id;

      final res = await _getWithFallback('/user/$id');
      if (res == null || res.statusCode != 200) {
        _showError('Không tải được thông tin tài khoản.');
        setState(() => _isLoading = false);
        return;
      }

      final decoded = jsonDecode(res.body);
      Map<String, dynamic>? data;
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is List && decoded.isNotEmpty) {
        data = decoded.first as Map<String, dynamic>;
      }

      final dynamic bal = data?['balance'];
      final double balance = bal is num
          ? bal.toDouble()
          : double.tryParse(bal?.toString() ?? '0') ?? 0;

      setState(() {
        _stk = data?['stk']?.toString() ?? '';
        _balance = balance;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("load user info wifi error: $e");
      _showError('Có lỗi xảy ra khi tải thông tin tài khoản.');
      setState(() => _isLoading = false);
    }
  }

  // ===== Helper =====
  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          )
        ],
      ),
    );
  }

  void _showSuccess(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          'Thành công',
          style: TextStyle(color: Colors.green),
        ),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // báo về màn trước để reload
            },
            child: const Text('ĐÓNG'),
          )
        ],
      ),
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

  String _formatAmountInt(int amount) {
    return amount
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  // Map nhà mạng text -> ENUM DB
  String _mapProviderToEnum(String name) {
    switch (name.toLowerCase()) {
      case 'viettel':
        return 'VIETTEL';
      case 'mobifone':
        return 'MOBIFONE';
      case 'vinaphone':
        return 'VINAPHONE';
      case 'vietnamobile':
        return 'VIETNAMOBILE';
      case 'wintel':
        return 'WINTEL';
      default:
        return 'VIETTEL';
    }
  }

  int _getPriceFromString(String s) {
    // "10,000 VND" -> 10000
    final clean = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  int? _getDurationDays(String group) {
    // dùng label group để set số ngày (tùy ý)
    switch (group) {
      case 'Gói 1 ngày':
        return 1;
      case 'Gói 3 ngày':
        return 3;
      case 'Gói 7 ngày':
        return 7;
      case 'Gói 10 ngày':
        return 10;
      case 'Gói 30 ngày':
        return 30;
      default:
        return null;
    }
  }

  // ====== CALL API /datatopup ======
  Future<void> _submitDataTopup() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('Vui lòng nhập số điện thoại');
      return;
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showError('Số điện thoại không hợp lệ');
      return;
    }
    if (selectedNetwork == null) {
      _showError('Vui lòng chọn nhà mạng');
      return;
    }
    if (selectedPackage == null) {
      _showError('Vui lòng chọn gói data');
      return;
    }
    if (_userId == null || _stk.isEmpty) {
      _showError('Không tìm thấy thông tin tài khoản nguồn');
      return;
    }

    final providerEnum = _mapProviderToEnum(selectedNetwork!);
    final priceStr = selectedPackage!['price']!; // "10,000 VND"
    final dataStr = selectedPackage!['data']!;   // "8GB" ...
    final price = _getPriceFromString(priceStr);
    final group = selectedPackage!['group'] ?? '';

    if (price <= 0) {
      _showError('Giá gói không hợp lệ');
      return;
    }
    if (price > _balance) {
      _showError('Số dư không đủ');
      return;
    }

    final duration = _getDurationDays(group) ?? 1;
    final packageName = '$group - $dataStr';

    // Confirm trước
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận nạp data'),
        content: Text(
          'Bạn chắc chắn nạp gói $packageName\n'
          'Nhà mạng: $selectedNetwork\n'
          'Giá: ${_formatAmountInt(price)} VND\n'
          'Cho số: $phone ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              final res = await _postWithFallback('/datatopup', {
                'user_id': _userId,
                'phone_number': phone,
                'provider': providerEnum,
                'package_name': group, // VD: "Gói 1 ngày"
                'data_amount': dataStr, // "8GB"
                'price': price,
                'duration_days': duration,
              });

              setState(() => _isLoading = false);

              if (res == null) {
                _showError('Không thể kết nối server');
                return;
              }

              if (res.statusCode == 201 || res.statusCode == 200) {
                final decoded = jsonDecode(res.body);
                final balAfter =
                    double.tryParse('${decoded["balance_after"]}') ??
                        (_balance - price);
                setState(() {
                  _balance = balAfter;
                });
                _showSuccess(
                  'Nạp gói $packageName thành công.\n'
                  'Số dư mới: ${_formatCurrency(_balance)} VND',
                );
              } else {
                String msg = 'Lỗi nạp data (${res.statusCode})';
                try {
                  final decoded = jsonDecode(res.body);
                  if (decoded is Map && decoded['message'] != null) {
                    msg = decoded['message'].toString();
                  }
                } catch (_) {}
                _showError(msg);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 104, 5, 211),
            ),
            child: const Text('ĐỒNG Ý', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 212, 241),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 223, 212, 241),
        title: const Center(
          child: Text(
            'Nạp Data 3G,4G',
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 104, 5, 211),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isLoading ? null : _submitDataTopup,
            child: const Text(
              'Tiếp tục',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Từ tài khoản',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.heartCircleCheck,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_stk.isNotEmpty ? _stk : '---',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 5),
                        Text(
                          '${_formatCurrency(_balance)} VND',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Thông tin nạp tiền',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Số điện thoại + nhà mạng
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    icon: Icons.phone,
                    hint: 'Số điện thoại',
                    isNumber: true,
                    controller: phoneController,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) {
                          final nets = [
                            'Viettel',
                            'Mobifone',
                            'Vinaphone',
                            'Vietnamobile',
                            'Wintel',
                          ];
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Container(
                                    width: 50,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Chọn nhà mạng',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...nets.map((n) {
                                  return ListTile(
                                    title: Text(n),
                                    onTap: () {
                                      setState(() {
                                        selectedNetwork = n;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi, color: Colors.purple),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedNetwork ?? 'Nhà mạng',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.purple),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildGroupTitle('Gói 1 ngày'),
            _buildPackageRow('Gói 1 ngày', [
              {'data': '8GB', 'price': '10,000 VND'},
              {'data': '24GB', 'price': '20,000 VND'},
            ]),
            const SizedBox(height: 16),

            _buildGroupTitle('Gói 3 ngày'),
            _buildPackageRow('Gói 3 ngày', [
              {'data': '3GB', 'price': '15,000 VND'},
              {'data': '5GB', 'price': '25,000 VND'},
            ]),
            const SizedBox(height: 16),

            _buildGroupTitle('Gói 7 ngày'),
            _buildPackageRow('Gói 7 ngày', [
              {'data': '5GB', 'price': '40,000 VND'},
              {'data': '7GB', 'price': '60,000 VND'},
            ]),
            const SizedBox(height: 16),

            _buildGroupTitle('Gói 30 ngày'),
            _buildPackageRow('Gói 30 ngày', [
              {'data': '8GB', 'price': '84,000 VND'},
              {'data': '50GB/30 ngày', 'price': '155,000 VND'},
            ]),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 12));
  }

  Widget _buildPackageRow(
      String group, List<Map<String, String>> packages) {
    return Row(
      children: packages.map((package) {
        final pkg = {
          ...package,
          'group': group,
        };
        final bool isSelected =
            selectedPackage?['data'] == package['data'] &&
            selectedPackage?['price'] == package['price'] &&
            selectedPackage?['group'] == group;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedPackage = pkg),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber[100] : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      isSelected ? Colors.amber : Colors.transparent,
                  width: 2,
                ),
              ),
              height: 50,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      package['data']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      package['price']!,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

Widget _buildInputField({
  required IconData icon,
  required String hint,
  bool isNumber = false,
  TextEditingController? controller,
}) {
  return Container(
    height: 60,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
              ),
              keyboardType:
                  isNumber ? TextInputType.number : TextInputType.text,
            ),
          ),
        ],
      ),
    ),
  );
}
