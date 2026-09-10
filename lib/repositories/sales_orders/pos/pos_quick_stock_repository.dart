import 'package:drift/drift.dart';

import '../../../database/db/app_database.dart';
import '../../../features/stock/shared/application/add_stock_sku_generator.dart';
import '../../../features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales_orders/sales_pos_models/pos_quick_stock_intake_model.dart';
import '../../../models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';

class PosQuickStockRepository {
  final AppDatabase _db;

  PosQuickStockRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<PosStockLookupModel> createSaleReadyStock(
    PosQuickStockIntakeModel intake,
  ) async {
    await _db.ensureStockInventorySchema();
    final now = DateTime.now();
    final createdAt = now.millisecondsSinceEpoch;
    final sku = _buildSku(intake, now);
    final itemName = _normalizedItemName(intake.itemName);
    final category = _stockCategoryForMetal(intake.metal).label;
    final stockItemId = await _db.transaction<int>(() async {
      final id = await _db.into(_db.stockItems).insert(
            StockItemsCompanion.insert(
              sku: sku,
              itemName: itemName,
              description:
                  const Value('Quick stock intake from POS advance sale'),
              category: category,
              subCategory: _subCategoryForItem(itemName),
              metalType: Value(_stockMetalLabel(intake.metal)),
              purity: Value(intake.purityLabel.trim()),
              grossWeight: Value(intake.grossWeight),
              stoneWeight: Value(intake.lessWeight),
              netWeight: Value(intake.netWeight),
              wastage: Value(intake.wastagePercent),
              purchaseRate: Value(intake.purchaseRate),
              purchasePrice: Value(intake.unitCost),
              mrp: Value(intake.unitCost),
              huid: Value(_nullableUpper(intake.huid)),
              quantity: const Value(1),
              supplierId: Value(intake.supplierId),
              supplierName: Value(_nullableText(intake.supplierName)),
              status: Value(stock.StockStatus.available.label),
            ),
          );

      await _db.customUpdate(
        '''
        UPDATE stock_items
        SET company_name = NULL,
            quantity_mode = 'PIECES',
            packet_count = 0,
            pieces_per_packet = 1
        WHERE id = ?
        ''',
        variables: [Variable<int>(id)],
      );

      await _insertUnit(
        stockItemId: id,
        sku: sku,
        itemName: itemName,
        intake: intake,
        createdAt: createdAt,
      );
      await _insertMovement(
        stockItemId: id,
        sku: sku,
        itemName: itemName,
        intake: intake,
        occurredAt: now,
      );
      return id;
    });

    return PosStockLookupModel(
      stockItemId: stockItemId,
      stockUnitId: await _stockUnitIdForSku('$sku-U001'),
      sku: '$sku-U001',
      itemName: itemName,
      description: 'Quick stock intake from POS advance sale',
      huid: _nullableUpper(intake.huid),
      huids: _nullableUpper(intake.huid) == null
          ? const []
          : [_nullableUpper(intake.huid)!],
      purity: intake.purityLabel.trim(),
      metal: intake.metal,
      categoryLabel: _subCategoryForItem(itemName),
      grossWeight: intake.grossWeight,
      lessWeight: intake.lessWeight,
      netWeight: intake.netWeight,
      unitCost: intake.unitCost,
      quantity: 1,
      availableQuantity: 1,
      quantityUnitLabel: 'pcs',
      status: stock.StockStatus.available.label,
    );
  }

  Future<void> _insertUnit({
    required int stockItemId,
    required String sku,
    required String itemName,
    required PosQuickStockIntakeModel intake,
    required int createdAt,
  }) {
    return _db.customStatement(
      '''
      INSERT INTO stock_item_units (
        stock_item_id,
        batch_code,
        unit_code,
        piece_no,
        metal_type,
        item_type,
        item_name,
        huid,
        gross_weight,
        less_weight,
        net_weight,
        purity_percent,
        actual_fine_weight,
        wastage_percent,
        wastage_fine_weight,
        valuation_fine_weight,
        rate_per_gram,
        making_amount,
        unit_cost,
        supplier_id,
        supplier_name,
        current_location,
        status,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        stockItemId,
        sku,
        '$sku-U001',
        1,
        _stockMetalLabel(intake.metal),
        _subCategoryForItem(itemName),
        itemName,
        _nullableUpper(intake.huid),
        intake.grossWeight,
        intake.lessWeight,
        intake.netWeight,
        intake.purityPercent,
        intake.fineWeight,
        intake.wastagePercent,
        intake.wastageFineWeight,
        intake.valuationFineWeight,
        intake.purchaseRate,
        0.0,
        intake.unitCost,
        intake.supplierId,
        _nullableText(intake.supplierName),
        'POS Quick Stock',
        stock.StockStatus.available.label,
        createdAt,
        createdAt,
      ],
    );
  }

  Future<void> _insertMovement({
    required int stockItemId,
    required String sku,
    required String itemName,
    required PosQuickStockIntakeModel intake,
    required DateTime occurredAt,
  }) {
    final timestamp = occurredAt.millisecondsSinceEpoch;
    return _db.customStatement(
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
        stockItemId,
        'IN',
        'POS_QUICK_STOCK',
        sku,
        intake.rowIndex + 1,
        sku,
        sku,
        _stockMetalLabel(intake.metal),
        itemName,
        1,
        intake.grossWeight,
        intake.netWeight,
        intake.fineWeight,
        'Quick stock intake before POS sale',
        timestamp,
        timestamp,
        timestamp,
      ],
    );
  }

  Future<int?> _stockUnitIdForSku(String unitCode) async {
    final row = await _db.customSelect(
      'SELECT id FROM stock_item_units WHERE unit_code = ? LIMIT 1',
      variables: [Variable<String>(unitCode)],
    ).getSingleOrNull();
    return row?.read<int>('id');
  }

  String _buildSku(PosQuickStockIntakeModel intake, DateTime now) {
    return 'QK-${AddStockSkuGenerator.generate(
      metal: _stockCategoryForMetal(intake.metal),
      index: intake.rowIndex,
      now: now,
    )}';
  }

  stock.StockCategory _stockCategoryForMetal(MetalType metal) {
    return switch (metal) {
      MetalType.gold => stock.StockCategory.gold,
      MetalType.silver => stock.StockCategory.silver,
      MetalType.platinum => stock.StockCategory.platinum,
      MetalType.diamond => stock.StockCategory.diamond,
    };
  }

  String _stockMetalLabel(MetalType metal) {
    return switch (metal) {
      MetalType.gold => 'Gold',
      MetalType.silver => 'Silver',
      MetalType.platinum => 'Platinum',
      MetalType.diamond => 'Diamond',
    };
  }

  String _normalizedItemName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Jewellery Item' : trimmed;
  }

  String _subCategoryForItem(String itemName) {
    final text = itemName.toLowerCase();
    if (text.contains('ring')) return 'Ring';
    if (text.contains('chain')) return 'Chain';
    if (text.contains('bangle')) return 'Bangle';
    if (text.contains('bracelet')) return 'Bracelet';
    if (text.contains('necklace') || text.contains('haar')) return 'Necklace';
    if (text.contains('earring') || text.contains('tops')) return 'Earring';
    if (text.contains('pendant')) return 'Pendant';
    if (text.contains('anklet') || text.contains('payal')) return 'Anklet';
    return 'Other';
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _nullableUpper(String value) {
    final trimmed = value.trim().toUpperCase();
    return trimmed.isEmpty ? null : trimmed;
  }
}
