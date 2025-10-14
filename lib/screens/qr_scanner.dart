import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = 250.0;
    final center = Offset(size.width / 2, size.height / 2);
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            scanWindow: Rect.fromCenter(
              center: center,
              width: scanArea,
              height: scanArea,
            ),
            onDetect: (barcodeCapture) {
              final barcode = barcodeCapture.barcodes.first;
              final String? code = barcode.rawValue;
              if (code != null) {
                debugPrint('QR code: $code');
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('QR: $code')));
              }
            },
          ),

          Positioned.fill(
            child: CustomPaint(painter: _ScannerOverlayPainter(scanArea)),
          ),
          Align(
            alignment: Alignment(0, -0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      iconSize: 30,
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                    SizedBox(width: 30),
                    Text(
                      'Đặt mã QR vào đây để quét mã',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TP',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 109, 32, 175),
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    Text(
                      'Bank',
                      style: TextStyle(
                        color: Color.fromARGB(255, 109, 32, 175),
                        fontSize: 30,
                      ),
                    ),
                    SizedBox(width: 20),
                    Text(
                      'V',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 173, 31, 31),
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'IETQR',
                      style: TextStyle(color: Colors.white, fontSize: 25),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                const _PartnerBanner(),
                SizedBox(height: 450),
                Text('hello'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanArea;
  _ScannerOverlayPainter(this.scanArea);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutOutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanArea,
      height: scanArea,
    );

    canvas.drawRect(rect, paint);
    paint.blendMode = BlendMode.clear;
    canvas.drawRect(cutOutRect, paint);

    paint.blendMode = BlendMode.srcOver;
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawRect(cutOutRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _PartnerBanner extends StatefulWidget {
  const _PartnerBanner({super.key});
  @override
  State<_PartnerBanner> createState() => _PartnerBannerState();
}

class _PartnerBannerState extends State<_PartnerBanner>
    with SingleTickerProviderStateMixin {
  late ScrollController _controller;
  late AnimationController _animationController;
  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
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
    return SizedBox(
      height: 40,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: logos.length * 3,
        separatorBuilder: (_, _) => const SizedBox(width: 30),
        itemBuilder: (_, i) {
          final logo = logos[i % logos.length];
          return Image.asset(logo, height: 30);
        },
      ),
    );
  }
}
