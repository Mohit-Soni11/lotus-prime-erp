import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_search_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('search supports lifecycle filters, supplier search and weight sorting',
      () async {
    final now = DateTime.now();
    final lightId = await _insertStockItem(
      database,
      sku: 'SEARCH-GOLD-LIGHT',
      itemName: 'Light Ring',
      subCategory: 'Ring',
      metal: stock.MetalType.gold.label,
      createdAt: now.subtract(const Duration(minutes: 2)),
    );
    final heavyId = await _insertStockItem(
      database,
      sku: 'SEARCH-SILVER-HEAVY',
      itemName: 'Heavy Payal',
      subCategory: 'Payal',
      metal: stock.MetalType.silver.label,
      category: stock.StockCategory.silver.label,
      createdAt: now,
    );

    await _insertStockUnit(
      database,
      stockItemId: lightId,
      unitCode: 'SEARCH-GOLD-LIGHT-U1',
      metal: stock.MetalType.gold.label,
      itemType: 'Ring',
      itemName: 'Light Ring',
      supplierName: 'Raj Jewellers',
      status: stock.StockStatus.available.label,
      purity: 91.6,
      netWeight: 5,
      unitCost: 25000,
      createdAt: now.subtract(const Duration(minutes: 2)),
    );
    await _insertStockUnit(
      database,
      stockItemId: heavyId,
      unitCode: 'SEARCH-SILVER-HEAVY-U1',
      metal: stock.MetalType.silver.label,
      itemType: 'Payal',
      itemName: 'Heavy Payal',
      supplierName: 'Sukh Silver',
      status: stock.StockStatus.onHold.label,
      purity: 60,
      netWeight: 80,
      unitCost: 18000,
      createdAt: now,
    );

    final controller = StockSearchController(database);
    await controller.load();

    expect(controller.errorMessage, isNull);
    expect(controller.results, hasLength(2));

    controller.setStatusFilter('On Hold');
    await _waitForLoad(controller);

    expect(controller.results, hasLength(1));
    expect(controller.results.single.itemName, 'Heavy Payal');

    controller.clearFilters();
    await _waitForLoad(controller);
    controller.setSearchText('Raj');
    await _waitForLoad(controller);

    expect(controller.results, hasLength(1));
    expect(controller.results.single.supplierName, 'Raj Jewellers');

    controller.clearFilters();
    await _waitForLoad(controller);
    controller.setSortMode('Weight High');
    await _waitForLoad(controller);

    expect(controller.results.first.itemName, 'Heavy Payal');
    expect(controller.results.first.netWeight, closeTo(80, 0.001));
  });

  test('summary total net weight counts sold HUID stock once', () async {
    final now = DateTime.now();
    final availableId = await _insertStockItem(
      database,
      sku: 'SEARCH-GOLD-AVAILABLE',
      itemName: 'Available Ring',
      subCategory: 'Ring',
      metal: stock.MetalType.gold.label,
      createdAt: now,
    );
    final soldId = await _insertStockItem(
      database,
      sku: 'SEARCH-GOLD-SOLD',
      itemName: 'Sold Jhumka',
      subCategory: 'Jhumka',
      metal: stock.MetalType.gold.label,
      status: stock.StockStatus.sold.label,
      createdAt: now,
    );

    await _insertStockUnit(
      database,
      stockItemId: availableId,
      unitCode: 'SEARCH-GOLD-AVAILABLE-U1',
      metal: stock.MetalType.gold.label,
      itemType: 'Ring',
      itemName: 'Available Ring',
      supplierName: 'Raj Jewellers',
      status: stock.StockStatus.available.label,
      purity: 75,
      netWeight: 5,
      unitCost: 25000,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: soldId,
      unitCode: 'SEARCH-GOLD-SOLD-U1',
      metal: stock.MetalType.gold.label,
      itemType: 'Jhumka',
      itemName: 'Sold Jhumka',
      supplierName: 'Raj Jewellers',
      status: stock.StockStatus.sold.label,
      purity: 75,
      netWeight: 6.351,
      unitCost: 30000,
      createdAt: now,
    );
    await _insertLinkedBillItem(
      database,
      stockItemId: soldId,
      itemName: 'Sold Jhumka',
      netWeight: 6.35,
      billDate: now,
    );

    final controller = StockSearchController(database);
    await controller.load();

    expect(controller.errorMessage, isNull);
    expect(controller.summary.availableWeight, closeTo(5, 0.001));
    expect(controller.summary.soldWeight, closeTo(6.35, 0.001));
    expect(controller.summary.netWeight, closeTo(11.35, 0.001));
  });
}

Future<void> _waitForLoad(StockSearchController controller) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    if (!controller.isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<int> _insertStockItem(
  AppDatabase database, {
  required String sku,
  required String itemName,
  required String subCategory,
  required String metal,
  required DateTime createdAt,
  String category = 'Gold',
  String status = 'Available',
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
          status: drift.Value(status),
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
  required String supplierName,
  required String status,
  required double purity,
  required double netWeight,
  required double unitCost,
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
      valuation_fine_weight,
      unit_cost,
      supplier_name,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
      netWeight * purity / 100,
      unitCost,
      supplierName,
      status,
      createdAt.millisecondsSinceEpoch,
    ],
  );
}

Future<void> _insertLinkedBillItem(
  AppDatabase database, {
  required int stockItemId,
  required String itemName,
  required double netWeight,
  required DateTime billDate,
}) async {
  final billId = await database.into(database.bills).insert(
        BillsCompanion.insert(
          billNo: 'SEARCH-BILL-$stockItemId',
          customerName: const drift.Value('Test Customer'),
          billDate: drift.Value(billDate),
          status: const drift.Value('ACTIVE'),
          finalAmount: drift.Value(netWeight * 1000),
        ),
      );

  await database.into(database.billItems).insert(
        BillItemsCompanion.insert(
          billId: billId,
          lineNo: const drift.Value(1),
          metalType: const drift.Value('GOLD'),
          itemName: itemName,
          purity: const drift.Value('18KT'),
          quantity: const drift.Value(1),
          grossWeight: drift.Value(netWeight),
          netWeight: drift.Value(netWeight),
          linkedStockItemId: drift.Value(stockItemId),
        ),
      );
}
