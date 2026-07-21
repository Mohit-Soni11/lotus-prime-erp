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
  final row = await database.customSelect(
    'SELECT last_insert_rowid() AS id',
  ).getSingle();
  return row.read<int>('id');
}
