import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';

void main() {
  test('return reversal schema prepares voucher and melting dependencies',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.ensureReturnReversalSchema();

    final tableRows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        )
        .get();
    final tables = tableRows.map((row) => row.read<String>('name')).toSet();

    expect(
      tables,
      containsAll(<String>{
        'return_vouchers',
        'return_voucher_lines',
        'purchase_vouchers',
        'purchase_voucher_items',
        'stock_item_units',
        'stock_unit_status_events',
      }),
    );

    final purchaseItemColumns = await database
        .customSelect('PRAGMA table_info(purchase_voucher_items)')
        .get();
    final columnNames =
        purchaseItemColumns.map((row) => row.read<String>('name')).toSet();

    expect(
      columnNames,
      containsAll(<String>{
        'quantity_mode',
        'packet_count',
        'pieces_per_packet',
        'valuation_fine_weight',
      }),
    );
  });
}
