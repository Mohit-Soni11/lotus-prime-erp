import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/reports/day_book_stock_movement_repository.dart';

void main() {
  test('mixed-purity stock cannot receive an invented purity snapshot',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final itemId = await db.into(db.stockItems).insert(
          StockItemsCompanion.insert(
            sku: 'MIXED-1',
            itemName: 'Mixed Lot',
            category: 'Jewellery',
            subCategory: 'Lot',
            purity: const drift.Value('22K'),
          ),
        );
    for (final (code, purity) in [('U-1', 91.6), ('U-2', 75.0)]) {
      await db.customStatement(
        '''INSERT INTO stock_item_units
           (stock_item_id, unit_code, piece_no, metal_type, item_name,
            purity_percent, created_at)
           VALUES (?, ?, 1, 'Gold', 'Mixed Lot', ?, ?)''',
        [itemId, code, purity, DateTime(2026, 6, 25).millisecondsSinceEpoch],
      );
    }
    final date = DateTime(2026, 6, 25, 12);
    await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
          stockItemId: itemId,
          movementType: 'SALE',
          sourceType: 'BILL',
          sourceId: 'INV-MIXED',
          skuSnapshot: 'MIXED-1',
          metalTypeSnapshot: 'Gold',
          itemNameSnapshot: 'Mixed Lot',
          quantityDelta: -1,
          netWeightDelta: const drift.Value(-10),
          occurredAt: date,
        ));
    final rows = await DayBookStockMovementRepository(db).fetch(date);
    expect(rows.single.puritySnapshot, isNull);
  });

  test('reads posted stock rows with both historical timestamp encodings',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 6, 25, 12);
    final itemId = await db.into(db.stockItems).insert(
          StockItemsCompanion.insert(
            sku: 'G-1',
            itemName: 'Gold Ring',
            category: 'Jewellery',
            subCategory: 'Ring',
            purity: const drift.Value('22K'),
          ),
        );
    await db.into(db.stockMovements).insert(
          StockMovementsCompanion.insert(
            stockItemId: itemId,
            movementType: 'IN',
            sourceType: 'PURCHASE',
            sourceId: 'P-1',
            skuSnapshot: 'G-1',
            metalTypeSnapshot: 'Gold',
            itemNameSnapshot: 'Gold Ring',
            quantityDelta: 1,
            netWeightDelta: const drift.Value(10),
            occurredAt: date,
          ),
        );
    await db.customStatement(
      '''INSERT INTO stock_movements
         (stock_item_id, movement_type, source_type, source_id, sku_snapshot,
          metal_type_snapshot, item_name_snapshot, quantity_delta,
          net_weight_delta, occurred_at, created_at, updated_at)
         VALUES (?, 'SALE', 'BILL', 'I-1', 'G-1', 'Gold', 'Gold Ring',
                 -1, -10, ?, ?, ?)''',
      [
        itemId,
        date.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        date.millisecondsSinceEpoch,
        date.millisecondsSinceEpoch,
      ],
    );

    final movements = await DayBookStockMovementRepository(db).fetch(date);
    expect(movements, hasLength(2));
    expect(movements.first.isInward, isTrue);
    expect(movements.first.puritySnapshot, '22K');
    expect(movements.first.purityVerified, isTrue);
    expect(movements.last.isOutward, isTrue);
    expect(movements.last.purityVerified, isTrue);
    expect(movements.last.sourceId, 'I-1');
    expect(movements.last.netWeightDelta, -10);
    expect(movements.last.occurredAt.hour, 13);
    await expectLater(
      db.customStatement(
          "UPDATE stock_movements SET source_id = 'ALTERED' WHERE source_id = 'P-1'"),
      throwsA(isA<Exception>()),
    );
  });
}
