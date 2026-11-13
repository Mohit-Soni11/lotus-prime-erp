import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../database/db/app_database.dart';
import '../../features/finance/transactions/domain/services/finance_transaction_numbering.dart';
import '../../models/finance/cash_book/cash_book_enums.dart';
import '../../models/reports/day_book/day_book_balance_verification.dart';
import 'day_book_balance_adjustment_posting.dart';
import 'day_book_money_repository.dart';

class DayBookBalanceVerificationRepository {
  const DayBookBalanceVerificationRepository(this._db);

  final AppDatabase _db;

  Future<DayBookBalanceVerification?> fetch(DateTime date) async {
    final row = await _db.customSelect(
      'SELECT * FROM day_book_balance_verifications WHERE day_key = ?',
      variables: [Variable.withString(_dayKey(date))],
    ).getSingleOrNull();
    return row == null ? null : _fromRow(date, row);
  }

  Future<DayBookBalanceVerification> verify({
    required DateTime date,
    required double expectedCash,
    required double actualCash,
    required double expectedBank,
    required double actualBank,
    ExpenseCategory? cashExpenseCategory,
    String? cashReason,
    String? bankReason,
    String? verifiedBy,
  }) async {
    for (final amount in [expectedCash, actualCash, expectedBank, actualBank]) {
      if (!amount.isFinite ||
          (amount * 100 - (amount * 100).round()).abs() > 0.000001) {
        throw ArgumentError('Balances must have at most two decimal places.');
      }
    }
    if (actualCash < 0) {
      throw ArgumentError('Physical cash cannot be negative.');
    }
    final cashVariance = _rounded(actualCash - expectedCash);
    final bankVariance = _rounded(actualBank - expectedBank);
    final netShortage = _rounded(-cashVariance - bankVariance);
    if ((cashVariance < -0.005 && bankVariance > 0.005) ||
        (cashVariance > 0.005 && bankVariance < -0.005)) {
      throw StateError(
          'Cash and bank differ in opposite directions. Record the transfer or correct the payment mode before verification.');
    }
    if (netShortage >= 0.01 &&
        (cashExpenseCategory == null ||
            cashExpenseCategory == ExpenseCategory.purchasePayment ||
            cashExpenseCategory == ExpenseCategory.girviGiven)) {
      throw ArgumentError('Select a Shop or Personal expense category.');
    }
    if (netShortage >= 0.01 && (cashReason?.trim().isEmpty ?? true)) {
      throw ArgumentError('Write a reason for the expense adjustment.');
    }
    if (netShortage < -0.005 &&
        (cashVariance > 0.005 || bankVariance > 0.005) &&
        (cashReason?.trim().isEmpty ?? true)) {
      throw ArgumentError('Explain the excess before saving.');
    }

    return _db.transaction(() async {
      final key = _dayKey(date);
      final existing = await fetch(date);
      if (existing != null) {
        throw StateError('Balance was already verified for this day.');
      }
      final closed = await _db.customSelect(
        'SELECT 1 FROM finance_day_closures WHERE day_key = ? LIMIT 1',
        variables: [Variable.withString(key)],
      ).getSingleOrNull();
      if (closed != null) {
        throw StateError('This day is closed.');
      }

      final money = DayBookMoneyRepository(_db);
      final start = DateTime(date.year, date.month, date.day);
      final openingCash = await money.fetchOpeningCash(start);
      final current = await money.fetch(date, openingCash);
      if (current.bankAccountCount == 0 &&
          current.openingBank.abs() < 0.01 &&
          actualBank.abs() >= 0.01) {
        throw StateError(
            'Add a bank account in Bank Book before verifying a non-zero bank balance.');
      }
      if ((_rounded(current.openingCash - expectedCash)).abs() >= 0.01 ||
          (_rounded(current.openingBank - expectedBank)).abs() >= 0.01) {
        throw StateError(
            'Recorded balances changed. Refresh and verify again.');
      }

      int? bankAccountId;
      if (bankVariance < -0.005) {
        final accounts = await (_db.select(_db.bankAccounts)
              ..where((account) => account.isActive.equals(true)))
            .get();
        final eligible = accounts.where((account) => !DateTime(
                account.activeSince.year,
                account.activeSince.month,
                account.activeSince.day)
            .isAfter(start));
        if (eligible.length > 1) {
          throw StateError(
              'Select exactly one active bank account before posting a bank balance adjustment.');
        }
        bankAccountId = eligible.isEmpty ? null : eligible.single.id;
      }

      String? adjustmentId;
      if (netShortage >= 0.01) {
        final now = DateTime.now();
        final postingDate = DateTime(
            date.year, date.month, date.day, now.hour, now.minute, now.second);
        adjustmentId = await DayBookBalanceAdjustmentPosting(_db).postShortage(
          date: postingDate,
          dayKey: key,
          cashAmount: cashVariance < 0 ? -cashVariance : 0,
          bankAmount: bankVariance < 0 ? -bankVariance : 0,
          category: cashExpenseCategory!,
          note: cashReason!.trim(),
          bankAccountId: bankAccountId,
        );
      } else if (cashVariance > 0.005) {
        final now = DateTime.now();
        final postingDate = DateTime(
            date.year, date.month, date.day, now.hour, now.minute, now.second);
        adjustmentId =
            await FinanceTransactionNumbering(_db).nextCashTransactionId();
        await _db.into(_db.cashTransactions).insert(
              CashTransactionsCompanion.insert(
                txnId: adjustmentId,
                txnDate: postingDate,
                type: CashTransactionType.income.dbValue,
                category: IncomeCategory.miscIncome.dbValue,
                amount: Value(cashVariance),
                paymentMode: const Value('CASH'),
                customLabel: const Value('Cash surplus'),
                description: Value(cashReason!.trim()),
                referenceId: Value('DAYBAL-$key'),
                referenceType: const Value('DAY_BOOK_BALANCE'),
                isAutoGenerated: const Value(true),
                isVoided: const Value(false),
              ),
            );
      }

      final verifiedAt = DateTime.now();
      await _db.customInsert(
        '''INSERT INTO day_book_balance_verifications
           (day_key, verified_at, expected_cash, actual_cash, cash_variance,
            expected_bank, actual_bank, bank_variance, cash_category,
            cash_reason, bank_reason, cash_adjustment_txn_id, verified_by)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        variables: [
          Variable.withString(key),
          Variable.withInt(verifiedAt.millisecondsSinceEpoch),
          Variable.withReal(expectedCash),
          Variable.withReal(actualCash),
          Variable.withReal(cashVariance),
          Variable.withReal(expectedBank),
          Variable.withReal(actualBank),
          Variable.withReal(bankVariance),
          Variable<String>(
              netShortage >= 0.01 ? cashExpenseCategory?.dbValue : null),
          Variable<String>(cashReason?.trim()),
          Variable<String>(bankVariance > 0.005 ? bankReason?.trim() : null),
          Variable<String>(adjustmentId),
          Variable<String>(verifiedBy?.trim()),
        ],
      );
      return DayBookBalanceVerification(
        date: date,
        verifiedAt: verifiedAt,
        expectedCash: expectedCash,
        actualCash: actualCash,
        cashVariance: cashVariance,
        expectedBank: expectedBank,
        actualBank: actualBank,
        bankVariance: bankVariance,
        cashCategory: netShortage >= 0.01 ? cashExpenseCategory?.dbValue : null,
        cashReason: cashReason?.trim(),
        bankReason: bankVariance > 0.005 ? bankReason?.trim() : null,
        cashAdjustmentTransactionId: adjustmentId,
        verifiedBy: verifiedBy?.trim(),
      );
    });
  }

  static DayBookBalanceVerification _fromRow(DateTime date, QueryRow row) =>
      DayBookBalanceVerification(
        date: date,
        verifiedAt:
            DateTime.fromMillisecondsSinceEpoch(row.read<int>('verified_at')),
        expectedCash: row.read<double>('expected_cash'),
        actualCash: row.read<double>('actual_cash'),
        cashVariance: row.read<double>('cash_variance'),
        expectedBank: row.read<double>('expected_bank'),
        actualBank: row.read<double>('actual_bank'),
        bankVariance: row.read<double>('bank_variance'),
        cashCategory: row.readNullable<String>('cash_category'),
        cashReason: row.readNullable<String>('cash_reason'),
        bankReason: row.readNullable<String>('bank_reason'),
        cashAdjustmentTransactionId:
            row.readNullable<String>('cash_adjustment_txn_id'),
        verifiedBy: row.readNullable<String>('verified_by'),
      );

  static String _dayKey(DateTime date) => DateFormat('yyyyMMdd').format(date);
  static double _rounded(double value) => (value * 100).roundToDouble() / 100;
}
