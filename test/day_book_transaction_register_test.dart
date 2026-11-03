import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_transaction_register.dart';

void main() {
  testWidgets('search filters posted money by source reference',
      (tester) async {
    final date = DateTime(2026, 6, 25);
    final entries = [
      DayBookMoneyEntry(
        date: date,
        amount: 100,
        incoming: true,
        isCash: true,
        category: 'SALE',
        paymentMode: 'CASH',
        transactionId: 'C-1',
        referenceId: 'INV-1',
      ),
      DayBookMoneyEntry(
        date: date,
        amount: 20,
        incoming: false,
        isCash: false,
        category: 'SHOP_RENT',
        paymentMode: 'UPI',
        transactionId: 'B-1',
        referenceId: 'RENT-1',
      ),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: DayBookTransactionRegister(entries: entries)),
    ));
    await tester.tap(find.text('Posted Money Register (2)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'RENT-1');
    await tester.pumpAndSettle();
    expect(find.text('1 matching records'), findsOneWidget);
    expect(find.text('Shop Rent'), findsOneWidget);
    expect(find.text('SALE'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
