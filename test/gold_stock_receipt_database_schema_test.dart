import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';

void main() {
  test('fresh database contains the Gold stock receipt schema', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final rows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        )
        .get();
    final tables = rows.map((row) => row.read<String>('name')).toSet();

    expect(
      tables,
      containsAll(<String>{
        'gold_stock_receipts',
        'gold_stock_receipt_lines',
        'gold_receipt_settlements',
        'gold_receipt_attachments',
        'gold_receipt_audit_events',
      }),
    );
  });
}
