import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/reports/day_book_stock_added_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final date = DateTime(2026, 11, 4, 10);

  test('two stock lines produce one batch with posted net weight and value',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final voucherId = await _voucher(db, 'GLD-42', 'SUPPLIER', 190000, date);
    await _line(db, voucherId, 1, 'Gold', 12, 5450, 3600, date);
    await _line(db, voucherId, 2, 'Gold', 18.5, 6250, 5200, date);
    await _movement(db, voucherId, 1, 12, 2, date);
    await _movement(db, voucherId, 2, 18.5, 1, date);
    final customerId = await _voucher(db, 'CUS-43', 'CUSTOMER', 10000, date);
    await _line(db, customerId, 1, 'Gold', 3, 3000, null, date);
    await _movement(db, customerId, 1, 3, 1, date);
    final otherSupplierId = await _voucher(
      db,
      'SUP-44',
      'SUPPLIER',
      6000,
      date,
      origin: 'SUPPLIER_PURCHASE',
    );
    await _line(db, otherSupplierId, 1, 'Gold', 1, 6000, null, date);
    await _movement(db, otherSupplierId, 1, 1, 1, date);

    final batches = await DayBookStockAddedRepository(db).fetch(date);
    expect(batches, hasLength(1));
    final batch = batches.single;
    expect(batch.batchCode, 'GLD-42');
    expect(batch.metal, 'Gold');
    expect(batch.pieces, 3);
    expect(batch.netWeightGrams, 30.5);
    expect(batch.hasMixedRates, isTrue);
    expect(batch.ratePerGram, isNull);
    expect(batch.makingTotal, 8800);
    expect(batch.purchaseValue, 190000);
    expect(
        await DayBookStockAddedRepository(db)
            .fetch(date.add(const Duration(days: 1))),
        isEmpty);
  });

  test('older batch keeps its value without inventing making', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await _voucher(db, 'SIL-44', 'SUPPLIER', 8000, date);
    await _line(db, id, 1, 'Silver', 80, 100, null, date);
    await _movement(db, id, 1, 80, 1, date);

    final batch = (await DayBookStockAddedRepository(db).fetch(date)).single;
    expect(batch.ratePerGram, 100);
    expect(batch.makingTotal, isNull);
    expect(batch.purchaseValue, 8000);
  });

  test('v71 purchase items retain data when nullable making column is added',
      () async {
    final directory = await Directory.systemTemp.createTemp('lotus-batch-v71-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}shop.sqlite');
    final original = AppDatabase.forTesting(NativeDatabase(file));
    final id = await _voucher(original, 'GLD-LEGACY', 'SUPPLIER', 12000, date);
    await _line(original, id, 1, 'Gold', 2, 6000, null, date);
    await original.close();

    final legacy = sqlite3.open(file.path);
    try {
      legacy.execute(
          'ALTER TABLE purchase_voucher_items DROP COLUMN making_total');
      legacy.execute('PRAGMA user_version=71');
    } finally {
      legacy.dispose();
    }

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(migrated.close);
    final rows = await migrated.customSelect(
      'SELECT line_amount, making_total FROM purchase_voucher_items WHERE purchase_voucher_id = ?',
      variables: [drift.Variable.withInt(id)],
    ).get();
    expect(rows.single.read<double>('line_amount'), 12000);
    expect(rows.single.readNullable<double>('making_total'), isNull);
  });

  test(
      'v72 migration tags old batches and moves customer metal out of saleable stock',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus-origin-v72-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}shop.sqlite');
    final original = AppDatabase.forTesting(NativeDatabase(file));
    final supplierId =
        await _voucher(original, 'GS-LEGACY', 'SUPPLIER', 12000, date);
    final customerId =
        await _voucher(original, 'CUS-LEGACY', 'CUSTOMER', 3000, date);
    await _line(original, supplierId, 1, 'Gold', 2, 6000, null, date);
    await _movement(original, supplierId, 1, 2, 1, date);
    await _movement(original, customerId, 1, 5, 1, date);
    final customerStockId = await original.into(original.stockItems).insert(
          StockItemsCompanion.insert(
            sku: 'CUSTOMER-RAW-METAL',
            itemName: 'Old Gold',
            category: 'Gold',
            subCategory: 'Old Metal',
          ),
        );
    await original.customStatement('''
      INSERT INTO stock_item_units
        (stock_item_id, purchase_voucher_id, unit_code, piece_no,
         metal_type, item_name, status, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      customerStockId,
      customerId,
      'RAW-001-LOT001',
      1,
      'Gold',
      'Old Gold',
      'Available',
      date.millisecondsSinceEpoch,
    ]);
    await original.close();

    final legacy = sqlite3.open(file.path);
    try {
      legacy.execute('DROP TRIGGER purchase_voucher_origin_immutable');
      legacy.execute('ALTER TABLE purchase_vouchers DROP COLUMN entry_origin');
      legacy.execute('PRAGMA user_version=72');
    } finally {
      legacy.dispose();
    }

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(migrated.close);
    final originRows = await migrated
        .customSelect(
          'SELECT source_type, entry_origin FROM purchase_vouchers ORDER BY id',
        )
        .get();
    expect(originRows.first.read<String>('entry_origin'), 'ADD_STOCK');
    expect(originRows.last.read<String>('entry_origin'),
        'CUSTOMER_METAL_PURCHASE');
    final customerUnit = await migrated.customSelect(
      'SELECT status FROM stock_item_units WHERE purchase_voucher_id = ?',
      variables: [drift.Variable.withInt(customerId)],
    ).getSingle();
    expect(customerUnit.read<String>('status'), 'Processing');
    final customerStock = await migrated.customSelect(
      'SELECT status FROM stock_items WHERE id = ?',
      variables: [drift.Variable.withInt(customerStockId)],
    ).getSingle();
    expect(customerStock.read<String>('status'), 'Processing');
    final customerMovement = await migrated.customSelect(
      "SELECT movement_type FROM stock_movements WHERE source_id = ?",
      variables: [drift.Variable.withString('$customerId')],
    ).getSingle();
    expect(customerMovement.read<String>('movement_type'), 'CUSTOMER_METAL_IN');
    expect(
        (await DayBookStockAddedRepository(migrated).fetch(date))
            .single
            .batchCode,
        'GS-LEGACY');
  });
}

Future<int> _voucher(
    AppDatabase db, String code, String source, double value, DateTime date,
    {String? origin}) async {
  await db.customStatement(
    '''INSERT INTO purchase_vouchers
       (voucher_no, sequence_no, source_type, entry_origin,
        party_name, grand_total, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)''',
    [
      code,
      code.hashCode.abs(),
      source,
      origin ??
          (source == 'SUPPLIER' ? 'ADD_STOCK' : 'CUSTOMER_METAL_PURCHASE'),
      'Supplier',
      value,
      date.millisecondsSinceEpoch
    ],
  );
  final row =
      await db.customSelect('SELECT last_insert_rowid() AS id').getSingle();
  return row.read<int>('id');
}

Future<void> _line(AppDatabase db, int voucherId, int lineNo, String metal,
    double weight, double rate, double? making, DateTime date) async {
  await db.customStatement(
    '''INSERT INTO purchase_voucher_items
       (purchase_voucher_id, line_no, metal_type, net_weight, rate,
        making_total, line_amount, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
    [
      voucherId,
      lineNo,
      metal,
      weight,
      rate,
      making,
      weight * rate + (making ?? 0),
      date.millisecondsSinceEpoch
    ],
  );
}

Future<void> _movement(AppDatabase db, int voucherId, int lineNo, double weight,
    int pieces, DateTime date) async {
  final stockItemId = await db.into(db.stockItems).insert(
        StockItemsCompanion.insert(
          sku: 'SKU-$voucherId-$lineNo',
          itemName: 'Source item',
          category: 'Jewellery',
          subCategory: 'Stock',
          metalType: drift.Value(weight > 50 ? 'Silver' : 'Gold'),
        ),
      );
  await db.into(db.stockMovements).insert(
        StockMovementsCompanion.insert(
          stockItemId: stockItemId,
          movementType: 'IN',
          sourceType: 'PURCHASE',
          sourceId: '$voucherId',
          sourceLineNo: drift.Value(lineNo),
          sourceNumber: drift.Value('BATCH-$voucherId'),
          skuSnapshot: 'SKU-$voucherId-$lineNo',
          metalTypeSnapshot: weight > 50 ? 'Silver' : 'Gold',
          itemNameSnapshot: 'Source item',
          quantityDelta: pieces,
          netWeightDelta: drift.Value(weight),
          occurredAt: date,
        ),
      );
}
