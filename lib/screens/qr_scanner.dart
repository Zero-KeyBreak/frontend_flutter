import 'dart:io';
import 'dart:ui';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  /// 📸 Hàm quét QR từ ảnh trong gallery
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
          Navigator.pop(context, qrValue);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy mã QR trong ảnh')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi quét ảnh: $e')));
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
            onPressed: _scanFromGallery, // 📁 Quét từ ảnh
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Flash chưa được bật')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AiBarcodeScanner(
            onDetect: (capture) {
              final code = capture.barcodes.first.rawValue;
              if (code != null && mounted) {
                Navigator.pop(context, code);
              }
            },

            appBarBuilder: (context, controller) => const PreferredSize(
              preferredSize: Size.zero,
              child: SizedBox.shrink(),
            ),

            /// ✅ Overlay full che toàn bộ phần giao diện mặc định (ẩn các nút Upload, Flash...)
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

/// ========== LỚP PHỦ KHUNG QUÉT + BANNER ==========

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

        /// ✅ Khung quét chính
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

        /// ✅ Tiêu đề trên cùng
        Align(
          alignment: const Alignment(0, -0.7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'TP',
                style: TextStyle(
                  color: Color(0xFF6D20AF),
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              Text(
                'Bank',
                style: TextStyle(color: Color(0xFF6D20AF), fontSize: 30),
              ),
              SizedBox(width: 10),
              Text(
                'VIETQR',
                style: TextStyle(color: Colors.white, fontSize: 26),
              ),
            ],
          ),
        ),

        /// ✅ Dòng trạng thái
        const Align(
          alignment: Alignment(0, 0.7),
          child: Text(
            'Đang quét mã...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),

        /// ✅ Banner chạy logo + dòng chữ
        const Align(alignment: Alignment(0, 0.9), child: _PartnerBanner()),
      ],
    );
  }
}

/// ========== HIỆU ỨNG MỜ NGOÀI KHUNG ==========

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
      ..color = Colors.black.withValues(alpha: 0.5)
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

/// ========== BANNER CHẠY LOGO + TEXT ==========

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
