import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/finance/cash_book/cash_book_controller.dart';
import 'package:lotus_erp/logic/finance/cash_book/cash_book_export_service.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_summary_model.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_transaction_model.dart';
import 'package:lotus_erp/repositories/finance/cash_book_repository.dart';
import 'package:lotus_erp/ui/finance/cash_book/cash_book_entry_dialog.dart';
import 'package:lotus_erp/ui/finance/cash_book/cash_book_date_selector.dart';

class _LedgerFixture extends CashBookRepository {
  _LedgerFixture(AppDatabase db,
      {this.entries = const [], this.useDatabaseSummary = false})
      : super(db: db);

  final List<CashTransactionModel> entries;
  final bool useDatabaseSummary;

  DateTime? lastFrom;
  DateTime? lastTo;

  @override
  Stream<List<CashTransactionModel>> watchTransactions({
    required DateTime from,
    required DateTime to,
  }) {
    lastFrom = from;
    lastTo = to;
    return Stream.value(entries);
  }

  @override
  Future<CashBookSummaryModel> computeSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    if (useDatabaseSummary) {
      return super.computeSummary(from: from, to: to);
    }
    return CashBookSummaryModel.zero();
  }
}

void main() {
  testWidgets(
      'Promise Date style selector opens calendar and loads an older day',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = _LedgerFixture(db);
    final controller = CashBookController(repository: repo);
    addTearDown(() async {
      controller.dispose();
      await db.close();
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (_, __) => CashBookDateSelector(controller: controller),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Cash Ledger Date'), findsOneWidget);
    expect(find.text('Daily'), findsNothing);
    expect(find.text('Monthly'), findsNothing);
    expect(find.text('Yearly'), findsNothing);
    expect(find.text('Range'), findsNothing);
    expect(find.text('Today'), findsNothing);
    await tester.tap(find.byIcon(Icons.event_available_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    controller.selectDate(DateTime(2024, 3, 12));
    await tester.pump();
    expect(repo.lastFrom, DateTime(2024, 3, 1));
    expect(repo.lastTo, DateTime(2024, 3, 31, 23, 59, 59));
    expect(find.text('12/03/2024'), findsOneWidget);
  });

  testWidgets('manual Cash Book entry only offers extra income',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = CashBookController(repository: _LedgerFixture(db));
    addTearDown(() async {
      controller.dispose();
      await db.close();
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CashBookEntryDialog(ctrl: controller)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Add Extra Cash Income'), findsOneWidget);
    expect(find.text('Expense'), findsNothing);
    expect(controller.availableCategories, [
      IncomeCategory.miscIncome.dbValue,
      IncomeCategory.otherIncome.dbValue
    ]);
    expect(controller.entryCategory, IncomeCategory.miscIncome.dbValue);
    controller.amountCtrl.text = '200';
    expect(await controller.saveEntry(), isFalse);
    await tester.pump();
    expect(find.text('Enter the reason for cash received.'), findsOneWidget);
  });

  test('repository refuses manual sales and keeps automatic expenses visible',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = CashBookRepository(db: db);
    final date = DateTime(2024, 3, 12, 10);

    expect(
      await repo.saveExtraCashIncome(
        categoryDbValue: IncomeCategory.sale.dbValue,
        amount: 200,
        txnDate: date,
        description: 'Test receipt',
      ),
      isFalse,
    );
    expect(
      await repo.saveExtraCashIncome(
        categoryDbValue: IncomeCategory.otherIncome.dbValue,
        amount: 200,
        txnDate: date,
        description: 'Test receipt',
      ),
      isFalse,
    );
    expect(
      await repo.saveExtraCashIncome(
        categoryDbValue: IncomeCategory.miscIncome.dbValue,
        amount: 200,
        txnDate: date,
        description: 'Other shop cash received',
      ),
      isTrue,
    );
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'SOURCE-EXPENSE',
          txnDate: date.add(const Duration(hours: 1)),
          type: CashTransactionType.expense.dbValue,
          category: ExpenseCategory.shopRent.dbValue,
          amount: const drift.Value(50),
          paymentMode: const drift.Value('CASH'),
          isAutoGenerated: const drift.Value(true),
        ));
    final entries = await repo.fetchTransactions(
      from: DateTime(2024, 3, 12),
      to: DateTime(2024, 3, 12, 23, 59, 59),
      searchQuery: 'SOURCE-EXPENSE',
    );
    expect(entries.single.isExpense, isTrue);
  });

  test('running balance follows every cash movement and reference search',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.shopProfiles).insert(const ShopProfilesCompanion(
          openingCashBalance: drift.Value(100),
        ));
    final date = DateTime(2024, 3, 12, 10);
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'RECEIPT',
          txnDate: date,
          type: CashTransactionType.income.dbValue,
          category: IncomeCategory.sale.dbValue,
          amount: const drift.Value(10),
          referenceId: const drift.Value('INV-42'),
        ));
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'PAYMENT',
          txnDate: date.add(const Duration(hours: 1)),
          type: CashTransactionType.expense.dbValue,
          category: ExpenseCategory.shopRent.dbValue,
          amount: const drift.Value(4),
        ));
    final storedEntries = await CashBookRepository(db: db).fetchTransactions(
      from: DateTime(2024, 3, 12),
      to: DateTime(2024, 3, 12, 23, 59, 59),
    );
    final controller = CashBookController(
      repository:
          _LedgerFixture(db, entries: storedEntries, useDatabaseSummary: true),
    );
    addTearDown(() async {
      controller.dispose();
      await db.close();
    });
    controller.selectDate(DateTime(2024, 3, 12));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final entries = controller.exportData.transactions;
    expect(entries, hasLength(2));
    expect(controller.summary.openingBalance, 100);
    expect(controller.summary.closingBalance, 106);
    final receipt = entries.singleWhere((entry) => entry.txnId == 'RECEIPT');
    final payment = entries.singleWhere((entry) => entry.txnId == 'PAYMENT');
    expect(controller.runningBalanceFor(receipt.id), 110);
    expect(controller.runningBalanceFor(payment.id), 106);

    controller.setFilter(CashBookFilter.incomeOnly);
    expect(controller.groups.single.transactions.single.txnId, 'RECEIPT');
  });

  test('month ledger stays populated when selected day has no transactions',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.shopProfiles).insert(const ShopProfilesCompanion(
          openingCashBalance: drift.Value(100),
        ));
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'MARCH-RECEIPT',
          txnDate: DateTime(2024, 3, 5, 10),
          type: CashTransactionType.income.dbValue,
          category: IncomeCategory.miscIncome.dbValue,
          amount: const drift.Value(10),
        ));
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'MARCH-PAYMENT',
          txnDate: DateTime(2024, 3, 12, 10),
          type: CashTransactionType.expense.dbValue,
          category: ExpenseCategory.shopRent.dbValue,
          amount: const drift.Value(5),
        ));
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'APRIL-RECEIPT',
          txnDate: DateTime(2024, 4, 2, 10),
          type: CashTransactionType.income.dbValue,
          category: IncomeCategory.miscIncome.dbValue,
          amount: const drift.Value(20),
        ));
    final controller =
        CashBookController(repository: CashBookRepository(db: db));
    addTearDown(() async {
      controller.dispose();
      await db.close();
    });
    controller.selectDate(DateTime(2024, 3, 20));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(controller.summary.totalTransactions, 0);
    expect(controller.monthSummary.totalTransactions, 2);
    expect(controller.monthSummary.openingBalance, 100);
    expect(controller.monthSummary.totalIncome, 10);
    expect(controller.monthSummary.totalExpense, 5);
    expect(controller.monthSummary.closingBalance, 105);
    expect(controller.groups, hasLength(2));
    expect(controller.exportData.transactions, isEmpty);
    expect(
        controller
            .runningBalanceFor(controller.groups.first.transactions.single.id),
        105);

    controller.setFilter(CashBookFilter.incomeOnly);
    expect(controller.groups.single.transactions.single.txnId, 'MARCH-RECEIPT');
    controller.selectDate(DateTime(2024, 4, 2));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(controller.monthSummary.openingBalance, 105);
    expect(controller.monthSummary.closingBalance, 125);
    expect(controller.exportData.transactions.single.txnId, 'APRIL-RECEIPT');
  });

  test('CSV and PDF include chronological cash movements and balance',
      () async {
    final date = DateTime(2024, 3, 12, 10);
    final income = CashTransactionModel(
      id: 1,
      txnId: 'TXN-1',
      txnDate: date,
      type: CashTransactionType.income,
      categoryDbValue: IncomeCategory.miscIncome.dbValue,
      categoryLabel: 'Misc. Income',
      amount: 10,
      amountFormatted: 'Rs 10.00',
      paymentMode: PaymentMode.cash,
      partyName: '=unsafe',
      isAutoGenerated: false,
      isVoided: false,
    );
    final expense = CashTransactionModel(
      id: 2,
      txnId: 'TXN-2',
      txnDate: date.add(const Duration(hours: 1)),
      type: CashTransactionType.expense,
      categoryDbValue: ExpenseCategory.shopRent.dbValue,
      categoryLabel: 'Shop Rent',
      amount: 4,
      amountFormatted: 'Rs 4.00',
      paymentMode: PaymentMode.cash,
      isAutoGenerated: true,
      isVoided: false,
    );
    const summary = CashBookSummaryModel(
      openingBalance: 100,
      totalIncome: 10,
      totalExpense: 4,
      closingBalance: 106,
      netFlow: 6,
      openingBalanceStr: 'Rs 100.00',
      totalIncomeStr: 'Rs 10.00',
      totalExpenseStr: 'Rs 4.00',
      closingBalanceStr: 'Rs 106.00',
      netFlowStr: 'Rs 6.00',
      incomeBreakdown: [],
      expenseBreakdown: [],
      totalTransactions: 2,
      incomeCount: 1,
      expenseCount: 1,
    );
    final data = CashBookExportData(
      periodStart: DateTime(2024, 3, 12),
      periodEnd: DateTime(2024, 3, 12, 23, 59, 59),
      summary: summary,
      transactions: [expense, income],
      runningBalances: const {1: 110, 2: 106},
    );
    final csv = CashBookExportService.buildCsv(data);
    expect(csv, contains('Lotus ERP Account Book - Cash'));
    expect(csv.indexOf('TXN-1'), lessThan(csv.indexOf('TXN-2')));
    expect(csv, contains('"\'=unsafe"'));
    expect(csv, contains('"100.00"'));
    expect(csv, contains('"106.00"'));
    final pdf = await CashBookExportService.buildPdf(data);
    expect(pdf.length, greaterThan(1000));
  });
}
