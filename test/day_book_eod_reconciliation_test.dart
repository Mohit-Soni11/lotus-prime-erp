import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_eod_sections.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_closing_reconciliation_card.dart';

void main() {
  testWidgets('expenses are visible without being deducted twice',
      (tester) async {
    final date = DateTime(2026, 11, 11);
    final flow =
        DayBookMoneyFlow(openingCash: 1050, openingBank: 200, entries: [
      DayBookMoneyEntry(
        date: date,
        amount: 50,
        incoming: false,
        isCash: true,
        category: 'SHOP_RENT',
        paymentMode: 'CASH',
        transactionId: 'EXP-1',
      ),
    ]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: SingleChildScrollView(
              child: Column(children: [
        EodRecordedClosingBalances(date: date, flow: flow, expenseTotal: 50),
        const EodClosingReconciliation(
          expectedCash: 1000,
          countedCash: 1000,
          expectedBank: 200,
          countedBank: 200,
        ),
      ]))),
    ));
    expect(find.text('Expenses Paid'), findsOneWidget);
    expect(find.text('Recorded Total'), findsOneWidget);
    expect(find.text('₹1,200.00'), findsWidgets);
    expect(find.text('Cash and bank match. Ready to close.'), findsOneWidget);
  });

  testWidgets('pending cheques are explained beside the bank closing',
      (tester) async {
    final date = DateTime(2026, 11, 11);
    final flow = DayBookMoneyFlow(openingCash: 0, openingBank: 0, entries: [
      DayBookMoneyEntry(
        date: date,
        amount: 1000,
        incoming: true,
        isCash: false,
        category: 'SALE_PAYMENT',
        paymentMode: 'CHEQUE',
        transactionId: 'CHEQUE-1',
        chequeStatus: 'PRESENTED',
      ),
    ]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: EodRecordedClosingBalances(date: date, flow: flow)),
    ));
    expect(find.textContaining('Bank ledger includes uncleared cheques'),
        findsOneWidget);
  });

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
          child: EodActualBankBalanceEntry(controller: bank, expected: 250),
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
        body: EodClosingReconciliation(
          expectedCash: 200000,
          countedCash: 195000,
          expectedBank: 100000,
          countedBank: 105000,
        ),
      ),
    ));

    expect(find.text('Cash and bank match. Ready to close.'), findsNothing);
    expect(find.text('Enter actual balances and resolve each difference.'),
        findsNothing);
    expect(find.text('Net zero'), findsOneWidget);
    expect(find.text('₹0.00'), findsNothing);
    expect(find.text('Short ₹5,000.00'), findsOneWidget);
    expect(find.text('Excess ₹5,000.00'), findsOneWidget);
  });

  testWidgets('variance badges fit the narrow closing workspace',
      (tester) async {
    tester.view.physicalSize = const Size(340, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EodClosingReconciliation(
          expectedCash: 488710,
          countedCash: 488000,
          expectedBank: 21615.94,
          countedBank: 21615.94,
        ),
      ),
    ));

    expect(find.text('Short ₹710.00'), findsWidgets);
    expect(find.text('Matched'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
