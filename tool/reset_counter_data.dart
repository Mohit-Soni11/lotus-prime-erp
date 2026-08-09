// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

const _tablesToClear = <String>[
  'gold_receipt_audit_events',
  'gold_receipt_attachments',
  'gold_receipt_settlements',
  'gold_stock_receipt_lines',
  'gold_stock_receipts',
  'girvi_notice_actions',
  'girvi_payments',
  'girvi_disbursements',
  'girvi_item_photos',
  'girvi_loan_items',
  'girvi_loans',
  'delivery_items',
  'delivery_orders',
  'karigar_receipts',
  'karigar_issues',
  'bill_trade_in_items',
  'bill_items',
  'bills',
  'customer_account_ledger',
  'purchase_item_huids',
  'purchase_voucher_items',
  'purchase_vouchers',
  'stock_movements',
  'stock_item_units',
  'stock_items',
  'sales_orders',
  'order_advances',
  'loans',
  'notifications',
  'cash_transactions',
  'bank_transactions',
  'customers',
  'suppliers',
];

void main(List<String> args) {
  final dbPath = args.isEmpty ? _defaultDatabasePath() : args.single;
  final databaseFile = File(dbPath);

  if (!databaseFile.existsSync()) {
    stderr.writeln('Database not found: $dbPath');
    exitCode = 2;
    return;
  }

  final backupDirectory = _backupDatabaseFiles(databaseFile);
  final before = _clearDatabase(dbPath);

  print('Database cleaned: $dbPath');
  print('Backup folder: ${backupDirectory.path}');
  print('');
  print('Rows deleted:');
  for (final entry in before.entries) {
    if (entry.value > 0) {
      print('  ${entry.key}: ${entry.value} -> 0');
    }
  }
  if (before.values.every((count) => count == 0)) {
    print('  No rows were present in the selected tables.');
  }
}

String _defaultDatabasePath() {
  final temp = Platform.environment['TEMP'] ?? Directory.systemTemp.path;
  return p.join(temp, 'lotus_erp_pro.sqlite');
}

Directory _backupDatabaseFiles(File databaseFile) {
  final timestamp =
      DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('.', '-');
  final localAppData =
      Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path;
  final backupDirectory = Directory(
    p.join(localAppData, 'lotus_erp_backups', 'reset_$timestamp'),
  )..createSync(recursive: true);

  for (final sourcePath in <String>[
    databaseFile.path,
    '${databaseFile.path}-wal',
    '${databaseFile.path}-shm',
  ]) {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      continue;
    }
    source.copySync(p.join(backupDirectory.path, p.basename(source.path)));
  }

  return backupDirectory;
}

Map<String, int> _clearDatabase(String dbPath) {
  final database = sqlite3.open(dbPath);
  try {
    database.execute('PRAGMA busy_timeout = 5000');
    database.execute('PRAGMA foreign_keys = OFF');

    final existingTables = database
        .select("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((row) => row['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();

    final before = <String, int>{};
    database.execute('BEGIN IMMEDIATE');
    try {
      for (final table in _tablesToClear) {
        if (!existingTables.contains(table)) {
          continue;
        }
        final rows = database.select('SELECT COUNT(*) AS count FROM $table');
        before[table] = rows.first['count'] as int;
        database.execute('DELETE FROM $table');
      }
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }

    database.execute('PRAGMA foreign_keys = ON');
    database.execute('VACUUM');
    return before;
  } finally {
    database.dispose();
  }
}
