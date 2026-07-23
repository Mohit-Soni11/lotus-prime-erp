import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/repositories/sales_orders/pos/pos_stock_lookup_repository.dart';

void main() {
  late AppDatabase db;
  late PosStockLookupRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PosStockLookupRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('description search starts from item name and ignores selected purity',
      () async {
    await _insertLookupStock(
      db,
      sku: 'JHM-22-001',
      itemName: 'Jhumka',
      purityLabel: '22KT',
      grossWeight: 12.5,
      huid: 'HUID-J22',
    );
    await _insertLookupStock(
      db,
      sku: 'JHM-18-001',
      itemName: 'Jhumka',
      purityLabel: '18KT',
      purityPercent: 75,
      grossWeight: 10,
      huid: 'HUID-J18',
    );
    await _insertLookupStock(
      db,
      sku: 'RN-22-001',
      itemName: 'Ring',
      purityLabel: '22KT',
      grossWeight: 4,
      huid: 'HUID-R22',
    );

    final matches = await repository.searchByDescription(
      query: 'j',
      metal: MetalType.gold,
      purityLabel: '22KT',
    );

    expect(matches.map((item) => item.itemName), ['Jhumka', 'Jhumka']);
    expect(
      matches.map((item) => item.huid),
      containsAll(['HUID-J22', 'HUID-J18']),
    );
    expect(matches.map((item) => item.companyName).toSet(), {'Test Brand'});
  });

  test('description search returns stock even when selected purity differs',
      () async {
    await _insertLookupStock(
      db,
      sku: 'JHM-PCT-001',
      itemName: 'Jhumka',
      purityLabel: '',
      purityPercent: 91.67,
      grossWeight: 8,
      huid: 'HUID-PCT',
    );

    final matches = await repository.searchByDescription(
      query: 'jhumka',
      metal: MetalType.gold,
      purityLabel: '18KT',
    );

    expect(matches, hasLength(1));
    expect(matches.single.sku, 'JHM-PCT-001-U001');
  });
}

Future<int> _insertLookupStock(
  AppDatabase db, {
  required String sku,
  required String itemName,
  required String purityLabel,
  required double grossWeight,
  required String huid,
  double purityPercent = 91.67,
}) async {
  final stockItemId = await db.into(db.stockItems).insert(
        StockItemsCompanion.insert(
          sku: sku,
          itemName: itemName,
          category: 'Gold',
          subCategory: 'Retail',
          metalType: const drift.Value('Gold'),
          purity: drift.Value(purityLabel),
          grossWeight: drift.Value(grossWeight),
          netWeight: drift.Value(grossWeight),
          quantity: const drift.Value(1),
          status: drift.Value(stock.StockStatus.available.label),
          isActive: const drift.Value(true),
        ),
      );

  await db.customInsert(
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
      huid,
      gross_weight,
      less_weight,
      net_weight,
      purity_percent,
      actual_fine_weight,
      wastage_fine_weight,
      valuation_fine_weight,
      rate_per_gram,
      making_amount,
      unit_cost,
      company_name,
      supplier_name,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    variables: [
      drift.Variable<int>(stockItemId),
      const drift.Variable<String>('POS-LOOKUP'),
      drift.Variable<String>('$sku-U001'),
      const drift.Variable<int>(1),
      const drift.Variable<String>('Gold'),
      drift.Variable<String>(itemName),
      const drift.Variable<String>('Retail'),
      drift.Variable<String>(itemName),
      drift.Variable<String>(huid),
      drift.Variable<double>(grossWeight),
      const drift.Variable<double>(0),
      drift.Variable<double>(grossWeight),
      drift.Variable<double>(purityPercent),
      drift.Variable<double>(grossWeight * purityPercent / 100),
      const drift.Variable<double>(0),
      drift.Variable<double>(grossWeight * purityPercent / 100),
      const drift.Variable<double>(6000),
      const drift.Variable<double>(0),
      const drift.Variable<double>(60000),
      const drift.Variable<String>('Test Brand'),
      const drift.Variable<String>('Test Supplier'),
      drift.Variable<String>(stock.StockStatus.available.label),
      drift.Variable<int>(DateTime(2026, 7, 22, 12).millisecondsSinceEpoch),
    ],
  );

  return stockItemId;
}
