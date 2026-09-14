import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/transactions/domain/services/finance_transaction_numbering.dart';

void main() {
  late AppDatabase db;
  late FinanceTransactionNumbering numbering;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    numbering = FinanceTransactionNumbering(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('cash transaction numbering uses the highest suffix, not row count',
      () async {
    final year = DateTime.now().year;
    await db.into(db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: 'TXN-$year-0007',
            txnDate: DateTime.now(),
            type: 'INCOME',
            category: 'DUE_COLLECTION',
            amount: const Value(100),
          ),
        );

    expect(await numbering.nextCashTransactionId(), 'TXN-$year-0008');
  });

  test('bank transaction numbering uses the highest suffix, not row count',
      () async {
    final year = DateTime.now().year;
    final accountId = await db.into(db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Primary Account',
            bankName: 'Bank',
            accountNumber: '1234567890',
          ),
        );
    await db.into(db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'BTXN-$year-0012',
            accountId: accountId,
            txnDate: DateTime.now(),
            type: 'CREDIT',
            category: 'DUE_COLLECTION',
            amount: const Value(100),
          ),
        );

    expect(await numbering.nextBankTransactionId(), 'BTXN-$year-0013');
  });
}
