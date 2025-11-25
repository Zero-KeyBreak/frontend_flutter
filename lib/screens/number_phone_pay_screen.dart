import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NumberPhonePayScreen extends StatefulWidget {
  const NumberPhonePayScreen({super.key});

  @override
  State<NumberPhonePayScreen> createState() => _NumberPhonePayScreenState();
}

class _NumberPhonePayScreenState extends State<NumberPhonePayScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? selectedNetwork;
  int? selectedAmount;

  bool _isLoading = false;

  // user data
  int? _userId;
  String _stk = '';
  double _balance = 0;

  // giống login / transfer / history
  final List<String> apiUrls = [
    "https://df4b91vt-4000.asse.devtunnels.ms",
    "http://10.0.2.2:4000",
    "http://localhost:4000",
  ];

  // danh sách nhà mạng
  final List<Map<String, String>> networks = [
    {'name': 'Viettel', 'icon': 'assets/viettel.png'},
    {'name': 'Mobifone', 'icon': 'assets/mobifone.png'},
    {'name': 'Vinaphone', 'icon': 'assets/vinaphone.png'},
    {'name': 'Vietnamobile', 'icon': 'assets/vietnamobile.png'},
    {'name': 'Wintel', 'icon': 'assets/wintel.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // ================== LOAD USER DATA ==================
  Future<void> _loadUserInfo() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id');
      if (id == null) {
        setState(() => _isLoading = false);
        showErrorDialog('Không tìm thấy user_id. Vui lòng đăng nhập lại.');
        return;
      }
      _userId = id;

      http.Response? res;
      for (final base in apiUrls) {
        try {
          final uri = Uri.parse('$base/user/$id');
          final r = await http.get(uri).timeout(const Duration(seconds: 10));
          debugPrint('GET $uri → ${r.statusCode}');
          if (r.statusCode == 200) {
            res = r;
            break;
          }
        } catch (e) {
          debugPrint('GET /user/$id error with $base: $e');
        }
      }

      if (res == null || res.statusCode != 200) {
        setState(() => _isLoading = false);
        showErrorDialog('Không load được thông tin tài khoản.');
        return;
      }

      final decoded = jsonDecode(res.body);
      Map<String, dynamic>? data;
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is List &&
          decoded.isNotEmpty &&
          decoded[0] is Map<String, dynamic>) {
        data = decoded[0];
      }

      if (data == null) {
        setState(() => _isLoading = false);
        showErrorDialog('Dữ liệu tài khoản không hợp lệ.');
        return;
      }

      final dynamic bal = data['balance'];
      final double balance = bal is num
          ? bal.toDouble()
          : double.tryParse(bal?.toString() ?? '0') ?? 0;

      setState(() {
        _stk = data?['stk']?.toString() ?? '';
        _balance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      showErrorDialog('Lỗi tải thông tin tài khoản: $e');
    }
  }

  // ======= COMMON DIALOG =======
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Thành công',
          style: TextStyle(color: Colors.green),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // đóng dialog
              Navigator.pop(context, true); // quay lại màn trước, báo thành công
            },
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }

  // ============= CALL API /PHONETOPUP =============
  Future<void> _createTopup({
    required String phone,
    required String provider,
    required int amount,
  }) async {
    if (_userId == null) {
      showErrorDialog('Không tìm thấy user_id. Vui lòng đăng nhập lại.');
      return;
    }

    try {
      setState(() => _isLoading = true);

      http.Response? res;

      for (final base in apiUrls) {
        try {
          final uri = Uri.parse('$base/phonetopup');
          res = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  // transaction_id backend tự tạo qua bảng transactions
                  "user_id": _userId,
                  "phone_number": phone,
                  "provider": provider,
                  "amount": amount,
                  "status": "SUCCESS",
                }),
              )
              .timeout(const Duration(seconds: 10));

          debugPrint("POST $uri → ${res.statusCode} ${res.body}");

          if (res.statusCode == 201) break;
        } catch (e) {
          debugPrint("POST /phonetopup error with $base: $e");
        }
      }

      setState(() => _isLoading = false);

      if (res == null) {
        showErrorDialog('Không thể kết nối server. Thử lại sau.');
        return;
      }

      if (res.statusCode == 201) {
        // có thể parse balance_after nếu muốn update ngay
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map && decoded['balance_after'] != null) {
            final ba = decoded['balance_after'];
            setState(() {
              _balance = ba is num
                  ? ba.toDouble()
                  : double.tryParse(ba.toString()) ?? _balance;
            });
          }
        } catch (_) {}

        showSuccessDialog(
          'Nạp tiền thành công cho số $phone\n'
          'Nhà mạng: $provider\n'
          'Mệnh giá: ${_formatAmount(amount)} VND',
        );
      } else {
        String msg = 'Lỗi nạp tiền (${res.statusCode})';
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map && decoded['message'] != null) {
            msg = decoded['message'].toString();
          }
        } catch (_) {}
        showErrorDialog(msg);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showErrorDialog('Có lỗi xảy ra: $e');
    }
  }

  String _formatAmount(int amount) {
    return amount
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]}.');
  }

  // ================== ON CONTINUE ==================
  void onContinue() {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      showErrorDialog('Vui lòng nhập số điện thoại.');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      showErrorDialog('Số điện thoại chỉ được chứa chữ số.');
      return;
    }
    if (phone.length != 10) {
      showErrorDialog('Số điện thoại không hợp lệ. Vui lòng nhập lại.');
      return;
    }
    if (selectedNetwork == null) {
      showErrorDialog('Vui lòng chọn nhà mạng.');
      return;
    }
    if (selectedAmount == null) {
      showErrorDialog('Vui lòng chọn mệnh giá.');
      return;
    }

    if (selectedAmount! > _balance) {
      showErrorDialog('Số dư không đủ để nạp mệnh giá này.');
      return;
    }

    // ✅ Hỏi confirm trước khi gọi API
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận nạp tiền'),
        content: Text(
          'Bạn chắc chắn nạp ${_formatAmount(selectedAmount!)} VND\n'
          'cho số $phone\n'
          'Nhà mạng: $selectedNetwork ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createTopup(
                phone: phone,
                provider: selectedNetwork!,
                amount: selectedAmount!,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 104, 5, 211),
            ),
            child: const Text(
              'ĐỒNG Ý',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 212, 241),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 223, 212, 241),
        elevation: 0,
        title: Container(
          margin: const EdgeInsets.symmetric(horizontal: 80),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: const Text(
            'Nạp tiền điện thoại',
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 104, 5, 211),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Tiếp tục',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==== Từ tài khoản (dùng data thật) ====
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10,
            ),
            child: const Text(
              'Từ tài khoản',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(FontAwesomeIcons.heartCircleCheck,
                    color: Colors.purple),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stk.isNotEmpty ? _stk : '---',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatAmount(_balance.toInt())} VND',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Thông tin nạp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Text(
              'Thông tin nạp tiền',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số điện thoại',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    hintText: 'Nhập số điện thoại',
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),

          // Nhà mạng
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 20,
            ),
            child: const Text('Nhà mạng', style: TextStyle(fontSize: 16)),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...networks.map((network) {
                final isSelected = selectedNetwork == network['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedNetwork = network['name'];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 5,
                    ),
                    child: Container(
                      width: 100,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromARGB(255, 243, 235, 165)
                                .withValues(alpha: 0.3)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color.fromARGB(255, 244, 235, 156)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        network['icon']!,
                        width: 50,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),

          // Mệnh giá
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 20,
            ),
            child: const Text('Mệnh giá', style: TextStyle(fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var amount in [
                  30000,
                  50000,
                  100000,
                  200000,
                  300000,
                  500000,
                ])
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAmount = amount;
                      });
                    },
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 72) / 3,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: selectedAmount == amount
                            ? const Color.fromARGB(255, 243, 235, 165)
                                .withValues(alpha: 0.3)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedAmount == amount
                              ? const Color.fromARGB(255, 244, 235, 156)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${_formatAmount(amount)} VND',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
