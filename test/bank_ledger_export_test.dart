import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/finance/bank_book/bank_book_export_service.dart';
import 'package:lotus_erp/repositories/finance/bank_book_repository.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<int> account(String number, DateTime active, double opening) =>
      db.into(db.bankAccounts).insert(BankAccountsCompanion.insert(
            accountName: 'Main Bank',
            bankName: 'Bank',
            accountNumber: number,
            activeSince: drift.Value(active),
            openingBalance: drift.Value(opening),
          ));

  Future<void> post(
          int accountId, String id, DateTime date, String type, double amount,
          {bool voided = false}) =>
      db.into(db.bankTransactions).insert(BankTransactionsCompanion.insert(
            txnId: id,
            accountId: drift.Value(accountId),
            txnDate: date,
            type: type,
            category: type == 'CREDIT' ? 'SALE_PAYMENT' : 'SHOP_RENT',
            amount: drift.Value(amount),
            paymentMode: const drift.Value('UPI'),
            isVoided: drift.Value(voided),
          ));

  test('opening carries prior bank movements and export reconciles', () async {
    final id = await account('BANK-LEDGER-1', DateTime(2026, 1), 500);
    await post(id, 'FEB-CREDIT', DateTime(2026, 2, 20), 'CREDIT', 100);
    await post(id, 'MAR-CREDIT', DateTime(2026, 3, 5), 'CREDIT', 200);
    await post(id, 'MAR-DEBIT', DateTime(2026, 3, 8), 'DEBIT', 50);
    await post(id, 'MAR-VOID', DateTime(2026, 3, 9), 'CREDIT', 999,
        voided: true);
    await post(id, 'APR-CREDIT', DateTime(2026, 4, 1), 'CREDIT', 300);

    final repository = BankBookRepository(db: db);
    final start = DateTime(2026, 3);
    final end = DateTime(2026, 3, 31, 23, 59, 59);
    final summary =
        await repository.computeSummary(accountId: id, from: start, to: end);
    final transactions =
        await repository.fetchTransactions(accountId: id, from: start, to: end);
    final data = BankBookExportData(
      account: (await repository.fetchAccounts()).single,
      periodStart: start,
      periodEnd: end,
      summary: summary,
      transactions: transactions,
    );

    expect(summary.openingBalance, 600);
    expect(summary.totalCredit, 200);
    expect(summary.totalDebit, 50);
    expect(summary.closingBalance, 750);
    expect(data.lines.map((line) => line.balance), [800, 750]);
    final csv = BankBookExportService.buildCsv(data);
    expect(csv, contains('MAR-CREDIT'));
    expect(csv, contains('MAR-DEBIT'));
    expect(csv, isNot(contains('MAR-VOID')));
    expect(csv, contains('Period totals'));
    final pdf = await BankBookExportService.buildPdf(data);
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  });

  test('new account opening inside month has its own ledger line', () async {
    final id = await account('BANK-LEDGER-2', DateTime(2026, 3, 10), 300);
    await post(id, 'NEW-CREDIT', DateTime(2026, 3, 12), 'CREDIT', 50);
    final repository = BankBookRepository(db: db);
    final start = DateTime(2026, 3);
    final end = DateTime(2026, 3, 31, 23, 59, 59);
    final summary =
        await repository.computeSummary(accountId: id, from: start, to: end);
    final data = BankBookExportData(
      account: (await repository.fetchAccounts()).single,
      periodStart: start,
      periodEnd: end,
      summary: summary,
      transactions: await repository.fetchTransactions(
          accountId: id, from: start, to: end),
    );
    expect(summary.openingBalance, 0);
    expect(summary.openingAdjustment, 300);
    expect(summary.totalCredit, 50);
    expect(summary.closingBalance, 350);
    expect(data.lines.map((line) => line.balance), [300, 350]);
    expect(data.lines.first.transaction, isNull);
    expect(BankBookExportService.buildCsv(data),
        contains('New account opening balance'));
  });
}
