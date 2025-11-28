import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  final List<String> apiUrls = const [
    "https://df4b91vt-4000.asse.devtunnels.ms",
    "http://10.0.2.2:4000",
    "http://localhost:4000",
  ];

  bool _isProcessing = false;
  bool _hasHandledCamera = false;

  /// =========================================
  /// QUÉT TỪ ẢNH TRONG GALLERY
  /// =========================================
  Future<void> _scanFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final inputImage = InputImage.fromFile(File(pickedFile.path));
      final barcodeScanner = BarcodeScanner();
      final barcodes = await barcodeScanner.processImage(inputImage);
      await barcodeScanner.close();

      if (barcodes.isNotEmpty) {
        final qrValue = barcodes.first.rawValue;
        if (qrValue != null && mounted) {
          await _handleQrValue(qrValue);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy mã QR trong ảnh')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi quét ảnh: $e')),
      );
    }
  }

  /// =========================================
  /// XỬ LÝ CHUỖI QR → GỌI API /transactions
  /// =========================================
  Future<void> _handleQrValue(String qrValue) async {
    if (_isProcessing) return; // chặn double-call
    _isProcessing = true;

    try {
      // Parse JSON từ QR
      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(qrValue);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã QR không đúng định dạng TPBank QR'),
          ),
        );
        _isProcessing = false;
        return;
      }

      final toAccount = payload["to_account"]?.toString();
      final amount = payload["amount"];

      if (toAccount == null || amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('QR thiếu thông tin tài khoản / số tiền')),
        );
        _isProcessing = false;
        return;
      }

      // Lấy user hiện tại (người quét = người gửi)
      final prefs = await SharedPreferences.getInstance();
      final senderId = prefs.getInt("user_id");

      if (senderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Không tìm thấy user_id. Vui lòng đăng nhập lại.')),
        );
        _isProcessing = false;
        return;
      }

      // Lấy stk người gửi
      http.Response? userRes;
      for (final base in apiUrls) {
        try {
          final uri = Uri.parse("$base/user/$senderId");
          userRes = await http.get(uri).timeout(const Duration(seconds: 8));
          if (userRes.statusCode == 200) break;
        } catch (_) {}
      }

      if (userRes == null || userRes.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được thông tin người gửi')),
        );
        _isProcessing = false;
        return;
      }

      final userDecoded = jsonDecode(userRes.body);
      final userData = userDecoded is Map<String, dynamic>
          ? userDecoded
          : Map<String, dynamic>.from(userDecoded);
      final fromAccount = userData["stk"]?.toString();

      if (fromAccount == null || fromAccount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tài khoản nguồn không hợp lệ')),
        );
        _isProcessing = false;
        return;
      }

      // Gửi API chuyển tiền
      http.Response? txRes;
      for (final base in apiUrls) {
        try {
          final uri = Uri.parse("$base/transactions");
          txRes = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  "user_id": senderId,
                  "from_account": fromAccount,
                  "to_account": toAccount,
                  "amount": amount,
                  "transfer_method": "INTERNAL",
                  "transaction_type": "TRANSFER",
                  "description": "Thanh toán qua QR",
                }),
              )
              .timeout(const Duration(seconds: 8));

          if (txRes.statusCode == 200 || txRes.statusCode == 201) break;
        } catch (e) {
          debugPrint("POST /transactions error with $base: $e");
        }
      }

      if (txRes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể kết nối server')),
        );
        _isProcessing = false;
        return;
      }

      if (txRes.statusCode != 200 && txRes.statusCode != 201) {
        String msg = "Chuyển tiền thất bại (${txRes.statusCode})";
        try {
          final decoded = jsonDecode(txRes.body);
          if (decoded is Map && decoded["message"] != null) {
            msg = decoded["message"].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        _isProcessing = false;
        return;
      }

      // Thành công
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text(
      "Vui lòng nhập đầy đủ thông tin",
      style: TextStyle(color: Colors.white),   // màu chữ
    ),
    backgroundColor: Colors.green,               // màu nền đỏ
    behavior: SnackBarBehavior.floating,       // (tuỳ chọn) cho đẹp hơn
  ),
);
      Navigator.pop(context, true); // ✅ chỉ pop 1 lần
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 109, 50, 211),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Đặt mã QR vào khung để quét tự động",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            onPressed: _scanFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          AiBarcodeScanner(
            onDetect: (capture) async {
              if (_hasHandledCamera) return;            // chặn gọi nhiều lần
              _hasHandledCamera = true;

              final code = capture.barcodes.first.rawValue;
              if (code != null && mounted) {
                await _handleQrValue(code);
              }
            },
            appBarBuilder: (context, controller) => const PreferredSize(
              preferredSize: Size.zero,
              child: SizedBox.shrink(),
            ),
            overlayConfig: const ScannerOverlayConfig(
              scannerOverlayBackground: ScannerOverlayBackground.none,
              scannerBorder: ScannerBorder.none,
            ),
          ),

          const _TPBankOverlay(),
        ],
      ),
    );
  }
}

/// ================= OVERLAY TPBANK =================

class _TPBankOverlay extends StatelessWidget {
  const _TPBankOverlay();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double scanBox = size.width * 0.65;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _BlurBackgroundPainter(scanBox)),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: scanBox,
            height: scanBox,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'TP',
                style: TextStyle(
                  color: Color(0xFFF37A20),
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              Text(
                'Bank',
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
              SizedBox(width: 10),
              Text(
                'VIETQR',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ],
          ),
        ),
        const Align(
          alignment: Alignment(0, 0.7),
          child: Text(
            'Đang quét mã...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        const Align(
          alignment: Alignment(0, 0.9),
          child: _PartnerBanner(),
        ),
      ],
    );
  }
}

class _BlurBackgroundPainter extends CustomPainter {
  final double scanBox;
  _BlurBackgroundPainter(this.scanBox);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutOutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanBox,
      height: scanBox,
    );

    final paint = Paint()
      ..imageFilter = ImageFilter.blur(sigmaX: 12, sigmaY: 12)
      ..color = Colors.black.withOpacity(0.5)
      ..blendMode = BlendMode.srcOver;

    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, paint);
    paint.blendMode = BlendMode.clear;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, const Radius.circular(16)),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PartnerBanner extends StatefulWidget {
  const _PartnerBanner({super.key});

  @override
  State<_PartnerBanner> createState() => _PartnerBannerState();
}

class _PartnerBannerState extends State<_PartnerBanner>
    with SingleTickerProviderStateMixin {
  late final ScrollController _controller;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 25))
          ..addListener(() {
            if (_controller.hasClients) {
              _controller.jumpTo(
                _animationController.value *
                    _controller.position.maxScrollExtent,
              );
            }
          })
          ..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logos = [
      'assets/vnpay.png',
      'assets/smartpay.png',
      'assets/napas.png',
      'assets/payoo.png',
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemCount: logos.length * 3,
            separatorBuilder: (_, __) => const SizedBox(width: 25),
            itemBuilder: (_, i) {
              final logo = logos[i % logos.length];
              return Image.asset(logo, height: 30);
            },
          ),
        ),
      ],
    );
  }
}
