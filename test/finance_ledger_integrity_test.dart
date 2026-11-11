import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_repository.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/repositories/finance/bank_book_repository.dart';
import 'package:lotus_erp/repositories/finance/cash_book_repository.dart';
import 'package:lotus_erp/repositories/finance/expense_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_money_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_balance_verification_repository.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_expense_classification.dart';

void main() {
  late AppDatabase db;
  late CashBookRepository cash;
  late BankBookRepository bank;
  late ExpenseRepository expenses;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cash = CashBookRepository(db: db);
    bank = BankBookRepository(db: db);
    expenses = ExpenseRepository(db: db);
  });

  tearDown(() async => db.close());

  test('cash balance carries prior cash activity and excludes bank activity',
      () async {
    await db.into(db.shopProfiles).insert(const ShopProfilesCompanion(
          openingCashBalance: drift.Value(100),
        ));
    await _cashRow(db, 'C-1', DateTime(2026, 6, 24), 'INCOME', 50);
    await _cashRow(db, 'C-2', DateTime(2026, 6, 24), 'INCOME', 900,
        mode: 'UPI');
    await _cashRow(db, 'C-3', DateTime(2026, 6, 25), 'EXPENSE', 20);
    await _cashRow(db, 'C-4', DateTime(2026, 6, 25), 'INCOME', 40, mode: 'UPI');

    final summary = await cash.computeSummary(
      from: DateTime(2026, 6, 25),
      to: DateTime(2026, 6, 25, 23, 59, 59),
    );
    expect(summary.openingBalance, 150);
    expect(summary.totalIncome, 0);
    expect(summary.totalExpense, 20);
    expect(summary.closingBalance, 130);
    final visible = await cash.fetchTransactions(
      from: DateTime(2026, 6, 25),
      to: DateTime(2026, 6, 25, 23, 59, 59),
    );
    expect(visible.map((entry) => entry.txnId), ['C-3']);
  });

  test('a day without transactions closes with carried cash and bank balances',
      () async {
    await db.into(db.shopProfiles).insert(const ShopProfilesCompanion(
          openingCashBalance: drift.Value(500),
        ));
    await db.into(db.bankAccounts).insert(BankAccountsCompanion.insert(
          accountName: 'Current Account',
          bankName: 'HDFC Bank',
          accountNumber: '111122223333',
          openingBalance: const drift.Value(200),
          activeSince: drift.Value(DateTime(2026, 6, 24)),
        ));

    final day = DateTime(2026, 6, 25);
    final moneyRepo = DayBookMoneyRepository(db);
    final openingCash = await moneyRepo.fetchOpeningCash(day);
    final flow = await moneyRepo.fetch(day, openingCash);
    expect(flow.openingCash, 500);
    expect(flow.openingBank, 200);
    expect(flow.closingCash, 500);
    expect(flow.closingBank, 200);

    final closure = FinanceDayClosureRepository(db);
    expect(
      await closure.closeDay(day,
          closingCash: 500,
          physicalBank: 200,
          closedBy: 'owner-1',
          denominationCount: {'500': 1}),
      isTrue,
    );
    final nextDay = DateTime(2026, 6, 26);
    final nextOpeningCash = await moneyRepo.fetchOpeningCash(nextDay);
    final nextFlow = await moneyRepo.fetch(nextDay, nextOpeningCash);
    expect(nextFlow.openingCash, 500);
    expect(nextFlow.openingBank, 200);
  });

  test('bill reconciliation posts only actual cash and is idempotent',
      () async {
    final date = DateTime(2026, 6, 25, 12);
    await _bill(db, 'B-UPI', date, paid: 300, upi: 300);
    await _bill(db, 'B-MIXED', date, paid: 300, cash: 100, upi: 200);

    expect(await cash.syncBillsToIncome(date), 1);
    expect(await cash.syncBillsToIncome(date), 0);
    final rows = await db.select(db.cashTransactions).get();
    expect(rows, hasLength(1));
    expect(rows.single.amount, 100);
    expect(rows.single.referenceId, 'B-MIXED');
  });

  test('bank reconciliation posts only missing payment split', () async {
    final date = DateTime(2026, 6, 25, 12);
    final accountId = await _bankAccount(db);
    await _bill(db, 'B-MIXED', date, paid: 300, cash: 100, upi: 200);

    expect(await bank.syncBillsToBank(accountId: accountId, date: date), 1);
    expect(await bank.syncBillsToBank(accountId: accountId, date: date), 0);
    final rows = await db.select(db.bankTransactions).get();
    expect(rows, hasLength(1));
    expect(rows.single.amount, 200);
    expect(rows.single.referenceId, 'B-MIXED#UPI');
  });

  test('legacy Girvi bank principal is reported as Girvi, not invoice due',
      () async {
    final date = DateTime(2026, 6, 25, 12);
    final accountId = await _bankAccount(db);
    await db.into(db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'GIRVI-PAY-1-P',
            accountId: accountId,
            txnDate: date,
            type: 'CREDIT',
            category: 'DUE_COLLECTION',
            amount: const drift.Value(250),
            paymentMode: const drift.Value('UPI'),
            referenceId: const drift.Value('GIRVI-1-PAY-1'),
            referenceType: const drift.Value('GIRVI'),
          ),
        );
    final money = await DayBookMoneyRepository(db).fetch(date, 0);
    expect(money.bySource(incoming: true)['GIRVI_RETURN'], 250);
    expect(money.bySource(incoming: true)['DUE_COLLECTION'], isNull);
  });

  test('customer change and held refund are not operating income or expense',
      () async {
    final date = DateTime(2026, 6, 25, 12);
    await db.into(db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: 'CHANGE-OUT',
            txnDate: date,
            type: 'EXPENSE',
            category: 'MISC_EXPENSE',
            amount: const drift.Value(30),
            referenceType: const drift.Value('CUSTOMER_CHANGE'),
          ),
        );
    await db.into(db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: 'HELD-REFUND',
            txnDate: date,
            type: 'INCOME',
            category: 'ADVANCE',
            amount: const drift.Value(25),
            referenceType: const drift.Value('CUSTOMER_REFUND_PAYABLE'),
          ),
        );
    final money = await DayBookMoneyRepository(db).fetch(date, 0);
    expect(money.bySource(incoming: true)['REFUND_PAYABLE_RECEIVED'], 25);
    expect(money.bySource(incoming: true)['ADVANCE'], isNull);
    expect(
        DayBookExpenseClassification.totals(
            money)[DayBookOutflowPurpose.refunds],
        30);
    expect(
        DayBookExpenseClassification.totals(
            money)[DayBookOutflowPurpose.operations],
        isNull);
  });

  test('bank reconciliation keeps valid legacy UPI and restores card',
      () async {
    final date = DateTime(2026, 6, 25, 12);
    final accountId = await _bankAccount(db);
    await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'B-OLD-BANK',
          billDate: drift.Value(date),
          paidAmount: const drift.Value(500),
          upiPaid: const drift.Value(200),
          cardPaid: const drift.Value(300),
        ));
    await db.into(db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'B-OLD',
            accountId: accountId,
            txnDate: date,
            type: 'CREDIT',
            category: 'SALE_PAYMENT',
            amount: const drift.Value(200),
            paymentMode: const drift.Value('UPI'),
            referenceId: const drift.Value('B-OLD-BANK'),
            referenceType: const drift.Value('BILL'),
          ),
        );

    expect(await bank.syncBillsToBank(accountId: accountId, date: date), 1);
    final rows = await db.select(db.bankTransactions).get();
    expect(rows.map((row) => row.amount).toSet(), {200.0, 300.0});
    expect(rows.where((row) => row.paymentMode == 'CARD').single.referenceId,
        'B-OLD-BANK#CARD');
  });

  test('cash reconciliation retires an inflated legacy receipt', () async {
    final date = DateTime(2026, 6, 25, 12);
    await _bill(db, 'B-LEGACY', date, paid: 300, cash: 100, upi: 200);
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'OLD-1',
          txnDate: date,
          type: 'INCOME',
          category: 'SALE',
          amount: const drift.Value(300),
          referenceId: const drift.Value('B-LEGACY'),
          referenceType: const drift.Value('BILL'),
          isAutoGenerated: const drift.Value(true),
        ));

    expect(await cash.syncBillsToIncome(date), 1);
    final rows = await db.select(db.cashTransactions).get();
    expect(rows, hasLength(2));
    expect(rows.where((row) => !row.isVoided).single.amount, 100);
    expect(rows.where((row) => row.isVoided).single.voidReason, isNotEmpty);
  });

  test('bank expense posts and voids both linked ledger records', () async {
    final accountId = await _bankAccount(db);
    final date = DateTime(2026, 6, 25, 12);
    expect(
      await expenses.saveExpense(
        category: ExpenseCategory.shopRent,
        amount: 250,
        paymentMode: PaymentMode.upi,
        bankAccountId: accountId,
        expenseDate: date,
      ),
      isTrue,
    );
    final source = (await db.select(db.cashTransactions).get()).single;
    final bankRow = (await db.select(db.bankTransactions).get()).single;
    expect(source.paymentMode, 'UPI');
    expect(bankRow.referenceId, source.txnId);
    expect(bankRow.amount, 250);
    expect(await cash.voidTransaction(source.id, 'Wrong expense'), isFalse);
    expect(await expenses.voidExpense(source.id, 'Wrong expense'), isTrue);
    expect(
        (await db.select(db.cashTransactions).get()).single.isVoided, isTrue);
    expect(
        (await db.select(db.bankTransactions).get()).single.isVoided, isTrue);
  });

  test('closed day blocks ledger insert and update at database level',
      () async {
    final date = DateTime(2026, 6, 25, 12);
    final cashId = await _cashRow(db, 'C-1', date, 'INCOME', 100);
    final closure = FinanceDayClosureRepository(db);
    expect(await closure.closeDay(date, closingCash: 100, closedBy: 'owner-1'),
        isTrue);
    expect(await closure.isClosed(date), isTrue);
    final close = await db.customSelect(
      'SELECT closed_by FROM finance_day_closures WHERE day_key = ?',
      variables: [const drift.Variable<String>('20260625')],
    ).getSingle();
    expect(close.read<String>('closed_by'), 'owner-1');
    await expectLater(
      _cashRow(db, 'C-2', date, 'INCOME', 50),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      (db.update(db.cashTransactions)..where((t) => t.id.equals(cashId)))
          .write(const CashTransactionsCompanion(isVoided: drift.Value(true))),
      throwsA(isA<Exception>()),
    );
    expect(
        (await db.select(db.cashTransactions).get()).single.isVoided, isFalse);
  });

  test('day close stores immutable cash, bank and metal evidence', () async {
    final date = DateTime(2026, 6, 25, 12);
    await _cashRow(db, 'C-SNAPSHOT', date, 'INCOME', 100);
    final bankId = await _bankAccount(db);
    await (db.update(db.bankAccounts)..where((row) => row.id.equals(bankId)))
        .write(BankAccountsCompanion(
      activeSince: drift.Value(DateTime(2026, 6, 24)),
    ));
    await db.into(db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'B-SNAPSHOT',
            accountId: bankId,
            txnDate: date,
            type: 'CREDIT',
            category: 'SALE_PAYMENT',
            amount: const drift.Value(250),
            paymentMode: const drift.Value('UPI'),
          ),
        );
    final closure = FinanceDayClosureRepository(db);
    expect(
      await closure.closeDay(date,
          closingCash: 100,
          physicalBank: 250,
          closedBy: 'owner-1',
          denominationCount: {'50': 2}),
      isTrue,
    );
    final snapshot = (await closure.fetchSnapshot(date))!;
    final payload = jsonDecode(snapshot.json) as Map<String, dynamic>;
    final money = payload['money'] as Map<String, dynamic>;
    expect(money['closingCash'], 100);
    expect(money['closingBank'], 250);
    expect(money['closingTotal'], 350);
    expect(payload['physicalBank'], 250);
    expect(payload['ownedMetal'], isA<Map<String, dynamic>>());
    expect(snapshot.sourceHash, hasLength(64));
    expect(await closure.closeDay(date, closingCash: 100, closedBy: 'owner-1'),
        isTrue);
    expect(
        (await closure.fetchSnapshot(date))!.sourceHash, snapshot.sourceHash);
    await expectLater(
      db.customUpdate(
          "UPDATE finance_day_closure_snapshots SET source_hash = 'changed' WHERE day_key = '20260625'"),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.into(db.bankAccounts).insert(BankAccountsCompanion.insert(
            accountName: 'Retroactive Account',
            bankName: 'SBI',
            accountNumber: '444455556666',
            openingBalance: const drift.Value(500),
            activeSince: drift.Value(DateTime(2026, 6, 24)),
          )),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      (db.delete(db.bankAccounts)..where((row) => row.id.equals(bankId))).go(),
      throwsA(isA<Exception>()),
    );
  });

  test('mismatched physical denomination count cannot close the day', () async {
    final date = DateTime(2026, 6, 26, 12);
    await _cashRow(db, 'C-COUNT', date, 'INCOME', 100);
    final closure = FinanceDayClosureRepository(db);
    await expectLater(
      closure.closeDay(date,
          closingCash: 100, closedBy: 'owner-1', denominationCount: {'50': 1}),
      throwsStateError,
    );
    expect(await closure.isClosed(date), isFalse);
  });

  test('bank closing mismatch cannot lock cash or bank ledgers', () async {
    final date = DateTime(2026, 6, 27, 12);
    final bankId = await _bankAccount(db);
    await (db.update(db.bankAccounts)..where((row) => row.id.equals(bankId)))
        .write(BankAccountsCompanion(
      activeSince: drift.Value(DateTime(2026, 6, 26)),
    ));
    await db.into(db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'B-MISMATCH',
            accountId: bankId,
            txnDate: date,
            type: 'CREDIT',
            category: 'SALE_PAYMENT',
            amount: const drift.Value(250),
            paymentMode: const drift.Value('UPI'),
          ),
        );
    final closure = FinanceDayClosureRepository(db);
    await expectLater(
      closure.closeDay(date,
          closingCash: 0, physicalBank: 200, closedBy: 'owner-1'),
      throwsStateError,
    );
    expect(await closure.isClosed(date), isFalse);
    expect(await closure.fetchSnapshot(date), isNull);
  });

  test('verified opening and day movements are saved as close evidence',
      () async {
    final date = DateTime(2026, 6, 28, 12);
    final closure = FinanceDayClosureRepository(db);
    await expectLater(
      closure.closeDay(date,
          closingCash: 0,
          physicalBank: 0,
          closedBy: 'owner-1',
          requireVerifiedOpening: true),
      throwsStateError,
    );
    await DayBookBalanceVerificationRepository(db).verify(
      date: date,
      expectedCash: 0,
      actualCash: 0,
      expectedBank: 0,
      actualBank: 0,
    );
    await _cashRow(db, 'C-VERIFIED-CLOSE', date, 'INCOME', 100);
    expect(
      await closure.closeDay(date,
          closingCash: 100,
          physicalBank: 0,
          closedBy: 'owner-1',
          requireVerifiedOpening: true),
      isTrue,
    );
    final snapshot = jsonDecode((await closure.fetchSnapshot(date))!.json)
        as Map<String, dynamic>;
    final opening = snapshot['verifiedOpening'] as Map<String, dynamic>;
    expect(opening['actualCash'], 0);
    expect(opening['closingCash'], 100);
    expect(opening['closingBank'], 0);
  });

  test('day closing rejects a stale or incorrect physical cash amount',
      () async {
    final date = DateTime(2026, 6, 26, 12);
    await _cashRow(db, 'C-CLOSE-1', date, 'INCOME', 125);
    final closure = FinanceDayClosureRepository(db);
    expect(await closure.closeDay(date, closingCash: 100, closedBy: 'owner-1'),
        isFalse);
    expect(await closure.isClosed(date), isFalse);
    expect(await closure.closeDay(date, closingCash: 125, closedBy: 'owner-1'),
        isTrue);
    expect(await closure.closeDay(date, closingCash: 125, closedBy: 'staff-2'),
        isFalse);
    expect(await closure.closeDay(date, closingCash: 100, closedBy: 'owner-1'),
        isFalse);
    expect(await closure.closeDay(date, closingCash: 125, closedBy: 'owner-1'),
        isTrue);
  });

  test('closed bank day freezes money but permits later reconciliation',
      () async {
    final date = DateTime(2026, 6, 25, 12);
    final accountId = await _bankAccount(db);
    final id = await db.into(db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'B-1',
            accountId: accountId,
            txnDate: date,
            type: 'CREDIT',
            category: 'SALE_PAYMENT',
            amount: const drift.Value(100),
          ),
        );
    await FinanceDayClosureRepository(db)
        .closeDay(date, closingCash: 0, closedBy: 'owner-1');
    await expectLater(
      (db.update(db.bankTransactions)..where((row) => row.id.equals(id)))
          .write(const BankTransactionsCompanion(amount: drift.Value(200))),
      throwsA(isA<Exception>()),
    );
    expect(
        await bank.markReconciled(id, note: 'Bank statement matched'), isTrue);
    final row = (await db.select(db.bankTransactions).get()).single;
    expect(row.amount, 100);
    expect(row.isReconciled, isTrue);
  });
}

Future<int> _cashRow(
    AppDatabase db, String id, DateTime date, String type, double amount,
    {String mode = 'CASH'}) {
  return db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
        txnId: id,
        txnDate: date,
        type: type,
        category: type == 'INCOME' ? 'SALE' : 'SHOP_RENT',
        amount: drift.Value(amount),
        paymentMode: drift.Value(mode),
      ));
}

Future<int> _bill(AppDatabase db, String number, DateTime date,
    {required double paid, double cash = 0, double upi = 0}) {
  return db.into(db.bills).insert(BillsCompanion.insert(
        billNo: number,
        billDate: drift.Value(date),
        paidAmount: drift.Value(paid),
        cashPaid: drift.Value(cash),
        upiPaid: drift.Value(upi),
      ));
}

Future<int> _bankAccount(AppDatabase db) {
  return db.into(db.bankAccounts).insert(BankAccountsCompanion.insert(
        accountName: 'Primary Current',
        bankName: 'HDFC Bank',
        accountNumber: '111122223333',
      ));
}
