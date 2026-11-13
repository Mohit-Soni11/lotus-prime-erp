import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_repository.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/repositories/reports/day_book_balance_verification_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_expense_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_money_repository.dart';
import 'package:lotus_erp/repositories/finance/expense_repository.dart';
import 'package:sqlite3/sqlite3.dart';

Future<AppDatabase> _database() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.into(db.shopProfiles).insert(ShopProfilesCompanion.insert(
        openingCashBalance: const drift.Value(100),
      ));
  await db.into(db.bankAccounts).insert(BankAccountsCompanion.insert(
        accountName: 'Main Bank',
        bankName: 'Test Bank',
        accountNumber: '123456',
        openingBalance: const drift.Value(50),
        activeSince: drift.Value(DateTime(2026, 11, 7, 12)),
      ));
  return db;
}

void main() {
  final date = DateTime(2026, 11, 7);

  test('matching cash and bank saves one immutable verification', () async {
    final db = await _database();
    addTearDown(db.close);
    final repo = DayBookBalanceVerificationRepository(db);

    final saved = await repo.verify(
      date: date,
      expectedCash: 100,
      actualCash: 100,
      expectedBank: 50,
      actualBank: 50,
      verifiedBy: 'tester',
    );

    expect(saved.fullyMatched, isTrue);
    expect(saved.cashAdjustmentTransactionId, isNull);
    expect((await repo.fetch(date))?.verifiedBy, 'tester');
    expect(await db.select(db.cashTransactions).get(), isEmpty);
    await expectLater(
      repo.verify(
        date: date,
        expectedCash: 100,
        actualCash: 100,
        expectedBank: 50,
        actualBank: 50,
      ),
      throwsStateError,
    );
  });

  test('certified closing rejects invoices without original issue evidence',
      () async {
    final db = await _database();
    addTearDown(db.close);
    await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'LEGACY-UNVERIFIED',
          billDate: drift.Value(date),
          finalAmount: const drift.Value(100),
        ));
    await DayBookBalanceVerificationRepository(db).verify(
      date: date,
      expectedCash: 100,
      actualCash: 100,
      expectedBank: 50,
      actualBank: 50,
      verifiedBy: 'tester',
    );
    await expectLater(
      FinanceDayClosureRepository(db).closeDay(date,
          closingCash: 100,
          physicalBank: 50,
          requireVerifiedOpening: true,
          closedBy: 'tester'),
      throwsA(isA<StateError>().having((error) => error.message, 'message',
          contains('issue values are unverified'))),
    );
    expect(await FinanceDayClosureRepository(db).isClosed(date), isFalse);
  });

  test('cash and bank shortages post classified Expense Entry sources',
      () async {
    final db = await _database();
    addTearDown(db.close);
    final repo = DayBookBalanceVerificationRepository(db);

    final saved = await repo.verify(
      date: date,
      expectedCash: 100,
      actualCash: 90,
      expectedBank: 50,
      actualBank: 45,
      cashExpenseCategory: ExpenseCategory.miscExpense,
      cashReason: 'Cash used for packing supplies',
      bankReason: 'Bank charge confirmed',
    );

    expect(saved.cashVariance, -10);
    expect(saved.bankVariance, -5);
    expect(saved.bankNeedsReview, isFalse);
    final cashRows = await db.select(db.cashTransactions).get();
    expect(cashRows, hasLength(2));
    expect(cashRows.map((row) => row.amount), containsAll([10, 5]));
    expect(cashRows.every((row) => row.type == 'EXPENSE'), isTrue);
    expect(
        cashRows.every(
            (row) => row.category == ExpenseCategory.miscExpense.dbValue),
        isTrue);
    expect(cashRows.every((row) => row.referenceType == 'DAY_BOOK_BALANCE'),
        isTrue);
    expect(cashRows.first.txnId, saved.cashAdjustmentTransactionId);
    expect((await DayBookExpenseRepository(db).fetch(date)), hasLength(2));
    final flow = await DayBookMoneyRepository(db).fetch(date, 100);
    expect(flow.closingCash, 90);
    expect(flow.closingBank, 45);
    expect((await db.select(db.bankTransactions).get()).single.amount, 5);
    expect(
      await FinanceDayClosureRepository(db).closeDay(
        date,
        closingCash: 90,
        physicalBank: 45,
        closedBy: 'tester',
        requireVerifiedOpening: true,
      ),
      isTrue,
    );
  });

  test('personal cash shortage is linked to Expense Entry as owner drawing',
      () async {
    final db = await _database();
    addTearDown(db.close);
    final saved = await DayBookBalanceVerificationRepository(db).verify(
      date: date,
      expectedCash: 100,
      actualCash: 80,
      expectedBank: 50,
      actualBank: 50,
      cashExpenseCategory: ExpenseCategory.personalHousehold,
      cashReason: 'Owner took cash for personal use',
    );

    final entries = await ExpenseRepository(db: db).fetchExpenses(
      from: date,
      to: DateTime(2026, 11, 7, 23, 59, 59),
    );
    expect(entries, hasLength(1));
    expect(entries.single.category, ExpenseCategory.personalHousehold);
    expect(entries.single.expenseId, saved.cashAdjustmentTransactionId);
    final dayBookExpenses = await DayBookExpenseRepository(db).fetch(date);
    expect(dayBookExpenses, hasLength(1));
    expect(dayBookExpenses.single.amount, 20);
    expect(dayBookExpenses.single.reference, saved.cashAdjustmentTransactionId);
  });

  test('bank-only shortage links Expense Entry and debits the bank once',
      () async {
    final db = await _database();
    addTearDown(db.close);
    final saved = await DayBookBalanceVerificationRepository(db).verify(
      date: date,
      expectedCash: 100,
      actualCash: 100,
      expectedBank: 50,
      actualBank: 45,
      cashExpenseCategory: ExpenseCategory.bankCharges,
      cashReason: 'Confirmed service charge',
    );

    final source = (await db.select(db.cashTransactions).get()).single;
    final bank = (await db.select(db.bankTransactions).get()).single;
    expect(source.txnId, saved.cashAdjustmentTransactionId);
    expect(source.amount, 5);
    expect(source.paymentMode, 'BANK');
    expect(source.category, ExpenseCategory.bankCharges.dbValue);
    expect(bank.referenceId, source.txnId);
    expect(bank.amount, 5);
    expect(saved.bankNeedsReview, isFalse);
    final flow = await DayBookMoneyRepository(db).fetch(date, 100);
    expect(flow.closingCash, 100);
    expect(flow.closingBank, 45);
    expect(
        (await ExpenseRepository(db: db).fetchExpenses(
          from: date,
          to: DateTime(2026, 11, 7, 23, 59, 59),
        )),
        hasLength(1));
  });

  test('cash surplus posts income and stale expected balance is rejected',
      () async {
    final db = await _database();
    addTearDown(db.close);
    final repo = DayBookBalanceVerificationRepository(db);

    await expectLater(
      repo.verify(
        date: date,
        expectedCash: 99,
        actualCash: 99,
        expectedBank: 50,
        actualBank: 50,
      ),
      throwsStateError,
    );
    expect(await repo.fetch(date), isNull);

    await repo.verify(
      date: date,
      expectedCash: 100,
      actualCash: 110,
      expectedBank: 50,
      actualBank: 50,
      cashReason: 'Unrecorded cash recovered',
    );
    final row = (await db.select(db.cashTransactions).get()).single;
    expect(row.type, 'INCOME');
    expect(row.amount, 10);
    expect(row.category, IncomeCategory.miscIncome.dbValue);
  });

  test('unexplained differences never create a posting', () async {
    final db = await _database();
    addTearDown(db.close);
    final repo = DayBookBalanceVerificationRepository(db);

    await expectLater(
      repo.verify(
        date: date,
        expectedCash: 100,
        actualCash: 90,
        expectedBank: 50,
        actualBank: 50,
        cashExpenseCategory: ExpenseCategory.miscExpense,
      ),
      throwsArgumentError,
    );
    await expectLater(
      repo.verify(
        date: date,
        expectedCash: 100,
        actualCash: 100,
        expectedBank: 50,
        actualBank: 45,
      ),
      throwsArgumentError,
    );
    expect(await db.select(db.cashTransactions).get(), isEmpty);
    expect(await repo.fetch(date), isNull);
  });

  test('opposite cash and bank differences never become a false expense',
      () async {
    final db = await _database();
    addTearDown(db.close);
    final repo = DayBookBalanceVerificationRepository(db);

    await expectLater(
      repo.verify(
        date: date,
        expectedCash: 100,
        actualCash: 80,
        expectedBank: 50,
        actualBank: 65,
        cashExpenseCategory: ExpenseCategory.miscExpense,
        cashReason: 'Unexplained cash shortage',
        bankReason: 'Unexplained bank excess',
      ),
      throwsStateError,
    );
    expect(await db.select(db.cashTransactions).get(), isEmpty);
    expect(await repo.fetch(date), isNull);
  });

  test('non-zero bank balance cannot be verified without a bank account',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.shopProfiles).insert(ShopProfilesCompanion.insert(
          openingCashBalance: const drift.Value(100),
        ));
    final repo = DayBookBalanceVerificationRepository(db);
    await expectLater(
      repo.verify(
        date: date,
        expectedCash: 100,
        actualCash: 100,
        expectedBank: 0,
        actualBank: 50,
        bankReason: 'Actual balance shown by bank',
        cashReason: 'Unrecorded bank credit needs review',
      ),
      throwsStateError,
    );
    expect(await repo.fetch(date), isNull);
  });

  test('carried digital receipts can be verified without a bank account',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.shopProfiles).insert(ShopProfilesCompanion.insert(
          openingCashBalance: const drift.Value(100),
        ));
    await db.into(db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'BTXN-UNASSIGNED-UPI',
            txnDate: DateTime(2026, 11, 6, 12),
            type: 'CREDIT',
            category: 'SALE_PAYMENT',
            amount: const drift.Value(50),
            paymentMode: const drift.Value('UPI'),
          ),
        );
    final repo = DayBookBalanceVerificationRepository(db);
    final saved = await repo.verify(
      date: date,
      expectedCash: 100,
      actualCash: 100,
      expectedBank: 50,
      actualBank: 45,
      cashExpenseCategory: ExpenseCategory.miscExpense,
      cashReason: 'Digital receipt discrepancy',
    );

    expect(saved.bankVariance, -5);
    final bankRows = await db.select(db.bankTransactions).get();
    expect(bankRows, hasLength(2));
    expect(bankRows.every((row) => row.accountId == null), isTrue);
    expect(bankRows.where((row) => row.type == 'DEBIT').single.amount, 5);
    final flow = await DayBookMoneyRepository(db).fetch(date, 100);
    expect(flow.openingBank, 50);
    expect(flow.closingBank, 45);
    expect(
      await FinanceDayClosureRepository(db).closeDay(
        date,
        closingCash: 100,
        physicalBank: 45,
        requireVerifiedOpening: true,
        closedBy: 'tester',
      ),
      isTrue,
    );
  });

  test(
      'opening verification ignores today’s transactions and carries adjustment forward',
      () async {
    final db = await _database();
    addTearDown(db.close);
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'TODAY-SALE',
          txnDate: DateTime(2026, 11, 7, 10),
          type: 'INCOME',
          category: 'SALE_PAYMENT',
          amount: const drift.Value(40),
          paymentMode: const drift.Value('CASH'),
        ));

    final repo = DayBookBalanceVerificationRepository(db);
    await repo.verify(
      date: date,
      expectedCash: 100,
      actualCash: 90,
      expectedBank: 50,
      actualBank: 50,
      cashExpenseCategory: ExpenseCategory.miscExpense,
      cashReason: 'Counted cash shortage',
    );
    final today = await DayBookMoneyRepository(db).fetch(date, 100);
    expect(today.openingCash, 100);
    expect(today.closingCash, 130);
    expect(
        await DayBookMoneyRepository(db)
            .fetchOpeningCash(DateTime(2026, 11, 8)),
        130);
  });

  test('v73 migration preserves balances and creates verification storage',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus-day-balance-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}shop.sqlite');
    final original = AppDatabase.forTesting(NativeDatabase(file));
    await original.into(original.shopProfiles).insert(
          ShopProfilesCompanion.insert(
            openingCashBalance: const drift.Value(125),
          ),
        );
    await original.close();

    final legacy = sqlite3.open(file.path);
    try {
      legacy.execute('DROP TABLE day_book_balance_verifications');
      legacy.execute('PRAGMA user_version=73');
    } finally {
      legacy.dispose();
    }

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(migrated.close);
    expect(
        (await migrated.select(migrated.shopProfiles).getSingle())
            .openingCashBalance,
        125);
    final repo = DayBookBalanceVerificationRepository(migrated);
    expect(await repo.fetch(date), isNull);
    final saved = await repo.verify(
      date: date,
      expectedCash: 125,
      actualCash: 125,
      expectedBank: 0,
      actualBank: 0,
    );
    expect(saved.fullyMatched, isTrue);
  });
}
