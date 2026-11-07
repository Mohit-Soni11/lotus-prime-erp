import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_schema.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_balance_verification.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/repositories/finance/cash_book_repository.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_cash_income_dialog.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_balance_dialog.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_primary_grid.dart';
import 'package:lotus_erp/theme/reports/day_book/day_book_colors.dart';

void main() {
  testWidgets('cash income form saves only a valid extra receipt',
      (tester) async {
    double? savedAmount;
    String? savedCategory;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookCashIncomeDialog(
          date: DateTime(2026, 11, 7),
          onSave: ({
            required amount,
            required category,
            required description,
            customLabel,
            partyName,
          }) async {
            savedAmount = amount;
            savedCategory = category;
            return true;
          },
        ),
      ),
    ));
    final cashTheme =
        Theme.of(tester.element(find.byType(TextFormField).first));
    expect(cashTheme.colorScheme.primary, DayBookColors.brandGold);
    expect(cashTheme.inputDecorationTheme.labelStyle?.color,
        DayBookColors.textPrimary);

    await tester.tap(find.text('Save Income'));
    await tester.pump();
    expect(find.text('Enter a valid amount with up to two decimals.'),
        findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'), '250.50');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Reason'), 'Other cash received');
    await tester.tap(find.text('Save Income'));
    await tester.pumpAndSettle();
    expect(savedAmount, 250.50);
    expect(savedCategory, IncomeCategory.miscIncome.dbValue);
  });

  testWidgets('daily balance requires reasons and expense type for shortages',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    double? savedCash;
    double? savedBank;
    ExpenseCategory? savedCategory;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookBalanceDialog(
          date: DateTime(2026, 11, 7),
          expectedCash: 400,
          expectedBank: 200,
          onSave: (
              {required actualCash,
              required actualBank,
              cashExpenseCategory,
              cashReason,
              bankReason}) async {
            savedCash = actualCash;
            savedBank = actualBank;
            savedCategory = cashExpenseCategory;
            return DayBookBalanceVerification(
              date: DateTime(2026, 11, 7),
              verifiedAt: DateTime.now(),
              expectedCash: 400,
              actualCash: actualCash,
              cashVariance: actualCash - 400,
              expectedBank: 200,
              actualBank: actualBank,
              bankVariance: actualBank - 200,
            );
          },
        ),
      ),
    ));
    final balanceTheme =
        Theme.of(tester.element(find.byKey(const ValueKey('actual-cash'))));
    expect(balanceTheme.colorScheme.primary, DayBookColors.brandGold);
    expect(balanceTheme.inputDecorationTheme.labelStyle?.color,
        DayBookColors.textPrimary);
    await tester.enterText(find.byKey(const ValueKey('actual-cash')), '390');
    await tester.enterText(find.byKey(const ValueKey('actual-bank')), '195');
    await tester.pump();
    expect(find.text('Combined Opening · Cash + Bank'), findsOneWidget);
    expect(find.textContaining('585.00'), findsOneWidget);
    expect(find.textContaining('15.00'), findsOneWidget);
    expect(find.textContaining('Cash shortage'), findsOneWidget);
    expect(
        find.text('Bank difference · reconciliation pending'), findsOneWidget);
    await tester.tap(find.text('Save Verification'));
    await tester.pump();
    expect(find.text('Select the expense type.'), findsOneWidget);
    await tester
        .ensureVisible(find.byKey(const ValueKey('cash-variance-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cash-variance-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Misc. Expense').last);
    await tester
        .ensureVisible(find.byKey(const ValueKey('cash-variance-reason')));
    await tester.enterText(find.byKey(const ValueKey('cash-variance-reason')),
        'Cash used for supplies');
    await tester
        .ensureVisible(find.byKey(const ValueKey('bank-variance-reason')));
    await tester.enterText(find.byKey(const ValueKey('bank-variance-reason')),
        'UPI settlement pending');
    await tester.tap(find.text('Save Verification'));
    await tester.pumpAndSettle();
    expect(savedCash, 390);
    expect(savedBank, 195);
    expect(savedCategory, ExpenseCategory.miscExpense);
  });

  testWidgets('offsetting cash and bank differences remain visible',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookBalanceDialog(
          date: DateTime(2026, 11, 7),
          expectedCash: 400,
          expectedBank: 200,
          onSave: ({
            required actualCash,
            required actualBank,
            cashExpenseCategory,
            cashReason,
            bankReason,
          }) async =>
              throw UnimplementedError(),
        ),
      ),
    ));
    await tester.enterText(find.byKey(const ValueKey('actual-cash')), '390');
    await tester.enterText(find.byKey(const ValueKey('actual-bank')), '210');
    await tester.pump();
    expect(
        find.textContaining('differences offset each other'), findsOneWidget);
    expect(find.textContaining('Cash shortage'), findsOneWidget);
    expect(
        find.text('Bank difference · reconciliation pending'), findsOneWidget);
  });

  testWidgets('bank amount needs an account before verification',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookBalanceDialog(
          date: DateTime(2026, 11, 7),
          expectedCash: 400,
          expectedBank: 0,
          bankAccountConfigured: false,
          onSave: ({
            required actualCash,
            required actualBank,
            cashExpenseCategory,
            cashReason,
            bankReason,
          }) async =>
              throw UnimplementedError(),
        ),
      ),
    ));
    await tester.enterText(find.byKey(const ValueKey('actual-cash')), '400');
    await tester.enterText(find.byKey(const ValueKey('actual-bank')), '50');
    await tester.tap(find.text('Save Verification'));
    await tester.pump();
    expect(find.text('Add a bank account in Bank Book first.'), findsOneWidget);
  });

  testWidgets('Day Book actions sit beside the related sections',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var incomeTaps = 0;
    var balanceTaps = 0;
    final summary = DayBookSummary(
      date: DateTime(2026, 11, 7),
      moneyFlow: DayBookMoneyFlow(
        openingCash: 0,
        openingBank: 0,
        entries: [],
      ),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookPrimaryGrid(
            summary: summary,
            onAddCashIncome: () => incomeTaps++,
            onSetBalance: () => balanceTaps++,
            showBalanceAction: true,
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Add Cash Income'));
    await tester.tap(find.text('Set Balance'));
    expect(incomeTaps, 1);
    expect(balanceTaps, 1);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(320, 900);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookPrimaryGrid(
            summary: summary,
            onAddCashIncome: () => incomeTaps++,
            onSetBalance: () => balanceTaps++,
            showBalanceAction: true,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add Cash Income'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('initial cash setup stops after a financial posting', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.shopProfiles).insert(ShopProfilesCompanion.insert());
    final repo = CashBookRepository(db: db);

    expect((await repo.fetchInitialCashSetup()).canSet, isTrue);
    expect(await repo.updateOpeningBalance(1000), isTrue);
    expect((await repo.fetchInitialCashSetup()).amount, 1000);
    expect(
      await repo.saveExtraCashIncome(
        categoryDbValue: IncomeCategory.miscIncome.dbValue,
        amount: 25,
        txnDate: DateTime(2026, 11, 7),
        description: 'Other cash received',
      ),
      isTrue,
    );
    expect((await repo.fetchInitialCashSetup()).canSet, isFalse);
    expect(await repo.updateOpeningBalance(2000), isFalse);
  });

  test('closed day prevents changing initial cash without transactions',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.shopProfiles).insert(ShopProfilesCompanion.insert());
    await db.customStatement(financeDayClosureSchemaSql.first);
    final dayStart = DateTime(2026, 11, 6).millisecondsSinceEpoch;
    final dayEnd = DateTime(2026, 11, 7).millisecondsSinceEpoch;
    await db.customStatement('''
      INSERT INTO finance_day_closures
      (day_key, start_epoch, end_epoch, closing_cash, closed_at)
      VALUES ('2026-11-06', $dayStart, $dayEnd, 0, $dayEnd)
    ''');

    final repo = CashBookRepository(db: db);
    expect((await repo.fetchInitialCashSetup()).canSet, isFalse);
    expect(await repo.updateOpeningBalance(500), isFalse);
  });

  test('bank posting also locks initial cash setup', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.shopProfiles).insert(ShopProfilesCompanion.insert());
    final accountId = await db.into(db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Current Account',
            bankName: 'Test Bank',
            accountNumber: '123456',
          ),
        );
    await db.into(db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'BANK-1',
            accountId: accountId,
            txnDate: DateTime(2026, 11, 7),
            type: 'CREDIT',
            category: 'OTHER_INCOME',
            amount: const drift.Value(100),
            paymentMode: const drift.Value('UPI'),
          ),
        );

    final repo = CashBookRepository(db: db);
    expect((await repo.fetchInitialCashSetup()).canSet, isFalse);
    expect(await repo.updateOpeningBalance(500), isFalse);
  });
}
