import 'package:finlife_superapp/features/home/presentation/views/payment_amount_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PaymentAmountScreen requires a positive amount', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PaymentAmountScreen(recipient: 'aarav@upi')),
    );

    await tester.tap(find.text('Review payment'));
    await tester.pump();

    expect(find.text('Enter an amount greater than zero'), findsOneWidget);
  });
}
