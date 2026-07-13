import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/inventory_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;

void main() {
  late AppDatabase database;
  late InventoryController controller;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    controller = InventoryController(database);
  });

  tearDown(() => database.close());

  test('loadStats reads today movement counts from stock movement ledger',
      () async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final yesterday = dayStart.subtract(const Duration(hours: 1));

    final firstStockId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-001',
      quantity: 2,
      createdAt: yesterday,
      status: stock.StockStatus.available.label,
    );
    final secondStockId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-002',
      quantity: 1,
      createdAt: now,
      status: stock.StockStatus.sold.label,
    );

    await _insertStockMovement(
      database,
      stockItemId: firstStockId,
      movementType: 'IN',
      sourceId: 'PUR-1',
      sourceNumber: 'GSTOCK-2026-0001',
      quantityDelta: 2,
      occurredAt: now,
    );
    await _insertStockMovement(
      database,
      stockItemId: firstStockId,
      movementType: 'SALE',
      sourceId: 'INV-1',
      sourceNumber: 'INV-LJ-2026-0001',
      quantityDelta: -1,
      occurredAt: now,
    );
    await _insertStockMovement(
      database,
      stockItemId: firstStockId,
      movementType: 'SALE_RESTORE',
      sourceId: 'INV-1',
      sourceNumber: 'INV-LJ-2026-0001',
      quantityDelta: 1,
      occurredAt: now,
    );
    await _insertStockMovement(
      database,
      stockItemId: secondStockId,
      movementType: 'SALE',
      sourceId: 'INV-1',
      sourceNumber: 'INV-LJ-2026-0001',
      quantityDelta: -1,
      occurredAt: now,
    );

    await controller.loadStats();

    expect(controller.errorMessage, isNull);
    expect(controller.stats.todayAdded, 2);
    expect(controller.stats.todaySold, 1);
    expect(controller.stats.openingCount, 2);
    expect(controller.stats.closingCount, 2);
  });

  test('watchRecentMovements returns latest movements and respects category',
      () async {
    final now = DateTime.now();
    final goldStockId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-010',
      quantity: 1,
      createdAt: now,
      status: stock.StockStatus.available.label,
    );
    final silverStockId = await _insertStockItem(
      database,
      sku: 'LJ-SILVER-010',
      quantity: 1,
      createdAt: now,
      status: stock.StockStatus.available.label,
      category: stock.StockCategory.silver.label,
      metalType: stock.MetalType.silver.label,
    );

    await _insertStockMovement(
      database,
      stockItemId: goldStockId,
      movementType: 'IN',
      sourceId: 'PUR-10',
      sourceNumber: 'GSTOCK-2026-0010',
      quantityDelta: 1,
      occurredAt: now.subtract(const Duration(minutes: 2)),
    );
    await _insertStockMovement(
      database,
      stockItemId: silverStockId,
      movementType: 'SALE',
      sourceId: 'INV-10',
      sourceNumber: 'INV-LJ-2026-0010',
      quantityDelta: -1,
      occurredAt: now,
      metalType: stock.MetalType.silver.label,
    );

    final latest = await controller.watchRecentMovements(limit: 1).first;
    expect(latest, hasLength(1));
    expect(latest.single.metalTypeSnapshot, stock.MetalType.silver.label);

    controller.setCategory(stock.StockCategory.gold.label);
    final goldMovements = await controller.watchRecentMovements().first;
    expect(goldMovements, hasLength(1));
    expect(goldMovements.single.metalTypeSnapshot, stock.MetalType.gold.label);
  });
}

Future<int> _insertStockItem(
  AppDatabase database, {
  required String sku,
  required int quantity,
  required DateTime createdAt,
  required String status,
  String category = 'Gold',
  String metalType = 'Gold',
}) {
  return database.into(database.stockItems).insert(
        StockItemsCompanion.insert(
          createdAt: drift.Value(createdAt),
          sku: sku,
          itemName: 'Gold Ring',
          category: category,
          subCategory: 'Ring',
          metalType: drift.Value(metalType),
          purity: const drift.Value('22KT'),
          grossWeight: const drift.Value(10),
          netWeight: const drift.Value(10),
          quantity: drift.Value(quantity),
          status: drift.Value(status),
          isActive: const drift.Value(true),
        ),
      );
}

Future<int> _insertStockMovement(
  AppDatabase database, {
  required int stockItemId,
  required String movementType,
  required String sourceId,
  required String sourceNumber,
  required int quantityDelta,
  required DateTime occurredAt,
  String metalType = 'Gold',
}) {
  return database.into(database.stockMovements).insert(
        StockMovementsCompanion.insert(
          stockItemId: stockItemId,
          movementType: movementType,
          sourceType: movementType == 'IN' ? 'PURCHASE' : 'SALE',
          sourceId: sourceId,
          sourceNumber: drift.Value(sourceNumber),
          skuSnapshot: 'LJ-GOLD',
          metalTypeSnapshot: metalType,
          itemNameSnapshot: 'Gold Ring',
          quantityDelta: quantityDelta,
          grossWeightDelta: drift.Value(10 * quantityDelta.toDouble()),
          netWeightDelta: drift.Value(10 * quantityDelta.toDouble()),
          fineWeightDelta: drift.Value(9.16 * quantityDelta.toDouble()),
          occurredAt: occurredAt,
        ),
      );
}
