import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_schema.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_balance_verification.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_expense_record.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/repositories/finance/cash_book_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_manual_income_repository.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_income_dialog.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_balance_dialog.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_balance_summary.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_primary_grid.dart';
import 'package:lotus_erp/theme/reports/day_book/day_book_colors.dart';

void main() {
  testWidgets('opening comparison shows entered modes and only net difference',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DayBookBalanceSummary(
          expectedCash: 404610,
          expectedBank: 0,
          actualCash: 200000,
          actualBank: 200000,
        ),
      ),
    ));
    expect(find.text('Verification Summary'), findsOneWidget);
    expect(find.text('System Opening'), findsOneWidget);
    expect(find.text('Counted Opening'), findsOneWidget);
    final subtraction = tester.widget<Text>(
        find.byKey(const ValueKey('opening-balance-subtraction')));
    expect(subtraction.data, contains('−'));
    expect(subtraction.data, contains('4,04,610.00'));
    expect(subtraction.data, contains('4,00,000.00'));
    expect(find.text('Difference'), findsOneWidget);
    expect(find.text('₹4,610.00'), findsOneWidget);
    expect(find.text('Mismatch'), findsOneWidget);
    final systemTop = tester.getTopLeft(find.text('System Opening'));
    final countedTop = tester.getTopLeft(find.text('Counted Opening'));
    final differenceTop = tester.getTopLeft(find.text('Difference'));
    expect((systemTop.dy - countedTop.dy).abs(), lessThan(1));
    expect((countedTop.dy - differenceTop.dy).abs(), lessThan(1));
    expect(tester.getTopLeft(find.text('Mismatch')).dx,
        greaterThan(tester.getTopRight(find.text('₹4,610.00')).dx));
  });

  testWidgets('verification dialog matches the compact reference hierarchy',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookBalanceDialog(
          date: DateTime(2026, 11, 7),
          expectedCash: 404610,
          expectedBank: 0,
          expenseRecords: const [
            DayBookExpenseRecord(
              reference: 'EXP-1',
              category: 'Shop Rent',
              amount: 750,
              paymentMode: 'CASH',
            ),
            DayBookExpenseRecord(
              reference: 'EXP-2',
              category: 'Personal',
              amount: 250,
              paymentMode: 'UPI',
            ),
          ],
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
    await tester.enterText(find.byKey(const ValueKey('actual-cash')), '200000');
    await tester.enterText(find.byKey(const ValueKey('actual-bank')), '200000');
    await tester.pumpAndSettle();
    expect(find.text('Previous Day Closing · 6 Nov 2026'), findsOneWidget);
    expect(find.text('Today’s Opening Count · 7 Nov 2026'), findsOneWidget);
    expect(find.text('Verification Summary'), findsOneWidget);
    expect(find.text("Today's Expenses Paid"), findsOneWidget);
    expect(find.text('₹1,000.00'), findsOneWidget);
    expect(find.text('₹4,610.00'), findsOneWidget);
    expect(find.text('Attention Needed'), findsOneWidget);
    expect(find.text('Mismatch Transfer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('income form saves a non-invoiced cash receipt', (tester) async {
    double? savedAmount;
    String? savedCategory;
    PaymentMode? savedMode;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookIncomeDialog(
          date: DateTime(2026, 11, 7),
          bankAccounts: const [],
          onSave: ({
            required amount,
            required category,
            required paymentMode,
            bankAccountId,
            customLabel,
          }) async {
            savedAmount = amount;
            savedCategory = category;
            savedMode = paymentMode;
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
    expect(find.widgetWithText(TextFormField, 'Reason'), findsNothing);
    await tester
        .tap(find.byKey(const ValueKey('day-book-income-category-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gold repair').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Income'));
    await tester.pumpAndSettle();
    expect(savedAmount, 250.50);
    expect(savedCategory, IncomeCategory.goldRepairIncome.dbValue);
    expect(savedMode, PaymentMode.cash);
  });

  testWidgets('Other category is typed in the category field', (tester) async {
    String? savedCategory;
    String? savedLabel;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookIncomeDialog(
          date: DateTime(2026, 11, 8),
          bankAccounts: const [],
          onSave: ({
            required amount,
            required category,
            required paymentMode,
            bankAccountId,
            customLabel,
          }) async {
            savedCategory = category;
            savedLabel = customLabel;
            return true;
          },
        ),
      ),
    ));
    expect(find.text('Received from (optional)'), findsNothing);
    expect(find.text('Category name'), findsNothing);
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '750');
    await tester
        .tap(find.byKey(const ValueKey('day-book-income-category-options')));
    await tester.pumpAndSettle();
    expect(find.text('Counter sale (no invoice)'), findsNothing);
    expect(find.text('Jewellery making'), findsNothing);
    await tester.tap(find.text('Other · type your own'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('day-book-income-category')),
        'Pearl restringing');
    await tester.tap(find.text('Save Income'));
    await tester.pumpAndSettle();
    expect(savedCategory, IncomeCategory.otherIncome.dbValue);
    expect(savedLabel, 'Pearl restringing');
  });

  testWidgets('bank income requires an account and uses bank mode',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    PaymentMode? savedMode;
    int? savedAccount;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookIncomeDialog(
          date: DateTime(2026, 11, 8),
          bankAccounts: const [ManualIncomeBankAccount(7, 'Current Account')],
          onSave: ({
            required amount,
            required category,
            required paymentMode,
            bankAccountId,
            customLabel,
          }) async {
            savedMode = paymentMode;
            savedAccount = bankAccountId;
            return true;
          },
        ),
      ),
    ));
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '600');
    await tester
        .tap(find.byKey(const ValueKey('day-book-income-category-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Silver repair').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Income'));
    await tester.pump();
    expect(find.text('Select a bank account.'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current Account').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Income'));
    await tester.pumpAndSettle();
    expect(savedMode, PaymentMode.bank);
    expect(savedAccount, 7);
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
    expect(find.text('Daily Balance Verification'), findsOneWidget);
    expect(find.text('Previous Day Closing · 6 Nov 2026'), findsOneWidget);
    expect(find.text('Today’s Opening Count · 7 Nov 2026'), findsOneWidget);
    expect(find.text('Difference'), findsNothing);
    expect(find.text('Open Bank Book'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('actual-cash')), '390');
    await tester.pump();
    expect(find.text('Verification Summary'), findsOneWidget);
    expect(find.text('Difference'), findsNothing);
    expect(find.byKey(const ValueKey('opening-balance-subtraction')),
        findsNothing);
    await tester.enterText(find.byKey(const ValueKey('actual-bank')), '195');
    await tester.pump();
    expect(find.text('₹585.00'), findsOneWidget);
    await tester.ensureVisible(find.text('Difference', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(find.text('Difference'), findsOneWidget);
    expect(find.text('Expense adjustment'), findsOneWidget);
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Mismatch Transfer'))
            .onPressed,
        isNotNull);
    await tester.tap(find.text('Save & Verify'));
    await tester.pump();
    expect(find.text('Write a reason before saving.'), findsOneWidget);
    await tester
        .ensureVisible(find.byKey(const ValueKey('balance-expense-note')));
    await tester.enterText(find.byKey(const ValueKey('balance-expense-note')),
        'Cash used for supplies and confirmed bank charge');
    await tester.tap(find.text('Save & Verify'));
    await tester.pump();
    expect(find.text('Choose Shop or Personal expense and its category.'),
        findsOneWidget);
    await tester.ensureVisible(find.text('Shop expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shop expense'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.byKey(const ValueKey('balance-expense-category-shop')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('balance-expense-category-shop')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Misc. Expense').last);
    await tester.pumpAndSettle();
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.ensureVisible(find.text('Save & Verify'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & Verify'));
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
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Difference'), findsNothing);
    expect(find.text('Attention Needed'), findsOneWidget);
    expect(find.text('Mismatch Transfer'), findsOneWidget);
    final mismatch = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Mismatch Transfer'));
    expect(mismatch.onPressed, isNull);
    final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save & Verify'));
    expect(save.onPressed, isNull);
  });

  testWidgets('mismatch action hands off only the net shortage',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DayBookBalanceDialogResult? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () async {
              result = await showDialog<DayBookBalanceDialogResult>(
                context: context,
                builder: (_) => DayBookBalanceDialog(
                  date: DateTime(2026, 11, 7),
                  expectedCash: 404610,
                  expectedBank: 0,
                  onSave: ({
                    required actualCash,
                    required actualBank,
                    cashExpenseCategory,
                    cashReason,
                    bankReason,
                  }) async =>
                      throw UnimplementedError(),
                ),
              );
            },
            child: const Text('Open verification'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('actual-cash')), '200000');
    await tester.enterText(find.byKey(const ValueKey('actual-bank')), '200000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mismatch Transfer'));
    await tester.pumpAndSettle();
    expect(result?.mismatchExpenseAmount, 4610);
  });

  testWidgets('matched opening does not show mismatch action', (tester) async {
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
    await tester.enterText(find.byKey(const ValueKey('actual-cash')), '400');
    await tester.enterText(find.byKey(const ValueKey('actual-bank')), '200');
    await tester.pump();
    expect(find.text('Mismatch Transfer'), findsNothing);
    expect(find.text('Verified'), findsOneWidget);
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
    await tester.tap(find.text('Save & Verify'));
    await tester.pump();
    expect(find.text('Add a bank account first.'), findsOneWidget);
  });

  testWidgets('Day Book money and position cards have no header actions',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          ),
        ),
      ),
    ));
    expect(find.text('Add Income'), findsNothing);
    expect(find.text('Verify Opening'), findsNothing);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(320, 900);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookPrimaryGrid(
            summary: summary,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Add Income'), findsNothing);
    expect(find.text('Verify Opening'), findsNothing);
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
