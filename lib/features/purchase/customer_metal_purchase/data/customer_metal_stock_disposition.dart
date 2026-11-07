import 'package:drift/drift.dart';

import '../../../../database/db/app_database.dart';
import '../../../stock/shared/application/stock_lifecycle_controller.dart';
import '../../../stock/shared/domain/models/stock_item/stock_enums.dart';
import '../domain/entities/customer_metal_purchase_entry.dart';

class CustomerMetalStockDisposition {
  const CustomerMetalStockDisposition(this._db);

  final AppDatabase _db;

  Future<void> markReturned(CustomerMetalPurchaseEntry entry) =>
      _transition(entry, StockStatus.returned.label, entry.referenceNo);

  Future<void> markMelted(CustomerMetalPurchaseEntry entry, String batchNo) =>
      _transition(entry, StockStatus.melted.label, batchNo);

  Future<void> _transition(
    CustomerMetalPurchaseEntry entry,
    String nextStatus,
    String sourceNumber,
  ) async {
    if (entry.source != 'Direct Purchase' &&
        entry.source != 'Booking Advance Metal') {
      return;
    }
    await StockLifecycleSchema.ensure(_db);
    final units = await _db.customSelect('''
      SELECT u.id, u.stock_item_id, u.unit_code, u.huid, u.batch_code
      FROM stock_item_units u
      JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
      WHERE u.purchase_voucher_item_id = ?
        AND u.purchase_voucher_id = ?
        AND UPPER(pv.source_type) = 'CUSTOMER'
        AND u.status = ?
    ''', variables: [
      Variable.withInt(entry.id),
      Variable.withInt(entry.sourceDocumentId),
      Variable.withString(StockStatus.processing.label),
    ]).get();
    if (units.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final unit in units) {
      final unitId = unit.read<int>('id');
      final stockItemId = unit.read<int>('stock_item_id');
      await _db.customStatement('''
        UPDATE stock_item_units
        SET status = ?, updated_at = ?
        WHERE id = ? AND status = ?
      ''', [
        nextStatus,
        now,
        unitId,
        StockStatus.processing.label,
      ]);
      await _db.customStatement('''
        INSERT INTO stock_unit_status_events (
          stock_unit_id, stock_item_id, unit_code, huid, batch_code,
          previous_status, new_status, reason, source_type, source_number,
          created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        unitId,
        stockItemId,
        unit.read<String>('unit_code'),
        unit.readNullable<String>('huid'),
        unit.readNullable<String>('batch_code'),
        StockStatus.processing.label,
        nextStatus,
        nextStatus == StockStatus.melted.label
            ? 'Transferred to melting batch'
            : 'Returned to customer',
        nextStatus == StockStatus.melted.label
            ? 'CUSTOMER_METAL_MELTING'
            : 'CUSTOMER_METAL_RETURN',
        sourceNumber,
        now,
      ]);
      await _db.customStatement('''
        UPDATE stock_items
        SET status = ?, updated_at = ?
        WHERE id = ? AND status = ?
          AND NOT EXISTS (
            SELECT 1 FROM stock_item_units remaining
            WHERE remaining.stock_item_id = ? AND remaining.status = ?
          )
      ''', [
        nextStatus,
        now,
        stockItemId,
        StockStatus.processing.label,
        stockItemId,
        StockStatus.processing.label,
      ]);
    }
  }
}
