import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_stock_movement.dart';
import 'package:lotus_erp/repositories/reports/day_book_owned_stock_repository.dart';

void main() {
  test('selected-day metal opening reverses later movements from owned stock',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final day = DateTime(2026, 11, 4);
    final stockId = await db.into(db.stockItems).insert(
          StockItemsCompanion.insert(
            sku: 'GOLD-TEST-1',
            itemName: 'Gold lot',
            category: 'Gold',
            subCategory: 'Ring',
            netWeight: const drift.Value(110),
            createdAt: drift.Value(day),
          ),
        );
    await db.into(db.stockItems).insert(
          StockItemsCompanion.insert(
            sku: 'SILVER-LEGACY-1',
            itemName: 'Silver lot',
            category: 'Silver',
            subCategory: 'Chain',
            metalType: const drift.Value('Silver'),
            netWeight: const drift.Value(1250),
            createdAt: drift.Value(day),
          ),
        );
    await db.customStatement('''
      INSERT INTO stock_item_units
      (stock_item_id, unit_code, piece_no, metal_type, item_name,
       net_weight, status, created_at)
      VALUES (?, 'UNIT-GOLD-1', 1, 'Gold', 'Gold lot', 110, 'Available', ?)
    ''', [stockId, day.millisecondsSinceEpoch]);
    await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
          stockItemId: stockId,
          movementType: 'IN',
          sourceType: 'PURCHASE',
          sourceId: 'PUR-1',
          skuSnapshot: 'GOLD-TEST-1',
          metalTypeSnapshot: 'Gold',
          itemNameSnapshot: 'Gold lot',
          quantityDelta: 1,
          netWeightDelta: const drift.Value(20),
          occurredAt: day.add(const Duration(hours: 10)),
        ));
    await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
          stockItemId: stockId,
          movementType: 'SALE',
          sourceType: 'SALE',
          sourceId: 'INV-1',
          skuSnapshot: 'GOLD-TEST-1',
          metalTypeSnapshot: 'Gold',
          itemNameSnapshot: 'Gold lot',
          quantityDelta: -1,
          netWeightDelta: const drift.Value(-10),
          occurredAt: day.add(const Duration(hours: 12)),
        ));
    await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
          stockItemId: stockId,
          movementType: 'IN',
          sourceType: 'PURCHASE',
          sourceId: 'PUR-2',
          skuSnapshot: 'GOLD-TEST-1',
          metalTypeSnapshot: 'Gold',
          itemNameSnapshot: 'Gold lot',
          quantityDelta: 1,
          netWeightDelta: const drift.Value(30),
          occurredAt: day.add(const Duration(days: 1, hours: 10)),
        ));
    final today = [
      DayBookStockMovement(
        id: 1,
        occurredAt: day.add(const Duration(hours: 10)),
        movementType: 'IN',
        metal: 'Gold',
        itemName: 'Gold lot',
        sourceType: 'PURCHASE',
        sourceId: 'PUR-1',
        quantityDelta: 1,
        grossWeightDelta: 20,
        netWeightDelta: 20,
        fineWeightDelta: 18.32,
      ),
      DayBookStockMovement(
        id: 2,
        occurredAt: day.add(const Duration(hours: 12)),
        movementType: 'SALE',
        metal: 'Gold',
        itemName: 'Gold lot',
        sourceType: 'SALE',
        sourceId: 'INV-1',
        quantityDelta: -1,
        grossWeightDelta: -10,
        netWeightDelta: -10,
        fineWeightDelta: -9.16,
      ),
    ];

    final position = await DayBookOwnedStockRepository(db).fetch(day, today);
    expect(position.gold.openingGrams, 70);
    expect(position.gold.inwardGrams, 20);
    expect(position.gold.soldGrams, 10);
    expect(position.gold.closingGrams, 80);
    expect(position.gold.isConsistent, isTrue);
    expect(position.silver.closingGrams, 1250);
  });
}
