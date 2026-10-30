import 'package:drift/drift.dart';

import '../../../../database/db/app_database.dart';

/// Reads the recorded receipt date, rather than a mutable bill update date.
class SalesInvoiceDuePaymentDateRepository {
  const SalesInvoiceDuePaymentDateRepository(this.database);

  final AppDatabase database;

  Future<DateTime?> latestForBill(String billNo) async {
    final referencePrefix = '$billNo#DUE#';
    final cash = await (database.select(database.cashTransactions)
          ..where((row) =>
              row.category.equals('DUE_COLLECTION') &
              row.referenceType.equals('BILL') &
              row.isVoided.equals(false) &
              row.referenceId.like('$referencePrefix%'))
          ..orderBy([(row) => OrderingTerm.desc(row.txnDate)])
          ..limit(1))
        .getSingleOrNull();
    final bank = await (database.select(database.bankTransactions)
          ..where((row) =>
              row.category.equals('DUE_COLLECTION') &
              row.referenceType.equals('BILL') &
              row.isVoided.equals(false) &
              row.referenceId.like('$referencePrefix%'))
          ..orderBy([(row) => OrderingTerm.desc(row.txnDate)])
          ..limit(1))
        .getSingleOrNull();

    DateTime? latest;
    void consider(DateTime date) {
      if (latest == null || date.isAfter(latest!)) latest = date;
    }

    if (cash?.referenceId?.startsWith(referencePrefix) == true) {
      consider(cash!.txnDate);
    }
    if (bank?.referenceId?.startsWith(referencePrefix) == true) {
      consider(bank!.txnDate);
    }
    return latest;
  }
}
