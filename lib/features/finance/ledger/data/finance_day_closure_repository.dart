import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'finance_day_close_snapshot.dart';

class FinanceDayClosureRepository {
  FinanceDayClosureRepository(this._db);

  final AppDatabase _db;

  static const _legacyPrefix = 'day_book_locked_';

  Future<bool> isClosed(DateTime date) async {
    final row = await _db.customSelect(
      'SELECT 1 FROM finance_day_closures WHERE day_key = ? LIMIT 1',
      variables: [Variable.withString(_dayKey(date))],
    ).getSingleOrNull();
    return row != null;
  }

  Future<bool> closeDay(DateTime date,
      {required double closingCash,
      double? physicalBank,
      bool requireVerifiedOpening = false,
      required String closedBy,
      Map<String, num>? denominationCount}) async {
    if (!closingCash.isFinite ||
        closingCash < 0 ||
        (physicalBank != null && !physicalBank.isFinite) ||
        closedBy.trim().isEmpty) {
      return false;
    }
    return _db.transaction(() async {
      final recordedClosing = await _recordedCashClosing(date);
      if ((recordedClosing - closingCash).abs() >= 0.01) {
        return false;
      }
      final snapshot = await FinanceDayCloseSnapshotBuilder(_db).build(
        date,
        physicalCash: closingCash,
        physicalBank: physicalBank,
        requireVerifiedOpening: requireVerifiedOpening,
        denominationCount: denominationCount,
      );
      final (start, end) = _bounds(date);
      final changed = await _db.customUpdate(
        '''INSERT OR IGNORE INTO finance_day_closures
           (day_key, start_epoch, end_epoch, closing_cash, closed_at, closed_by)
           VALUES (?, ?, ?, ?, ?, ?)''',
        variables: [
          Variable.withString(_dayKey(date)),
          Variable.withInt(start),
          Variable.withInt(end),
          Variable.withReal(closingCash),
          Variable.withInt(DateTime.now().millisecondsSinceEpoch ~/ 1000),
          Variable.withString(closedBy.trim()),
        ],
      );
      if (changed == 1) {
        await _db.customUpdate(
          '''INSERT INTO finance_day_closure_snapshots
             (day_key, snapshot_json, source_hash, created_at, created_by)
             VALUES (?, ?, ?, ?, ?)''',
          variables: [
            Variable.withString(_dayKey(date)),
            Variable.withString(snapshot.json),
            Variable.withString(snapshot.sourceHash),
            Variable.withInt(DateTime.now().millisecondsSinceEpoch ~/ 1000),
            Variable.withString(closedBy.trim()),
          ],
        );
        return true;
      }
      final existing = await _db.customSelect(
        'SELECT closing_cash, closed_by FROM finance_day_closures WHERE day_key = ?',
        variables: [Variable.withString(_dayKey(date))],
      ).getSingleOrNull();
      return existing != null &&
          (existing.read<double>('closing_cash') - closingCash).abs() < 0.01 &&
          existing.readNullable<String>('closed_by') == closedBy.trim();
    });
  }

  Future<FinanceDayCloseSnapshot?> fetchSnapshot(DateTime date) async {
    final row = await _db.customSelect(
      '''SELECT snapshot_json, source_hash
         FROM finance_day_closure_snapshots WHERE day_key = ?''',
      variables: [Variable.withString(_dayKey(date))],
    ).getSingleOrNull();
    return row == null
        ? null
        : FinanceDayCloseSnapshot(
            row.read<String>('snapshot_json'), row.read<String>('source_hash'));
  }

  Future<double> _recordedCashClosing(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day + 1);
    final profile = await _db.select(_db.shopProfiles).getSingleOrNull();
    final movement = await _db.customSelect(
      '''SELECT COALESCE(SUM(CASE WHEN type = 'INCOME' THEN amount
          WHEN type = 'EXPENSE' THEN -amount ELSE 0 END), 0) AS amount
         FROM cash_transactions
         WHERE is_voided = 0 AND payment_mode = 'CASH' AND txn_date < ?''',
      variables: [Variable.withDateTime(start)],
      readsFrom: {_db.cashTransactions},
    ).getSingle();
    return (profile?.openingCashBalance ?? 0) + movement.read<double>('amount');
  }

  Future<void> migrateLegacyLocks() async {
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences.getKeys().where((key) =>
        key.startsWith(_legacyPrefix) && preferences.getBool(key) == true);
    for (final key in keys) {
      final text = key.substring(_legacyPrefix.length);
      if (!RegExp(r'^\d{8}$').hasMatch(text)) continue;
      final date = DateTime.tryParse(
        '${text.substring(0, 4)}-${text.substring(4, 6)}-${text.substring(6, 8)}',
      );
      if (date == null) continue;
      final closingCash = await _recordedCashClosing(date);
      if (await closeDay(date,
          closingCash: closingCash, closedBy: 'legacy-lock-import')) {
        await preferences.remove(key);
      }
    }
  }

  static String _dayKey(DateTime date) => DateFormat('yyyyMMdd').format(date);

  static (int, int) _bounds(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);
    return (
      start.millisecondsSinceEpoch ~/ 1000,
      end.millisecondsSinceEpoch ~/ 1000,
    );
  }
}
