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

  test('description and HUID lookup keep gold and silver stock isolated',
      () async {
    await _insertLookupStock(
      db,
      sku: 'GOLD-RING-001',
      itemName: 'Casting Ring',
      purityLabel: '22KT',
      grossWeight: 5.2,
      huid: 'GOLD-HUID-01',
      metalType: 'Gold',
      category: 'Gold',
    );
    final silverStockId = await _insertLookupStock(
      db,
      sku: 'SIL-RING-001',
      itemName: 'Casting Ring',
      purityLabel: '925',
      grossWeight: 12.4,
      huid: 'SIL-HUID-01',
      metalType: 'Silver',
      category: 'Silver',
    );
    await db.customUpdate(
      '''
      UPDATE stock_item_units
      SET metal_type = ?
      WHERE stock_item_id = ?
      ''',
      variables: [
        const drift.Variable<String>('Gold'),
        drift.Variable<int>(silverStockId),
      ],
    );

    final goldMatches = await repository.searchByDescription(
      query: 'casting',
      metal: MetalType.gold,
    );
    final silverMatches = await repository.searchByDescription(
      query: 'casting',
      metal: MetalType.silver,
    );
    final goldHuidMatch = await repository.findExactByHuid(
      query: 'SIL-HUID-01',
      metal: MetalType.gold,
    );
    final silverHuidMatch = await repository.findExactByHuid(
      query: 'SIL-HUID-01',
      metal: MetalType.silver,
    );

    expect(goldMatches.map((item) => item.sku), ['GOLD-RING-001-U001']);
    expect(silverMatches.map((item) => item.sku), ['SIL-RING-001-U001']);
    expect(goldMatches.single.metal, MetalType.gold);
    expect(silverMatches.single.metal, MetalType.silver);
    expect(goldHuidMatch, isNull);
    expect(silverHuidMatch, isNotNull);
    expect(silverHuidMatch!.sku, 'SIL-RING-001-U001');
    expect(silverHuidMatch.metal, MetalType.silver);
  });

  test(
      'unique exact description resolves typed stock without picking prefix rows',
      () async {
    await _insertLookupStock(
      db,
      sku: 'CHAND-001',
      itemName: 'CHAND',
      purityLabel: '999',
      grossWeight: 11.95,
      huid: '',
    );
    await _insertLookupStock(
      db,
      sku: 'OPP-CHAND-001',
      itemName: 'OPP. CHAND',
      purityLabel: '999',
      grossWeight: 11.95,
      huid: '',
    );

    final match = await repository.findUniqueExactDescription(
      query: 'CHAND',
      metal: MetalType.gold,
    );

    expect(match, isNotNull);
    expect(match!.itemName, 'CHAND');
    expect(match.sku, 'CHAND-001-U001');
  });

  test('unique exact description refuses ambiguous same-name stock', () async {
    await _insertLookupStock(
      db,
      sku: 'CHAIN-001',
      itemName: 'CHAIN',
      purityLabel: '999',
      grossWeight: 20.30,
      huid: '',
    );
    await _insertLookupStock(
      db,
      sku: 'CHAIN-002',
      itemName: 'CHAIN',
      purityLabel: '999',
      grossWeight: 17.95,
      huid: '',
    );

    final match = await repository.findUniqueExactDescription(
      query: 'CHAIN',
      metal: MetalType.gold,
    );

    expect(match, isNull);
  });

  test('packet stock lookup shows current available packet balance', () async {
    await _insertLookupStock(
      db,
      sku: 'SIL-PAYAL-PACK-001',
      itemName: 'PAYAL',
      purityLabel: '35.50',
      grossWeight: 500,
      huid: '',
      metalType: 'Silver',
      category: 'Silver',
      quantityMode: 'packet',
      quantity: 32,
      packetCount: 33,
      piecesPerPacket: 2,
      stockGrossWeight: 474.7,
      stockNetWeight: 458.2,
      unitNetWeight: 483.5,
    );

    final matches = await repository.searchByDescription(
      query: 'payal',
      metal: MetalType.silver,
    );

    expect(matches, hasLength(1));
    expect(matches.single.quantityUnitLabel, 'packet');
    expect(matches.single.availableQuantity, 32);
    expect(matches.single.quantity, 32);
    expect(matches.single.grossWeight, closeTo(474.7, 0.001));
    expect(matches.single.netWeight, closeTo(458.2, 0.001));
  });

  test('gold lot lookup shows current available balance after partial sale',
      () async {
    await _insertLookupStock(
      db,
      sku: 'GOLD-NOSEPIN-LOT-001',
      itemName: 'NOSE PIN',
      purityLabel: '18KT',
      grossWeight: 8.35,
      huid: '',
      metalType: 'Gold',
      category: 'Gold',
      quantityMode: 'PIECES',
      quantity: 14,
      unitCode: 'GOLD-NOSEPIN-LOT-001-LOT001',
      stockGrossWeight: 7.8,
      stockNetWeight: 7.8,
      unitNetWeight: 8.35,
    );

    final matches = await repository.searchByDescription(
      query: 'nose',
      metal: MetalType.gold,
    );

    expect(matches, hasLength(1));
    expect(matches.single.quantityUnitLabel, 'pcs');
    expect(matches.single.availableQuantity, 14);
    expect(matches.single.quantity, 14);
    expect(matches.single.grossWeight, closeTo(7.8, 0.001));
    expect(matches.single.netWeight, closeTo(7.8, 0.001));
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
  String metalType = 'Gold',
  String category = 'Gold',
  String quantityMode = 'PIECES',
  int quantity = 1,
  int packetCount = 0,
  int piecesPerPacket = 1,
  String? unitCode,
  double? stockGrossWeight,
  double? stockNetWeight,
  double? unitGrossWeight,
  double? unitNetWeight,
}) async {
  final stockGross = stockGrossWeight ?? grossWeight;
  final stockNet = stockNetWeight ?? stockGross;
  final unitGross = unitGrossWeight ?? grossWeight;
  final unitNet = unitNetWeight ?? unitGross;

  final stockItemId = await db.into(db.stockItems).insert(
        StockItemsCompanion.insert(
          sku: sku,
          itemName: itemName,
          category: category,
          subCategory: 'Retail',
          metalType: drift.Value(metalType),
          purity: drift.Value(purityLabel),
          grossWeight: drift.Value(stockGross),
          stoneWeight: drift.Value(
            (stockGross - stockNet).clamp(0.0, stockGross).toDouble(),
          ),
          netWeight: drift.Value(stockNet),
          quantity: drift.Value(quantity),
          status: drift.Value(stock.StockStatus.available.label),
          isActive: const drift.Value(true),
        ),
      );

  await db.ensureStockInventorySchema();
  await db.customUpdate(
    '''
    UPDATE stock_items
    SET quantity_mode = ?,
        packet_count = ?,
        pieces_per_packet = ?
    WHERE id = ?
    ''',
    variables: [
      drift.Variable<String>(quantityMode),
      drift.Variable<int>(packetCount),
      drift.Variable<int>(piecesPerPacket),
      drift.Variable<int>(stockItemId),
    ],
    updates: {db.stockItems},
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
      drift.Variable<String>(unitCode ?? '$sku-U001'),
      const drift.Variable<int>(1),
      drift.Variable<String>(metalType),
      drift.Variable<String>(itemName),
      const drift.Variable<String>('Retail'),
      drift.Variable<String>(itemName),
      drift.Variable<String>(huid),
      drift.Variable<double>(unitGross),
      const drift.Variable<double>(0),
      drift.Variable<double>(unitNet),
      drift.Variable<double>(purityPercent),
      drift.Variable<double>(unitNet * purityPercent / 100),
      const drift.Variable<double>(0),
      drift.Variable<double>(unitNet * purityPercent / 100),
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
