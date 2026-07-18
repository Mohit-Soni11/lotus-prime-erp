import 'package:drift/drift.dart' show OrderingTerm, QueryRow, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_lot_sale_reconciliation_service.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_summary_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;
import 'package:lotus_erp/models/purchase/purchase_enums/purchase_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart'
    as pos;
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/repositories/purchase/purchase_entry_repository.dart';
import 'package:lotus_erp/repositories/sales_orders/pos/pos_checkout_repository.dart';

void main() {
  late AppDatabase db;
  late PurchaseEntryRepository purchaseRepository;
  late PosCheckoutRepository posRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    purchaseRepository = PurchaseEntryRepository(db: db);
    posRepository = PosCheckoutRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('gold HUID pair sells both linked units from one POS line', () async {
    final purchase = await purchaseRepository.savePurchase(
      _goldDraft(
        voucherNo: 'GS-E2E-HUID-0001',
        description: 'Hallmark Gold Jhumka',
        quantity: 2,
        grossWeight: 12,
        lessWeight: 0,
        netWeight: 12,
        purity: 75,
        fineWeight: 9,
        wastageFineWeight: 0.36,
        valuationFineWeight: 9.36,
        lineAmount: 140520,
        huids: const ['GJ1234', 'GJ5678'],
      ),
    );

    expect(
      purchase,
      isNotNull,
      reason: purchaseRepository.lastErrorMessage,
    );

    final stockItem = await _stockByVoucher(db, 'GS-E2E-HUID-0001');
    final unitsBeforeSale = await _stockUnits(db, stockItem.id);

    expect(stockItem.quantity, 2);
    expect(unitsBeforeSale, hasLength(2));
    expect(unitsBeforeSale.map((row) => row.read<String>('huid')).toList(), [
      'GJ1234',
      'GJ5678',
    ]);

    final saleItem = _goldSaleItem(
      stockItemId: stockItem.id,
      stockUnitId: unitsBeforeSale.first.read<int>('id'),
      sku: stockItem.sku,
      description: 'Hallmark Gold Jhumka',
      pieces: 2,
      grossWeight: 12,
      purity: '75',
      rate: 15600,
    );

    await posRepository.finalizeSale(
      invoice: _invoice(
        invoiceNumber: 'INV-GOLD-E2E-0001',
        saleItems: [saleItem],
        cashPaid: saleItem.totalValue,
      ),
      customerId: null,
    );

    final updatedStock = await _stockById(db, stockItem.id);
    final unitsAfterSale = await _stockUnits(db, stockItem.id);
    final movements = await _movementsFor(db, stockItem.id);

    expect(updatedStock.quantity, 0);
    expect(updatedStock.status, stock.StockStatus.sold.label);
    expect(unitsAfterSale.map((row) => row.read<String>('status')).toSet(), {
      stock.StockStatus.sold.label,
    });
    expect(movements.last.movementType, 'SALE');
    expect(movements.last.quantityDelta, -2);
    expect(movements.last.netWeightDelta, closeTo(-12, 0.001));

    final summary = StockSummaryController(db);
    await summary.load();
    final goldSummary = summary.metals
        .singleWhere((item) => item.metal.toLowerCase() == 'gold');

    expect(goldSummary.availableUnits, 0);
    expect(goldSummary.soldUnits, 2);
    expect(goldSummary.netWeight, closeTo(0, 0.001));
    expect(goldSummary.soldWeight, closeTo(12, 0.001));
    expect(goldSummary.totalWeight, closeTo(12, 0.001));

    saleItem.dispose();
  });

  test('gold bulk lot deducts actual POS sale weight', () async {
    final purchase = await purchaseRepository.savePurchase(
      _goldDraft(
        voucherNo: 'GS-E2E-BULK-0002',
        description: 'Gold Casting Ring',
        quantity: 10,
        grossWeight: 50,
        lessWeight: 0,
        netWeight: 50,
        purity: 75,
        fineWeight: 37.5,
        wastageFineWeight: 1.5,
        valuationFineWeight: 39,
        lineAmount: 585000,
        huids: const [],
        stockTrackingMode: PurchaseStockTrackingMode.lot,
      ),
    );

    expect(
      purchase,
      isNotNull,
      reason: purchaseRepository.lastErrorMessage,
    );

    final stockItem = await _stockByVoucher(db, 'GS-E2E-BULK-0002');
    final saleItem = _goldSaleItem(
      stockItemId: stockItem.id,
      sku: stockItem.sku,
      description: 'Gold Casting Ring',
      pieces: 1,
      grossWeight: 6.250,
      purity: '75',
      rate: 15600,
    );

    await posRepository.finalizeSale(
      invoice: _invoice(
        invoiceNumber: 'INV-GOLD-E2E-0002',
        saleItems: [saleItem],
        cashPaid: saleItem.totalValue,
      ),
      customerId: null,
    );

    final updatedStock = await _stockById(db, stockItem.id);
    final lotUnit = await _singleStockUnit(db, stockItem.id);
    final movements = await _movementsFor(db, stockItem.id);

    expect(updatedStock.quantity, 9);
    expect(updatedStock.status, stock.StockStatus.available.label);
    expect(updatedStock.netWeight, closeTo(43.750, 0.001));
    expect(lotUnit.read<double>('net_weight'), closeTo(43.750, 0.001));
    expect(movements.last.movementType, 'SALE');
    expect(movements.last.quantityDelta, -1);
    expect(movements.last.netWeightDelta, closeTo(-6.250, 0.001));

    final summary = StockSummaryController(db);
    await summary.load();
    final goldSummary = summary.metals
        .singleWhere((item) => item.metal.toLowerCase() == 'gold');

    expect(goldSummary.availableUnits, 9);
    expect(goldSummary.soldUnits, 1);
    expect(goldSummary.netWeight, closeTo(43.750, 0.001));
    expect(goldSummary.soldWeight, closeTo(6.250, 0.001));
    expect(goldSummary.totalWeight, closeTo(50, 0.001));

    saleItem.dispose();
  });

  test('gold lot reconciliation repairs old average-weight sale deduction',
      () async {
    final purchase = await purchaseRepository.savePurchase(
      _goldDraft(
        voucherNo: 'GS-E2E-REPAIR-0003',
        description: 'Gold Casting Ring',
        quantity: 10,
        grossWeight: 50,
        lessWeight: 0,
        netWeight: 50,
        purity: 75,
        fineWeight: 37.5,
        wastageFineWeight: 1.5,
        valuationFineWeight: 39,
        lineAmount: 585000,
        huids: const [],
        stockTrackingMode: PurchaseStockTrackingMode.lot,
      ),
    );

    expect(
      purchase,
      isNotNull,
      reason: purchaseRepository.lastErrorMessage,
    );

    final stockItem = await _stockByVoucher(db, 'GS-E2E-REPAIR-0003');
    final saleItem = _goldSaleItem(
      stockItemId: stockItem.id,
      sku: stockItem.sku,
      description: 'Gold Casting Ring',
      pieces: 1,
      grossWeight: 6.250,
      purity: '75',
      rate: 15600,
    );

    await posRepository.finalizeSale(
      invoice: _invoice(
        invoiceNumber: 'INV-GOLD-E2E-0003',
        saleItems: [saleItem],
        cashPaid: saleItem.totalValue,
      ),
      customerId: null,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      '''
      UPDATE stock_items
      SET quantity = 9,
          gross_weight = 45,
          stone_weight = 0,
          net_weight = 45,
          updated_at = ?
      WHERE id = ?
      ''',
      [now, stockItem.id],
    );
    await db.customStatement(
      '''
      UPDATE stock_item_units
      SET gross_weight = 45,
          less_weight = 0,
          net_weight = 45,
          actual_fine_weight = 33.75,
          valuation_fine_weight = 35.10,
          updated_at = ?
      WHERE stock_item_id = ?
      ''',
      [now, stockItem.id],
    );
    await db.customStatement(
      '''
      UPDATE stock_movements
      SET gross_weight_delta = -5,
          net_weight_delta = -5,
          fine_weight_delta = -3.75,
          updated_at = ?
      WHERE stock_item_id = ?
        AND movement_type = 'SALE'
      ''',
      [now, stockItem.id],
    );

    await StockLotSaleReconciliationService(db).reconcile();

    final repairedStock = await _stockById(db, stockItem.id);
    final repairedUnit = await _singleStockUnit(db, stockItem.id);
    final repairedMovements = await _movementsFor(db, stockItem.id);

    expect(repairedStock.quantity, 9);
    expect(repairedStock.netWeight, closeTo(43.750, 0.001));
    expect(repairedUnit.read<double>('net_weight'), closeTo(43.750, 0.001));
    expect(repairedMovements.last.netWeightDelta, closeTo(-6.250, 0.001));

    final summary = StockSummaryController(db);
    await summary.load();
    final goldSummary = summary.metals
        .singleWhere((item) => item.metal.toLowerCase() == 'gold');

    expect(goldSummary.availableUnits, 9);
    expect(goldSummary.soldUnits, 1);
    expect(goldSummary.netWeight, closeTo(43.750, 0.001));
    expect(goldSummary.soldWeight, closeTo(6.250, 0.001));
    expect(goldSummary.totalWeight, closeTo(50, 0.001));

    saleItem.dispose();
  });
}

Future<StockItem> _stockById(AppDatabase db, int id) {
  return (db.select(db.stockItems)..where((tbl) => tbl.id.equals(id)))
      .getSingle();
}

Future<StockItem> _stockByVoucher(AppDatabase db, String voucherNo) async {
  final row = await db.customSelect(
    '''
    SELECT u.stock_item_id AS id
    FROM stock_item_units u
    INNER JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
    WHERE pv.voucher_no = ?
    ORDER BY u.id ASC
    LIMIT 1
    ''',
    variables: [Variable<String>(voucherNo)],
  ).getSingle();
  return _stockById(db, row.read<int>('id'));
}

Future<List<QueryRow>> _stockUnits(AppDatabase db, int stockItemId) {
  return db.customSelect(
    '''
    SELECT *
    FROM stock_item_units
    WHERE stock_item_id = ?
    ORDER BY piece_no ASC
    ''',
    variables: [Variable<int>(stockItemId)],
  ).get();
}

Future<QueryRow> _singleStockUnit(AppDatabase db, int stockItemId) {
  return db.customSelect(
    '''
    SELECT *
    FROM stock_item_units
    WHERE stock_item_id = ?
    ORDER BY piece_no ASC
    LIMIT 1
    ''',
    variables: [Variable<int>(stockItemId)],
  ).getSingle();
}

Future<List<StockMovement>> _movementsFor(AppDatabase db, int stockItemId) {
  return (db.select(db.stockMovements)
        ..where((tbl) => tbl.stockItemId.equals(stockItemId))
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
      .get();
}

SaleItemModel _goldSaleItem({
  required int stockItemId,
  required String sku,
  required String description,
  required int pieces,
  required double grossWeight,
  required String purity,
  required double rate,
  int? stockUnitId,
}) {
  final item = SaleItemModel(metal: pos.MetalType.gold);
  item.attachStockReference(
    stockItemId: stockItemId,
    stockUnitId: stockUnitId,
    sku: sku,
  );
  item.descCtrl.text = description;
  item.pcsCtrl.text = pieces.toString();
  item.huidCtrl.text = sku;
  item.purityCtrl.text = purity;
  item.grossCtrl.text = _formatNumber(grossWeight);
  item.lessCtrl.text = '0';
  item.rateCtrl.text = _formatNumber(rate);
  item.makingCtrl.text = '0';
  return item;
}

PosInvoiceModel _invoice({
  required String invoiceNumber,
  required List<SaleItemModel> saleItems,
  required double cashPaid,
}) {
  final grossAmount =
      saleItems.fold<double>(0, (sum, item) => sum + item.totalValue);
  return PosInvoiceModel(
    invoiceNumber: invoiceNumber,
    invoiceDate: DateTime(2026, 7, 18, 12),
    billType: pos.BillType.normal,
    billingMode: pos.BillingMode.retail,
    shopName: 'Lotus Jewellers',
    shopAddress: 'Patna',
    shopPhone: '9000000000',
    shopGstin: '',
    customerName: 'Walk-in Customer',
    customerMobile: '',
    customerCity: 'Patna',
    customerPan: '',
    customerGstin: '',
    oldGoldMode: pos.OldGoldAdjustMode.cashAdjust,
    saleItems: saleItems,
    oldGoldItems: const [],
    grossAmount: grossAmount,
    discountAmount: 0,
    taxableAmount: grossAmount,
    cgst: 0,
    sgst: 0,
    totalGst: 0,
    totalOldGoldDeduction: 0,
    grandTotal: grossAmount,
    cashPaid: cashPaid,
    upiPaid: 0,
    cardPaid: 0,
    advancePaid: 0,
    balanceDue: 0,
    totalMakingCharge: 0,
  );
}

PurchaseVoucherDraft _goldDraft({
  required String voucherNo,
  required String description,
  required int quantity,
  required double grossWeight,
  required double lessWeight,
  required double netWeight,
  required double purity,
  required double fineWeight,
  required double wastageFineWeight,
  required double valuationFineWeight,
  required double lineAmount,
  required List<String> huids,
  PurchaseStockTrackingMode stockTrackingMode = PurchaseStockTrackingMode.unit,
}) {
  return PurchaseVoucherDraft(
    sequenceNo: 1,
    voucherNo: voucherNo,
    source: PurchaseSource.fromSupplier,
    taxType: PurchaseTaxType.normal,
    discountType: PurchaseDiscountType.flatAmount,
    discountValue: 0,
    discountAmount: 0,
    grossAmount: lineAmount,
    taxableAmount: lineAmount,
    gstAmount: 0,
    cgstAmount: 0,
    sgstAmount: 0,
    grandTotal: lineAmount,
    cashPaid: lineAmount,
    upiPaid: 0,
    bankPaid: 0,
    cardPaid: 0,
    totalPaid: lineAmount,
    balanceDue: 0,
    ratePerKg: 15600000,
    metalPaidGrossWeight: 0,
    metalPaidPurity: 0,
    metalPaidFine: 0,
    metalPaidValue: 0,
    party: const PurchaseVoucherPartyDraft(
      supplierId: null,
      name: 'Lotus Gold Supplier',
    ),
    items: [
      PurchaseVoucherItemDraft(
        metal: PurchaseMetalType.gold,
        description: description,
        companyLabel: '',
        segmentLabel: 'Ladies',
        quantity: quantity,
        grossWeight: grossWeight,
        lessWeight: lessWeight,
        netWeight: netWeight,
        purity: purity,
        fineWeight: fineWeight,
        wastageFineWeight: wastageFineWeight,
        valuationFineWeight: valuationFineWeight,
        rate: 15600,
        lineAmount: lineAmount,
        subCategory: 'Jhumka',
        huids: huids,
        hsnCode: '7113',
        labourCharge: 0,
        labourType: stock.MakingChargesType.flat,
        purityLabel: '${purity.toStringAsFixed(2)}%',
        effectiveRatePerGram: 15600,
        gstRate: 0,
        quantityMode: 'PIECES',
        packetCount: 0,
        piecesPerPacket: 1,
        weightsAreLineTotals: true,
        stockTrackingMode: stockTrackingMode,
      ),
    ],
  );
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}
