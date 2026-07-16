import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_lifecycle_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_search/stock_search_models.dart';

class StockSaleRestoreResult {
  final String sourceNumber;
  final String customerName;

  const StockSaleRestoreResult({
    required this.sourceNumber,
    required this.customerName,
  });
}

class StockSaleRestoreController {
  final AppDatabase _db;

  StockSaleRestoreController(this._db);

  Future<StockSaleRestoreResult> restoreToInventory({
    required StockSearchResult item,
    required String reason,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.length < 3) {
      throw ArgumentError('Restore reason is required.');
    }
    if (!item.isSold) {
      throw StateError('Only sold stock can be restored to inventory.');
    }

    await StockLifecycleSchema.ensure(_db);
    final currentStatus = await _currentUnitStatus(item.id);
    if (currentStatus.toLowerCase() != StockStatus.sold.label.toLowerCase()) {
      throw StateError('This stock unit is already restored or not sold.');
    }

    final saleLink = await _findSaleLink(item);
    final duplicateRestore = await _hasRestoreMovement(
      stockUnitId: item.id,
      sourceNumber: saleLink.sourceNumber,
    );
    if (duplicateRestore) {
      throw StateError('This sale restore has already been recorded.');
    }

    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.customStatement(
        '''
        UPDATE stock_item_units
        SET status = ?, sold_at = NULL, updated_at = ?
        WHERE id = ? AND LOWER(status) = ?
        ''',
        [
          drift.Variable.withString(StockStatus.available.label),
          drift.Variable.withDateTime(now),
          drift.Variable.withInt(item.id),
          drift.Variable.withString(StockStatus.sold.label.toLowerCase()),
        ],
      );

      if (item.stockItemId != null) {
        await _db.customStatement(
          '''
          UPDATE stock_items
          SET quantity = quantity + 1,
              is_active = 1,
              status = ?,
              updated_at = ?
          WHERE id = ?
          ''',
          [
            drift.Variable.withString(StockStatus.available.label),
            drift.Variable.withDateTime(now),
            drift.Variable.withInt(item.stockItemId!),
          ],
        );
      }

      await _db.customStatement(
        '''
        INSERT INTO stock_unit_status_events (
          stock_unit_id,
          stock_item_id,
          unit_code,
          huid,
          batch_code,
          previous_status,
          new_status,
          reason,
          source_type,
          source_number,
          created_at
        ) VALUES (?, NULLIF(?, 0), ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          drift.Variable.withInt(item.id),
          drift.Variable.withInt(item.stockItemId ?? 0),
          drift.Variable.withString(item.unitCode),
          drift.Variable.withString(item.huid),
          drift.Variable.withString(item.inventoryBatchCode),
          drift.Variable.withString(StockStatus.sold.label),
          drift.Variable.withString(StockStatus.available.label),
          drift.Variable.withString(cleanReason),
          drift.Variable.withString('SALE_RESTORE'),
          drift.Variable.withString(saleLink.sourceNumber),
          drift.Variable.withDateTime(now),
        ],
      );

      if (item.stockItemId != null) {
        await _db.customStatement(
          '''
          INSERT INTO stock_movements (
            stock_item_id,
            movement_type,
            source_type,
            source_id,
            source_line_no,
            source_number,
            sku_snapshot,
            metal_type_snapshot,
            item_name_snapshot,
            quantity_delta,
            gross_weight_delta,
            net_weight_delta,
            fine_weight_delta,
            reason,
            occurred_at,
            created_at,
            updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            drift.Variable.withInt(item.stockItemId!),
            drift.Variable.withString('SALE_RESTORE'),
            drift.Variable.withString('SALE_RESTORE'),
            drift.Variable.withString(item.id.toString()),
            drift.Variable.withInt(saleLink.lineNo),
            drift.Variable.withString(saleLink.sourceNumber),
            drift.Variable.withString(item.unitCode),
            drift.Variable.withString(item.metalType),
            drift.Variable.withString(item.itemName),
            drift.Variable.withInt(1),
            drift.Variable.withReal(item.grossWeight),
            drift.Variable.withReal(item.netWeight),
            drift.Variable.withReal(item.actualFineWeight),
            drift.Variable.withString(cleanReason),
            drift.Variable.withDateTime(now),
            drift.Variable.withDateTime(now),
            drift.Variable.withDateTime(now),
          ],
        );
      }
    });

    return StockSaleRestoreResult(
      sourceNumber: saleLink.sourceNumber,
      customerName: saleLink.customerName,
    );
  }

  Future<String> _currentUnitStatus(int stockUnitId) async {
    final row = await _db.customSelect(
      '''
      SELECT status
      FROM stock_item_units
      WHERE id = ?
      LIMIT 1
      ''',
      variables: [drift.Variable.withInt(stockUnitId)],
    ).getSingleOrNull();
    if (row == null) {
      throw StateError('Stock unit no longer exists.');
    }
    return (row.data['status'] as String?)?.trim() ?? '';
  }

  Future<bool> _hasRestoreMovement({
    required int stockUnitId,
    required String sourceNumber,
  }) async {
    final row = await _db.customSelect(
      '''
      SELECT COUNT(*) AS restore_count
      FROM stock_movements
      WHERE movement_type = 'SALE_RESTORE'
        AND source_type = 'SALE_RESTORE'
        AND source_id = ?
        AND source_number = ?
      ''',
      variables: [
        drift.Variable.withString(stockUnitId.toString()),
        drift.Variable.withString(sourceNumber),
      ],
    ).getSingle();
    return ((row.data['restore_count'] as num?)?.toInt() ?? 0) > 0;
  }

  Future<_SaleLink> _findSaleLink(StockSearchResult item) async {
    final row = await _db.customSelect(
      '''
      SELECT
        COALESCE(b.bill_no, '') AS source_number,
        COALESCE(b.customer_name, '') AS customer_name,
        COALESCE(bi.line_no, 0) AS line_no
      FROM bill_items bi
      INNER JOIN bills b ON b.id = bi.bill_id
      WHERE
        bi.linked_stock_unit_id = ?
        OR (
          TRIM(?) <> ''
          AND LOWER(COALESCE(bi.huid, '')) = LOWER(?)
        )
        OR (
          TRIM(?) <> ''
          AND LOWER(COALESCE(bi.linked_stock_sku, '')) = LOWER(?)
        )
      ORDER BY COALESCE(b.bill_date, bi.created_at) DESC, bi.id DESC
      LIMIT 1
      ''',
      variables: [
        drift.Variable.withInt(item.id),
        drift.Variable.withString(item.huid.trim()),
        drift.Variable.withString(item.huid.trim()),
        drift.Variable.withString(item.unitCode.trim()),
        drift.Variable.withString(item.unitCode.trim()),
      ],
    ).getSingleOrNull();

    if (row == null) {
      return _SaleLink(
        sourceNumber: item.soldBillNo.trim().isEmpty
            ? 'Sale restore'
            : item.soldBillNo.trim(),
        customerName: item.soldCustomerName.trim(),
        lineNo: 0,
      );
    }

    return _SaleLink(
      sourceNumber: ((row.data['source_number'] as String?) ?? '').trim(),
      customerName: ((row.data['customer_name'] as String?) ?? '').trim(),
      lineNo: ((row.data['line_no'] as num?)?.toInt() ?? 0),
    );
  }
}

class _SaleLink {
  final String sourceNumber;
  final String customerName;
  final int lineNo;

  const _SaleLink({
    required this.sourceNumber,
    required this.customerName,
    required this.lineNo,
  });
}
