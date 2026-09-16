import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Displays the signed-in user's payment QR code for receiving money.
class MyQrScreen extends StatelessWidget {
  const MyQrScreen({super.key});

  static const _upiId = 'pawan@finlife';
  static const _upiPayload = 'upi://pay?pa=$_upiId&pn=FinLife%20User';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My QR')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Receive money',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Let someone scan this QR code to send you money.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(blurRadius: 18, color: Colors.black12),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: QrImageView(
                    data: _upiPayload,
                    version: QrVersions.auto,
                    size: 240,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(_upiId, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('FinLife User'),
            ],
          ),
        ),
      ),
    );
  }
}
