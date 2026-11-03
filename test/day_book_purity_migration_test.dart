import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/reports/day_book_stock_movement_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('v70 stock history survives additive purity snapshot migration',
      () async {
    final directory = await Directory.systemTemp.createTemp('lotus-v70-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}shop.sqlite');

    final original = AppDatabase.forTesting(NativeDatabase(file));
    final itemId = await original.into(original.stockItems).insert(
          StockItemsCompanion.insert(
            sku: 'G-LEGACY',
            itemName: 'Gold Ring',
            category: 'Jewellery',
            subCategory: 'Ring',
            purity: const drift.Value('22K'),
          ),
        );
    final date = DateTime(2026, 6, 25, 12);
    await _movement(original, itemId, 'OLD-1', date);
    await original.close();

    final legacy = sqlite3.open(file.path);
    try {
      legacy.execute('DROP TRIGGER stock_movement_purity_snapshot_insert');
      legacy.execute('DROP TRIGGER stock_movement_identity_update');
      legacy.execute('ALTER TABLE stock_movements DROP COLUMN purity_snapshot');
      legacy.execute('PRAGMA user_version=70');
    } finally {
      legacy.dispose();
    }

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(migrated.close);
    var rows = await DayBookStockMovementRepository(migrated).fetch(date);
    expect(rows, hasLength(1));
    expect(rows.single.sourceId, 'OLD-1');
    expect(rows.single.puritySnapshot, isNull);

    await _movement(migrated, itemId, 'NEW-1', date);
    rows = await DayBookStockMovementRepository(migrated).fetch(date);
    expect(rows, hasLength(2));
    expect(rows.last.puritySnapshot, '22K');
  });
}

Future<void> _movement(
    AppDatabase db, int itemId, String sourceId, DateTime date) async {
  await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
        stockItemId: itemId,
        movementType: 'IN',
        sourceType: 'PURCHASE',
        sourceId: sourceId,
        skuSnapshot: 'G-LEGACY',
        metalTypeSnapshot: 'Gold',
        itemNameSnapshot: 'Gold Ring',
        quantityDelta: 1,
        netWeightDelta: const drift.Value(10),
        occurredAt: date,
      ));
}
