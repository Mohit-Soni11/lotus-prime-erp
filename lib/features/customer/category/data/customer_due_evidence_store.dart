import '../../../../database/db/app_database.dart';

/// Preserves the first recorded payment promise before the bill's editable
/// promise_date is cleared or replaced during due collection.
class CustomerDueEvidenceStore {
  const CustomerDueEvidenceStore(this._db);

  final AppDatabase _db;

  Future<void> ensureSchema() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS customer_due_settlement_evidence (
        bill_id INTEGER PRIMARY KEY REFERENCES bills(id) ON DELETE CASCADE,
        customer_id INTEGER NOT NULL,
        original_promise_at INTEGER,
        settled_at INTEGER
      )
    ''');
    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_customer_due_evidence_customer_settled
      ON customer_due_settlement_evidence(customer_id, settled_at)
    ''');
  }

  /// Call inside the same transaction that updates the bill.
  Future<void> recordCollection({
    required int billId,
    required int? customerId,
    required DateTime? originalPromise,
    required DateTime collectedAt,
    required bool settled,
  }) async {
    if (customerId == null) return;
    await _db.customStatement('''
      INSERT INTO customer_due_settlement_evidence
        (bill_id, customer_id, original_promise_at, settled_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(bill_id) DO UPDATE SET
        settled_at = CASE WHEN excluded.settled_at IS NOT NULL
          THEN excluded.settled_at ELSE settled_at END
    ''', [
      billId,
      customerId,
      originalPromise == null
          ? null
          : originalPromise.millisecondsSinceEpoch ~/ 1000,
      settled ? collectedAt.millisecondsSinceEpoch ~/ 1000 : null,
    ]);
  }
}
