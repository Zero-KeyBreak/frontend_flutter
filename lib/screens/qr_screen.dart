import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/models/user_model.dart';

class QrScreen extends StatefulWidget {
  
  final double defaultAmount;

  const QrScreen({super.key, this.defaultAmount = 50000});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen>
    with SingleTickerProviderStateMixin {
  late double displayedAmount;
  late TextEditingController amountController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Khởi tạo số tiền hiển thị, đảm bảo ≥1000
    displayedAmount = widget.defaultAmount >= 1000
        ? widget.defaultAmount
        : 1000;
    amountController = TextEditingController(
      text: displayedAmount.toStringAsFixed(0),
    );

    // Animation fade QR code
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_fadeController);
  }

  @override
  void dispose() {
    amountController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Dữ liệu QR code: số tài khoản + số tiền
  String get qrData =>
      "{widget.user.stk}?amount=${displayedAmount.toStringAsFixed(0)}";

  void _showChangeAmountSheet() {
    amountController.text = displayedAmount.toStringAsFixed(0);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nhập số tiền muốn nhận',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Số tiền (VND)',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  double? value = double.tryParse(amountController.text);
                  if (value == null || value < 1000 || value > 10000000000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vui lòng nhập số hợp lệ từ 1.000 đến 10 tỷ',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Placeholder gọi API: gửi displayedAmount lên server
                  // await ApiService.updateAmount(widget.user.stk, value);

                  // Fade animation QR code
                  await _fadeController.forward();
                  setState(() {
                    displayedAmount = value;
                  });
                  await _fadeController.reverse();

                  Navigator.pop(context);
                },
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7E57C2),
      appBar: AppBar(
        title: const Text('QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF7E57C2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
             '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
               '',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _fadeAnimation.drive(Tween(begin: 1.0, end: 1.0)),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '${displayedAmount.toStringAsFixed(0)} VND',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                onPressed: _showChangeAmountSheet,
                child: const Text(
                  'Thay đổi số tiền',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
