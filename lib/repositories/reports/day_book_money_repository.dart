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

  Future<double> fetchOpeningCash(DateTime date) async {
    final profile = await _db.select(_db.shopProfiles).getSingleOrNull();
    final prior = await _db.customSelect(
      '''SELECT COALESCE(SUM(CASE WHEN type = 'INCOME' THEN amount
          WHEN type = 'EXPENSE' THEN -amount ELSE 0 END), 0) AS movement
         FROM cash_transactions
         WHERE is_voided = 0 AND payment_mode = 'CASH' AND txn_date < ?''',
      variables: [Variable.withDateTime(date)],
      readsFrom: {_db.cashTransactions},
    ).getSingle();
    return (profile?.openingCashBalance ?? 0) + prior.read<double>('movement');
  }

  Future<DayBookMoneyFlow> fetch(DateTime date, double openingCash) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);

    final accounts = await _db.select(_db.bankAccounts).get();
    final accountNames = {
      for (final account in accounts) account.id: account.accountName
    };
    final openingAccounts = accounts
        .where((account) => !DateTime(account.activeSince.year,
                account.activeSince.month, account.activeSince.day)
            .isAfter(start))
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
            category: _categoryFor(
                row.category, row.referenceType, row.type == 'INCOME'),
            paymentMode: 'CASH',
            transactionId: row.txnId,
            referenceId: row.referenceId,
            referenceType: row.referenceType,
            isInternalTransfer: _internalCategories.contains(row.category),
          ),
      for (final row in bankRows)
        if (row.type == 'CREDIT' || row.type == 'DEBIT')
          DayBookMoneyEntry(
            date: row.txnDate,
            amount: row.amount,
            incoming: row.type == 'CREDIT',
            isCash: false,
            category: _categoryFor(
                row.category, row.referenceType, row.type == 'CREDIT'),
            paymentMode: row.paymentMode,
            transactionId: row.txnId,
            accountName: accountNames[row.accountId],
            referenceId: row.referenceId,
            referenceType: row.referenceType,
            isInternalTransfer: _internalCategories.contains(row.category),
            chequeNumber: row.chequeNumber,
            chequeStatus: row.chequeStatus,
            valueDate: row.valueDate,
            isReconciled: row.isReconciled,
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return DayBookMoneyFlow(
      openingCash: openingCash,
      openingBank: openingAccounts + priorBankMovement.read<double>('movement'),
      entries: entries,
      bankAccountCount: accounts.length,
    );
  }

  static String _categoryFor(
      String category, String? referenceType, bool incoming) {
    switch (referenceType?.toUpperCase()) {
      case 'GIRVI' when category.toUpperCase() == 'DUE_COLLECTION':
        return 'GIRVI_RETURN';
      case 'CUSTOMER_CHANGE':
        return incoming ? 'CHANGE_RECEIVED' : 'CHANGE_RETURNED';
      case 'CUSTOMER_REFUND_PAYABLE':
        return incoming ? 'REFUND_PAYABLE_RECEIVED' : category;
      default:
        return category;
    }
  }
}
