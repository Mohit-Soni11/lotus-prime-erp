import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/theme/reports/day_book/day_book_theme.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_money_panel.dart';

void main() {
  testWidgets('empty day hides unused movement breakdowns', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: DayBookStyles.theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookMoneyPanel(
            flow: DayBookMoneyFlow(openingCash: 0, openingBank: 0, entries: []),
          ),
        ),
      ),
    ));

    expect(find.text('Physical Cash'), findsOneWidget);
    expect(find.text('Money In by Source'), findsNothing);
    expect(find.text('Money Out by Mode'), findsNothing);
    expect(find.text('Transactions (0)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 1200.0]) {
    testWidgets('money panel shows cash, bank and source at ${width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final flow = DayBookMoneyFlow(
        openingCash: 100,
        openingBank: 1000,
        entries: [
          DayBookMoneyEntry(
            date: DateTime(2026, 6, 25, 12),
            amount: 500,
            incoming: true,
            isCash: false,
            category: 'SALE_PAYMENT',
            paymentMode: 'UPI',
            transactionId: 'B-1',
            accountName: 'Current Account',
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        theme: DayBookStyles.theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DayBookMoneyPanel(flow: flow),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Money Movement'), findsOneWidget);
      expect(find.text('Physical Cash'), findsOneWidget);
      expect(find.text('Bank Accounts'), findsOneWidget);
      expect(find.text('Money In by Source'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Transactions (1)'));
      await tester.tap(find.text('Transactions (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Sale Payment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
