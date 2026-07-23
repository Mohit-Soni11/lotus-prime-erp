import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';

class InventoryWeightVarianceLine {
  final int stockItemId;
  final int unitId;
  final String unitCode;
  final String metalType;
  final String itemName;
  final double netWeightDelta;
  final double fineWeightDelta;

  const InventoryWeightVarianceLine({
    required this.stockItemId,
    required this.unitId,
    required this.unitCode,
    required this.metalType,
    required this.itemName,
    required this.netWeightDelta,
    required this.fineWeightDelta,
  });
}

class InventoryWeightReconciliationService {
  final AppDatabase _db;

  const InventoryWeightReconciliationService(this._db);

  Future<void> closeBatchVariance({
    required String batchCode,
    required List<InventoryWeightVarianceLine> lines,
    required String reason,
  }) async {
    final cleanBatchCode = batchCode.trim();
    final cleanReason = reason.trim();
    if (cleanBatchCode.isEmpty) {
      throw ArgumentError('Batch code is required.');
    }
    if (cleanReason.length < 3) {
      throw ArgumentError('Reconciliation note is required.');
    }

    final pendingLines = lines
        .where((line) =>
            line.stockItemId > 0 && line.netWeightDelta.abs() > 0.000001)
        .toList(growable: false);
    if (pendingLines.isEmpty) {
      throw StateError('No open weight variance is pending for this batch.');
    }

    final now = DateTime.now();
    await _db.transaction(() async {
      for (final line in pendingLines) {
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
            drift.Variable.withInt(line.stockItemId),
            drift.Variable.withString('WEIGHT_RECONCILIATION'),
            drift.Variable.withString('STOCK_RECONCILIATION'),
            drift.Variable.withString(cleanBatchCode),
            drift.Variable.withInt(line.unitId),
            drift.Variable.withString('Close Variance'),
            drift.Variable.withString(line.unitCode),
            drift.Variable.withString(line.metalType),
            drift.Variable.withString(line.itemName),
            drift.Variable.withInt(0),
            drift.Variable.withReal(line.netWeightDelta),
            drift.Variable.withReal(line.netWeightDelta),
            drift.Variable.withReal(line.fineWeightDelta),
            drift.Variable.withString(cleanReason),
            drift.Variable.withDateTime(now),
            drift.Variable.withDateTime(now),
            drift.Variable.withDateTime(now),
          ],
        );
      }
    });
  }
}
