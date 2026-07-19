import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_activity_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('activity breakdown groups gold by grade and silver by item type',
      () async {
    final now = DateTime.now();
    final gold22Id = await _insertStockItem(
      database,
      sku: 'ACT-GOLD-22',
      itemName: 'Gold Chain',
      subCategory: 'Chain',
      metal: stock.MetalType.gold.label,
      createdAt: now,
    );
    final gold18Id = await _insertStockItem(
      database,
      sku: 'ACT-GOLD-18',
      itemName: 'Gold Ring',
      subCategory: 'Ring',
      metal: stock.MetalType.gold.label,
      createdAt: now,
    );
    final silverId = await _insertStockItem(
      database,
      sku: 'ACT-SILVER-PAYAL',
      itemName: 'Dulhan Payal',
      subCategory: 'Payal',
      metal: stock.MetalType.silver.label,
      category: stock.StockCategory.silver.label,
      createdAt: now,
    );

    await _insertStockUnit(
      database,
      stockItemId: gold22Id,
      unitCode: 'ACT-GOLD-22-U1',
      metal: stock.MetalType.gold.label,
      itemType: 'Chain',
      itemName: 'Gold Chain',
      purity: 91.6,
      netWeight: 24,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: gold18Id,
      unitCode: 'ACT-GOLD-18-U1',
      metal: stock.MetalType.gold.label,
      itemType: 'Ring',
      itemName: 'Gold Ring',
      purity: 75,
      netWeight: 10,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: silverId,
      unitCode: 'ACT-SILVER-PAYAL-U1',
      metal: stock.MetalType.silver.label,
      itemType: 'Payal',
      itemName: 'Dulhan Payal',
      purity: 60,
      netWeight: 90,
      createdAt: now,
    );

    await _insertStockMovement(
      database,
      stockItemId: gold22Id,
      movementType: 'IN',
      sourceId: 'PUR-G22',
      sourceNumber: 'GS-ACT-22',
      itemName: 'Gold Chain',
      metal: stock.MetalType.gold.label,
      quantityDelta: 2,
      netWeightDelta: 24,
      occurredAt: now,
    );
    await _insertStockMovement(
      database,
      stockItemId: gold18Id,
      movementType: 'SALE',
      sourceId: 'INV-G18',
      sourceNumber: 'INV-ACT-18',
      itemName: 'Gold Ring',
      metal: stock.MetalType.gold.label,
      quantityDelta: -1,
      netWeightDelta: -10,
      occurredAt: now,
    );
    await _insertStockMovement(
      database,
      stockItemId: silverId,
      movementType: 'IN',
      sourceId: 'PUR-SILVER',
      sourceNumber: 'SV-ACT-PAYAL',
      itemName: 'Dulhan Payal',
      metal: stock.MetalType.silver.label,
      quantityDelta: 6,
      netWeightDelta: 90,
      occurredAt: now,
    );

    final controller = StockActivityController(database);
    await controller.load();

    expect(controller.errorMessage, isNull);

    final gold22 = controller.breakdownSummaries.singleWhere(
      (item) => item.metal == 'Gold' && item.groupLabel == '22KT (91.6%)',
    );
    final gold18 = controller.breakdownSummaries.singleWhere(
      (item) => item.metal == 'Gold' && item.groupLabel == '18KT (75%)',
    );
    final payal = controller.breakdownSummaries.singleWhere(
      (item) => item.metal == 'Silver' && item.groupLabel == 'Payal',
    );

    expect(gold22.groupKind, 'Grade');
    expect(gold22.inwardQuantity, 2);
    expect(gold22.inwardWeight, closeTo(24, 0.001));
    expect(gold18.outwardQuantity, 1);
    expect(gold18.outwardWeight, closeTo(10, 0.001));
    expect(payal.groupKind, 'Item Type');
    expect(payal.inwardQuantity, 6);
    expect(payal.gradeCount, 1);
  });
}

Future<int> _insertStockItem(
  AppDatabase database, {
  required String sku,
  required String itemName,
  required String subCategory,
  required String metal,
  required DateTime createdAt,
  String category = 'Gold',
}) {
  return database.into(database.stockItems).insert(
        StockItemsCompanion.insert(
          createdAt: drift.Value(createdAt),
          sku: sku,
          itemName: itemName,
          category: category,
          subCategory: subCategory,
          metalType: drift.Value(metal),
          purity: const drift.Value(''),
          grossWeight: const drift.Value(0),
          netWeight: const drift.Value(0),
          quantity: const drift.Value(1),
          status: drift.Value(stock.StockStatus.available.label),
          isActive: const drift.Value(true),
        ),
      );
}

Future<void> _insertStockUnit(
  AppDatabase database, {
  required int stockItemId,
  required String unitCode,
  required String metal,
  required String itemType,
  required String itemName,
  required double purity,
  required double netWeight,
  required DateTime createdAt,
}) {
  return database.customStatement(
    '''
    INSERT INTO stock_item_units (
      stock_item_id,
      batch_code,
      unit_code,
      piece_no,
      metal_type,
      item_type,
      segment,
      item_name,
      gross_weight,
      less_weight,
      net_weight,
      purity_percent,
      actual_fine_weight,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      stockItemId,
      'BATCH-$unitCode',
      unitCode,
      1,
      metal,
      itemType,
      'General',
      itemName,
      netWeight,
      0.0,
      netWeight,
      purity,
      netWeight * purity / 100,
      stock.StockStatus.available.label,
      createdAt.millisecondsSinceEpoch,
    ],
  );
}

Future<int> _insertStockMovement(
  AppDatabase database, {
  required int stockItemId,
  required String movementType,
  required String sourceId,
  required String sourceNumber,
  required String itemName,
  required String metal,
  required int quantityDelta,
  required double netWeightDelta,
  required DateTime occurredAt,
}) {
  return database.into(database.stockMovements).insert(
        StockMovementsCompanion.insert(
          stockItemId: stockItemId,
          movementType: movementType,
          sourceType: movementType == 'IN' ? 'PURCHASE' : 'SALE',
          sourceId: sourceId,
          sourceNumber: drift.Value(sourceNumber),
          skuSnapshot: sourceId,
          metalTypeSnapshot: metal,
          itemNameSnapshot: itemName,
          quantityDelta: quantityDelta,
          grossWeightDelta: drift.Value(netWeightDelta),
          netWeightDelta: drift.Value(netWeightDelta),
          fineWeightDelta: drift.Value(netWeightDelta),
          occurredAt: occurredAt,
        ),
      );
}
