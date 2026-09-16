import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR scanning screen used by the Home quick action.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key, this.onScanned});

  final ValueChanged<String>? onScanned;

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  if (widget.onScanned != null) {
                    _controller.stop();
                    widget.onScanned!(_recipientFromQr(rawValue));
                    Navigator.of(context).pop();
                    break;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Scanned: $rawValue'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _controller.stop();
                  break;
                }
              }
            },
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Point your camera at a QR code to pay or verify a code.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _recipientFromQr(String rawValue) {
    final uri = Uri.tryParse(rawValue);
    if (uri?.scheme == 'upi') {
      final pa = uri?.queryParameters['pa'];
      if (pa != null && pa.isNotEmpty) return pa;
    }
    return rawValue;
  }
}
