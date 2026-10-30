import 'package:drift/drift.dart';

import '../../../database/db/app_database.dart';

/// Tracks invoice content edits independently from payment and return updates.
class SalesBillEditAudit {
  SalesBillEditAudit(this._db);

  final AppDatabase _db;
  Future<void>? _schemaReady;

  Future<void> ensureSchema() => _schemaReady ??= _db.customStatement('''
        CREATE TABLE IF NOT EXISTS sales_bill_content_edits (
          bill_id INTEGER PRIMARY KEY REFERENCES bills(id) ON DELETE CASCADE,
          edit_count INTEGER NOT NULL DEFAULT 0,
          last_edited_at INTEGER NOT NULL
        )
      ''');

  Future<void> recordEdit(int billId, DateTime editedAt) async {
    await ensureSchema();
    await _db.customStatement(
      '''
      INSERT INTO sales_bill_content_edits (bill_id, edit_count, last_edited_at)
      VALUES (?, 1, ?)
      ON CONFLICT(bill_id) DO UPDATE SET
        edit_count = edit_count + 1,
        last_edited_at = excluded.last_edited_at
      ''',
      [billId, editedAt.millisecondsSinceEpoch],
    );
  }

  Future<Set<int>> editedBillIds(Iterable<int> billIds) async {
    final ids = billIds.toList(growable: false);
    if (ids.isEmpty) return <int>{};
    await ensureSchema();
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await _db.customSelect(
      'SELECT bill_id FROM sales_bill_content_edits '
      'WHERE bill_id IN ($placeholders)',
      variables: [for (final id in ids) Variable.withInt(id)],
    ).get();
    return {for (final row in rows) row.read<int>('bill_id')};
  }
}
