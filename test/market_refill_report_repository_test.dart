import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/market_refill_report_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/market_refill/market_refill_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;

void main() {
  late AppDatabase database;
  late MarketRefillReportRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = MarketRefillReportRepository(database);
  });

  tearDown(() => database.close());

  test('report converts sold movements into market refill rows', () async {
    final now = DateTime.now();
    await _ensureReportColumns(database);
    final silverPayalId = await _insertStockItem(
      database,
      sku: 'LJ-REFILL-SIL-PAYAL-001',
      itemName: 'Dulhan Payal',
      subCategory: 'Payal',
      metal: 'Silver',
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: silverPayalId,
      unitCode: 'UNIT-REFILL-SIL-PAYAL-001',
      metal: 'Silver',
      itemType: 'Payal',
      itemName: 'Dulhan Payal',
      netWeight: 50,
      purityPercent: 79,
      companyName: 'Raj',
      createdAt: now,
    );
    await _insertStockMovement(
      database,
      stockItemId: silverPayalId,
      movementType: 'SALE',
      sourceId: 'INV-PAYAL',
      sourceNumber: 'INV-PAYAL-001',
      quantityDelta: -3,
      netWeightDelta: -150,
      occurredAt: now,
    );

    final secondSilverPayalId = await _insertStockItem(
      database,
      sku: 'LJ-REFILL-SIL-PAYAL-002',
      itemName: 'Simple Payal',
      subCategory: 'Payal',
      metal: 'Silver',
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: secondSilverPayalId,
      unitCode: 'UNIT-REFILL-SIL-PAYAL-002',
      metal: 'Silver',
      itemType: 'Payal',
      itemName: 'Simple Payal',
      netWeight: 40,
      purityPercent: 79,
      companyName: 'Sukh',
      createdAt: now,
    );
    await _insertStockMovement(
      database,
      stockItemId: secondSilverPayalId,
      movementType: 'SALE',
      sourceId: 'INV-PAYAL-2',
      sourceNumber: 'INV-PAYAL-002',
      quantityDelta: -2,
      netWeightDelta: -80,
      occurredAt: now,
    );

    final goldChainId = await _insertStockItem(
      database,
      sku: 'LJ-REFILL-GOLD-CHAIN-001',
      itemName: 'Gold Chain',
      subCategory: 'Chain',
      metal: 'Gold',
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: goldChainId,
      unitCode: 'UNIT-REFILL-GOLD-CHAIN-001',
      metal: 'Gold',
      itemType: 'Chain',
      itemName: 'Gold Chain',
      netWeight: 18,
      purityPercent: 91.6,
      status: stock.StockStatus.sold.label,
      createdAt: now,
    );
    await _insertStockMovement(
      database,
      stockItemId: goldChainId,
      movementType: 'SALE',
      sourceId: 'INV-CHAIN',
      sourceNumber: 'INV-CHAIN-001',
      quantityDelta: -1,
      netWeightDelta: -18,
      occurredAt: now,
    );

    final report = await repository.loadReport(
      MarketRefillDateRange(
        start: now.subtract(const Duration(days: 1)),
        end: now.add(const Duration(days: 1)),
        label: 'Test Range',
      ),
    );

    expect(report.rows, hasLength(3));
    expect(report.summary.soldQuantity, 6);
    expect(report.summary.refillQuantity, 6);
    expect(report.summary.metalGroups, 2);

    final payal = report.rows.singleWhere((row) => row.companyLabel == 'Raj');
    expect(payal.unitLabel, 'pair');
    expect(payal.soldQuantity, 3);
    expect(payal.availableQuantity, 1);
    expect(payal.refillQuantity, 3);
    expect(payal.soldNetWeight, 150);
    expect(payal.companyLabel, 'Raj');

    final sukhPayal =
        report.rows.singleWhere((row) => row.companyLabel == 'Sukh');
    expect(sukhPayal.itemType, 'Payal');
    expect(sukhPayal.soldQuantity, 2);

    final chain = report.rows.singleWhere((row) => row.itemType == 'Chain');
    expect(chain.availableQuantity, 0);
    expect(chain.statusLabel, 'Refill Now');

    final active = await repository.loadActiveReport();
    final activePayal =
        active.rows.singleWhere((row) => row.companyLabel == 'Raj');
    await repository.saveLineProgress(
      progressScope: active.progressScope,
      rowKey: activePayal.rowKey,
      boughtQuantity: 2,
      purchaseDone: true,
    );

    final reloaded = await repository.loadActiveReport();
    final savedPayal =
        reloaded.rows.singleWhere((row) => row.companyLabel == 'Raj');
    expect(savedPayal.boughtQuantity, 2);
    expect(savedPayal.purchaseDone, isTrue);
  });

  test('checkout clears current purchase list and starts a fresh window',
      () async {
    final now = DateTime.now();
    await _ensureReportColumns(database);
    final itemId = await _insertStockItem(
      database,
      sku: 'LJ-REFILL-CHECKOUT-001',
      itemName: 'Gold Ring',
      subCategory: 'Ring',
      metal: 'Gold',
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: itemId,
      unitCode: 'UNIT-REFILL-CHECKOUT-001',
      metal: 'Gold',
      itemType: 'Ring',
      itemName: 'Gold Ring',
      netWeight: 10,
      purityPercent: 91.6,
      status: stock.StockStatus.sold.label,
      createdAt: now,
    );
    await _insertStockMovement(
      database,
      stockItemId: itemId,
      movementType: 'SALE',
      sourceId: 'INV-CHECKOUT-OLD',
      sourceNumber: 'INV-CHECKOUT-OLD',
      quantityDelta: -1,
      netWeightDelta: -10,
      occurredAt: now.subtract(const Duration(minutes: 2)),
    );

    final activeBeforeCheckout = await repository.loadActiveReport();
    expect(activeBeforeCheckout.rows, hasLength(1));

    await repository.saveLineProgress(
      progressScope: activeBeforeCheckout.progressScope,
      rowKey: activeBeforeCheckout.rows.single.rowKey,
      boughtQuantity: 4,
      purchaseDone: true,
    );

    final readyForCheckout = await repository.loadActiveReport();
    await repository.checkoutAndClear(report: readyForCheckout);
    expect((await repository.loadActiveReport()).rows, isEmpty);

    final history = await repository.loadRecentCheckouts();
    expect(history, hasLength(1));
    expect(history.single.soldQuantity, 1);

    final oldCheckoutAt =
        DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch;
    await database.customStatement(
      '''
      INSERT INTO market_refill_checkout_history (
        checkout_no,
        checked_out_at,
        cleared_until,
        sold_quantity,
        item_groups,
        metal_groups,
        sold_net_weight
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      ['MPL-OLD-001', oldCheckoutAt, oldCheckoutAt, 1, 1, 1, 0.0],
    );
    final oldCheckout = await database.customSelect(
      '''
      SELECT id
      FROM market_refill_checkout_history
      WHERE checkout_no = ?
      ''',
      variables: [const drift.Variable<String>('MPL-OLD-001')],
    ).getSingle();
    final oldCheckoutId = oldCheckout.data['id'] as int;
    await database.customStatement(
      '''
      INSERT INTO market_refill_checkout_lines (
        checkout_id,
        row_key,
        metal,
        grade_label,
        company_name,
        item_type,
        unit_label,
        sold_quantity,
        bought_quantity,
        is_checked,
        sold_net_weight
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        oldCheckoutId,
        'old|gold|18kt|ring|pcs',
        'Gold',
        '18KT (75%)',
        '',
        'Ring',
        'pcs',
        1,
        1,
        1,
        0.0,
      ],
    );

    final retainedHistory = await repository.loadRecentCheckouts();
    expect(
      retainedHistory.map((record) => record.checkoutNo),
      contains(history.single.checkoutNo),
    );
    expect(
      retainedHistory.map((record) => record.checkoutNo),
      isNot(contains('MPL-OLD-001')),
    );
    final staleHistory = await database.customSelect(
      '''
      SELECT COUNT(*) AS count
      FROM market_refill_checkout_history
      WHERE checkout_no = ?
      ''',
      variables: [const drift.Variable<String>('MPL-OLD-001')],
    ).getSingle();
    final staleLines = await database.customSelect(
      '''
      SELECT COUNT(*) AS count
      FROM market_refill_checkout_lines
      WHERE checkout_id = ?
      ''',
      variables: [drift.Variable<int>(oldCheckoutId)],
    ).getSingle();
    expect(staleHistory.data['count'], 0);
    expect(staleLines.data['count'], 0);

    final checkoutLine = await database.customSelect(
      '''
      SELECT bought_quantity, is_checked
      FROM market_refill_checkout_lines
      WHERE checkout_id = ?
      ''',
      variables: [drift.Variable<int>(history.single.id)],
    ).getSingle();
    expect(checkoutLine.data['bought_quantity'], 4);
    expect(checkoutLine.data['is_checked'], 1);

    await repository.restoreClearedList();
    final restored = await repository.loadActiveReport();
    expect(restored.rows, hasLength(1));
    expect(restored.rows.single.boughtQuantity, 4);
    expect(restored.rows.single.purchaseDone, isTrue);

    await repository.checkoutAndClear();

    await _insertStockMovement(
      database,
      stockItemId: itemId,
      movementType: 'SALE',
      sourceId: 'INV-CHECKOUT-NEW',
      sourceNumber: 'INV-CHECKOUT-NEW',
      quantityDelta: -2,
      netWeightDelta: -20,
      occurredAt: DateTime.now().add(const Duration(milliseconds: 5)),
    );

    final fresh = await repository.loadActiveReport();
    expect(fresh.rows, hasLength(1));
    expect(fresh.rows.single.soldQuantity, 2);
  });
}

Future<void> _ensureReportColumns(AppDatabase database) async {
  await database.customStatement(
    'ALTER TABLE stock_item_units ADD COLUMN company_name TEXT',
  );
  await database.customStatement(
    'ALTER TABLE stock_items ADD COLUMN company_name TEXT',
  );
}

Future<int> _insertStockItem(
  AppDatabase database, {
  required String sku,
  required String itemName,
  required String subCategory,
  required String metal,
  required DateTime createdAt,
}) {
  return database.into(database.stockItems).insert(
        StockItemsCompanion.insert(
          createdAt: drift.Value(createdAt),
          sku: sku,
          itemName: itemName,
          category: metal,
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
  required double netWeight,
  required double purityPercent,
  String companyName = '',
  String? status,
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
      company_name,
      gross_weight,
      less_weight,
      net_weight,
      purity_percent,
      actual_fine_weight,
      supplier_name,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
      companyName,
      netWeight,
      0.0,
      netWeight,
      purityPercent,
      netWeight * (purityPercent / 100),
      'Lotus Supplier',
      status ?? stock.StockStatus.available.label,
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
  required int quantityDelta,
  required double netWeightDelta,
  required DateTime occurredAt,
}) async {
  await database.customStatement(
    '''
    INSERT INTO stock_movements (
      stock_item_id,
      movement_type,
      source_type,
      source_id,
      source_number,
      sku_snapshot,
      metal_type_snapshot,
      item_name_snapshot,
      quantity_delta,
      gross_weight_delta,
      net_weight_delta,
      fine_weight_delta,
      occurred_at,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      stockItemId,
      movementType,
      'SALE',
      sourceId,
      sourceNumber,
      'LJ-REFILL',
      'Gold',
      'Refill Item',
      quantityDelta,
      netWeightDelta,
      netWeightDelta,
      netWeightDelta,
      occurredAt.millisecondsSinceEpoch,
      occurredAt.millisecondsSinceEpoch,
    ],
  );
  final row = await database
      .customSelect(
        'SELECT last_insert_rowid() AS id',
      )
      .getSingle();
  return row.read<int>('id');
}
