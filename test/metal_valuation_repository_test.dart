import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_grade_repository.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_repository.dart';

void main() {
  late AppDatabase database;
  late MetalValuationRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = MetalValuationRepository(database: database);
  });

  tearDown(() => database.close());

  test('exposes valuation purity across summary, batch and item ledger',
      () async {
    await _insertStockUnit(
      database,
      unitCode: 'GOLD-VAL-001',
      netWeight: 10,
      actualFineWeight: 9,
      purityPercent: 91.6,
      wastagePercent: 0,
      valuationFineWeight: 9.16,
      status: 'Available',
    );

    final snapshot = await repository.fetchSnapshot();
    final goldBreakdown = snapshot.breakdown.single;
    final batch = snapshot.batchSummaries.single;
    final item = snapshot.availableStock.single;

    expect(
      snapshot.summary.availableValuationPurityPercent,
      closeTo(91.6, 0.001),
    );
    expect(snapshot.summary.availablePurityPercent, closeTo(91.6, 0.001));
    expect(snapshot.summary.availableWastagePercent, closeTo(0, 0.001));
    expect(goldBreakdown.availablePurityPercent, closeTo(91.6, 0.001));
    expect(goldBreakdown.availableWastagePercent, closeTo(0, 0.001));
    expect(goldBreakdown.availableValuationPurityPercent, closeTo(91.6, 0.001));
    expect(batch.purityPercent, closeTo(91.6, 0.001));
    expect(batch.wastagePercent, closeTo(0, 0.001));
    expect(batch.valuationPurityPercent, closeTo(91.6, 0.001));
    expect(item.purityPercent, closeTo(91.6, 0.001));
    expect(item.wastagePercent, closeTo(0, 0.001));
    expect(item.valuationPurityPercent, closeTo(91.6, 0.001));
  });

  test('uses stored purity and wastage instead of rounded fine weight',
      () async {
    await _insertStockUnit(
      database,
      unitCode: 'CASTING-RING-001',
      netWeight: 10,
      actualFineWeight: 7.495,
      purityPercent: 75,
      wastagePercent: 3,
      valuationFineWeight: 7.8,
      status: 'Available',
    );

    final snapshot = await repository.fetchSnapshot();
    final goldBreakdown = snapshot.breakdown.single;
    final batch = snapshot.batchSummaries.single;
    final item = snapshot.availableStock.single;

    expect(snapshot.summary.availablePurityPercent, closeTo(75, 0.001));
    expect(snapshot.summary.availableWastagePercent, closeTo(3, 0.001));
    expect(
        snapshot.summary.availableValuationPurityPercent, closeTo(78, 0.001));
    expect(goldBreakdown.availablePurityPercent, closeTo(75, 0.001));
    expect(goldBreakdown.availableWastagePercent, closeTo(3, 0.001));
    expect(goldBreakdown.availableValuationPurityPercent, closeTo(78, 0.001));
    expect(batch.purityPercent, closeTo(75, 0.001));
    expect(batch.wastagePercent, closeTo(3, 0.001));
    expect(batch.valuationPurityPercent, closeTo(78, 0.001));
    expect(item.purityPercent, closeTo(75, 0.001));
    expect(item.wastagePercent, closeTo(3, 0.001));
    expect(item.valuationPurityPercent, closeTo(78, 0.001));
  });

  test('prefers live stock unit values over linked purchase line fallback',
      () async {
    final purchaseVoucherId = await _insertPurchaseVoucher(database);
    final purchaseItemId = await _insertPurchaseLine(
      database,
      purchaseVoucherId: purchaseVoucherId,
      grossWeight: 99,
      netWeight: 99,
      purityPercent: 74.95,
      wastagePercent: 9,
      valuationFineWeight: 99,
      ratePerGram: 1,
      lineAmount: 99,
    );

    await _insertStockUnit(
      database,
      unitCode: 'LIVE-STOCK-RING-001',
      netWeight: 10,
      actualFineWeight: 7.5,
      purityPercent: 75,
      wastagePercent: 3,
      valuationFineWeight: 7.8,
      ratePerGram: 7000,
      makingAmount: 123,
      unitCost: 54723,
      purchaseVoucherId: purchaseVoucherId,
      purchaseVoucherItemId: purchaseItemId,
      status: 'Available',
    );

    final snapshot = await repository.fetchSnapshot();
    final batch = snapshot.batchSummaries.single;
    final item = snapshot.availableStock.single;

    expect(item.itemName, 'Gold Ring');
    expect(item.unitCode, 'LIVE-STOCK-RING-001');
    expect(item.grossWeight, closeTo(10, 0.001));
    expect(item.netWeight, closeTo(10, 0.001));
    expect(item.purityPercent, closeTo(75, 0.001));
    expect(item.wastagePercent, closeTo(3, 0.001));
    expect(item.valuationPurityPercent, closeTo(78, 0.001));
    expect(item.valuationFine, closeTo(7.8, 0.001));
    expect(item.ratePerGram, closeTo(7000, 0.001));
    expect(item.makingAmount, closeTo(123, 0.001));
    expect(item.unitCost, closeTo(54723, 0.001));

    expect(batch.totalGrossWeight, closeTo(10, 0.001));
    expect(batch.totalNetWeight, closeTo(10, 0.001));
    expect(batch.purityPercent, closeTo(75, 0.001));
    expect(batch.wastagePercent, closeTo(3, 0.001));
    expect(batch.valuationPurityPercent, closeTo(78, 0.001));
    expect(batch.ratePerGram, closeTo(7000, 0.001));
    expect(batch.makingAmount, closeTo(123, 0.001));
    expect(batch.totalCost, closeTo(54723, 0.001));
  });

  test('item valuation ledger keeps original add-stock lot valuation',
      () async {
    final purchaseVoucherId = await _insertPurchaseVoucher(database);
    final purchaseItemId = await _insertPurchaseLine(
      database,
      purchaseVoucherId: purchaseVoucherId,
      grossWeight: 5,
      netWeight: 5,
      purityPercent: 75,
      wastagePercent: 3,
      valuationFineWeight: 3.9,
      ratePerGram: 14150,
      quantity: 14,
      lineAmount: 55315.93,
    );
    final unitId = await _insertStockUnit(
      database,
      unitCode: 'GOLD-LOT-001',
      itemType: 'Nose Pin',
      itemName: 'Nose Pin',
      netWeight: 5,
      actualFineWeight: 3.75,
      purityPercent: 75,
      wastagePercent: 3,
      valuationFineWeight: 3.9,
      ratePerGram: 14150,
      unitCost: 55315.93,
      purchaseVoucherId: purchaseVoucherId,
      purchaseVoucherItemId: purchaseItemId,
      status: 'Available',
    );

    await database.customStatement(
      '''
      UPDATE stock_item_units
      SET huid = '',
          gross_weight = 3.0,
          net_weight = 3.0,
          actual_fine_weight = 2.25,
          wastage_fine_weight = 0.09,
          valuation_fine_weight = 2.34,
          unit_cost = 33189.56
      WHERE id = ?
      ''',
      [unitId],
    );

    final snapshot = await repository.fetchSnapshot();
    final item = snapshot.availableStock.single;
    final batch = snapshot.batchSummaries.single;

    expect(item.itemName, 'Nose Pin');
    expect(item.unitLabel, '14 pcs');
    expect(item.grossWeight, closeTo(5, 0.001));
    expect(item.netWeight, closeTo(5, 0.001));
    expect(item.purityPercent, closeTo(75, 0.001));
    expect(item.wastagePercent, closeTo(3, 0.001));
    expect(item.valuationPurityPercent, closeTo(78, 0.001));
    expect(item.valuationFine, closeTo(3.9, 0.001));
    expect(item.ratePerGram, closeTo(14150, 0.001));
    expect(item.makingAmount, closeTo(130.93, 0.001));
    expect(item.unitCost, closeTo(55315.93, 0.001));
    expect(batch.makingAmount, closeTo(130.93, 0.001));
  });

  test('item valuation ledger excludes sold stock units', () async {
    await _insertStockUnit(
      database,
      unitCode: 'GOLD-AVAILABLE-001',
      netWeight: 10,
      actualFineWeight: 9,
      purityPercent: 91.6,
      wastagePercent: 0,
      valuationFineWeight: 9.16,
      status: 'Available',
    );
    await _insertStockUnit(
      database,
      unitCode: 'GOLD-SOLD-001',
      netWeight: 5,
      actualFineWeight: 4.5,
      purityPercent: 91.6,
      wastagePercent: 0,
      valuationFineWeight: 4.58,
      status: 'Sold',
    );

    final snapshot = await repository.fetchSnapshot();

    expect(snapshot.availableStock, hasLength(1));
    expect(snapshot.availableStock.single.unitCode, 'GOLD-AVAILABLE-001');
    expect(snapshot.summary.availableNetWeight, closeTo(10, 0.001));
    expect(
      snapshot.batchSummaries.single.availableNetWeight,
      closeTo(10, 0.001),
    );
  });

  test('sold audit uses invoice customer and live stock cost basis', () async {
    final customerId = await database.into(database.customers).insert(
          CustomersCompanion.insert(
            name: 'Asha Devi',
            mobile: '9000000001',
            city: const drift.Value('Jaipur'),
          ),
        );
    final unitId = await _insertStockUnit(
      database,
      unitCode: 'SOLD-RING-001',
      netWeight: 8,
      actualFineWeight: 6,
      purityPercent: 75,
      wastagePercent: 3,
      valuationFineWeight: 6.24,
      unitCost: 52000,
      status: 'Sold',
    );
    final billId = await database.into(database.bills).insert(
          BillsCompanion.insert(
            billNo: 'INV-GST-001',
            customerId: drift.Value(customerId),
            customerName: const drift.Value('Asha Devi'),
            finalAmount: const drift.Value(76000),
            paidAmount: const drift.Value(76000),
            billDate: drift.Value(DateTime(2026, 8, 9, 15)),
          ),
        );

    await database.into(database.billItems).insert(
          BillItemsCompanion.insert(
            billId: billId,
            lineNo: const drift.Value(1),
            metalType: const drift.Value('Gold'),
            itemName: 'Casting Ring',
            huid: const drift.Value('HUID-ASH-001'),
            quantity: const drift.Value(2),
            grossWeight: const drift.Value(8.2),
            netWeight: const drift.Value(8),
            fineWeight: const drift.Value(6),
            itemTotal: const drift.Value(76000),
            linkedStockUnitId: drift.Value(unitId),
            linkedStockSku: const drift.Value('STALE-SKU-SHOULD-NOT-WIN'),
            stockUnitCost: const drift.Value(0),
          ),
        );

    final snapshot = await repository.fetchSnapshot();
    final sold = snapshot.soldStock.single;

    expect(sold.billId, billId);
    expect(sold.customerId, customerId);
    expect(sold.billNo, 'INV-GST-001');
    expect(sold.customerName, 'Asha Devi');
    expect(sold.itemName, 'Casting Ring');
    expect(sold.huid, 'HUID-ASH-001');
    expect(sold.unitCode, 'SOLD-RING-001');
    expect(sold.quantity, 2);
    expect(sold.unitLabel, '2 pcs');
    expect(sold.netWeight, closeTo(8, 0.001));
    expect(sold.costBasis, closeTo(52000, 0.001));
    expect(sold.saleValue, closeTo(76000, 0.001));
    expect(sold.profit, closeTo(24000, 0.001));
    expect(sold.marginPercent, closeTo(31.5789, 0.001));
    expect(snapshot.summary.soldCost, closeTo(52000, 0.001));
    expect(snapshot.summary.saleValue, closeTo(76000, 0.001));
    expect(snapshot.summary.profit, closeTo(24000, 0.001));
  });

  test('sold audit allocates lot metal by valuation fine and making by pieces',
      () async {
    final purchaseVoucherId = await _insertPurchaseVoucher(database);
    final purchaseItemId = await _insertPurchaseLine(
      database,
      purchaseVoucherId: purchaseVoucherId,
      grossWeight: 5.631,
      netWeight: 5.631,
      purityPercent: 75,
      wastagePercent: 3,
      valuationFineWeight: 4.392,
      ratePerGram: 14150,
      quantity: 15,
      lineAmount: 62296.80,
    );
    final unitId = await _insertStockUnit(
      database,
      unitCode: 'GOLD-NOSEPIN-LOT001',
      itemType: 'Nose Pin',
      itemName: 'Nose Pin',
      netWeight: 5.631,
      actualFineWeight: 4.22325,
      purityPercent: 75,
      wastagePercent: 3,
      valuationFineWeight: 4.392,
      ratePerGram: 14150,
      unitCost: 62296.80,
      purchaseVoucherId: purchaseVoucherId,
      purchaseVoucherItemId: purchaseItemId,
      status: 'Available',
    );

    await database.customStatement(
      'UPDATE stock_item_units SET huid = ? WHERE id = ?',
      ['', unitId],
    );
    final billId = await database.into(database.bills).insert(
          BillsCompanion.insert(
            billNo: 'INV-LOT-COST-001',
            customerName: const drift.Value('Walk-in Customer'),
            finalAmount: const drift.Value(8480.64),
            paidAmount: const drift.Value(8480.64),
          ),
        );
    await database.into(database.billItems).insert(
          BillItemsCompanion.insert(
            billId: billId,
            metalType: const drift.Value('Gold'),
            itemName: 'Nose Pin',
            quantity: const drift.Value(1),
            grossWeight: const drift.Value(0.631),
            netWeight: const drift.Value(0.631),
            fineWeight: const drift.Value(0.47325),
            itemTotal: const drift.Value(8480.64),
            linkedStockUnitId: drift.Value(unitId),
            stockUnitCost: const drift.Value(6980.87),
          ),
        );

    final snapshot = await repository.fetchSnapshot();
    final sold = snapshot.soldStock.single;
    const originalMaking = 62296.80 - (4.392 * 14150);
    const expectedCost =
        (0.631 * (4.392 / 5.631) * 14150) + (originalMaking / 15);

    expect(expectedCost, closeTo(6974.061, 0.001));
    expect(sold.costBasis, closeTo(expectedCost, 0.001));
    expect(sold.profit, closeTo(8480.64 - expectedCost, 0.001));
    expect(snapshot.summary.soldCost, closeTo(expectedCost, 0.001));
    expect(snapshot.summary.profit, closeTo(8480.64 - expectedCost, 0.001));
  });

  test('sold audit shows jewellery unit mode for pair items', () async {
    final customerId = await database.into(database.customers).insert(
          CustomersCompanion.insert(
            name: 'Reyansh Soni',
            mobile: '9000000002',
          ),
        );
    final unitId = await _insertStockUnit(
      database,
      unitCode: 'SOLD-JHUMKA-001',
      itemType: 'Jhumka',
      itemName: 'Jhumka',
      quantityMode: 'PAIR',
      netWeight: 3.63,
      actualFineWeight: 2.7225,
      purityPercent: 75,
      wastagePercent: 3,
      valuationFineWeight: 2.8314,
      unitCost: 6210.25,
      status: 'Sold',
    );
    final billId = await database.into(database.bills).insert(
          BillsCompanion.insert(
            billNo: 'INV-GST-PAIR-001',
            customerId: drift.Value(customerId),
            customerName: const drift.Value('Reyansh Soni'),
            finalAmount: const drift.Value(48787.20),
            paidAmount: const drift.Value(48787.20),
          ),
        );

    await database.into(database.billItems).insert(
          BillItemsCompanion.insert(
            billId: billId,
            metalType: const drift.Value('Gold'),
            itemName: 'Jhumka',
            huid: const drift.Value('75JKLN, 2ASZ03'),
            quantity: const drift.Value(1),
            grossWeight: const drift.Value(3.63),
            netWeight: const drift.Value(3.63),
            fineWeight: const drift.Value(2.7225),
            itemTotal: const drift.Value(48787.20),
            linkedStockUnitId: drift.Value(unitId),
            stockUnitCost: const drift.Value(6210.25),
          ),
        );

    final sold = (await repository.fetchSnapshot()).soldStock.single;

    expect(sold.itemName, 'Jhumka');
    expect(sold.quantity, 1);
    expect(sold.quantityMode, 'PAIR');
    expect(sold.unitLabel, '1 pair');
  });

  test('grade valuation groups gold movement by purity grade', () async {
    final purchaseVoucherId = await _insertPurchaseVoucher(database);
    final purchaseItemId = await _insertPurchaseLine(
      database,
      purchaseVoucherId: purchaseVoucherId,
      grossWeight: 5.631,
      netWeight: 5.631,
      purityPercent: 75,
      wastagePercent: 3,
      valuationFineWeight: 4.392,
      ratePerGram: 14150,
      quantity: 15,
      lineAmount: 62296.80,
    );
    final unitId = await _insertStockUnit(
      database,
      unitCode: 'GOLD-NOSEPIN-LOT002',
      itemType: 'Nose Pin',
      itemName: 'Nose Pin',
      netWeight: 5.631,
      actualFineWeight: 4.22325,
      purityPercent: 75,
      wastagePercent: 3,
      valuationFineWeight: 4.392,
      ratePerGram: 14150,
      unitCost: 62296.80,
      purchaseVoucherId: purchaseVoucherId,
      purchaseVoucherItemId: purchaseItemId,
      status: 'Available',
    );
    await database.customStatement(
      'UPDATE stock_item_units SET huid = ? WHERE id = ?',
      ['', unitId],
    );
    final billId = await database.into(database.bills).insert(
          BillsCompanion.insert(
            billNo: 'INV-GRADE-GOLD-001',
            customerName: const drift.Value('Walk-in Customer'),
            finalAmount: const drift.Value(8480.64),
            paidAmount: const drift.Value(8480.64),
          ),
        );
    await database.into(database.billItems).insert(
          BillItemsCompanion.insert(
            billId: billId,
            metalType: const drift.Value('Gold'),
            itemName: 'Nose Pin',
            quantity: const drift.Value(1),
            grossWeight: const drift.Value(0.631),
            netWeight: const drift.Value(0.631),
            fineWeight: const drift.Value(0.47325),
            itemTotal: const drift.Value(8480.64),
            linkedStockUnitId: drift.Value(unitId),
            stockUnitCost: const drift.Value(6980.87),
          ),
        );

    final snapshot = await MetalValuationGradeRepository(database: database)
        .fetchGradeSnapshot('Gold');
    final grade = snapshot.grades.single;

    expect(grade.gradeLabel, '18KT (75%)');
    expect(grade.availableUnits, 1);
    expect(grade.soldUnits, 1);
    expect(grade.availableNetWeight, closeTo(5.631, 0.001));
    expect(grade.soldNetWeight, closeTo(0.631, 0.001));
    expect(grade.soldCost, closeTo(6974.061, 0.001));

    final batchSnapshot =
        await MetalValuationGradeRepository(database: database)
            .fetchGradeSnapshot('Gold', batchCode: 'BATCH-VAL-001');
    final batchGrade = batchSnapshot.grades.single;

    expect(batchGrade.gradeLabel, '18KT (75%)');
    expect(batchGrade.availableUnits, 1);
    expect(batchGrade.soldUnits, 1);
    expect(batchGrade.availableNetWeight, closeTo(5.631, 0.001));
    expect(batchGrade.soldNetWeight, closeTo(0.631, 0.001));
    expect(batchGrade.soldCost, closeTo(6974.061, 0.001));

    final gradeBatches = await MetalValuationGradeRepository(database: database)
        .fetchGradeBatchRows('Gold');
    final gradeBatch = gradeBatches.single;

    expect(gradeBatch.gradeLabel, '18KT (75%)');
    expect(gradeBatch.batch.batchCode, 'BATCH-VAL-001');
    expect(gradeBatch.batch.availableUnits, 1);
    expect(gradeBatch.batch.soldUnits, 1);
    expect(gradeBatch.batch.soldNetWeight, closeTo(0.631, 0.001));
    expect(gradeBatch.batch.soldCost, closeTo(6974.061, 0.001));
  });

  test('grade valuation groups silver movement by item type', () async {
    final unitId = await _insertStockUnit(
      database,
      unitCode: 'SILVER-PAYAL-001',
      itemType: 'Payal',
      itemName: 'Payal',
      quantityMode: 'PAIR',
      netWeight: 120,
      actualFineWeight: 96,
      purityPercent: 80,
      wastagePercent: 0,
      valuationFineWeight: 96,
      unitCost: 7200,
      status: 'Sold',
    );
    await database.customStatement(
      'UPDATE stock_item_units SET metal_type = ?, item_type = ? WHERE id = ?',
      ['Silver', 'Payal', unitId],
    );
    final billId = await database.into(database.bills).insert(
          BillsCompanion.insert(
            billNo: 'INV-GRADE-SILVER-001',
            customerName: const drift.Value('Walk-in Customer'),
            finalAmount: const drift.Value(8500),
            paidAmount: const drift.Value(8500),
          ),
        );
    await database.into(database.billItems).insert(
          BillItemsCompanion.insert(
            billId: billId,
            metalType: const drift.Value('Silver'),
            itemName: 'Payal',
            quantity: const drift.Value(1),
            grossWeight: const drift.Value(120),
            netWeight: const drift.Value(120),
            fineWeight: const drift.Value(96),
            itemTotal: const drift.Value(8500),
            linkedStockUnitId: drift.Value(unitId),
            stockUnitCost: const drift.Value(7200),
          ),
        );

    final snapshot = await MetalValuationGradeRepository(database: database)
        .fetchGradeSnapshot('Silver');
    final grade = snapshot.grades.single;

    expect(grade.gradeLabel, 'Payal');
    expect(grade.availableUnits, 0);
    expect(grade.soldUnits, 1);
    expect(grade.soldNetWeight, closeTo(120, 0.001));
    expect(grade.soldCost, closeTo(7200, 0.001));
    expect(grade.profit, closeTo(1300, 0.001));
  });
}

Future<int> _insertStockUnit(
  AppDatabase database, {
  required String unitCode,
  String itemType = 'Ring',
  String itemName = 'Gold Ring',
  String quantityMode = 'PIECES',
  required double netWeight,
  required double actualFineWeight,
  required double purityPercent,
  required double wastagePercent,
  required double valuationFineWeight,
  double grossWeight = 0,
  double ratePerGram = 7000,
  double makingAmount = 0,
  double? unitCost,
  int? purchaseVoucherId,
  int? purchaseVoucherItemId,
  required String status,
}) async {
  final resolvedGrossWeight = grossWeight > 0 ? grossWeight : netWeight;
  final resolvedUnitCost = unitCost ?? (valuationFineWeight * ratePerGram);
  final stockItemId = await database.into(database.stockItems).insert(
        StockItemsCompanion.insert(
          sku: unitCode.replaceAll('-001', ''),
          itemName: itemName,
          category: 'Gold',
          subCategory: itemType,
          metalType: const drift.Value('Gold'),
          purity: const drift.Value('22KT'),
          grossWeight: drift.Value(resolvedGrossWeight),
          netWeight: drift.Value(netWeight),
          quantity: const drift.Value(1),
          status: drift.Value(status),
          isActive: const drift.Value(true),
        ),
      );

  await database.ensureStockInventorySchema();
  await database.customStatement(
    'UPDATE stock_items SET quantity_mode = ? WHERE id = ?',
    [quantityMode, stockItemId],
  );
  final hasPurchaseLink =
      purchaseVoucherId != null && purchaseVoucherItemId != null;
  return database.customInsert(
    '''
    INSERT INTO stock_item_units (
      stock_item_id,
      ${hasPurchaseLink ? 'purchase_voucher_id,' : ''}
      ${hasPurchaseLink ? 'purchase_voucher_item_id,' : ''}
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
      wastage_percent,
      wastage_fine_weight,
      valuation_fine_weight,
      rate_per_gram,
      making_amount,
      unit_cost,
      company_name,
      supplier_name,
      status,
      created_at
    ) VALUES (${List.filled(hasPurchaseLink ? 26 : 24, '?').join(', ')})
    ''',
    variables: [
      drift.Variable<int>(stockItemId),
      if (hasPurchaseLink) drift.Variable<int>(purchaseVoucherId),
      if (hasPurchaseLink) drift.Variable<int>(purchaseVoucherItemId),
      const drift.Variable<String>('BATCH-VAL-001'),
      drift.Variable<String>(unitCode),
      const drift.Variable<int>(1),
      const drift.Variable<String>('Gold'),
      drift.Variable<String>(itemType),
      const drift.Variable<String>('Retail'),
      drift.Variable<String>(itemName),
      drift.Variable<String>(unitCode),
      drift.Variable<double>(resolvedGrossWeight),
      const drift.Variable<double>(0),
      drift.Variable<double>(netWeight),
      drift.Variable<double>(purityPercent),
      drift.Variable<double>(actualFineWeight),
      drift.Variable<double>(wastagePercent),
      drift.Variable<double>(netWeight * wastagePercent / 100),
      drift.Variable<double>(valuationFineWeight),
      drift.Variable<double>(ratePerGram),
      drift.Variable<double>(makingAmount),
      drift.Variable<double>(resolvedUnitCost),
      const drift.Variable<String>('Lotus Test Brand'),
      const drift.Variable<String>('Lotus Test Supplier'),
      drift.Variable<String>(status),
      drift.Variable<int>(DateTime(2026, 8, 9, 12).millisecondsSinceEpoch),
    ],
  );
}

Future<int> _insertPurchaseVoucher(AppDatabase database) async {
  await database.ensureStockInventorySchema();
  return database.customInsert(
    '''
    INSERT INTO purchase_vouchers (
      sequence_no,
      voucher_no,
      source_type,
      party_name,
      created_at
    ) VALUES (?, ?, ?, ?, ?)
    ''',
    variables: [
      const drift.Variable<int>(1),
      const drift.Variable<String>('BATCH-VAL-001'),
      const drift.Variable<String>('SUPPLIER'),
      const drift.Variable<String>('Stale Purchase Supplier'),
      drift.Variable<int>(DateTime(2026, 8, 9, 10).millisecondsSinceEpoch),
    ],
  );
}

Future<int> _insertPurchaseLine(
  AppDatabase database, {
  required int purchaseVoucherId,
  required double grossWeight,
  required double netWeight,
  required double purityPercent,
  required double wastagePercent,
  required double valuationFineWeight,
  required double ratePerGram,
  int quantity = 1,
  required double lineAmount,
}) {
  return database.customInsert(
    '''
    INSERT INTO purchase_voucher_items (
      purchase_voucher_id,
      line_no,
      metal_type,
      item_description,
      gross_weight,
      less_weight,
      net_weight,
      purity,
      fine_weight,
      wastage_percent,
      wastage_fine_weight,
      valuation_fine_weight,
      rate,
      quantity,
      line_amount,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    variables: [
      drift.Variable<int>(purchaseVoucherId),
      const drift.Variable<int>(1),
      const drift.Variable<String>('Gold'),
      const drift.Variable<String>('Stale Purchase Ring'),
      drift.Variable<double>(grossWeight),
      const drift.Variable<double>(0),
      drift.Variable<double>(netWeight),
      drift.Variable<double>(purityPercent),
      drift.Variable<double>(netWeight * purityPercent / 100),
      drift.Variable<double>(wastagePercent),
      drift.Variable<double>(netWeight * wastagePercent / 100),
      drift.Variable<double>(valuationFineWeight),
      drift.Variable<double>(ratePerGram),
      drift.Variable<int>(quantity),
      drift.Variable<double>(lineAmount),
      drift.Variable<int>(DateTime(2026, 8, 9, 10).millisecondsSinceEpoch),
    ],
  );
}
