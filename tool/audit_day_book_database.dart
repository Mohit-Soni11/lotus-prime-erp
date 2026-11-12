// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Read-only, aggregate audit. Never prints customer or document contents.
void main(List<String> args) {
  if (args.length != 1) {
    stderr
        .writeln('Usage: dart run tool/audit_day_book_database.dart <db-path>');
    exitCode = 64;
    return;
  }
  final database = sqlite3.open(args.single, mode: OpenMode.readOnly);
  try {
    final tables = database
        .select("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((row) => row['name'] as String)
        .toSet();
    int count(String sql) => database.select(sql).single['n'] as int;
    final integrity = database
        .select('PRAGMA integrity_check')
        .single
        .values
        .single
        .toString();
    print('integrity=$integrity');
    print(
        'schema_version=${database.select('PRAGMA user_version').single.values.single}');
    for (final table in [
      'bills',
      'bill_issue_snapshots',
      'cash_transactions',
      'bank_accounts',
      'bank_transactions',
      'stock_items',
      'stock_item_units',
      'stock_movements',
      'girvi_loans',
      'girvi_loan_items',
      'finance_day_closures',
      'finance_day_closure_snapshots',
      'day_book_metal_verifications',
    ]) {
      if (tables.contains(table)) {
        print('$table=${count('SELECT COUNT(*) AS n FROM "$table"')}');
      } else {
        print('$table=MISSING');
      }
    }
    if (tables.containsAll({'bills', 'bill_issue_snapshots'})) {
      print('invoices_without_issue_snapshot=${count('''
        SELECT COUNT(*) AS n FROM bills b
        LEFT JOIN bill_issue_snapshots s ON s.bill_id = b.id
        WHERE s.bill_id IS NULL AND UPPER(b.status) NOT IN
          ('VOID', 'VOIDED', 'CANCELLED')
      ''')}');
    }
    if (tables.containsAll(
        {'finance_day_closures', 'finance_day_closure_snapshots'})) {
      print('closures_without_audit_snapshot=${count('''
        SELECT COUNT(*) AS n FROM finance_day_closures c
        LEFT JOIN finance_day_closure_snapshots s ON s.day_key = c.day_key
        WHERE s.day_key IS NULL
      ''')}');
    }
    if (tables.containsAll(
        {'finance_day_closures', 'day_book_metal_verifications'})) {
      print('closures_without_physical_metal_count=${count('''
        SELECT COUNT(*) AS n FROM finance_day_closures c
        LEFT JOIN day_book_metal_verifications m ON m.day_key = c.day_key
        WHERE m.day_key IS NULL
      ''')}');
    }
    if (tables.contains('bank_transactions')) {
      for (final row in database.select('''
        SELECT UPPER(COALESCE(cheque_status, 'UNKNOWN')) AS status,
          COUNT(*) AS n
        FROM bank_transactions
        WHERE UPPER(payment_mode) = 'CHEQUE' AND is_voided = 0
        GROUP BY 1 ORDER BY 1
      ''')) {
        print('cheque_${row['status']}=${row['n']}');
      }
    }
    if (tables.contains('stock_item_units')) {
      print('available_units_without_purity=${count('''
        SELECT COUNT(*) AS n FROM stock_item_units
        WHERE LOWER(status) = 'available' AND purity_percent <= 0
      ''')}');
    }
  } finally {
    database.dispose();
  }
}
