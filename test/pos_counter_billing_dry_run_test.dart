import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_pdf_builder.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_print_config.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart'
    as pos;
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/repositories/customer/customer_profile_repository.dart';
import 'package:lotus_erp/repositories/sales_orders/pos/pos_checkout_repository.dart';

void main() {
  late AppDatabase db;
  late PosCheckoutRepository checkoutRepository;
  late CustomerProfileRepository customerProfileRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    checkoutRepository = PosCheckoutRepository(db: db);
    customerProfileRepository = CustomerProfileRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'counter dry-run cuts a transparent tax invoice and links customer, stock and PDF',
    () async {
      final customerId = await _insertCustomer(db);
      final stockId = await _insertStockItem(
        db,
        sku: 'DRY-NGST-RING-001',
        itemName: 'Gold Ring',
        hsnCode: null,
        unitCost: 72000,
      );
      final stockUnit = await _stockUnitFor(db, stockId);
      final saleItem = _stockSaleItem(
        stockItemId: stockId,
        stockUnitId: stockUnit.id,
        sku: stockUnit.code,
        itemName: 'Gold Ring',
        hsnCode: null,
        grossWeight: 10,
        rate: 8000,
        stockUnitCost: stockUnit.cost,
      );
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0101',
        billType: pos.BillType.gst,
        customerName: 'Aarav Soni',
        customerMobile: '9304479436',
        saleItems: [saleItem],
        cashPaid: saleItem.totalValue,
      );

      final result = await checkoutRepository.finalizeSale(
        invoice: invoice,
        customerId: customerId,
      );

      final bill = await _billById(db, result.billId);
      final billItem = await _singleBillItem(db, result.billId);
      final profile = await customerProfileRepository.fetchProfile(customerId);
      final stockRow = await _stockById(db, stockId);
      final stockUnitStatus = await _stockUnitStatusFor(db, stockId);
      final movements = await _stockMovementsFor(db, stockId);
      final pdfBytes = await _buildPdf(invoice);

      expect(result.invoiceNumber, 'LJ-26-001');
      expect(bill.billType, 'GST');
      expect(bill.gstAmount, 0);
      expect(bill.paymentStatus, 'PAID');
      expect(bill.customerId, customerId);
      expect(billItem.hsnCode, isNull);
      expect(billItem.linkedStockItemId, stockId);
      expect(billItem.linkedStockUnitId, stockUnit.id);
      expect(billItem.stockUnitCost, 72000);
      expect(billItem.stockProfitAmount, closeTo(8000, 0.001));
      expect(profile, isNotNull);
      expect(profile!.bills.map((bill) => bill.billNo), contains(bill.billNo));
      expect(stockRow.status, stock.StockStatus.sold.label);
      expect(stockUnitStatus, stock.StockStatus.sold.label);
      expect(movements.single.sourceNumber, bill.billNo);
      expect(movements.single.quantityDelta, -1);
      expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');

      saleItem.dispose();
    },
  );

  test(
    'counter dry-run cuts a GST bill with HSN, tax snapshot and cost audit',
    () async {
      final customerId = await _insertCustomer(
        db,
        name: 'Riya Jewels Pvt Ltd',
        mobile: '9304479437',
      );
      final stockId = await _insertStockItem(
        db,
        sku: 'DRY-GST-RING-001',
        itemName: 'Hallmark Gold Ring',
        hsnCode: '7113',
        unitCost: 59000,
      );
      final stockUnit = await _stockUnitFor(db, stockId);
      final saleItem = _stockSaleItem(
        stockItemId: stockId,
        stockUnitId: stockUnit.id,
        sku: stockUnit.code,
        itemName: 'Hallmark Gold Ring',
        hsnCode: '7113',
        grossWeight: 10,
        rate: 6000,
        stockUnitCost: stockUnit.cost,
      );
      const cgst = 900.0;
      const sgst = 900.0;
      final invoice = _invoice(
        invoiceNumber: 'TAX-LJ-2026-0201',
        billType: pos.BillType.gst,
        customerName: 'Riya Jewels Pvt Ltd',
        customerMobile: '9304479437',
        customerGstin: '10ABCDE1234F1Z5',
        saleItems: [saleItem],
        taxableAmount: saleItem.totalValue,
        cgst: cgst,
        sgst: sgst,
        totalGst: cgst + sgst,
        cashPaid: saleItem.totalValue + cgst + sgst,
      );

      final result = await checkoutRepository.finalizeSale(
        invoice: invoice,
        customerId: customerId,
      );

      final bill = await _billById(db, result.billId);
      final billItem = await _singleBillItem(db, result.billId);
      final printableItems =
          await checkoutRepository.fetchPrintableSaleItems(result.billId);
      final profile = await customerProfileRepository.fetchProfile(customerId);
      final pdfBytes = await _buildPdf(invoice);

      expect(result.invoiceNumber, 'LJ-26-001');
      expect(bill.billType, 'GST');
      expect(bill.taxableAmount, saleItem.totalValue);
      expect(bill.cgstAmount, cgst);
      expect(bill.sgstAmount, sgst);
      expect(bill.gstAmount, cgst + sgst);
      expect(bill.finalAmount, saleItem.totalValue + cgst + sgst);
      expect(billItem.hsnCode, '7113');
      expect(billItem.purity, '22KT');
      expect(billItem.stockUnitCost, 59000);
      expect(billItem.stockProfitAmount, closeTo(1000, 0.001));
      expect(printableItems.single.invoiceHsnCode, '7113');
      expect(profile, isNotNull);
      expect(profile!.bills.map((bill) => bill.billNo), contains(bill.billNo));
      expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');

      saleItem.dispose();
      for (final item in printableItems) {
        item.dispose();
      }
    },
  );
}

Future<int> _insertCustomer(
  AppDatabase db, {
  String name = 'Aarav Soni',
  String mobile = '9304479436',
}) {
  return db.into(db.customers).insert(
        CustomersCompanion.insert(
          name: name,
          mobile: mobile,
          city: const drift.Value('Patna'),
        ),
      );
}

Future<int> _insertStockItem(
  AppDatabase db, {
  required String sku,
  required String itemName,
  required String? hsnCode,
  required double unitCost,
}) async {
  final stockItemId = await db.into(db.stockItems).insert(
        StockItemsCompanion.insert(
          sku: sku,
          itemName: itemName,
          category: 'Gold',
          subCategory: 'Ring',
          metalType: const drift.Value('Gold'),
          purity: const drift.Value('22KT'),
          grossWeight: const drift.Value(10),
          netWeight: const drift.Value(10),
          quantity: const drift.Value(1),
          status: drift.Value(stock.StockStatus.available.label),
          isActive: const drift.Value(true),
        ),
      );

  await db.ensureStockInventorySchema();
  final now = DateTime(2026, 8, 9, 12).millisecondsSinceEpoch;
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
      supplier_name,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    variables: [
      drift.Variable<int>(stockItemId),
      const drift.Variable<String>('POS-DRY-RUN'),
      drift.Variable<String>('$sku-U001'),
      const drift.Variable<int>(1),
      const drift.Variable<String>('Gold'),
      const drift.Variable<String>('Ring'),
      const drift.Variable<String>('Retail'),
      drift.Variable<String>(itemName),
      drift.Variable<String>(sku),
      const drift.Variable<double>(10),
      const drift.Variable<double>(0),
      const drift.Variable<double>(10),
      const drift.Variable<double>(91.6),
      const drift.Variable<double>(9.16),
      const drift.Variable<double>(0),
      const drift.Variable<double>(9.16),
      const drift.Variable<double>(5900),
      const drift.Variable<double>(0),
      drift.Variable<double>(unitCost),
      const drift.Variable<String>('Dry Run Supplier'),
      drift.Variable<String>(stock.StockStatus.available.label),
      drift.Variable<int>(now),
    ],
  );

  return stockItemId;
}

SaleItemModel _stockSaleItem({
  required int stockItemId,
  required int stockUnitId,
  required String sku,
  required String itemName,
  required String? hsnCode,
  required double grossWeight,
  required double rate,
  required double stockUnitCost,
}) {
  final item = SaleItemModel(metal: pos.MetalType.gold);
  item.descCtrl.text = itemName;
  item.pcsCtrl.text = '1';
  item.setHuidText(sku.replaceAll('-U001', ''));
  item.purityCtrl.text = '22KT';
  item.grossCtrl.text = _formatNumber(grossWeight);
  item.lessCtrl.text = '0';
  item.rateCtrl.text = _formatNumber(rate);
  item.makingCtrl.text = '0';
  item.setInvoiceHsnCode(hsnCode);
  item.attachStockReference(
    stockItemId: stockItemId,
    stockUnitId: stockUnitId,
    sku: sku,
    stockUnitCost: stockUnitCost,
  );
  return item;
}

PosInvoiceModel _invoice({
  required String invoiceNumber,
  required pos.BillType billType,
  pos.GstPricingMode gstPricingMode = pos.GstPricingMode.exclusive,
  required String customerName,
  required String customerMobile,
  String customerGstin = '',
  required List<SaleItemModel> saleItems,
  double? taxableAmount,
  double cgst = 0,
  double sgst = 0,
  double totalGst = 0,
  required double cashPaid,
}) {
  final grossAmount =
      saleItems.fold<double>(0, (sum, item) => sum + item.totalValue);
  final grandTotal = grossAmount + totalGst;
  return PosInvoiceModel(
    invoiceNumber: invoiceNumber,
    invoiceDate: DateTime(2026, 8, 9, 12),
    billType: billType,
    gstPricingMode: gstPricingMode,
    billingMode: pos.BillingMode.retail,
    shopName: 'Lotus Jewellers',
    shopAddress: 'Patna, Bihar',
    shopPhone: '9000000000',
    shopGstin: billType == pos.BillType.gst ? '10ABCDE1234F1Z5' : '',
    customerName: customerName,
    customerMobile: customerMobile,
    customerCity: 'Patna',
    customerPan: '',
    customerGstin: customerGstin,
    tradeInMode: pos.TradeInAdjustMode.cashAdjust,
    saleItems: saleItems,
    tradeInItems: const [],
    grossAmount: grossAmount,
    discountAmount: 0,
    taxableAmount: taxableAmount ?? grossAmount,
    cgst: cgst,
    sgst: sgst,
    totalGst: totalGst,
    totalTradeInDeduction: 0,
    grandTotal: grandTotal,
    cashPaid: cashPaid,
    upiPaid: 0,
    cardPaid: 0,
    advancePaid: 0,
    balanceDue: (grandTotal - cashPaid).clamp(0.0, double.infinity),
    totalMakingCharge: saleItems.fold<double>(
      0,
      (sum, item) => sum + item.makingAmt,
    ),
  );
}

Future<List<int>> _buildPdf(PosInvoiceModel invoice) {
  return const PosInvoicePdfBuilder().build(
    invoice: invoice,
    options: PosInvoicePdfBuildOptions(
      format: PrintFormat.a4,
      copies: 1,
      includeDuplicateStamp: false,
      metalPrintSettings: {pos.MetalType.gold: BillSettings()},
    ),
  );
}

Future<Bill> _billById(AppDatabase db, int id) {
  return (db.select(db.bills)..where((tbl) => tbl.id.equals(id))).getSingle();
}

Future<BillItem> _singleBillItem(AppDatabase db, int billId) {
  return (db.select(db.billItems)..where((tbl) => tbl.billId.equals(billId)))
      .getSingle();
}

Future<StockItem> _stockById(AppDatabase db, int id) {
  return (db.select(db.stockItems)..where((tbl) => tbl.id.equals(id)))
      .getSingle();
}

Future<_StockUnitSnapshot> _stockUnitFor(AppDatabase db, int stockId) async {
  final row = await db.customSelect(
    '''
    SELECT id, unit_code, unit_cost
    FROM stock_item_units
    WHERE stock_item_id = ?
    ORDER BY id ASC
    LIMIT 1
    ''',
    variables: [drift.Variable<int>(stockId)],
  ).getSingle();
  return _StockUnitSnapshot(
    id: row.read<int>('id'),
    code: row.read<String>('unit_code'),
    cost: row.read<double>('unit_cost'),
  );
}

Future<String> _stockUnitStatusFor(AppDatabase db, int stockId) async {
  final row = await db.customSelect(
    '''
    SELECT status
    FROM stock_item_units
    WHERE stock_item_id = ?
    ORDER BY id ASC
    LIMIT 1
    ''',
    variables: [drift.Variable<int>(stockId)],
  ).getSingle();
  return row.read<String>('status');
}

Future<List<StockMovement>> _stockMovementsFor(AppDatabase db, int stockId) {
  return (db.select(db.stockMovements)
        ..where((tbl) => tbl.stockItemId.equals(stockId))
        ..orderBy([(tbl) => drift.OrderingTerm.asc(tbl.id)]))
      .get();
}

String _formatNumber(double value) {
  return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
}

class _StockUnitSnapshot {
  final int id;
  final String code;
  final double cost;

  const _StockUnitSnapshot({
    required this.id,
    required this.code,
    required this.cost,
  });
}
