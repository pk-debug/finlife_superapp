import 'package:finlife_superapp/features/home/presentation/views/support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SupportScreen shows all support options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SupportScreen(),
      ),
    );

    expect(find.text('Support'), findsAtLeastNWidgets(1));
    expect(find.text('Call Support'), findsOneWidget);
    expect(find.text('Email Support'), findsOneWidget);
    expect(find.text('Chat / Help Center'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
  });
}
