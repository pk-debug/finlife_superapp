import 'package:finlife_superapp/features/home/presentation/views/my_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('MyQrScreen displays the receiving UPI ID', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyQrScreen()));

    expect(find.text('Receive money'), findsOneWidget);
    expect(find.text('pawan@finlife'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
  });
}
