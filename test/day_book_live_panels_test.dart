import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_expense_record.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_stock_added_batch.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_document_summary_panel.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_receipts_register_panel.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_stock_added_panel.dart';

void main() {
  final date = DateTime(2026, 11, 4);

  test('adding the day lock preserves fetched stock and source records', () {
    final batch = DayBookStockAddedBatch(
      voucherId: 42,
      batchCode: 'LIVE-BATCH-42',
      metal: 'Gold',
      postedAt: date,
      pieces: 2,
      netWeightGrams: 20,
      purchaseValue: 100000,
    );
    final original = DayBookSummary(
      date: date,
      stockAddedBatches: [batch],
      documents: [
        DayBookDocument(
          kind: DayBookDocumentKind.regularInvoice,
          sourceId: '7',
          number: 'LIVE-INV-7',
          date: date,
          amount: 12000,
          status: 'ACTIVE',
        ),
      ],
    );

    final locked = original.withDayLocked(true);

    expect(locked.isDayLocked, isTrue);
    expect(locked.stockAddedBatches.single, same(batch));
    expect(locked.documents, same(original.documents));
  });

  testWidgets('source, due, and stock panels render saved records only',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final summary = DayBookSummary(
      date: date,
      documents: [
        DayBookDocument(
          kind: DayBookDocumentKind.regularInvoice,
          sourceId: '7',
          number: 'LIVE-INV-7',
          date: date,
          amount: 12000,
          collection: 8000,
          savedPaid: 8000,
          savedDue: 4000,
          status: 'ACTIVE',
          partyName: 'Live Customer',
        ),
      ],
      expenseRecords: const [
        DayBookExpenseRecord(
          reference: 'LIVE-EXP-1',
          category: 'SHOP_RENT',
          amount: 500,
          paymentMode: 'CASH',
        ),
      ],
      stockAddedBatches: [
        DayBookStockAddedBatch(
          voucherId: 42,
          batchCode: 'LIVE-BATCH-42',
          metal: 'Gold',
          postedAt: date,
          pieces: 2,
          netWeightGrams: 20,
          purchaseValue: 100000,
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            DayBookDocumentSummaryPanel(summary: summary),
            DayBookReceiptsRegisterPanel(summary: summary),
            DayBookStockAddedPanel(summary: summary),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('LIVE-INV-7'), findsWidgets);
    expect(find.text('LIVE-BATCH-42'), findsOneWidget);
    expect(find.text('DEMO PREVIEW'), findsNothing);
    expect(find.text('REG-025'), findsNothing);
    expect(find.text('STK-26-001473'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
