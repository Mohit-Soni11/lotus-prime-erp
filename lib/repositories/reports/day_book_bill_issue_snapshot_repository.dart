import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';

class DayBookBillIssueSnapshot {
  const DayBookBillIssueSnapshot({
    required this.finalAmount,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.issuedDue,
  });

  final double finalAmount;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double issuedDue;
}

/// The invoice issue event is separate from later due receipts and discounts.
class DayBookBillIssueSnapshotRepository {
  const DayBookBillIssueSnapshotRepository(this.db);

  final AppDatabase db;

  Future<void> capture(int billId) async {
    await db.customStatement('''
      INSERT INTO bill_issue_snapshots
        (bill_id, final_amount, taxable_amount, cgst_amount, sgst_amount,
         igst_amount, issued_due, issued_at)
      SELECT id, final_amount, taxable_amount, cgst_amount, sgst_amount,
             igst_amount, due_amount, bill_date
      FROM bills WHERE id = ?
      ON CONFLICT(bill_id) DO UPDATE SET
        final_amount = excluded.final_amount,
        taxable_amount = excluded.taxable_amount,
        cgst_amount = excluded.cgst_amount,
        sgst_amount = excluded.sgst_amount,
        igst_amount = excluded.igst_amount,
        issued_due = excluded.issued_due,
        issued_at = excluded.issued_at
    ''', [billId]);
  }

  Future<Map<int, DayBookBillIssueSnapshot>> fetchForBills(
      Iterable<int> billIds) async {
    final result = <int, DayBookBillIssueSnapshot>{};
    final ids = billIds.toList(growable: false);
    for (var offset = 0; offset < ids.length; offset += 500) {
      final batch = ids.skip(offset).take(500).toList(growable: false);
      final rows = await db
          .customSelect(
            'SELECT * FROM bill_issue_snapshots WHERE bill_id IN (${List.filled(batch.length, '?').join(',')})',
            variables: batch.map(Variable.withInt).toList(growable: false),
          )
          .get();
      for (final row in rows) {
        result[row.read<int>('bill_id')] = DayBookBillIssueSnapshot(
          finalAmount: row.read<double>('final_amount'),
          taxableAmount: row.read<double>('taxable_amount'),
          cgst: row.read<double>('cgst_amount'),
          sgst: row.read<double>('sgst_amount'),
          igst: row.read<double>('igst_amount'),
          issuedDue: row.read<double>('issued_due'),
        );
      }
    }
    return Map.unmodifiable(result);
  }
}
