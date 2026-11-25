import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'finance_day_close_snapshot.dart';

/// An immutable counter-session snapshot.
///
/// Unlike a finance-day closure this never locks source documents. A shop may
/// close, sign out, and safely resume work later on the same business date.
class FinanceSessionClosureRepository {
  FinanceSessionClosureRepository(this._db);

  final AppDatabase _db;

  Future<bool> closeSession(
    DateTime date, {
    required double closingCash,
    required double physicalBank,
    required String closedBy,
    required Map<String, num> denominationCount,
  }) async {
    if (!closingCash.isFinite ||
        closingCash < 0 ||
        !physicalBank.isFinite ||
        physicalBank < 0 ||
        closedBy.trim().isEmpty) {
      return false;
    }

    return _db.transaction(() async {
      await _ensureSchema();
      final snapshot = await FinanceDayCloseSnapshotBuilder(_db).build(
        date,
        physicalCash: closingCash,
        physicalBank: physicalBank,
        requireVerifiedInvoiceIssues: true,
        requireConsistentMetal: true,
        denominationCount: denominationCount,
      );
      final key = _dayKey(date);
      final nextNumber = (await _sessionCountForKey(key)) + 1;
      final inserted = await _db.customUpdate(
        '''INSERT INTO finance_session_closures
          (day_key, business_date, session_number, closing_cash, closing_bank,
           denomination_json, snapshot_json, source_hash, closed_at, closed_by)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        variables: [
          Variable.withString(key),
          Variable.withString(_businessDate(date)),
          Variable.withInt(nextNumber),
          Variable.withReal(closingCash),
          Variable.withReal(physicalBank),
          Variable.withString(_encodeDenominations(denominationCount)),
          Variable.withString(snapshot.json),
          Variable.withString(snapshot.sourceHash),
          Variable.withInt(DateTime.now().millisecondsSinceEpoch),
          Variable.withString(closedBy.trim()),
        ],
      );
      return inserted == 1;
    });
  }

  Future<int> sessionCount(DateTime date) async {
    await _ensureSchema();
    return _sessionCountForKey(_dayKey(date));
  }

  Future<bool> hasSessionClose(DateTime date) async =>
      (await sessionCount(date)) > 0;

  Future<void> _ensureSchema() => _db.customStatement('''
    CREATE TABLE IF NOT EXISTS finance_session_closures (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      day_key TEXT NOT NULL,
      business_date TEXT NOT NULL,
      session_number INTEGER NOT NULL,
      closing_cash REAL NOT NULL,
      closing_bank REAL NOT NULL,
      denomination_json TEXT NOT NULL,
      snapshot_json TEXT NOT NULL,
      source_hash TEXT NOT NULL,
      closed_at INTEGER NOT NULL,
      closed_by TEXT NOT NULL,
      UNIQUE(day_key, session_number)
    )
  ''');

  Future<int> _sessionCountForKey(String key) async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS count FROM finance_session_closures WHERE day_key = ?',
      variables: [Variable.withString(key)],
    ).getSingle();
    return row.read<int>('count');
  }

  static String _dayKey(DateTime date) => DateFormat('yyyyMMdd').format(date);

  static String _businessDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static String _encodeDenominations(Map<String, num> denominations) {
    final entries = denominations.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return jsonEncode({for (final entry in entries) entry.key: entry.value});
  }
}
