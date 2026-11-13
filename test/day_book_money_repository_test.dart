import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/reports/day_book_money_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('later cheque clearing stays pending on its original Day Book date',
      () async {
    final day = DateTime(2026, 6, 25, 12);
    final accountId = await db.into(db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Cheque Bank',
            bankName: 'Bank',
            accountNumber: 'CHEQUE-AS-OF',
          ),
        );
    await db.into(db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'CHEQUE-LATE-CLEAR',
            accountId: drift.Value(accountId),
            txnDate: day,
            type: 'CREDIT',
            category: 'SALE_PAYMENT',
            amount: const drift.Value(500),
            paymentMode: const drift.Value('CHEQUE'),
            chequeStatus: const drift.Value('CLEARED'),
            valueDate: drift.Value(day.add(const Duration(days: 2))),
          ),
        );
    final originalDay = await DayBookMoneyRepository(db).fetch(day, 0);
    expect(originalDay.closingBank, 500);
    expect(originalDay.unclearedChequeIn, 500);
    expect(originalDay.byBankReconciliation(incoming: true),
        {'Uncleared Cheque': 500});
  });

  test('posted money flow separates sources, modes, balances and transfers',
      () async {
    final date = DateTime(2026, 6, 25, 12);
    final accountId = await db.into(db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Current Account',
            bankName: 'Bank',
            accountNumber: 'DAY-BOOK-TEST-1',
            openingBalance: const drift.Value(1000),
            activeSince: drift.Value(DateTime(2026, 1)),
          ),
        );

    Future<void> cash(String id, String type, String category, double amount,
        {String mode = 'CASH', bool voided = false}) async {
      await db.into(db.cashTransactions).insert(
            CashTransactionsCompanion.insert(
              txnId: id,
              txnDate: date,
              type: type,
              category: category,
              amount: drift.Value(amount),
              paymentMode: drift.Value(mode),
              isVoided: drift.Value(voided),
            ),
          );
    }

    Future<void> bank(String id, String type, String category, double amount,
        {String mode = 'UPI', bool voided = false}) async {
      await db.into(db.bankTransactions).insert(
            BankTransactionsCompanion.insert(
              txnId: id,
              accountId: drift.Value(accountId),
              txnDate: date,
              type: type,
              category: category,
              amount: drift.Value(amount),
              paymentMode: drift.Value(mode),
              isVoided: drift.Value(voided),
            ),
          );
    }

    await cash('C-SALE', 'INCOME', 'SALE', 100);
    await bank('B-SALE', 'CREDIT', 'SALE_PAYMENT', 500);
    await cash('C-RENT', 'EXPENSE', 'SHOP_RENT', 20);
    await cash('C-SHADOW', 'EXPENSE', 'STAFF_SALARY', 40, mode: 'NEFT');
    await bank('B-SALARY', 'DEBIT', 'STAFF_SALARY', 40, mode: 'NEFT');
    await cash('C-TRANSFER', 'EXPENSE', 'CASH_DEPOSIT', 30);
    await bank('B-TRANSFER', 'CREDIT', 'CASH_DEPOSIT', 30,
        mode: 'CASH_DEPOSIT');
    await bank('B-VOID', 'CREDIT', 'SALE_PAYMENT', 999, voided: true);

    final flow = await DayBookMoneyRepository(db).fetch(date, 100);

    expect(flow.openingTotal, 1100);
    expect(flow.moneyIn, 600);
    expect(flow.moneyOut, 60);
    expect(flow.cashIn, 100);
    expect(flow.cashOut, 50);
    expect(flow.bankIn, 530);
    expect(flow.bankOut, 40);
    expect(flow.closingCash, 150);
    expect(flow.closingBank, 1490);
    expect(flow.closingTotal, 1640);
    expect(flow.internalIn, 30);
    expect(flow.internalOut, 30);
    expect(flow.bySource(incoming: true), {
      'SALE': 600,
    });
    expect(flow.byMode(incoming: false), {'CASH': 20, 'NEFT': 40});
    expect(flow.entries.length, 6);
  });

  test('UPI, card and bank transfer modes affect bank, not physical cash',
      () async {
    final date = DateTime(2026, 11, 4, 12);
    final accountId = await db.into(db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Current Account',
            bankName: 'Bank',
            accountNumber: 'DAY-BOOK-MODES',
          ),
        );
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'CASH-1',
          txnDate: date,
          type: 'INCOME',
          category: 'SALE',
          amount: const drift.Value(100),
          paymentMode: const drift.Value('CASH'),
        ));
    for (final (index, mode)
        in ['UPI', 'CARD', 'NEFT', 'RTGS', 'IMPS', 'CHEQUE'].indexed) {
      await db
          .into(db.cashTransactions)
          .insert(CashTransactionsCompanion.insert(
            txnId: 'SHADOW-$index',
            txnDate: date,
            type: 'INCOME',
            category: 'SALE',
            amount: const drift.Value(50),
            paymentMode: drift.Value(mode),
          ));
      await db
          .into(db.bankTransactions)
          .insert(BankTransactionsCompanion.insert(
            txnId: 'BANK-$index',
            accountId: drift.Value(accountId),
            txnDate: date,
            type: 'CREDIT',
            category: 'SALE_PAYMENT',
            amount: const drift.Value(50),
            paymentMode: drift.Value(mode),
          ));
    }

    final flow = await DayBookMoneyRepository(db).fetch(date, 0);
    expect(flow.cashIn, 100);
    expect(flow.bankIn, 300);
    expect(flow.moneyIn, 400);
    expect(flow.byMode(incoming: true), {
      'CASH': 100,
      'UPI': 50,
      'CARD': 50,
      'NEFT': 50,
      'RTGS': 50,
      'IMPS': 50,
      'CHEQUE': 50,
    });
  });

  test('previous digital invoice receipt carries into bank closing only',
      () async {
    final previousDay = DateTime(2026, 11, 6, 14);
    final accountId = await db.into(db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Main Bank',
            bankName: 'Test Bank',
            accountNumber: 'PREVIOUS-DAY-MODES',
            openingBalance: const drift.Value(25),
            activeSince: drift.Value(DateTime(2026, 11, 1)),
          ),
        );
    await db.into(db.shopProfiles).insert(ShopProfilesCompanion.insert(
          openingCashBalance: const drift.Value(100),
        ));
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'INVOICE-CASH',
          txnDate: previousDay,
          type: 'INCOME',
          category: 'SALE',
          amount: const drift.Value(40),
          paymentMode: const drift.Value('CASH'),
          referenceType: const drift.Value('BILL'),
          referenceId: const drift.Value('INV-1#CASH'),
        ));
    await db.into(db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'INVOICE-UPI',
            accountId: drift.Value(accountId),
            txnDate: previousDay,
            type: 'CREDIT',
            category: 'SALE_PAYMENT',
            amount: const drift.Value(60),
            paymentMode: const drift.Value('UPI'),
            referenceType: const drift.Value('BILL'),
            referenceId: const drift.Value('INV-1#UPI'),
          ),
        );

    final today = DateTime(2026, 11, 7);
    final openingCash =
        await DayBookMoneyRepository(db).fetchOpeningCash(today);
    final flow = await DayBookMoneyRepository(db).fetch(today, openingCash);
    expect(flow.openingCash, 140);
    expect(flow.openingBank, 85);
    expect(flow.openingTotal, 225);
  });
}
