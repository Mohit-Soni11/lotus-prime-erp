import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/reports/sales_report/sales_report_models.dart';
import 'package:lotus_erp/repositories/reports/sales_report_repository.dart';

void main() {
  late AppDatabase db;
  late SalesReportRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SalesReportRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('fetchReport builds invoice, tax and metal summaries from POS bills',
      () async {
    final date = DateTime(2026, 8, 9, 12, 30);

    final gstBillId = await _insertBill(
      db,
      billNo: 'TAX-AJ-2026-0001',
      billDate: date,
      billType: 'GST',
      totalAmount: 9690.91,
      discount: 0.64,
      taxableAmount: 9690.27,
      gstAmount: 290.71,
      roundOffAmount: 0.36,
      finalAmount: 9982,
      paidAmount: 9982,
      dueAmount: 0,
      cashPaid: 9982,
      makingTotal: 1038.31,
    );
    await _insertItem(
      db,
      billId: gstBillId,
      lineNo: 1,
      metalType: 'GOLD',
      itemName: 'NOSE PIN',
      purity: '18K',
      huid: 'HUID123',
      grossWeight: 0.759,
      netWeight: 0.759,
      rate: 11400,
      makingCharge: 1038.31,
      itemTotal: 9690.91,
      stockCost: 7000,
      profit: 2690.91,
    );

    final normalBillId = await _insertBill(
      db,
      billNo: 'INV-AJ-2026-0002',
      billDate: date,
      billType: 'NORMAL',
      totalAmount: 4072.20,
      finalAmount: 4072,
      paidAmount: 3000,
      dueAmount: 1072,
      upiPaid: 3000,
      makingTotal: 407.22,
    );
    await _insertItem(
      db,
      billId: normalBillId,
      lineNo: 1,
      metalType: 'SILVER',
      itemName: 'PAYAL',
      purity: '60',
      grossWeight: 20.361,
      netWeight: 20.361,
      rate: 180,
      makingCharge: 407.22,
      itemTotal: 4072.20,
      stockCost: 2500,
      profit: 1572.20,
    );

    final snapshot = await repository.fetchReport(
      SalesReportFilter(
        startDate: DateTime(2026, 8, 9),
        endDate: DateTime(2026, 8, 9, 23, 59, 59),
      ),
    );

    expect(snapshot.summary.invoiceCount, 2);
    expect(snapshot.summary.gstInvoiceCount, 1);
    expect(snapshot.summary.nonGstInvoiceCount, 1);
    expect(snapshot.summary.finalAmount, 14054);
    expect(snapshot.summary.gstAmount, 290.71);
    expect(snapshot.summary.dueAmount, 1072);
    expect(snapshot.summary.roundOffAmount, 0.36);
    expect(snapshot.summary.stockCostAmount, 9500);
    expect(snapshot.summary.profitAmount, closeTo(4263.11, 0.001));
    expect(snapshot.gstLiability.invoiceCount, 2);
    expect(snapshot.gstLiability.gstInvoiceCount, 1);
    expect(snapshot.gstLiability.nonGstInvoiceCount, 1);
    expect(snapshot.gstLiability.gstTaxableAmount, 9690.27);
    expect(snapshot.gstLiability.recordedGstAmount, 290.71);
    expect(snapshot.gstLiability.nonGstSalesAmount, 4072.20);
    expect(snapshot.gstLiability.projectedGstAmount, closeTo(122.166, 0.001));
    expect(
      snapshot.gstLiability.combinedGstExposure,
      closeTo(412.876, 0.001),
    );

    final gold = snapshot.metals.singleWhere((row) => row.metalType == 'Gold');
    expect(gold.netWeight, 0.759);
    expect(gold.salesAmount, 9690.91);

    final silver =
        snapshot.metals.singleWhere((row) => row.metalType == 'Silver');
    expect(silver.netWeight, 20.361);
    expect(silver.invoiceCount, 1);
  });

  test('fetchReport filters GST bills and metal item rows', () async {
    final date = DateTime(2026, 8, 9, 12, 30);
    final gstBillId = await _insertBill(
      db,
      billNo: 'TAX-AJ-2026-0003',
      billDate: date,
      billType: 'GST',
      finalAmount: 1030,
      paidAmount: 1030,
      gstAmount: 30,
    );
    await _insertItem(
      db,
      billId: gstBillId,
      lineNo: 1,
      metalType: 'GOLD',
      itemName: 'RING',
      netWeight: 1.25,
      itemTotal: 1000,
    );

    final normalBillId = await _insertBill(
      db,
      billNo: 'INV-AJ-2026-0004',
      billDate: date,
      billType: 'NORMAL',
      finalAmount: 600,
      paidAmount: 600,
    );
    await _insertItem(
      db,
      billId: normalBillId,
      lineNo: 1,
      metalType: 'SILVER',
      itemName: 'CHAIN',
      netWeight: 3,
      itemTotal: 600,
    );

    final snapshot = await repository.fetchReport(
      SalesReportFilter(
        startDate: DateTime(2026, 8, 9),
        endDate: DateTime(2026, 8, 9, 23, 59, 59),
        taxMode: SalesReportTaxMode.gst,
        metalType: 'Gold',
      ),
    );

    expect(snapshot.invoices, hasLength(1));
    expect(snapshot.invoices.single.billNo, 'TAX-AJ-2026-0003');
    expect(snapshot.items, hasLength(1));
    expect(snapshot.items.single.metalType, 'Gold');
    expect(snapshot.gstLiability.invoiceCount, 2);
    expect(snapshot.gstLiability.gstInvoiceCount, 1);
    expect(snapshot.gstLiability.nonGstInvoiceCount, 1);
    expect(snapshot.gstLiability.recordedGstAmount, 30);
    expect(snapshot.gstLiability.nonGstSalesAmount, 600);
    expect(snapshot.gstLiability.projectedGstAmount, 18);
  });

  test('fetchReport allocates mixed invoice totals to selected metal',
      () async {
    final date = DateTime(2026, 8, 9, 12, 30);
    final billId = await _insertBill(
      db,
      billNo: 'TAX-AJ-2026-0005',
      billDate: date,
      billType: 'GST',
      totalAmount: 10000,
      taxableAmount: 10000,
      gstAmount: 300,
      finalAmount: 10300,
      paidAmount: 10300,
      makingTotal: 1000,
    );
    await _insertItem(
      db,
      billId: billId,
      lineNo: 1,
      metalType: 'GOLD',
      itemName: 'RING',
      purity: '18K',
      netWeight: 1,
      itemTotal: 4000,
    );
    await _insertItem(
      db,
      billId: billId,
      lineNo: 2,
      metalType: 'SILVER',
      itemName: 'PAYAL',
      purity: '60',
      netWeight: 10,
      itemTotal: 6000,
    );

    final snapshot = await repository.fetchReport(
      SalesReportFilter(
        startDate: DateTime(2026, 8, 9),
        endDate: DateTime(2026, 8, 9, 23, 59, 59),
        metalType: 'Gold',
      ),
    );

    expect(snapshot.items, hasLength(1));
    expect(snapshot.items.single.itemTotal, 4000);

    final invoice = snapshot.invoices.single;
    expect(invoice.grossAmount, 4000);
    expect(invoice.taxableAmount, 4000);
    expect(invoice.gstAmount, 120);
    expect(invoice.finalAmount, 4120);
    expect(invoice.metalMix, 'GOLD');
    expect(snapshot.summary.finalAmount, 4120);
  });
}

Future<int> _insertBill(
  AppDatabase db, {
  required String billNo,
  required DateTime billDate,
  required String billType,
  double totalAmount = 0,
  double discount = 0,
  double taxableAmount = 0,
  double gstAmount = 0,
  double roundOffAmount = 0,
  required double finalAmount,
  required double paidAmount,
  double dueAmount = 0,
  double cashPaid = 0,
  double upiPaid = 0,
  double cardPaid = 0,
  double makingTotal = 0,
}) {
  return db.into(db.bills).insert(
        BillsCompanion.insert(
          billNo: billNo,
          customerName: const drift.Value('REYANSH SONI'),
          mobile: const drift.Value('9304479436'),
          billType: drift.Value(billType),
          paymentStatus: drift.Value(dueAmount > 0 ? 'PARTIAL' : 'PAID'),
          totalAmount:
              drift.Value(totalAmount == 0 ? finalAmount : totalAmount),
          discount: drift.Value(discount),
          taxableAmount: drift.Value(taxableAmount),
          gstAmount: drift.Value(gstAmount),
          cgstAmount: drift.Value(gstAmount / 2),
          sgstAmount: drift.Value(gstAmount / 2),
          roundOffAmount: drift.Value(roundOffAmount),
          finalAmount: drift.Value(finalAmount),
          paidAmount: drift.Value(paidAmount),
          cashPaid: drift.Value(cashPaid),
          upiPaid: drift.Value(upiPaid),
          cardPaid: drift.Value(cardPaid),
          dueAmount: drift.Value(dueAmount),
          makingTotal: drift.Value(makingTotal),
          billDate: drift.Value(billDate),
          status: const drift.Value('ACTIVE'),
        ),
      );
}

Future<int> _insertItem(
  AppDatabase db, {
  required int billId,
  required int lineNo,
  required String metalType,
  required String itemName,
  String purity = '22K',
  String huid = '',
  double grossWeight = 0,
  double netWeight = 0,
  double rate = 0,
  double makingCharge = 0,
  double itemTotal = 0,
  double stockCost = 0,
  double profit = 0,
}) {
  return db.into(db.billItems).insert(
        BillItemsCompanion.insert(
          billId: billId,
          lineNo: drift.Value(lineNo),
          metalType: drift.Value(metalType),
          itemName: itemName,
          huid: drift.Value(huid),
          purity: drift.Value(purity),
          grossWeight: drift.Value(grossWeight),
          netWeight: drift.Value(netWeight),
          rate: drift.Value(rate),
          makingCharge: drift.Value(makingCharge),
          itemTotal: drift.Value(itemTotal),
          stockUnitCost: drift.Value(stockCost),
          stockProfitAmount: drift.Value(profit),
        ),
      );
}
