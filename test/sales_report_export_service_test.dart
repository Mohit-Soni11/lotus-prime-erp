import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:lotus_erp/logic/report/sales_report/sales_report_export_service.dart';
import 'package:lotus_erp/models/reports/sales_report/sales_report_models.dart';

void main() {
  final snapshot = _snapshot();

  test('complete CSV includes GST liability and metal weight audit', () {
    final csv = SalesReportExportService.buildCompleteCsvForTest(snapshot);

    expect(csv, contains('GST LIABILITY'));
    expect(csv, contains('Combined GST Exposure'));
    expect(csv, contains('Metal Net Weight'));
    expect(csv, contains('Net Weight by Metal'));
    expect(csv, contains('Gold 0.759 g'));
    expect(csv, contains('Silver 20.361 g'));
    expect(csv, isNot(contains('Cash')));
    expect(csv, isNot(contains('UPI')));
    expect(csv, isNot(contains('Advance')));
  });

  test('complete sales report Excel builds a styled workbook', () {
    final bytes = SalesReportExportService.buildCompleteExcelBytes(snapshot);
    final archive = ZipDecoder().decodeBytes(bytes);
    final workbook = archive.findFile('xl/workbook.xml');
    final summarySheet = archive.findFile('xl/worksheets/sheet1.xml');
    final invoiceSheet = archive.findFile('xl/worksheets/sheet2.xml');
    final itemSheet = archive.findFile('xl/worksheets/sheet3.xml');

    expect(bytes.take(2), orderedEquals(const [80, 75]));
    expect(workbook, isNotNull);
    expect(String.fromCharCodes(workbook!.content as List<int>),
        contains('Invoice Ledger'));
    expect(summarySheet, isNotNull);
    expect(invoiceSheet, isNotNull);
    expect(itemSheet, isNotNull);
    expect(String.fromCharCodes(summarySheet!.content as List<int>),
        contains('Sales Summary'));
    expect(archive.findFile('xl/styles.xml'), isNotNull);
  });

  test('complete sales report PDF builds successfully', () async {
    final bytes =
        await SalesReportExportService.buildCompletePdfBytes(snapshot);

    expect(bytes.take(4), orderedEquals(const [37, 80, 68, 70]));
  });

  test('GST liability PDF builds successfully', () async {
    final bytes =
        await SalesReportExportService.buildGstLiabilityPdfBytes(snapshot);

    expect(bytes.take(4), orderedEquals(const [37, 80, 68, 70]));
  });

  test('invoice ledger PDF builds successfully', () async {
    final bytes =
        await SalesReportExportService.buildInvoiceLedgerPdfBytes(snapshot);

    expect(bytes.take(4), orderedEquals(const [37, 80, 68, 70]));
  });

  test('item ledger PDF builds successfully', () async {
    final bytes =
        await SalesReportExportService.buildItemLedgerPdfBytes(snapshot);

    expect(bytes.take(4), orderedEquals(const [37, 80, 68, 70]));
  });

  test('grade-wise PDF builds successfully', () async {
    final bytes = await SalesReportExportService.buildGradeWisePdfBytes(
      snapshot,
      metalTitle: 'Gold',
    );

    expect(bytes.take(4), orderedEquals(const [37, 80, 68, 70]));
  });
}

SalesReportSnapshot _snapshot() {
  final filter = SalesReportFilter(
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 31, 23, 59, 59),
  );
  final goldInvoice = _invoice(
    billId: 1,
    billNo: 'TAX-AJ-2026-0001',
    isGst: true,
    grossAmount: 9690.91,
    discountAmount: 0.64,
    taxableAmount: 9690.27,
    gstAmount: 290.71,
    finalAmount: 9980.98,
    paidAmount: 9980.98,
    metalMix: 'GOLD',
  );
  final silverInvoice = _invoice(
    billId: 2,
    billNo: 'INV-AJ-2026-0002',
    isGst: false,
    grossAmount: 4072.20,
    taxableAmount: 4072.20,
    finalAmount: 4072.20,
    paidAmount: 3000,
    dueAmount: 1072.20,
    metalMix: 'SILVER',
  );

  return SalesReportSnapshot(
    filter: filter,
    summary: const SalesReportSummary(
      invoiceCount: 2,
      gstInvoiceCount: 1,
      nonGstInvoiceCount: 1,
      grossAmount: 13763.11,
      discountAmount: 0.64,
      taxableAmount: 13762.47,
      gstAmount: 290.71,
      finalAmount: 14053.18,
      paidAmount: 12980.98,
      dueAmount: 1072.20,
      makingAmount: 1445.53,
      netWeight: 21.120,
    ),
    gstLiability: const SalesReportGstLiabilitySummary(
      invoiceCount: 2,
      gstInvoiceCount: 1,
      nonGstInvoiceCount: 1,
      gstTaxableAmount: 9690.27,
      gstFinalAmount: 9980.98,
      recordedGstAmount: 290.71,
      nonGstSalesAmount: 4072.20,
      projectedGstAmount: 122.17,
    ),
    metals: const [
      SalesReportMetalSummary(
        metalType: 'Gold',
        invoiceCount: 1,
        itemCount: 1,
        pieces: 1,
        grossWeight: 0.759,
        netWeight: 0.759,
        makingAmount: 1038.31,
        salesAmount: 9690.91,
      ),
      SalesReportMetalSummary(
        metalType: 'Silver',
        invoiceCount: 1,
        itemCount: 1,
        pieces: 1,
        grossWeight: 20.361,
        netWeight: 20.361,
        makingAmount: 407.22,
        salesAmount: 4072.20,
      ),
    ],
    invoices: [goldInvoice, silverInvoice],
    items: [
      _item(
        billId: goldInvoice.billId,
        billNo: goldInvoice.billNo,
        metalType: 'Gold',
        itemName: 'Nose Pin',
        purity: '18KT',
        grossWeight: 0.759,
        netWeight: 0.759,
        rate: 11400,
        makingCharge: 1038.31,
        itemTotal: 9690.91,
      ),
      _item(
        billId: silverInvoice.billId,
        billNo: silverInvoice.billNo,
        metalType: 'Silver',
        itemName: 'Payal',
        purity: '60',
        grossWeight: 20.361,
        netWeight: 20.361,
        rate: 180,
        makingCharge: 407.22,
        itemTotal: 4072.20,
      ),
    ],
    availableMetals: const ['ALL', 'Gold', 'Silver'],
  );
}

SalesReportInvoiceRow _invoice({
  required int billId,
  required String billNo,
  required bool isGst,
  required double grossAmount,
  double discountAmount = 0,
  required double taxableAmount,
  double gstAmount = 0,
  required double finalAmount,
  required double paidAmount,
  double dueAmount = 0,
  required String metalMix,
}) {
  return SalesReportInvoiceRow(
    billId: billId,
    billNo: billNo,
    billDate: DateTime(2026, 8, 9, 17, 18),
    customerName: 'REYANSH SONI',
    mobile: '9304479436',
    billType: isGst ? 'GST' : 'NORMAL',
    paymentStatus: dueAmount > 0 ? 'PARTIAL' : 'PAID',
    isGst: isGst,
    grossAmount: grossAmount,
    discountAmount: discountAmount,
    taxableAmount: taxableAmount,
    gstAmount: gstAmount,
    roundOffAmount: 0,
    finalAmount: finalAmount,
    paidAmount: paidAmount,
    dueAmount: dueAmount,
    cashAmount: paidAmount,
    upiAmount: 0,
    cardAmount: 0,
    advanceAmount: 0,
    makingAmount: 0,
    tradeInDeduction: 0,
    itemCount: 1,
    metalMix: metalMix,
  );
}

SalesReportItemRow _item({
  required int billId,
  required String billNo,
  required String metalType,
  required String itemName,
  required String purity,
  required double grossWeight,
  required double netWeight,
  required double rate,
  required double makingCharge,
  required double itemTotal,
}) {
  return SalesReportItemRow(
    billId: billId,
    billNo: billNo,
    billDate: DateTime(2026, 8, 9, 17, 18),
    customerName: 'REYANSH SONI',
    isGst: billNo.startsWith('TAX'),
    lineNo: 1,
    metalType: metalType,
    itemName: itemName,
    huid: '',
    purity: purity,
    quantity: 1,
    grossWeight: grossWeight,
    lessWeight: 0,
    netWeight: netWeight,
    fineWeight: 0,
    rate: rate,
    makingChargeType: 'PERCENTAGE',
    makingCharge: makingCharge,
    itemTotal: itemTotal,
    stockSku: '',
    stockCostAmount: 0,
    profitAmount: 0,
  );
}
