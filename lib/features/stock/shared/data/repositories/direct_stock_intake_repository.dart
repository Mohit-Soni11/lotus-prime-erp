import 'package:drift/drift.dart' as drift;

import '../../../../../database/db/app_database.dart';
import '../../application/add_stock_models.dart';
import '../../domain/models/stock_item/stock_enums.dart';

class DirectStockBatchResult {
  const DirectStockBatchResult(this.batchCode, this.itemCount);

  final String batchCode;
  final int itemCount;
}

/// Stock-only intake for metals without a supplier invoice workflow.
class DirectStockIntakeRepository {
  const DirectStockIntakeRepository(this._db);

  final AppDatabase _db;

  Future<DirectStockBatchResult> save({
    required StockCategory metal,
    required List<StockRowEntry> rows,
    required String Function(StockRowEntry) purityLabel,
    required double fallbackTouch,
    required String defaultHsnCode,
  }) async {
    await _db.ensureStockInventorySchema();
    final now = DateTime.now();
    final batchCode =
        'DAS-${metal.label.toUpperCase()}-${now.microsecondsSinceEpoch}';
    return _db.transaction(() async {
      final batchHuids = <String>{};
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        final quantity = row.quantity;
        if (quantity <= 0) throw StateError('Stock quantity must be positive.');
        final sku = '$batchCode-${(index + 1).toString().padLeft(3, '0')}';
        final label = purityLabel(row);
        final category = row.subCategoryLabel.trim().isEmpty
            ? row.subCategory.label
            : row.subCategoryLabel.trim();
        final huids = row.huids
            .map((value) => value.trim().toUpperCase())
            .where((value) => value.isNotEmpty)
            .toList();
        if (huids.isEmpty && row.huid.trim().isNotEmpty) {
          huids.add(row.huid.trim().toUpperCase());
        }
        if (huids.length > quantity) {
          throw StateError('More HUIDs than pieces in $sku.');
        }
        for (final huid in huids) {
          if (!batchHuids.add(huid)) {
            throw StateError('Duplicate HUID $huid in this batch.');
          }
          await _assertHuidAvailable(huid);
        }

        final stockItemId = await _db.into(_db.stockItems).insert(
              StockItemsCompanion.insert(
                sku: sku,
                itemName: row.itemName.trim(),
                description: drift.Value(
                  row.description.trim().isEmpty
                      ? null
                      : row.description.trim(),
                ),
                category: metal.label,
                subCategory: category,
                metalType: drift.Value(metal.label),
                purity: drift.Value(label.isEmpty ? null : label),
                grossWeight: drift.Value(row.grossWeight),
                stoneWeight: drift.Value(row.stoneWeight),
                netWeight: drift.Value(row.netWeight),
                wastage: drift.Value(row.resolveTouch(fallbackTouch)),
                stoneType: drift.Value(row.stoneType.label),
                stoneCarats: drift.Value(row.stoneCarats),
                stonePieces: drift.Value(row.stonePieces),
                stoneValue: drift.Value(row.stoneValue),
                purchaseRate: drift.Value(row.purchaseRate),
                makingCharge: drift.Value(row.makingCharges),
                makingChargeType: drift.Value(row.makingChargesType.label),
                purchasePrice: drift.Value(row.resolvedCostPrice),
                mrp: drift.Value(row.mrp),
                hsnCode: drift.Value(
                  row.hsnCode.trim().isEmpty
                      ? defaultHsnCode
                      : row.hsnCode.trim(),
                ),
                huid: drift.Value(huids.isEmpty ? null : huids.first),
                gstRate: drift.Value(row.gstRate),
                quantity: drift.Value(quantity),
                location: drift.Value(
                  row.location.trim().isEmpty ? null : row.location.trim(),
                ),
                supplierId: drift.Value(row.supplierId),
                supplierName: drift.Value(
                  row.supplierName.trim().isEmpty
                      ? null
                      : row.supplierName.trim(),
                ),
                status: drift.Value(StockStatus.available.label),
              ),
            );

        if (huids.isEmpty) {
          await _insertUnit(
            stockItemId: stockItemId,
            batchCode: batchCode,
            sku: sku,
            row: row,
            metal: metal,
            category: category,
            fallbackTouch: fallbackTouch,
            now: now,
            pieceNo: 1,
            multiplier: quantity,
            huid: null,
            isLot: true,
          );
        } else {
          for (var piece = 0; piece < quantity; piece++) {
            await _insertUnit(
              stockItemId: stockItemId,
              batchCode: batchCode,
              sku: sku,
              row: row,
              metal: metal,
              category: category,
              fallbackTouch: fallbackTouch,
              now: now,
              pieceNo: piece + 1,
              multiplier: 1,
              huid: piece < huids.length ? huids[piece] : null,
              isLot: false,
            );
          }
        }

        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                stockItemId: stockItemId,
                movementType: 'IN',
                sourceType: 'ADD_STOCK_DIRECT',
                sourceId: batchCode,
                sourceLineNo: drift.Value(index + 1),
                sourceNumber: drift.Value(batchCode),
                skuSnapshot: sku,
                metalTypeSnapshot: metal.label,
                itemNameSnapshot: row.itemName.trim(),
                quantityDelta: quantity,
                grossWeightDelta: drift.Value(row.grossWeight * quantity),
                netWeightDelta: drift.Value(row.netWeight * quantity),
                fineWeightDelta:
                    drift.Value(row.fineWeight(fallbackTouch) * quantity),
                reason: const drift.Value('Direct Add Stock batch'),
                occurredAt: now,
              ),
            );
      }
      return DirectStockBatchResult(batchCode, rows.length);
    });
  }

  Future<void> _assertHuidAvailable(String huid) async {
    final existing = await _db.customSelect('''
      SELECT 1 FROM stock_item_units
      WHERE UPPER(TRIM(huid)) = ?
      UNION ALL
      SELECT 1 FROM purchase_item_huids
      WHERE UPPER(TRIM(huid)) = ?
      LIMIT 1
    ''', variables: [
      drift.Variable.withString(huid),
      drift.Variable.withString(huid),
    ]).get();
    if (existing.isNotEmpty) throw StateError('HUID $huid already exists.');
  }

  Future<void> _insertUnit({
    required int stockItemId,
    required String batchCode,
    required String sku,
    required StockRowEntry row,
    required StockCategory metal,
    required String category,
    required double fallbackTouch,
    required DateTime now,
    required int pieceNo,
    required int multiplier,
    required String? huid,
    required bool isLot,
  }) async {
    final nowMs = now.millisecondsSinceEpoch;
    final metalAmount = row.netWeight * row.purchaseRate;
    await _db.customStatement('''
      INSERT INTO stock_item_units (
        stock_item_id, batch_code, unit_code, piece_no, metal_type,
        item_type, item_name, huid, gross_weight, less_weight, net_weight,
        purity_percent, actual_fine_weight, rate_per_gram, making_amount,
        unit_cost, supplier_id, supplier_name, current_location, status,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      stockItemId,
      batchCode,
      isLot ? '$sku-LOT001' : '$sku-U${pieceNo.toString().padLeft(3, '0')}',
      pieceNo,
      metal.label,
      category,
      row.itemName.trim(),
      huid,
      row.grossWeight * multiplier,
      row.stoneWeight * multiplier,
      row.netWeight * multiplier,
      row.resolveTouch(fallbackTouch),
      row.fineWeight(fallbackTouch) * multiplier,
      row.purchaseRate,
      row.labourAmount(
            metalAmount: metalAmount,
            fallbackTouch: fallbackTouch,
          ) *
          multiplier,
      row.resolvedCostPrice * multiplier,
      row.supplierId,
      row.supplierName.trim().isEmpty ? null : row.supplierName.trim(),
      row.location.trim().isEmpty ? null : row.location.trim(),
      StockStatus.available.label,
      nowMs,
      nowMs,
    ]);
  }
}
