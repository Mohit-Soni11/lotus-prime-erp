import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_summary_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('recent movements keep latest records per action filter', () async {
    final now = DateTime.now();
    final stockItemId = await _insertStockItem(database, now);

    for (var index = 0; index < 20; index += 1) {
      await _insertStockMovement(
        database,
        stockItemId: stockItemId,
        movementType: 'IN',
        sourceId: 'PUR-$index',
        sourceNumber: 'GS-RECENT-$index',
        quantityDelta: 1,
        occurredAt: now.subtract(Duration(minutes: index)),
      );
    }

    for (var index = 0; index < 2; index += 1) {
      await _insertStockMovement(
        database,
        stockItemId: stockItemId,
        movementType: 'SALE',
        sourceId: 'INV-$index',
        sourceNumber: 'INV-RECENT-$index',
        quantityDelta: -1,
        occurredAt: now.subtract(Duration(hours: 2, minutes: index)),
      );
    }

    final controller = StockSummaryController(database);
    await controller.load();

    final added = controller.recentMovements.where((item) => item.isInward);
    final sold = controller.recentMovements.where((item) => item.isSold);

    expect(controller.errorMessage, isNull);
    expect(added, hasLength(12));
    expect(sold, hasLength(2));
    expect(sold.map((item) => item.sourceNumber), contains('INV-RECENT-0'));
  });
}

Future<int> _insertStockItem(AppDatabase database, DateTime createdAt) {
  return database.into(database.stockItems).insert(
        StockItemsCompanion.insert(
          createdAt: drift.Value(createdAt),
          sku: 'LJ-STOCK-SUMMARY-001',
          itemName: 'Gold Ring',
          category: stock.StockCategory.gold.label,
          subCategory: 'Ring',
          metalType: drift.Value(stock.MetalType.gold.label),
          purity: const drift.Value('22KT'),
          grossWeight: const drift.Value(10),
          netWeight: const drift.Value(10),
          quantity: const drift.Value(1),
          status: drift.Value(stock.StockStatus.available.label),
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
}) {
  return database.into(database.stockMovements).insert(
        StockMovementsCompanion.insert(
          stockItemId: stockItemId,
          movementType: movementType,
          sourceType: movementType == 'IN' ? 'PURCHASE' : 'SALE',
          sourceId: sourceId,
          sourceNumber: drift.Value(sourceNumber),
          skuSnapshot: 'LJ-STOCK-SUMMARY-001',
          metalTypeSnapshot: stock.MetalType.gold.label,
          itemNameSnapshot: 'Gold Ring',
          quantityDelta: quantityDelta,
          grossWeightDelta: drift.Value(10 * quantityDelta.toDouble()),
          netWeightDelta: drift.Value(10 * quantityDelta.toDouble()),
          fineWeightDelta: drift.Value(9.16 * quantityDelta.toDouble()),
          occurredAt: occurredAt,
        ),
      );
}
