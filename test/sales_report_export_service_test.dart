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
    expect(csv, contains('GSTIN'));
    expect(csv, contains('B2B/B2C'));
    expect(csv, contains('Place of Supply'));
    expect(csv, contains('Old Gold Adjustment'));
    expect(csv, contains('Return/Credit Note'));
    expect(csv, contains('Net Weight by Metal'));
    expect(csv, contains('Gold 0.759 g'));
    expect(csv, contains('Silver 20.361 g'));
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
    final workbookXml = String.fromCharCodes(workbook!.content as List<int>);
    expect(workbookXml, contains('Sales Summary'));
    expect(workbookXml, contains('Invoice Register'));
    expect(workbookXml, contains('Item Register'));
    expect(workbookXml, contains('GST Register'));
    expect(workbookXml, contains('HSN GST Register'));
    expect(workbookXml, contains('Payment Register'));
    expect(workbookXml, contains('Customer Sales Register'));
    expect(workbookXml, contains('Advance Register'));
    expect(workbookXml, contains('Old Gold Adjustment'));
    expect(workbookXml, contains('Due Register'));
    expect(workbookXml, contains('Return Credit Register'));
    expect(workbookXml, contains('Metal Grade Register'));
    expect(summarySheet, isNotNull);
    expect(invoiceSheet, isNotNull);
    expect(itemSheet, isNotNull);
    final gstSheet = archive.findFile('xl/worksheets/sheet4.xml');
    final hsnGstSheet = archive.findFile('xl/worksheets/sheet5.xml');
    final paymentSheet = archive.findFile('xl/worksheets/sheet6.xml');
    final customerSheet = archive.findFile('xl/worksheets/sheet7.xml');
    final advanceSheet = archive.findFile('xl/worksheets/sheet8.xml');
    final oldGoldSheet = archive.findFile('xl/worksheets/sheet9.xml');
    final dueSheet = archive.findFile('xl/worksheets/sheet10.xml');
    final returnCreditSheet = archive.findFile('xl/worksheets/sheet11.xml');
    final metalGradeSheet = archive.findFile('xl/worksheets/sheet12.xml');
    expect(gstSheet, isNotNull);
    expect(hsnGstSheet, isNotNull);
    expect(paymentSheet, isNotNull);
    expect(customerSheet, isNotNull);
    expect(advanceSheet, isNotNull);
    expect(oldGoldSheet, isNotNull);
    expect(dueSheet, isNotNull);
    expect(returnCreditSheet, isNotNull);
    expect(metalGradeSheet, isNotNull);
    final summaryXml = String.fromCharCodes(summarySheet!.content as List<int>);
    final invoiceXml = String.fromCharCodes(invoiceSheet!.content as List<int>);
    final itemXml = String.fromCharCodes(itemSheet!.content as List<int>);
    final gstXml = String.fromCharCodes(gstSheet!.content as List<int>);
    final hsnGstXml = String.fromCharCodes(hsnGstSheet!.content as List<int>);
    final paymentXml = String.fromCharCodes(paymentSheet!.content as List<int>);
    final customerXml =
        String.fromCharCodes(customerSheet!.content as List<int>);
    final advanceXml = String.fromCharCodes(advanceSheet!.content as List<int>);
    final oldGoldXml = String.fromCharCodes(oldGoldSheet!.content as List<int>);
    final dueXml = String.fromCharCodes(dueSheet!.content as List<int>);
    final returnCreditXml =
        String.fromCharCodes(returnCreditSheet!.content as List<int>);
    final metalGradeXml =
        String.fromCharCodes(metalGradeSheet!.content as List<int>);
    expect(summaryXml, contains('Sales Register Summary'));
    expect(summaryXml, contains('Metal Wise Sales'));
    expect(invoiceXml, contains('GSTIN'));
    expect(invoiceXml, contains('B2B/B2C'));
    expect(invoiceXml, contains('Place of Supply'));
    expect(invoiceXml, contains('CGST'));
    expect(invoiceXml, contains('SGST'));
    expect(invoiceXml, contains('IGST'));
    expect(invoiceXml, contains('Old Gold Adjustment'));
    expect(invoiceXml, contains('Return/Credit Note'));
    expect(invoiceXml, contains('Bill Status'));
    expect(invoiceXml, contains('<autoFilter'));
    expect(invoiceXml, contains('<dimension ref='));
    expect(invoiceXml, contains('<f>SUM('));
    expect(invoiceXml, contains('<c r="J10" s="12"><f>SUM(J8:J9)</f>'));
    expect(gstXml, contains('<v>145.36</v>'));
    expect(gstXml, contains('<v>145.35</v>'));
    expect(gstXml, contains('<v>290.71</v>'));
    expect(hsnGstXml, contains('HSN GST Register'));
    expect(hsnGstXml, contains('7113'));
    expect(hsnGstXml, contains('GST Rate'));
    expect(hsnGstXml, contains('<v>9690.27</v>'));
    expect(hsnGstXml, contains('<v>9980.98</v>'));
    expect(paymentXml, contains('Payment Register'));
    expect(paymentXml, contains('Old Gold Adjustment'));
    expect(paymentXml, contains('<v>8480.98</v>'));
    expect(paymentXml, contains('<v>3000.00</v>'));
    expect(customerXml, contains('Customer Sales Register'));
    expect(customerXml, contains('REYANSH SONI'));
    expect(customerXml, contains('<v>14053.18</v>'));
    expect(advanceXml, contains('Advance Register'));
    expect(advanceXml, contains('Advance Adjusted'));
    expect(advanceXml, contains('<v>500.00</v>'));
    expect(oldGoldXml, contains('Old Gold Adjustment Register'));
    expect(oldGoldXml, contains('<v>1000.00</v>'));
    expect(dueXml, contains('Due Register'));
    expect(dueXml, contains('Outstanding invoice balances'));
    expect(dueXml, contains('<v>1072.20</v>'));
    expect(returnCreditXml, contains('Return Credit Register'));
    expect(returnCreditXml, contains('No return/credit notes found'));
    expect(metalGradeXml, contains('Metal Grade Register'));
    expect(metalGradeXml, contains('18KT'));
    expect(metalGradeXml, contains('60'));
    expect(metalGradeXml, contains('<v>0.759</v>'));
    expect(metalGradeXml, contains('<v>20.361</v>'));
    expect(itemXml, contains('Making Charges'));
    expect(itemXml, contains('<autoFilter'));
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
    cashAmount: 8480.98,
    advanceAmount: 500,
    tradeInDeduction: 1000,
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
        hsnCode: '7113',
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
        hsnCode: '7113',
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
  double? cashAmount,
  double dueAmount = 0,
  double advanceAmount = 0,
  double tradeInDeduction = 0,
  required String metalMix,
}) {
  return SalesReportInvoiceRow(
    billId: billId,
    billNo: billNo,
    billDate: DateTime(2026, 8, 9, 17, 18),
    customerName: 'REYANSH SONI',
    mobile: '9304479436',
    customerGstin: isGst ? '10ABCDE1234F1Z5' : '',
    businessType: isGst ? 'B2B' : 'B2C',
    placeOfSupply: 'Bihar',
    billType: isGst ? 'GST' : 'NORMAL',
    paymentStatus: dueAmount > 0 ? 'PARTIAL' : 'PAID',
    isGst: isGst,
    grossAmount: grossAmount,
    discountAmount: discountAmount,
    taxableAmount: taxableAmount,
    gstAmount: gstAmount,
    cgstAmount: isGst ? gstAmount / 2 : 0,
    sgstAmount: isGst ? gstAmount / 2 : 0,
    igstAmount: 0,
    roundOffAmount: 0,
    finalAmount: finalAmount,
    paidAmount: paidAmount,
    dueAmount: dueAmount,
    cashAmount: cashAmount ?? paidAmount,
    upiAmount: 0,
    cardAmount: 0,
    bankAmount: 0,
    advanceAmount: advanceAmount,
    makingAmount: 0,
    tradeInDeduction: tradeInDeduction,
    returnCreditNoteAmount: 0,
    itemCount: 1,
    metalMix: metalMix,
    billStatus: 'ACTIVE',
  );
}

SalesReportItemRow _item({
  required int billId,
  required String billNo,
  required String metalType,
  required String itemName,
  String hsnCode = '',
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
    hsnCode: hsnCode,
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
