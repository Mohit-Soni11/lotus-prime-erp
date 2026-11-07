import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/repositories/reports/day_book_balance_verification_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_expense_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_money_repository.dart';
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

  test('cash shortage posts classified expense; bank mismatch stays pending',
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
      bankReason: 'UPI settlement pending',
    );

    expect(saved.cashVariance, -10);
    expect(saved.bankVariance, -5);
    expect(saved.bankNeedsReview, isTrue);
    final cashRows = await db.select(db.cashTransactions).get();
    expect(cashRows, hasLength(1));
    expect(cashRows.single.type, 'EXPENSE');
    expect(cashRows.single.category, ExpenseCategory.miscExpense.dbValue);
    expect(cashRows.single.amount, 10);
    expect(cashRows.single.referenceType, 'DAY_BOOK_BALANCE');
    expect(cashRows.single.txnId, saved.cashAdjustmentTransactionId);
    expect((await DayBookExpenseRepository(db).fetch(date)).single.amount, 10);
    final flow = await DayBookMoneyRepository(db).fetch(date, 100);
    expect(flow.closingCash, 90);
    expect(flow.closingBank, 50);
    expect(await db.select(db.bankTransactions).get(), isEmpty);
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
      ),
      throwsStateError,
    );
    expect(await repo.fetch(date), isNull);
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
