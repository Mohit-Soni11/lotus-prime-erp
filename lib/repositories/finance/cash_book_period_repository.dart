import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/finance/cash_book/cash_book_period_summary.dart';

class CashBookPeriodRepository {
  CashBookPeriodRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  final AppDatabase _db;

  Stream<CashBookHistorySnapshot> watchHistory() {
    return _db
        .customSelect(
          '''SELECT MIN(txn_date) AS first_date, MAX(txn_date) AS last_date
         FROM cash_transactions
         WHERE is_voided = 0 AND payment_mode = 'CASH'
           AND type IN ('INCOME', 'EXPENSE')''',
          readsFrom: {_db.cashTransactions, _db.shopProfiles},
        )
        .watchSingle()
        .asyncMap((bounds) async {
          final first = bounds.data['first_date'] as int?;
          final last = bounds.data['last_date'] as int?;
          if (first == null || last == null) {
            return const CashBookHistorySnapshot.empty();
          }

          final firstDate = DateTime.fromMillisecondsSinceEpoch(first * 1000);
          final lastDate = DateTime.fromMillisecondsSinceEpoch(last * 1000);
          final periods = <DateTime>[];
          for (var date = DateTime(firstDate.year, firstDate.month);
              !date.isAfter(DateTime(lastDate.year, lastDate.month));
              date = DateTime(date.year, date.month + 1)) {
            periods.add(date);
          }

          final shop =
              await (_db.select(_db.shopProfiles)..limit(1)).getSingleOrNull();
          var runningBalance = shop?.openingCashBalance ?? 0.0;
          final months = <CashBookPeriodSummary>[];
          final years = <CashBookPeriodSummary>[];

          // Keep batches below SQLite's older 999-parameter limit.
          for (var start = 0; start < periods.length; start += 100) {
            final batch = periods.skip(start).take(100).toList();
            final variables = <Variable>[];
            final values = <String>[];
            for (final period in batch) {
              values.add('(?, ?, ?, ?)');
              variables.addAll([
                Variable<int>(period.year),
                Variable<int>(period.month),
                Variable.withDateTime(period),
                Variable.withDateTime(DateTime(period.year, period.month + 1)),
              ]);
            }
            final rows = await _db
                .customSelect(
                  '''WITH periods(year, month, start_at, end_at) AS
             (VALUES ${values.join(', ')})
             SELECT periods.year AS year, periods.month AS month,
               SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0 END) AS cash_in,
               SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0 END) AS cash_out,
               COUNT(*) AS transaction_count
             FROM periods
             JOIN cash_transactions
               ON txn_date >= periods.start_at AND txn_date < periods.end_at
             WHERE is_voided = 0 AND payment_mode = 'CASH'
               AND type IN ('INCOME', 'EXPENSE')
             GROUP BY periods.year, periods.month
             ORDER BY periods.year, periods.month''',
                  variables: variables,
                  readsFrom: {_db.cashTransactions},
                )
                .get();

            for (final row in rows) {
              final year = row.read<int>('year');
              final month = row.read<int>('month');
              final cashIn = row.read<double>('cash_in');
              final cashOut = row.read<double>('cash_out');
              final count = row.read<int>('transaction_count');
              final opening = runningBalance;
              runningBalance += cashIn - cashOut;
              months.add(CashBookPeriodSummary(
                year: year,
                month: month,
                openingBalance: opening,
                cashIn: cashIn,
                cashOut: cashOut,
                closingBalance: runningBalance,
                transactionCount: count,
              ));

              if (years.isEmpty || years.last.year != year) {
                years.add(CashBookPeriodSummary(
                  year: year,
                  month: null,
                  openingBalance: opening,
                  cashIn: cashIn,
                  cashOut: cashOut,
                  closingBalance: runningBalance,
                  transactionCount: count,
                ));
              } else {
                final previous = years.removeLast();
                years.add(CashBookPeriodSummary(
                  year: year,
                  month: null,
                  openingBalance: previous.openingBalance,
                  cashIn: previous.cashIn + cashIn,
                  cashOut: previous.cashOut + cashOut,
                  closingBalance: runningBalance,
                  transactionCount: previous.transactionCount + count,
                ));
              }
            }
          }

          return CashBookHistorySnapshot(
            months: List.unmodifiable(months),
            years: List.unmodifiable(years),
          );
        });
  }
}
