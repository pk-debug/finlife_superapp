import 'package:finlife_superapp/features/home/presentation/views/pay_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PayScreen lets the user choose a contact', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PayScreen()));

    expect(find.text('Aarav Sharma'), findsOneWidget);
    await tester.tap(find.text('Aarav Sharma'));
    await tester.pumpAndSettle();

    expect(find.text('Enter amount'), findsOneWidget);
    expect(find.text('Aarav Sharma'), findsOneWidget);
  });

  testWidgets('PayScreen rejects an invalid manual recipient', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PayScreen()));

    await tester.enterText(find.byType(TextField).last, 'not-a-recipient');
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    final continueButton = find.byType(FilledButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(
      find.text('Enter a valid 10-digit phone number or UPI ID'),
      findsOneWidget,
    );
  });
}
