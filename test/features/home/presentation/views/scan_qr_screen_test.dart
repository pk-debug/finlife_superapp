import 'package:finlife_superapp/features/home/presentation/views/scan_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScanQrScreen shows the QR scanner header and instructions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScanQrScreen(),
      ),
    );

    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('Point your camera at a QR code to pay or verify a code.'), findsOneWidget);
  });
}
