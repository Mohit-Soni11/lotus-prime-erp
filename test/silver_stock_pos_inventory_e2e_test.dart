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

  test('silver bulk and HUID stock update correctly after POS sale', () async {
    final bulkPurchase = await purchaseRepository.savePurchase(
      _silverDraft(
        voucherNo: 'SS-E2E-BULK-0001',
        description: 'Fancy Silver Payal',
        quantity: 50,
        grossWeight: 180,
        lessWeight: 0,
        netWeight: 180,
        purity: 60,
        fineWeight: 108,
        wastageFineWeight: 18,
        valuationFineWeight: 126,
        lineAmount: 27846,
        stockTrackingMode: PurchaseStockTrackingMode.lot,
        quantityMode: 'PACKET',
        packetCount: 25,
        piecesPerPacket: 2,
      ),
    );
    final huidPurchase = await purchaseRepository.savePurchase(
      _silverDraft(
        voucherNo: 'SS-E2E-HUID-0002',
        description: 'Hallmark Silver Pair',
        quantity: 2,
        grossWeight: 12,
        lessWeight: 0,
        netWeight: 12,
        purity: 92.5,
        fineWeight: 11.1,
        wastageFineWeight: 0.6,
        valuationFineWeight: 11.7,
        lineAmount: 2588.2,
        huids: const ['SV1234', 'SV5678'],
        stockTrackingMode: PurchaseStockTrackingMode.unit,
        quantityMode: 'PIECES',
      ),
    );

    expect(bulkPurchase, isNotNull);
    expect(huidPurchase, isNotNull);

    final bulkStock = await _stockByVoucher(db, 'SS-E2E-BULK-0001');
    final huidStock = await _stockByVoucher(db, 'SS-E2E-HUID-0002');
    final huidUnit = await db.customSelect(
      '''
      SELECT id
      FROM stock_item_units
      WHERE stock_item_id = ?
      ORDER BY piece_no ASC
      LIMIT 1
      ''',
      variables: [Variable<int>(huidStock.id)],
    ).getSingle();

    final bulkSale = _silverSaleItem(
      stockItemId: bulkStock.id,
      sku: bulkStock.sku,
      description: 'Fancy Silver Payal',
      pieces: 10,
      grossWeight: 36,
      purity: '60',
      rate: 250,
    );
    final huidSale = _silverSaleItem(
      stockItemId: huidStock.id,
      stockUnitId: huidUnit.read<int>('id'),
      sku: huidStock.sku,
      description: 'Hallmark Silver Pair',
      pieces: 2,
      grossWeight: 12,
      purity: '92.5',
      rate: 250,
    );

    await posRepository.finalizeSale(
      invoice: _invoice(
        invoiceNumber: 'INV-SILVER-E2E-0001',
        saleItems: [bulkSale, huidSale],
        cashPaid: bulkSale.totalValue + huidSale.totalValue,
      ),
      customerId: null,
    );

    final updatedBulk = await _stockById(db, bulkStock.id);
    final updatedHuid = await _stockById(db, huidStock.id);
    final bulkUnit = await _singleStockUnit(db, bulkStock.id);
    final huidUnits = await _stockUnits(db, huidStock.id);
    final bulkMovements = await _movementsFor(db, bulkStock.id);
    final huidMovements = await _movementsFor(db, huidStock.id);

    expect(updatedBulk.quantity, 40);
    expect(updatedBulk.status, stock.StockStatus.available.label);
    expect(updatedBulk.netWeight, closeTo(144, 0.001));
    expect(bulkUnit.read<double>('net_weight'), closeTo(144, 0.001));
    expect(bulkMovements.last.movementType, 'SALE');
    expect(bulkMovements.last.quantityDelta, -10);
    expect(bulkMovements.last.netWeightDelta, closeTo(-36, 0.001));

    expect(updatedHuid.quantity, 0);
    expect(updatedHuid.status, stock.StockStatus.sold.label);
    expect(huidUnits.map((row) => row.read<String>('status')).toSet(), {
      stock.StockStatus.sold.label,
    });
    expect(huidMovements.last.movementType, 'SALE');
    expect(huidMovements.last.quantityDelta, -2);
    expect(huidMovements.last.netWeightDelta, closeTo(-12, 0.001));

    final summary = StockSummaryController(db);
    await summary.load();
    final silverSummary = summary.metals
        .singleWhere((item) => item.metal.toLowerCase() == 'silver');

    expect(silverSummary.availableUnits, 40);
    expect(silverSummary.soldUnits, 12);
    expect(silverSummary.netWeight, closeTo(144, 0.001));
    expect(silverSummary.soldWeight, closeTo(48, 0.001));
    expect(silverSummary.totalWeight, closeTo(192, 0.001));

    bulkSale.dispose();
    huidSale.dispose();
  });

  test('silver bulk lot deducts actual POS sale weight', () async {
    final purchase = await purchaseRepository.savePurchase(
      _silverDraft(
        voucherNo: 'SS-E2E-ACTUAL-WEIGHT-0003',
        description: 'Silver Locket',
        quantity: 50,
        grossWeight: 150.526,
        lessWeight: 0,
        netWeight: 150.526,
        purity: 60,
        fineWeight: 90.316,
        wastageFineWeight: 15.052,
        valuationFineWeight: 105.368,
        lineAmount: 23419.06,
        stockTrackingMode: PurchaseStockTrackingMode.lot,
        quantityMode: 'PIECES',
      ),
    );

    expect(purchase, isNotNull);

    final stockItem = await _stockByVoucher(
      db,
      'SS-E2E-ACTUAL-WEIGHT-0003',
    );
    final saleItem = _silverSaleItem(
      stockItemId: stockItem.id,
      sku: stockItem.sku,
      description: 'Silver Locket',
      pieces: 1,
      grossWeight: 8.230,
      purity: '60',
      rate: 200,
    );

    await posRepository.finalizeSale(
      invoice: _invoice(
        invoiceNumber: 'INV-SILVER-ACTUAL-WEIGHT-0002',
        saleItems: [saleItem],
        cashPaid: saleItem.totalValue,
      ),
      customerId: null,
    );

    final updatedStock = await _stockById(db, stockItem.id);
    final lotUnit = await _singleStockUnit(db, stockItem.id);
    final movements = await _movementsFor(db, stockItem.id);

    expect(updatedStock.quantity, 49);
    expect(updatedStock.netWeight, closeTo(142.296, 0.001));
    expect(lotUnit.read<double>('net_weight'), closeTo(142.296, 0.001));
    expect(movements.last.movementType, 'SALE');
    expect(movements.last.quantityDelta, -1);
    expect(movements.last.netWeightDelta, closeTo(-8.230, 0.001));

    final summary = StockSummaryController(db);
    await summary.load();
    final silverSummary = summary.metals
        .singleWhere((item) => item.metal.toLowerCase() == 'silver');

    expect(silverSummary.availableUnits, 49);
    expect(silverSummary.soldUnits, 1);
    expect(silverSummary.netWeight, closeTo(142.296, 0.001));
    expect(silverSummary.soldWeight, closeTo(8.230, 0.001));
    expect(silverSummary.totalWeight, closeTo(150.526, 0.001));

    saleItem.dispose();
  });

  test('silver lot reconciliation repairs old average-weight sale deduction',
      () async {
    final purchase = await purchaseRepository.savePurchase(
      _silverDraft(
        voucherNo: 'SS-E2E-REPAIR-0004',
        description: 'Silver Locket',
        quantity: 50,
        grossWeight: 150.526,
        lessWeight: 0,
        netWeight: 150.526,
        purity: 60,
        fineWeight: 90.316,
        wastageFineWeight: 15.052,
        valuationFineWeight: 105.368,
        lineAmount: 23419.06,
        stockTrackingMode: PurchaseStockTrackingMode.lot,
        quantityMode: 'PIECES',
      ),
    );

    expect(purchase, isNotNull);

    final stockItem = await _stockByVoucher(db, 'SS-E2E-REPAIR-0004');
    final saleItem = _silverSaleItem(
      stockItemId: stockItem.id,
      sku: stockItem.sku,
      description: 'Silver Locket',
      pieces: 1,
      grossWeight: 8.230,
      purity: '60',
      rate: 200,
    );

    await posRepository.finalizeSale(
      invoice: _invoice(
        invoiceNumber: 'INV-SILVER-REPAIR-0003',
        saleItems: [saleItem],
        cashPaid: saleItem.totalValue,
      ),
      customerId: null,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      '''
      UPDATE stock_items
      SET quantity = 49,
          gross_weight = 147.515,
          stone_weight = 0,
          net_weight = 147.515,
          updated_at = ?
      WHERE id = ?
      ''',
      [now, stockItem.id],
    );
    await db.customStatement(
      '''
      UPDATE stock_item_units
      SET gross_weight = 147.515,
          less_weight = 0,
          net_weight = 147.515,
          actual_fine_weight = 88.509,
          valuation_fine_weight = 103.261,
          updated_at = ?
      WHERE stock_item_id = ?
      ''',
      [now, stockItem.id],
    );
    await db.customStatement(
      '''
      UPDATE stock_movements
      SET gross_weight_delta = -3.011,
          net_weight_delta = -3.011,
          fine_weight_delta = -1.807,
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

    expect(repairedStock.quantity, 49);
    expect(repairedStock.netWeight, closeTo(142.296, 0.001));
    expect(repairedUnit.read<double>('net_weight'), closeTo(142.296, 0.001));
    expect(repairedMovements.last.netWeightDelta, closeTo(-8.230, 0.001));

    final summary = StockSummaryController(db);
    await summary.load();
    final silverSummary = summary.metals
        .singleWhere((item) => item.metal.toLowerCase() == 'silver');

    expect(silverSummary.availableUnits, 49);
    expect(silverSummary.soldUnits, 1);
    expect(silverSummary.netWeight, closeTo(142.296, 0.001));
    expect(silverSummary.soldWeight, closeTo(8.230, 0.001));
    expect(silverSummary.totalWeight, closeTo(150.526, 0.001));

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

Future<List<StockMovement>> _movementsFor(AppDatabase db, int stockItemId) {
  return (db.select(db.stockMovements)
        ..where((tbl) => tbl.stockItemId.equals(stockItemId))
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
      .get();
}

SaleItemModel _silverSaleItem({
  required int stockItemId,
  required String sku,
  required String description,
  required int pieces,
  required double grossWeight,
  required String purity,
  required double rate,
  int? stockUnitId,
}) {
  final item = SaleItemModel(metal: pos.MetalType.silver);
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

PurchaseVoucherDraft _silverDraft({
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
  List<String> huids = const [],
  PurchaseStockTrackingMode stockTrackingMode = PurchaseStockTrackingMode.lot,
  String quantityMode = 'PIECES',
  int packetCount = 0,
  int piecesPerPacket = 1,
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
    ratePerKg: 221500,
    metalPaidGrossWeight: 0,
    metalPaidPurity: 0,
    metalPaidFine: 0,
    metalPaidValue: 0,
    party: const PurchaseVoucherPartyDraft(
      supplierId: null,
      name: 'Lotus Silver Supplier',
    ),
    items: [
      PurchaseVoucherItemDraft(
        metal: PurchaseMetalType.silver,
        description: description,
        companyLabel: 'RAJ',
        segmentLabel: 'Ladies',
        quantity: quantity,
        grossWeight: grossWeight,
        lessWeight: lessWeight,
        netWeight: netWeight,
        purity: purity,
        fineWeight: fineWeight,
        wastageFineWeight: wastageFineWeight,
        valuationFineWeight: valuationFineWeight,
        rate: 221.5,
        lineAmount: lineAmount,
        subCategory: 'Payal',
        huids: huids,
        hsnCode: '7113',
        labourCharge: 0,
        labourType: stock.MakingChargesType.flat,
        purityLabel: '${purity.toStringAsFixed(2)}%',
        effectiveRatePerGram: 221.5,
        gstRate: 0,
        quantityMode: quantityMode,
        packetCount: packetCount,
        piecesPerPacket: piecesPerPacket,
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
