import 'package:drift/drift.dart' as drift;
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier_profile/supplier_stock_batch.dart';

class SupplierBatchRepository {
  const SupplierBatchRepository(this._db);

  final AppDatabase _db;

  Future<List<SupplierStockBatch>> getBatches(int supplierId) async {
    final rows = await _db.customSelect(
      '''
      SELECT
        COALESCE(NULLIF(TRIM(u.batch_code), ''), pv.voucher_no) AS batch_code,
        GROUP_CONCAT(DISTINCT u.metal_type) AS metal_types,
        GROUP_CONCAT(DISTINCT u.item_name) AS item_names,
        COUNT(*) AS total_units,
        SUM(CASE
          WHEN lower(u.status) = 'available'
            AND (lower(COALESCE(u.unit_code, '')) NOT LIKE '%lot%'
              OR TRIM(COALESCE(u.huid, '')) <> ''
              OR COALESCE(s.quantity, 0) > 0)
          THEN 1 ELSE 0
        END) AS available_units
      FROM stock_item_units u
      LEFT JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
      LEFT JOIN stock_items s ON s.id = u.stock_item_id
      WHERE COALESCE(u.supplier_id, pv.supplier_id, s.supplier_id) = ?
        AND COALESCE(NULLIF(TRIM(u.batch_code), ''), pv.voucher_no) IS NOT NULL
      GROUP BY COALESCE(NULLIF(TRIM(u.batch_code), ''), pv.voucher_no)
      ORDER BY MAX(u.created_at) DESC, batch_code DESC
      ''',
      variables: [drift.Variable<int>(supplierId)],
      readsFrom: {_db.suppliers, _db.stockItems},
    ).get();
    return rows
        .map((row) => SupplierStockBatch(
              code: row.read<String>('batch_code'),
              metalTypes: row.readNullable<String>('metal_types') ?? '',
              itemNames: row.readNullable<String>('item_names') ?? '',
              totalUnits: row.read<int>('total_units'),
              availableUnits: row.read<int>('available_units'),
            ))
        .toList(growable: false);
  }
}
