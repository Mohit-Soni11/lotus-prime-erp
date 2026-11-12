import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_expense_record.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_timeline.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_timeline_panel.dart';

void main() {
  final date = DateTime(2026, 11, 12);
  final summary = DayBookSummary(
    date: date,
    documents: [
      DayBookDocument(
        kind: DayBookDocumentKind.regularInvoice,
        sourceId: '4',
        number: 'REG-4',
        date: date.add(const Duration(hours: 10)),
        amount: 500,
        status: 'ACTIVE',
      ),
    ],
    moneyFlow: DayBookMoneyFlow(
      openingCash: 0,
      openingBank: 0,
      entries: [
        DayBookMoneyEntry(
          date: date.add(const Duration(hours: 11)),
          amount: 300,
          incoming: true,
          isCash: true,
          category: 'SALE',
          paymentMode: 'CASH',
          transactionId: 'SALE-4',
          referenceId: 'REG-4',
        ),
        DayBookMoneyEntry(
          date: date.add(const Duration(hours: 12)),
          amount: 20,
          incoming: false,
          isCash: true,
          category: 'SHOP_RENT',
          paymentMode: 'CASH',
          transactionId: 'EXP-1',
        ),
      ],
    ),
    expenseRecords: [
      DayBookExpenseRecord(
        reference: 'EXP-1',
        category: 'Shop Rent',
        amount: 20,
        paymentMode: 'CASH',
        postedAt: date.add(const Duration(hours: 12)),
      ),
    ],
  );

  test('timeline orders source events without duplicating posted expense', () {
    final records = DayBookTimeline.fromSummary(summary);
    expect(records.map((row) => row.key), [
      'document:regularInvoice:4',
      'payment:SALE-4',
      'payment:EXP-1',
    ]);
    expect(records.where((row) => row.kind == DayBookTimelineKind.expense),
        isEmpty);
  });

  testWidgets('timeline filters by reference', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: DayBookTimelinePanel(summary: summary)),
    ));
    await tester.tap(find.text('Transaction Timeline'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'REG-4');
    await tester.pumpAndSettle();
    expect(find.textContaining('REG-4 ·'), findsNWidgets(2));
    expect(find.textContaining('EXP-1 ·'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline stays usable at narrow width', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: DayBookTimelinePanel(summary: summary)),
    ));
    await tester.tap(find.text('Transaction Timeline'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
