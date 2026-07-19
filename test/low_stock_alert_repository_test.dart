import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/low_stock_alert_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;

void main() {
  late AppDatabase database;
  late LowStockAlertRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LowStockAlertRepository(database);
  });

  tearDown(() => database.close());

  test('dashboard seeds default rules and flags critical low stock', () async {
    final now = DateTime.now();
    final stockItemId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-LOW-001',
      itemName: 'Gold Ring',
      subCategory: 'Ring',
      metal: 'Gold',
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: stockItemId,
      unitCode: 'UNIT-GOLD-LOW-001',
      metal: 'Gold',
      itemType: 'Ring',
      itemName: 'Gold Ring',
      netWeight: 7.5,
      createdAt: now,
    );

    final dashboard = await repository.loadDashboard();

    expect(dashboard.rules, hasLength(4));
    expect(dashboard.summary.watchedGroups, 1);
    expect(dashboard.summary.availableUnits, 1);
    expect(dashboard.metalCards, hasLength(1));
    expect(dashboard.gradeCards, hasLength(1));
    expect(dashboard.itemGroupCards, hasLength(1));
    expect(dashboard.itemTypeCards, hasLength(1));

    final gold = dashboard.itemTypeCards.firstWhere(
      (card) => card.metalType == 'Gold',
    );
    expect(gold.availableUnits, 1);
    expect(gold.totalUnits, 1);
    expect(gold.soldUnits, 0);
    expect(gold.riskLevel, LowStockRiskLevel.critical);
    expect(gold.suggestedReorderUnits, 9);
    expect(gold.suggestedReorderNetWeight, 12.5);
  });

  test('silver item type card combines the same item across grades', () async {
    final now = DateTime.now();
    final firstItemId = await _insertStockItem(
      database,
      sku: 'LJ-SIL-PAYAL-001',
      itemName: 'Dulhan Payal',
      subCategory: 'Payal',
      metal: 'Silver',
      createdAt: now,
    );
    final secondItemId = await _insertStockItem(
      database,
      sku: 'LJ-SIL-PAYAL-002',
      itemName: 'Fancy Payal',
      subCategory: 'Payal',
      metal: 'Silver',
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: firstItemId,
      unitCode: 'UNIT-SIL-PAYAL-001',
      metal: 'Silver',
      itemType: 'Payal',
      itemName: 'Dulhan Payal',
      netWeight: 200,
      purityPercent: 925,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: secondItemId,
      unitCode: 'UNIT-SIL-PAYAL-002',
      metal: 'Silver',
      itemType: 'Payal',
      itemName: 'Fancy Payal',
      netWeight: 150,
      purityPercent: 800,
      status: stock.StockStatus.sold.label,
      createdAt: now,
    );

    final dashboard = await repository.loadDashboard();

    expect(dashboard.metalCards, hasLength(1));
    expect(dashboard.itemGroupCards, hasLength(1));

    final payal = dashboard.itemGroupCards.single;
    expect(payal.metalType, 'Silver');
    expect(payal.itemType, 'Payal');
    expect(payal.totalUnits, 2);
    expect(payal.availableUnits, 1);
    expect(payal.soldUnits, 1);

    final silverDetails = dashboard.itemTypeCards
        .where((card) => card.metalType == 'Silver' && card.itemType == 'Payal')
        .toList(growable: false);
    expect(silverDetails, hasLength(2));
  });
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
  double purityPercent = 91.6,
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
      gross_weight,
      less_weight,
      net_weight,
      purity_percent,
      actual_fine_weight,
      supplier_name,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
      purityPercent,
      netWeight * (purityPercent / 100),
      'Lotus Supplier',
      status ?? stock.StockStatus.available.label,
      createdAt.millisecondsSinceEpoch,
    ],
  );
}
