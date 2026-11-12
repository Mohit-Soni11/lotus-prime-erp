import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_repository.dart';
import 'package:lotus_erp/logic/report/day_book/day_book_export_service.dart';
import 'package:lotus_erp/logic/report/day_book/export/day_book_export_data.dart';
import 'package:lotus_erp/logic/report/day_book/export/day_book_export_loader.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_activity_event.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_balance_verification.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_customer_metal_sales.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document_item.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_expense_record.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_owned_stock_position.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_stock_added_batch.dart';

void main() {
  test('legacy day lock exports honestly without inventing close evidence',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 1, 2);
    await db.customStatement(
      '''INSERT INTO finance_day_closures
         (day_key, start_epoch, end_epoch, closing_cash, closed_at, closed_by)
         VALUES (?, ?, ?, ?, ?, ?)''',
      [
        '20260102',
        date.millisecondsSinceEpoch ~/ 1000,
        DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
        0,
        date.millisecondsSinceEpoch ~/ 1000,
        'legacy-owner',
      ],
    );
    final summary = DayBookSummary(date: date);
    final data = await DayBookExportLoader(database: db).load(summary);
    expect(data.closing, isNull);
    expect(data.legacyClosedBy, 'legacy-owner');
    final csv = DayBookExportService.buildCsv(summary, data: data);
    expect(csv, contains('Closed under legacy day lock'));
    expect(csv, contains('Not recorded in legacy data'));
    expect(csv, isNot(contains('Day remains open')));
  });
  test('detailed PDF and CSV expose the same saved source and audit sections',
      () async {
    final date = DateTime(2026, 11, 11);
    final summary = DayBookSummary(
      date: date,
      moneyFlow: DayBookMoneyFlow(
        openingCash: 100,
        openingBank: 200,
        entries: [
          DayBookMoneyEntry(
            date: date,
            amount: 300,
            incoming: true,
            isCash: true,
            category: 'SALE',
            paymentMode: 'CASH',
            transactionId: 'C-1',
            referenceId: 'REG-1',
          ),
          DayBookMoneyEntry(
            date: date,
            amount: 50,
            incoming: false,
            isCash: true,
            category: 'SHOP_RENT',
            paymentMode: 'CASH',
            transactionId: 'E-1',
          ),
          DayBookMoneyEntry(
            date: date,
            amount: 70,
            incoming: true,
            isCash: false,
            category: 'DUE_COLLECTION',
            paymentMode: 'UPI',
            transactionId: 'B-1',
            referenceId: 'OLD-1',
          ),
        ],
      ),
      documents: [
        DayBookDocument(
          kind: DayBookDocumentKind.regularInvoice,
          sourceId: '1',
          number: 'REG-1',
          date: date,
          amount: 500,
          status: 'ACTIVE',
          partyName: 'Ramesh Shah',
          mobile: '9876543210',
          savedPaid: 300,
          savedDue: 200,
          collection: 300,
          items: const [
            DayBookDocumentItem(
                metal: 'Gold', name: 'Ring', netWeightGrams: 10),
          ],
        ),
        DayBookDocument(
          kind: DayBookDocumentKind.gstInvoice,
          sourceId: '2',
          number: 'TAX-1',
          date: date,
          amount: 1000,
          status: 'ACTIVE',
          tax: 30,
          savedPaid: 600,
          savedDue: 400,
          collection: 600,
        ),
      ],
      activityEvents: [
        DayBookActivityEvent(
          kind: DayBookActivityKind.dueCollection,
          sourceId: 3,
          number: 'OLD-1',
          date: date,
          amount: 70,
          customerId: 1,
          partyName: 'Kavita Desai',
          savedDue: 130,
        ),
      ],
      expenseRecords: const [
        DayBookExpenseRecord(
          reference: 'E-1',
          category: 'Shop Rent',
          amount: 50,
          paymentMode: 'CASH',
        ),
      ],
      stockAddedBatches: [
        DayBookStockAddedBatch(
          voucherId: 1,
          batchCode: 'STK-1',
          metal: 'Gold',
          postedAt: date,
          pieces: 2,
          netWeightGrams: 15,
          ratePerGram: 5000,
          makingTotal: 1000,
          purchaseValue: 76000,
        ),
      ],
      ownedStockPosition: const DayBookOwnedStockPosition(
        gold: DayBookOwnedMetalPosition(
          openingGrams: 100,
          inwardGrams: 15,
          soldGrams: 10,
          otherOutGrams: 0,
          closingGrams: 105,
          isConsistent: true,
        ),
        silver: DayBookOwnedMetalPosition(
          openingGrams: 50,
          inwardGrams: 0,
          soldGrams: 0,
          otherOutGrams: 0,
          closingGrams: 50,
          isConsistent: true,
        ),
      ),
      customerMetalSales:
          const DayBookCustomerMetalSales(goldGrams: 10, goldInvoices: 1),
    );
    final data = DayBookExportData(
      summary: summary,
      openingVerification: DayBookBalanceVerification(
        date: date,
        verifiedAt: date,
        expectedCash: 100,
        actualCash: 100,
        cashVariance: 0,
        expectedBank: 200,
        actualBank: 200,
        bankVariance: 0,
      ),
      closing: const DayBookCloseEvidence(
        physicalCash: 350,
        physicalBank: 270,
        denominations: {'100': 3, '50': 1},
        sourceHash: 'sample-hash',
        closedBy: 'owner-1',
      ),
    );

    final csv = DayBookExportService.buildCsv(summary, data: data);
    for (final expected in [
      '"Opening and Closing Balance","Closing","Total","620.00"',
      '"Source Document Register","REG-1","Current Due","200.00"',
      '"Source Document Tax and Collection","TAX-1","Saved Tax","30.00"',
      '"Invoice Dues and Due Collection","OLD-1","Collected Against Due Today","70.00"',
      '"Expense Entry Register","E-1","Amount","50.00"',
      '"Stock Added Today - Add Stock Batches","STK-1","Purchase Value","76000.00"',
      '"Daily Balance Verification","Expected Cash","Value","100.00"',
      '"Day Closing Audit","Counted Cash","Value","350.00"',
      '"Physical Cash Note Count","INR 100","Quantity","3"',
    ]) {
      expect(csv, contains(expected));
    }
    final pdf = await DayBookExportService.buildPdf(summary, data: data);
    expect(pdf.length, greaterThan(1000));
    final previewPath = Platform.environment['LOTUS_DAY_BOOK_PREVIEW'];
    if (previewPath != null) {
      await File(previewPath).writeAsBytes(pdf);
    }
  });

  test(
      'export loader reads saved closing evidence without inventing opening verification',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 6, 25);
    expect(
      await FinanceDayClosureRepository(db).closeDay(date,
          closingCash: 0,
          physicalBank: 0,
          closedBy: 'owner-1',
          denominationCount: const {'500': 0}),
      isTrue,
    );
    final summary = DayBookSummary(
      date: date,
      moneyFlow:
          DayBookMoneyFlow(openingCash: 0, openingBank: 0, entries: const []),
      ownedStockPosition: const DayBookOwnedStockPosition(
        gold: DayBookOwnedMetalPosition(
          openingGrams: 0,
          inwardGrams: 0,
          soldGrams: 0,
          otherOutGrams: 0,
          closingGrams: 0,
          isConsistent: true,
        ),
        silver: DayBookOwnedMetalPosition(
          openingGrams: 0,
          inwardGrams: 0,
          soldGrams: 0,
          otherOutGrams: 0,
          closingGrams: 0,
          isConsistent: true,
        ),
      ),
    );
    final data = await DayBookExportLoader(database: db).load(summary);
    expect(data.openingVerification, isNull);
    expect(data.closing?.physicalCash, 0);
    expect(data.closing?.physicalBank, 0);
    expect(data.closing?.closedBy, 'owner-1');
    expect(data.closing?.sourceHash, hasLength(64));
    expect(
        DayBookExportService.buildCsv(summary, data: data),
        contains(
            '"Daily Balance Verification","No saved opening verification for this day"'));

    final staleSummary = DayBookSummary(
      date: date,
      moneyFlow:
          DayBookMoneyFlow(openingCash: 10, openingBank: 0, entries: const []),
      ownedStockPosition: summary.ownedStockPosition,
    );
    await expectLater(
      DayBookExportLoader(database: db).load(staleSummary),
      throwsA(isA<StateError>()),
    );
  });
}
