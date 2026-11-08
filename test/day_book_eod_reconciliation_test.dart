import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_eod_sections.dart';

void main() {
  testWidgets('bank count remains usable on a narrow dialog', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bank = TextEditingController();
    addTearDown(bank.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: EodBankCount(controller: bank, expected: 250),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), '250.00');
    expect(bank.text, '250.00');
  });

  testWidgets('cash shortage and bank excess never appear reconciled',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EodVerificationSummary(
          expectedCash: 200000,
          countedCash: 195000,
          expectedBank: 100000,
          countedBank: 105000,
        ),
      ),
    ));

    expect(find.text('Cash and bank both match the system closing.'),
        findsNothing);
    expect(find.text('Complete both counts and resolve each difference.'),
        findsOneWidget);
    expect(find.text('-₹5,000.00'), findsOneWidget);
    expect(find.text('₹5,000.00'), findsOneWidget);
  });
}
