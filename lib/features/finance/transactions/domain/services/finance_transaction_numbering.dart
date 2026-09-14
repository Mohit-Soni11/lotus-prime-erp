import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';

enum FinanceTransactionLedger {
  cash(
    tableName: 'cash_transactions',
    prefix: 'TXN',
  ),
  bank(
    tableName: 'bank_transactions',
    prefix: 'BTXN',
  );

  final String tableName;
  final String prefix;

  const FinanceTransactionLedger({
    required this.tableName,
    required this.prefix,
  });
}

class FinanceTransactionNumbering {
  final AppDatabase _db;

  const FinanceTransactionNumbering(this._db);

  Future<String> nextCashTransactionId({int offset = 0}) {
    return _nextTransactionId(FinanceTransactionLedger.cash, offset: offset);
  }

  Future<String> nextBankTransactionId({int offset = 0}) {
    return _nextTransactionId(FinanceTransactionLedger.bank, offset: offset);
  }

  Future<String> _nextTransactionId(
    FinanceTransactionLedger ledger, {
    required int offset,
  }) async {
    final year = DateTime.now().year;
    final prefix = '${ledger.prefix}-$year-';
    final rows = await _db.customSelect(
      'SELECT txn_id FROM ${ledger.tableName} WHERE txn_id LIKE ?',
      variables: [Variable.withString('$prefix%')],
    ).get();

    var highestSuffix = 0;
    for (final row in rows) {
      final txnId = row.read<String>('txn_id');
      if (!txnId.startsWith(prefix)) continue;
      final suffix = int.tryParse(txnId.substring(prefix.length));
      if (suffix != null && suffix > highestSuffix) {
        highestSuffix = suffix;
      }
    }

    final nextSuffix = highestSuffix + 1 + offset;
    return '$prefix${nextSuffix.toString().padLeft(4, '0')}';
  }
}
