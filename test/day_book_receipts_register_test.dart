import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_activity_event.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_receipts_register.dart';
import 'support/day_book_receipts_register_preview.dart';
import 'support/day_book_demo_preview.dart';
import 'package:lotus_erp/theme/reports/day_book/day_book_theme.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_receipts_register_panel.dart';

void main() {
  final date = DateTime(2026, 11, 4);

  test('sample dues reconcile and retain the requested column values', () {
    final register = DayBookReceiptsRegisterPreview.forDate(date);
    expect(register.dues, hasLength(4));
    expect(register.received, hasLength(6));
    expect(register.expenses, hasLength(3));
    expect(
      register.dues
          .fold<double>(0, (sum, row) => sum + (row.dueBeforeReceipts ?? 0)),
      102400,
    );
    expect(
        register.dues.fold<double>(0, (sum, row) => sum + row.paidAgainstDue),
        44600);
    expect(
        register.dues.fold<double>(0, (sum, row) => sum + (row.dueAmount ?? 0)),
        57800);
    expect(register.dues.first.totalValue, 124600);
    expect(register.dues.first.amountPaid, 100000);
    expect(register.dues.first.dueAmount, 24600);
  });

  test('posted due receipts aggregate by invoice and exclude transfers', () {
    final summary = DayBookSummary(
      date: date,
      documents: [
        DayBookDocument(
          kind: DayBookDocumentKind.regularInvoice,
          sourceId: 'bill:1',
          number: 'REG-001',
          date: date,
          amount: 1000,
          status: 'ACTIVE',
          savedPaid: 800,
          savedDue: 200,
          outstanding: 350,
        ),
      ],
      activityEvents: [
        for (final amount in [100.0, 50.0])
          DayBookActivityEvent(
            kind: DayBookActivityKind.dueCollection,
            sourceId: amount.toInt(),
            number: 'REG-001',
            date: date,
            amount: amount,
            customerId: 1,
          ),
      ],
      moneyFlow: DayBookMoneyFlow(
        openingCash: 0,
        openingBank: 0,
        entries: [
          DayBookMoneyEntry(
            date: date,
            amount: 150,
            incoming: true,
            isCash: true,
            category: 'DUE_COLLECTION',
            paymentMode: 'CASH',
            transactionId: 'tx1',
            referenceId: 'REG-001',
          ),
          DayBookMoneyEntry(
            date: date,
            amount: 40,
            incoming: true,
            isCash: true,
            category: 'CONTRA',
            paymentMode: 'CASH',
            transactionId: 'tx2',
            isInternalTransfer: true,
          ),
          DayBookMoneyEntry(
            date: date,
            amount: 20,
            incoming: false,
            isCash: true,
            category: 'EXPENSE',
            paymentMode: 'CASH',
            transactionId: 'tx3',
          ),
        ],
      ),
    );
    final register = DayBookReceiptsRegister.fromSummary(summary);
    expect(register.dues, hasLength(1));
    expect(register.dues.single.paidAgainstDue, 150);
    expect(register.dues.single.dueAmount, 200);
    expect(register.received, hasLength(1));
    expect(register.received.single.reference, 'REG-001');
  });

  testWidgets('three tabs show source records and red due after paid',
      (tester) async {
    tester.view.physicalSize = const Size(1225, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookReceiptsRegisterPanel(
            summary: DayBookDemoPreview.forDate(date),
            register: DayBookReceiptsRegisterPreview.forDate(date),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Receipts, Dues & Expenses'), findsOneWidget);
    expect(find.text('Today Due (4)'), findsOneWidget);
    expect(find.text('Received (6)'), findsOneWidget);
    expect(find.text('Expense (3)'), findsOneWidget);
    expect(find.text('₹1,02,400'), findsOneWidget);
    expect(find.text('₹44,600'), findsWidgets);
    expect(find.text('₹57,800'), findsOneWidget);
    final totalX = tester.getTopLeft(find.text('Total Value')).dx;
    final paidX = tester.getTopLeft(find.text('Amount Paid')).dx;
    final dueX = tester.getTopLeft(find.text('Due Amount')).dx;
    expect(totalX, lessThan(paidX));
    expect(paidX, lessThan(dueX));
    expect(
      tester.widget<Text>(find.text('₹24,600')).style?.color,
      DayBookColors.negative,
    );

    await tester.tap(find.byKey(const ValueKey('register-tab-received')));
    await tester.pumpAndSettle();
    expect(find.text('Source No.'), findsOneWidget);
    expect(find.text('REG-025'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('register-tab-expense')));
    await tester.pumpAndSettle();
    expect(find.text('Entry No.'), findsOneWidget);
    expect(find.text('EXP-101'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('register remains usable at 320px', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookReceiptsRegisterPanel(
            summary: DayBookDemoPreview.forDate(date),
            register: DayBookReceiptsRegisterPreview.forDate(date),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Today Due (4)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
