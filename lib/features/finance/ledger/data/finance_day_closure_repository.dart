import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lotus_erp/database/db/app_database.dart';

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

  Future<bool> closeDay(DateTime date, {required double closingCash}) async {
    if (!closingCash.isFinite) return false;
    final (start, end) = _bounds(date);
    final changed = await _db.customUpdate(
      '''INSERT OR IGNORE INTO finance_day_closures
         (day_key, start_epoch, end_epoch, closing_cash, closed_at)
         VALUES (?, ?, ?, ?, ?)''',
      variables: [
        Variable.withString(_dayKey(date)),
        Variable.withInt(start),
        Variable.withInt(end),
        Variable.withReal(closingCash),
        Variable.withInt(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      ],
    );
    return changed == 1 || await isClosed(date);
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
      await closeDay(date, closingCash: 0);
      await preferences.remove(key);
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
