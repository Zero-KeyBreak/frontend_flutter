import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  int _selectedTransferType = 0; // 0: TPBank, 1: Liên NH, 2: ATM
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String? _accountError;
  String? _amountError;
  bool _isLoading = false;

  // ===== Thông tin user hiện tại (không dùng User model) =====
  int? _userId;
  String _username = '';
  String _stk = '';
  double _balance = 0;

  // ===== Thông tin người nhận =====
  String? _receiverName;
  String? _receiverStk;

  final List<String> _banks = [
    'TPBank',
    'Vietcombank',
    'BIDV',
    'Agribank',
    'Techcombank',
    'MB Bank',
    'ACB',
    'VPBank',
  ];
  String? _selectedBank;

  @override
  void initState() {
    super.initState();
    _contentController.text = 'Chuyển tiền'; // tạm, update sau khi load user
    _loadUserInfo();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ====== BASE URL FALLBACK (devtunnel -> android -> localhost) ======
  final List<String> _baseUrls = const [
    'https://df4b91vt-4000.asse.devtunnels.ms',
    'http://10.0.2.2:4000', // Android emulator
    'http://localhost:4000', // PC
  ];

  Future<http.Response?> _getWithFallback(String path) async {
  http.Response? lastRes;

  for (final base in _baseUrls) {
    try {
      final uri = Uri.parse('$base$path');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return res;
      } else {
        debugPrint('GET $uri lỗi: ${res.statusCode} ${res.body}');
        lastRes = res; // lưu lại response cuối cùng
      }
    } catch (e) {
      debugPrint('GET exception ($path, $base): $e');
    }
  }

  // nếu tất cả đều fail / 404 → trả về response cuối cùng (để còn đọc statusCode)
  return lastRes;
}


  Future<http.Response?> _postWithFallback(
      String path, Map<String, dynamic> body) async {
    for (final base in _baseUrls) {
      try {
        final uri = Uri.parse('$base$path');
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 5));
        if (res.statusCode == 200 || res.statusCode == 201) {
          return res;
        } else {
          debugPrint('POST $uri lỗi: ${res.statusCode} ${res.body}');
        }
      } catch (e) {
        debugPrint('POST exception ($path, $base): $e');
      }
    }
    return null;
  }

  // ===== Load thông tin user giống Home (không dùng User model) =====
  Future<void> _loadUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final int? id = prefs.getInt('user_id');
      if (id == null) {
        _showErrorDialog('Không tìm thấy user_id trong máy.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      _userId = id;

      final res = await _getWithFallback('/user/$id');
      if (res == null) {
        _showErrorDialog('Có lỗi xảy ra khi tải thông tin tài khoản.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final decoded = jsonDecode(res.body);
      Map<String, dynamic>? data;
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is List &&
          decoded.isNotEmpty &&
          decoded[0] is Map<String, dynamic>) {
        data = decoded[0] as Map<String, dynamic>;
      }

      if (data == null) {
        _showErrorDialog('Dữ liệu tài khoản không hợp lệ.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final dynamic bal = data['balance'];
      final double balance = bal is num
          ? bal.toDouble()
          : double.tryParse(bal?.toString() ?? '0') ?? 0;

      setState(() {
        _username = data?['username']?.toString() ?? '';
        _stk = data?['stk']?.toString() ?? '';
        _balance = balance;
        _contentController.text =
            _username.isNotEmpty ? '$_username chuyển tiền' : 'Chuyển tiền';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Exception _loadUserInfo: $e');
      _showErrorDialog('Có lỗi xảy ra khi tải thông tin tài khoản.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ====== TÌM NGƯỜI NHẬN TỪ STK / SĐT ======
  Future<bool> _fetchReceiverInfo() async {
    final input = _accountController.text.trim();
    if (input.isEmpty) {
      _showErrorDialog('Vui lòng nhập số tài khoản / số điện thoại người nhận');
      return false;
    }

    // Với loại 2 (ATM) thì backend users không có thẻ ATM -> tạm không lookup
    if (_selectedTransferType == 2) {
      setState(() {
        _receiverName = null;
        _receiverStk = input;
      });
      return true;
    }

    // Ở đây anh đang gọi /user/:id, nên input phải là user_id
    // Nếu anh muốn tìm theo stk hoặc phone thì backend phải có route riêng.
   final res = await _getWithFallback('/user/search?keyword=$input');


    if (res == null) {
      _showErrorDialog('Không tìm được thông tin người nhận (lỗi kết nối).');
      return false;
    }

    if (res.statusCode == 404) {
      _showErrorDialog('Không tìm thấy tài khoản người nhận.');
      return false;
    }

    if (res.statusCode != 200) {
      _showErrorDialog('Lỗi khi tìm người nhận: ${res.statusCode}');
      return false;
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      _showErrorDialog('Dữ liệu người nhận không hợp lệ.');
      return false;
    }

    setState(() {
      _receiverName = decoded['username']?.toString();
      _receiverStk = decoded['stk']?.toString() ?? input;
    });

    return true;
  }

  // ===== Validation =====
  bool _isValidPhoneNumber(String phone) =>
      RegExp(r'^[0-9]{10}$').hasMatch(phone);
  bool _isValidTPBankAccount(String account) =>
      RegExp(r'^[0-9]{11}$').hasMatch(account);
  bool _isValidAccountNumber(String account) =>
      RegExp(r'^[0-9]{8,15}$').hasMatch(account);
  bool _isValidATMCard(String card) => RegExp(r'^[0-9]{10}$').hasMatch(card);

  String? _validateAccountInput(String input, int transferType) {
    if (input.isEmpty) return 'Vui lòng nhập thông tin người nhận';
    switch (transferType) {
      case 0: // Trong TPBank
        if (!_isValidPhoneNumber(input) && !_isValidTPBankAccount(input)) {
          return 'SĐT phải 10 số hoặc STK phải 11 số';
        }
        break;
      case 1: // Liên Ngân Hàng
        if (!_isValidAccountNumber(input)) {
          return 'Số tài khoản phải từ 8-15 số';
        }
        break;
      case 2: // ATM
        if (!_isValidATMCard(input)) {
          return 'Số thẻ ATM phải 10 số';
        }
        break;
    }
    return null;
  }

  String? _validateAmount(String value) {
    if (value.isEmpty) return 'Vui lòng nhập số tiền';
    final clean = value.replaceAll(',', '');
    final amount = double.tryParse(clean);
    if (amount == null || amount <= 0) return 'Số tiền không hợp lệ';
    if (amount < 1000) return 'Số tiền tối thiểu 1,000 VND';
    if (amount > _balance) return 'Số dư không đủ';
    return null;
  }

  // ===== API chuyển tiền -> POST /transactions (3 đường dẫn fallback) =====
  Future<void> _callTransferAPI(double amount) async {
    if (_userId == null || _stk.isEmpty) {
      _showErrorDialog('Không tìm thấy thông tin tài khoản nguồn.');
      return;
    }

   String transferMethod;
switch (_selectedTransferType) {
  case 0:
    transferMethod = 'INTERNAL';     // giao dịch nội bộ TPBank
    break;
  case 1:
    transferMethod = 'INTERBANK';    // chuyển liên ngân hàng
    break;
  case 2:
  default:
    transferMethod = 'ATM_CARD';     // qua thẻ ATM
    break;
}


    String? toAccount;
    String? toPhone;
    String? toCardNumber;

    final input = _accountController.text.trim();
    if (_selectedTransferType == 0) {
      if (_isValidPhoneNumber(input)) {
        toPhone = input;
      } else {
        toAccount = input;
      }
    } else if (_selectedTransferType == 1) {
      toAccount = input;
    } else {
      toCardNumber = input;
    }

    final body = {
      'user_id': _userId,
      'from_account': _stk,
      'available_balance_before': _balance,
      'transfer_method': transferMethod,
      'to_account': toAccount,
      'to_phone': toPhone,
      'to_card_number': toCardNumber,
      'bank_code': _selectedBank,
      'amount': amount.toString().replaceAll(',', ''),
      'transaction_type': 'TRANSFER',
      'description': _contentController.text,
      'status': 'SUCCESS',
      'balance_after': _balance - amount,
      'reference_code': null,
      'qr_id': null,
      'wallet_id': null,
    };

    final res = await _postWithFallback('/transactions', body);

    if (res == null) {
      _showErrorDialog('Không thể kết nối server. Vui lòng thử lại sau.');
      return;
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      setState(() {
        _balance -= amount;
      });
      _showSuccessDialog(amount);
     
    } else if (res.statusCode == 400) {
      _showErrorDialog('Thông tin chuyển tiền không hợp lệ');
    } else {
      _showErrorDialog('Lỗi server: ${res.statusCode}');
    }
  }

  // ===== Transfer =====
  void _transferMoney() async {
    FocusScope.of(context).unfocus();

    final accountError = _validateAccountInput(
      _accountController.text.trim(),
      _selectedTransferType,
    );
    final amountError = _validateAmount(_amountController.text);

    setState(() {
      _accountError = accountError;
      _amountError = amountError;
    });

    if (accountError != null || amountError != null) return;

    if (_selectedTransferType == 1 && _selectedBank == null) {
      _showErrorDialog('Vui lòng chọn ngân hàng');
      return;
    }

    // 🔹 TÌM NGƯỜI NHẬN TRƯỚC KHI XÁC NHẬN
    setState(() => _isLoading = true);
    final ok = await _fetchReceiverInfo();
    setState(() => _isLoading = false);

    if (!ok) return;

    final amount = double.parse(
  _amountController.text.replaceAll(',', '').trim(),
);

// 🔥 Popup xác nhận thêm (popup số 1)
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Text("Xác nhận", style: TextStyle(color: Color(0xFF6A1B9A))),
    content: Text("Bạn có chắc chắn muốn chuyển ${_formatCurrency(amount)} VND không?"),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text("HỦY"),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context); // đóng popup 1
          _showConfirmDialog(amount); // hiện popup số 2 (chi tiết giao dịch)
        },
        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6A1B9A), foregroundColor: Colors.white),
        child: const Text("TIẾP TỤC"),
      ),
    ],
  ),
);

  }

  // ===== Dialogs =====
  void _showConfirmDialog(double amount) {
    final receiverText = _receiverName != null
        ? '${_receiverName!} (${_receiverStk ?? _accountController.text})'
        : _accountController.text;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF6A1B9A)),
            SizedBox(width: 8),
            Text(
              'Xác nhận giao dịch',
              style: TextStyle(color: Color(0xFF6A1B9A)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConfirmRow('Người nhận', receiverText),
            if (_selectedBank != null)
              _buildConfirmRow('Ngân hàng', _selectedBank!),
            _buildConfirmRow('Số tiền', '${_formatCurrency(amount)} VND'),
            _buildConfirmRow('Nội dung', _contentController.text),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    await _callTransferAPI(amount);
                    setState(() => _isLoading = false);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            child: const Text('XÁC NHẬN'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Giao dịch thành công!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSuccessRow(
                      'Số tiền:',
                      '${_amountController.text} VND',
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildSuccessRow(
                      'Tới:',
                      _receiverName != null
                          ? '${_receiverName!} (Số tài khoản: ${_receiverStk ?? _accountController.text})'
                          : _accountController.text,
                      Colors.black87,
                    ),
                    const SizedBox(height: 8),
                    _buildSuccessRow(
                      'Nội dung:',
                      _contentController.text,
                      Colors.black87,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context,true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      const Text('HOÀN TẤT', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi giao dịch', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ĐÃ HIỂU',
              style: TextStyle(color: Color(0xFF6A1B9A)),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Utils =====
  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  void _clearForm() {
    _accountController.clear();
    _amountController.clear();
    _receiverName = null;
    _receiverStk = null;
    _contentController.text =
        _username.isNotEmpty ? '$_username chuyển tiền' : 'Chuyển tiền';
    _selectedBank = null;
    setState(() {
      _accountError = null;
      _amountError = null;
    });
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Chuyển tiền',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6D32D3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _clearForm,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAccountInfoCard(),
                  const SizedBox(height: 24),
                  _buildTransferTypeSection(),
                  const SizedBox(height: 24),
                  _buildTransferForm(),
                  const SizedBox(height: 24),
                  _buildScheduleButton(),
                  const SizedBox(height: 16),
                  _buildTransferButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingScreen() =>
      const Center(child: CircularProgressIndicator(color: Color(0xFF6D32D3)));

  Widget _buildAccountField() {
    String labelText = '';
    String hintText = '';

    switch (_selectedTransferType) {
      case 0:
        labelText = 'Số tài khoản hoặc số điện thoại';
        hintText = 'Nhập 10 số điện thoại hoặc 8-15 số tài khoản';
        break;
      case 1:
        labelText = 'Số tài khoản người nhận';
        hintText = 'Nhập 8-15 số tài khoản người nhận';
        break;
      case 2:
        labelText = 'Số thẻ ATM người nhận';
        hintText = 'Nhập 10 số thẻ ATM người nhận';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _accountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey[50],
            errorText: _accountError,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Số tiền',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Nhập số tiền',
              suffixText: 'VND',
              filled: true,
              fillColor: Colors.grey[50],
              errorText: _amountError,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) {
              final clean = value.replaceAll(',', '');
              final num = int.tryParse(clean);
              if (num != null) {
                final formatted = _formatCurrency(num.toDouble());
                _amountController.value = TextEditingValue(
                  text: formatted,
                  selection:
                      TextSelection.collapsed(offset: formatted.length),
                );
              }
            },
          ),
        ],
      );

  Widget _buildTransferButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _transferMoney,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6D32D3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'CHUYỂN TIỀN NGAY',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );

  Widget _buildConfirmRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text('$label:')),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );

  Widget _buildSuccessRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: TextStyle(color: color),
              ),
            ),
          ],
        ),
      );

  Widget _buildAccountInfoCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7D4BD2), Color(0xFF6D32D3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STK: ${_stk.isNotEmpty ? _stk : '---'}',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Số dư khả dụng: ${_formatCurrency(_balance)} VND',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _buildTransferTypeSection() {
    return Row(
      children: [
        _buildTransferTypeButton(0, 'Trong TPBank', Icons.account_balance),
        const SizedBox(width: 12),
        _buildTransferTypeButton(1, 'Liên Ngân Hàng', Icons.swap_horiz),
        const SizedBox(width: 12),
        _buildTransferTypeButton(2, 'Qua Thẻ ATM', Icons.credit_card),
      ],
    );
  }

  Widget _buildTransferTypeButton(int type, String text, IconData icon) {
    final isSelected = _selectedTransferType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTransferType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6D32D3) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFF6D32D3) : Colors.grey[300]!,
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferForm() => Column(
        children: [
          _buildAccountField(),
          if (_selectedTransferType == 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                hint: const Text('Chọn ngân hàng'),
                value: _selectedBank,
                items: _banks
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBank = v),
              ),
            ),
          const SizedBox(height: 16),
          _buildAmountField(),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(
              labelText: 'Nội dung chuyển tiền',
              filled: true,
              fillColor: Colors.grey[50],
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );

  Widget _buildScheduleButton() => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.schedule, color: Color(0xFF6D32D3)),
          label: const Text(
            'Lên lịch chuyển tiền',
            style: TextStyle(color: Color(0xFF6D32D3)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF6D32D3)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}
