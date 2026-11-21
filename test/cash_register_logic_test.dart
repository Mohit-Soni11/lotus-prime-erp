import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/dashboard/cash_register/cash_register_logic.dart';
import 'package:lotus_erp/repositories/reports/day_book_money_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('dashboard balances match Day Book cash plus bank', () async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1, 15);
    await db.into(db.shopProfiles).insert(
          ShopProfilesCompanion.insert(
              openingCashBalance: const drift.Value(500)),
        );
    await _insert(db, 'prior-income', yesterday, 'INCOME', 'CASH', 100);
    await _insert(db, 'prior-expense', yesterday, 'EXPENSE', 'CASH', 20);
    await _insert(db, 'today-income', now, 'INCOME', 'CASH', 250.25);
    await _insert(db, 'today-expense', now, 'EXPENSE', 'CASH', 35);
    await _insert(db, 'bank-income', now, 'INCOME', 'UPI', 1000);
    await _insert(db, 'tomorrow-income',
        DateTime(now.year, now.month, now.day + 1), 'INCOME', 'CASH', 1000);
    await _insert(db, 'void-income', now, 'INCOME', 'CASH', 1000,
        isVoided: true);
    final bankId = await db.into(db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Primary Bank',
            bankName: 'Test Bank',
            accountNumber: '100000001',
            activeSince: drift.Value(yesterday),
            openingBalance: const drift.Value(1200),
          ),
        );
    await _bank(db, bankId, 'prior-credit', yesterday, 'CREDIT', 100);
    await _bank(db, bankId, 'prior-debit', yesterday, 'DEBIT', 25);
    await _bank(db, bankId, 'today-credit', now, 'CREDIT', 500);
    await _bank(db, bankId, 'today-debit', now, 'DEBIT', 40);
    await _bank(db, bankId, 'void-credit', now, 'CREDIT', 1000, isVoided: true);

    final logic = CashRegisterLogic(db: db);
    addTearDown(logic.dispose);
    logic.init();
    final data =
        await logic.dataStream.first.timeout(const Duration(seconds: 2));

    final money = DayBookMoneyRepository(db);
    final flow = await money.fetch(now,
        await money.fetchOpeningCash(DateTime(now.year, now.month, now.day)));
    expect(data.openingBalance, flow.openingTotal);
    expect(data.closingBalance, flow.closingTotal);
    expect(data.openingBalance, 1855);
    expect(data.moneyIn, 750.25);
    expect(data.moneyOut, 75);
    expect(data.closingBalance, 2530.25);
  });

  test('cash register updates when cash ledger changes', () async {
    final logic = CashRegisterLogic(db: db);
    addTearDown(logic.dispose);
    logic.init();
    await logic.dataStream.first.timeout(const Duration(seconds: 2));

    final next = logic.dataStream
        .firstWhere(
          (data) => data.moneyIn == 75,
        )
        .timeout(const Duration(seconds: 2));
    await _insert(db, 'live-income', DateTime.now(), 'INCOME', 'CASH', 75);

    expect((await next).closingBalance, 75);
  });

  test('dashboard closing balance refreshes after bank receipt', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final bankId = await db.into(db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Live Bank',
            bankName: 'Test Bank',
            accountNumber: '100000002',
            activeSince: drift.Value(yesterday),
            openingBalance: const drift.Value(300),
          ),
        );
    final logic = CashRegisterLogic(db: db);
    addTearDown(logic.dispose);
    logic.init();
    final initial =
        await logic.dataStream.first.timeout(const Duration(seconds: 2));
    expect(initial.openingBalance, 300);

    final updated = logic.dataStream
        .firstWhere(
          (data) => data.closingBalance == 425,
        )
        .timeout(const Duration(seconds: 2));
    await _bank(db, bankId, 'live-bank-receipt', DateTime.now(), 'CREDIT', 125);

    expect((await updated).moneyIn, 125);
  });
}

Future<void> _insert(
  AppDatabase db,
  String id,
  DateTime date,
  String type,
  String mode,
  double amount, {
  bool isVoided = false,
}) async {
  await db.into(db.cashTransactions).insert(
        CashTransactionsCompanion.insert(
          txnId: id,
          txnDate: date,
          type: type,
          category: 'TEST',
          paymentMode: drift.Value(mode),
          amount: drift.Value(amount),
          isVoided: drift.Value(isVoided),
        ),
      );
}

Future<void> _bank(
  AppDatabase db,
  int accountId,
  String id,
  DateTime date,
  String type,
  double amount, {
  bool isVoided = false,
}) async {
  await db.into(db.bankTransactions).insert(
        BankTransactionsCompanion.insert(
          txnId: id,
          accountId: drift.Value(accountId),
          txnDate: date,
          type: type,
          category: 'TEST',
          paymentMode: const drift.Value('UPI'),
          amount: drift.Value(amount),
          isVoided: drift.Value(isVoided),
        ),
      );
}
