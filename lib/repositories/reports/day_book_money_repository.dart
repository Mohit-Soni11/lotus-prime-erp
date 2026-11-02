import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/reports/day_book/day_book_money_flow.dart';

class DayBookMoneyRepository {
  const DayBookMoneyRepository(this._db);

  final AppDatabase _db;

  static const _internalCategories = {
    'CASH_DEPOSIT',
    'CASH_WITHDRAWAL',
    'TRANSFER_IN',
    'TRANSFER_OUT',
  };

  Future<DayBookMoneyFlow> fetch(DateTime date, double openingCash) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);

    final accounts = await _db.select(_db.bankAccounts).get();
    final accountNames = {
      for (final account in accounts) account.id: account.accountName
    };
    final openingAccounts = accounts
        .where((account) => !account.activeSince.isAfter(start))
        .fold(0.0, (double total, account) => total + account.openingBalance);

    final priorBankMovement = await _db.customSelect(
      '''SELECT COALESCE(SUM(CASE WHEN type = 'CREDIT' THEN amount
                 WHEN type = 'DEBIT' THEN -amount ELSE 0 END), 0) AS movement
         FROM bank_transactions
         WHERE is_voided = 0 AND txn_date < ?''',
      variables: [Variable.withDateTime(start)],
      readsFrom: {_db.bankTransactions},
    ).getSingle();

    final cashRows = await (_db.select(_db.cashTransactions)
          ..where((row) =>
              row.isVoided.equals(false) &
              row.paymentMode.equals('CASH') &
              row.txnDate.isBiggerOrEqualValue(start) &
              row.txnDate.isSmallerThanValue(end)))
        .get();
    final bankRows = await (_db.select(_db.bankTransactions)
          ..where((row) =>
              row.isVoided.equals(false) &
              row.txnDate.isBiggerOrEqualValue(start) &
              row.txnDate.isSmallerThanValue(end)))
        .get();

    final entries = <DayBookMoneyEntry>[
      for (final row in cashRows)
        if (row.type == 'INCOME' || row.type == 'EXPENSE')
          DayBookMoneyEntry(
            date: row.txnDate,
            amount: row.amount,
            incoming: row.type == 'INCOME',
            isCash: true,
            category: row.category,
            paymentMode: 'CASH',
            transactionId: row.txnId,
            referenceId: row.referenceId,
            isInternalTransfer: _internalCategories.contains(row.category),
          ),
      for (final row in bankRows)
        if (row.type == 'CREDIT' || row.type == 'DEBIT')
          DayBookMoneyEntry(
            date: row.txnDate,
            amount: row.amount,
            incoming: row.type == 'CREDIT',
            isCash: false,
            category: row.category,
            paymentMode: row.paymentMode,
            transactionId: row.txnId,
            accountName: accountNames[row.accountId],
            referenceId: row.referenceId,
            isInternalTransfer: _internalCategories.contains(row.category),
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return DayBookMoneyFlow(
      openingCash: openingCash,
      openingBank: openingAccounts + priorBankMovement.read<double>('movement'),
      entries: entries,
    );
  }
}
