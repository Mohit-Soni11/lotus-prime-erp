import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../../models/reports/sales_report/sales_report_models.dart';
import 'sales_report_export_formatters.dart';

part 'sales_report_excel_workbook.dart';

class SalesReportExcelBuilder {
  SalesReportExcelBuilder._();

  static Uint8List buildComplete(
    SalesReportSnapshot snapshot, {
    required SalesReportExportIdentity identity,
    String reportTitle = 'Sales Report',
  }) {
    final summarySheet = _WorksheetBuilder(
      columnWidths: const [18, 18, 18, 18, 18, 18, 18, 18, 18, 18],
    );
    _addReportHeader(summarySheet, snapshot, identity, reportTitle);
    _addSalesRegisterSummary(summarySheet, snapshot);
    _addMetalWeightSummary(summarySheet, snapshot);
    _addGstRegisterSummary(summarySheet, snapshot);

    final invoiceSheet = _WorksheetBuilder(
      columnWidths: const [
        8,
        24,
        22,
        14,
        28,
        16,
        18,
        12,
        20,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
        18,
        16,
        16,
        16,
        16,
        16,
        16,
        22,
        14,
      ],
    );
    _addReportHeader(invoiceSheet, snapshot, identity, 'Invoice Register');
    _addInvoiceLedger(invoiceSheet, snapshot);

    final itemSheet = _WorksheetBuilder(
      columnWidths: const [
        8,
        24,
        22,
        28,
        14,
        14,
        24,
        20,
        16,
        10,
        15,
        15,
        15,
        15,
        16,
        16,
      ],
    );
    _addReportHeader(itemSheet, snapshot, identity, 'Item Register');
    _addItemLedger(itemSheet, snapshot.items);

    final gstSheet = _WorksheetBuilder(
      columnWidths: const [8, 24, 22, 28, 15, 17, 17, 17, 17, 17],
    );
    _addReportHeader(gstSheet, snapshot, identity, 'GST Register');
    _addGstRegister(gstSheet, snapshot);

    final hsnGstSheet = _WorksheetBuilder(
      columnWidths: const [8, 16, 14, 16, 14, 14, 16, 16, 16, 16, 16, 16],
    );
    _addReportHeader(hsnGstSheet, snapshot, identity, 'HSN GST Register');
    _addHsnGstRegister(hsnGstSheet, snapshot);

    final paymentSheet = _WorksheetBuilder(
      columnWidths: const [
        8,
        24,
        22,
        28,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
        22,
        16,
        16,
        18,
        14,
      ],
    );
    _addReportHeader(paymentSheet, snapshot, identity, 'Payment Register');
    _addPaymentRegister(paymentSheet, snapshot);

    final customerSheet = _WorksheetBuilder(
      columnWidths: const [
        8,
        30,
        16,
        20,
        12,
        14,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
        22,
      ],
    );
    _addReportHeader(
      customerSheet,
      snapshot,
      identity,
      'Customer Sales Register',
    );
    _addCustomerSalesRegister(customerSheet, snapshot);

    final advanceSheet = _WorksheetBuilder(
      columnWidths: const [
        8,
        24,
        22,
        28,
        16,
        16,
        18,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
        14
      ],
    );
    _addReportHeader(advanceSheet, snapshot, identity, 'Advance Register');
    _addAdvanceRegister(advanceSheet, snapshot);

    final oldGoldSheet = _WorksheetBuilder(
      columnWidths: const [
        8,
        24,
        22,
        28,
        16,
        16,
        22,
        16,
        16,
        16,
        16,
        16,
        16,
        14
      ],
    );
    _addReportHeader(
      oldGoldSheet,
      snapshot,
      identity,
      'Old Gold Adjustment',
    );
    _addOldGoldAdjustmentRegister(oldGoldSheet, snapshot);

    final dueSheet = _WorksheetBuilder(
      columnWidths: const [
        8,
        24,
        22,
        28,
        16,
        18,
        12,
        20,
        16,
        16,
        16,
        16,
        16,
        16,
        14,
      ],
    );
    _addReportHeader(dueSheet, snapshot, identity, 'Due Register');
    _addDueRegister(dueSheet, snapshot);

    final returnCreditSheet = _WorksheetBuilder(
      columnWidths: const [8, 24, 22, 28, 16, 16, 22, 16, 16, 18, 14],
    );
    _addReportHeader(
      returnCreditSheet,
      snapshot,
      identity,
      'Return Credit Register',
    );
    _addReturnCreditRegister(returnCreditSheet, snapshot);

    final metalGradeSheet = _WorksheetBuilder(
      columnWidths: const [8, 14, 16, 16, 16, 14, 16, 16, 16, 16],
    );
    _addReportHeader(
      metalGradeSheet,
      snapshot,
      identity,
      'Metal Grade Register',
    );
    _addMetalGradeRegister(metalGradeSheet, snapshot);

    return _buildWorkbook({
      'Sales Summary': summarySheet.toXml(),
      'Invoice Register': invoiceSheet.toXml(),
      'Item Register': itemSheet.toXml(),
      'GST Register': gstSheet.toXml(),
      'HSN GST Register': hsnGstSheet.toXml(),
      'Payment Register': paymentSheet.toXml(),
      'Customer Sales Register': customerSheet.toXml(),
      'Advance Register': advanceSheet.toXml(),
      'Old Gold Adjustment': oldGoldSheet.toXml(),
      'Due Register': dueSheet.toXml(),
      'Return Credit Register': returnCreditSheet.toXml(),
      'Metal Grade Register': metalGradeSheet.toXml(),
    });
  }

  static Uint8List buildMetalComplete(
    SalesReportSnapshot snapshot, {
    required SalesReportExportIdentity identity,
    required String metalTitle,
  }) {
    final summarySheet = _WorksheetBuilder(
      columnWidths: const [18, 18, 18, 18, 18, 18, 18, 18, 18, 18],
    );
    _addReportHeader(summarySheet, snapshot, identity, '$metalTitle Sales');
    _addSalesRegisterSummary(summarySheet, snapshot);
    _addMetalWeightSummary(summarySheet, snapshot);

    final gradeSheet = _WorksheetBuilder(
      columnWidths: const [8, 14, 16, 16, 16, 14, 16, 16, 16, 16],
    );
    _addReportHeader(gradeSheet, snapshot, identity, '$metalTitle Grade Sales');
    _addMetalGradeRegister(gradeSheet, snapshot);

    final invoiceSheet = _WorksheetBuilder(
      columnWidths: const [
        8,
        24,
        22,
        14,
        28,
        16,
        18,
        12,
        20,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
        18,
        16,
        16,
        16,
        16,
        16,
        16,
        22,
        14,
      ],
    );
    _addReportHeader(
      invoiceSheet,
      snapshot,
      identity,
      '$metalTitle Invoice Ledger',
    );
    _addInvoiceLedger(invoiceSheet, snapshot);

    final itemSheet = _WorksheetBuilder(
      columnWidths: const [
        8,
        24,
        22,
        28,
        14,
        14,
        24,
        20,
        16,
        10,
        15,
        15,
        15,
        15,
        16,
        16,
      ],
    );
    _addReportHeader(itemSheet, snapshot, identity, '$metalTitle Item Ledger');
    _addItemLedger(itemSheet, snapshot.items);

    return _buildWorkbook({
      'Metal Sales Ledger': summarySheet.toXml(),
      'Grade-wise Sales': gradeSheet.toXml(),
      'Invoice Ledger': invoiceSheet.toXml(),
      'Item Ledger': itemSheet.toXml(),
    });
  }

  static void _addReportHeader(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
    SalesReportExportIdentity identity,
    String reportTitle,
  ) {
    final shopName = identity.shopName.trim().isEmpty
        ? 'Sales Report'
        : identity.shopName.trim();
    sheet.addMergedText(
      shopName.toUpperCase(),
      1,
      sheet.columnCount,
      _ExcelStyle.title,
    );
    sheet.addMergedText(
      reportTitle,
      1,
      sheet.columnCount,
      _ExcelStyle.subtitle,
    );
    for (final line in identity.headerLines.take(3)) {
      sheet.addMergedText(line, 1, sheet.columnCount, _ExcelStyle.muted);
    }
    sheet.addBlankRow();
    sheet.addRow([
      _ExcelCell.text('Period', _ExcelStyle.sectionLabel),
      _ExcelCell.text(
        SalesReportExportFormatters.periodLabel(snapshot.filter),
        _ExcelStyle.sectionValue,
      ),
      _ExcelCell.text('Tax View', _ExcelStyle.sectionLabel),
      _ExcelCell.text(
        SalesReportExportFormatters.taxModeLabel(snapshot.filter.taxMode),
        _ExcelStyle.sectionValue,
      ),
      _ExcelCell.text('Metal View', _ExcelStyle.sectionLabel),
      _ExcelCell.text(snapshot.filter.metalType, _ExcelStyle.sectionValue),
    ]);
    sheet.addBlankRow();
  }

  static void _addSalesRegisterSummary(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final summary = snapshot.summary;
    sheet.addSection(
      'Sales Register Summary',
      'Clean monthly totals for accountant and CA review',
    );
    sheet.addRow([
      _ExcelCell.text('Total Bills', _ExcelStyle.tableHeader),
      _ExcelCell.text('GST Bills', _ExcelStyle.tableHeader),
      _ExcelCell.text('Normal Bills', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gross Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('Discount', _ExcelStyle.tableHeader),
      _ExcelCell.text('Taxable Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('Output GST', _ExcelStyle.tableHeader),
      _ExcelCell.text('Round Off', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Total', _ExcelStyle.tableHeader),
      _ExcelCell.text('Balance Due', _ExcelStyle.tableHeader),
    ]);
    sheet.addRow([
      _ExcelCell.number(summary.invoiceCount, _ExcelStyle.integerStrong),
      _ExcelCell.number(summary.gstInvoiceCount, _ExcelStyle.integerStrong),
      _ExcelCell.number(summary.nonGstInvoiceCount, _ExcelStyle.integerStrong),
      _ExcelCell.number(summary.grossAmount, _ExcelStyle.moneyStrong),
      _ExcelCell.number(summary.discountAmount, _ExcelStyle.moneyStrong),
      _ExcelCell.number(summary.taxableAmount, _ExcelStyle.moneyStrong),
      _ExcelCell.number(summary.gstAmount, _ExcelStyle.moneyStrong),
      _ExcelCell.number(summary.roundOffAmount, _ExcelStyle.moneyStrong),
      _ExcelCell.number(summary.finalAmount, _ExcelStyle.totalMoney),
      _ExcelCell.number(summary.dueAmount, _ExcelStyle.moneyStrong),
    ]);
    sheet.addBlankRow();
  }

  static void _addGstRegisterSummary(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final gst = snapshot.gstLiability;
    sheet.addSection(
      'Sales Overview',
      'Normal bill sales, GST bill sales, due amount and tax collection snapshot',
    );
    sheet.addRow([
      _ExcelCell.text('Normal Bills', _ExcelStyle.tableHeader),
      _ExcelCell.text('Normal Bill Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('GST Bills', _ExcelStyle.tableHeader),
      _ExcelCell.text('GST Bill Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('Due Amount', _ExcelStyle.tableHeader),
      _ExcelCell.text('GST Collected', _ExcelStyle.tableHeader),
      _ExcelCell.text('Normal Bill GST Estimate', _ExcelStyle.tableHeader),
    ]);
    sheet.addRow([
      _ExcelCell.number(gst.nonGstInvoiceCount, _ExcelStyle.integerStrong),
      _ExcelCell.number(gst.nonGstSalesAmount, _ExcelStyle.moneyStrong),
      _ExcelCell.number(gst.gstInvoiceCount, _ExcelStyle.integerStrong),
      _ExcelCell.number(gst.gstFinalAmount, _ExcelStyle.moneyStrong),
      _ExcelCell.number(gst.dueAmount, _ExcelStyle.moneyStrong),
      _ExcelCell.number(gst.recordedGstAmount, _ExcelStyle.totalMoney),
      _ExcelCell.number(gst.projectedGstAmount, _ExcelStyle.moneyStrong),
    ]);
    sheet.addBlankRow();
  }

  static void _addMetalWeightSummary(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    if (snapshot.metals.isEmpty) return;
    sheet.addSection(
      'Metal Wise Sales',
      'Sold weight and value by metal for the selected period',
    );
    sheet.addRow([
      _ExcelCell.text('Metal', _ExcelStyle.tableHeader),
      _ExcelCell.text('Bills With Metal', _ExcelStyle.tableHeader),
      _ExcelCell.text('Line Items', _ExcelStyle.tableHeader),
      _ExcelCell.text('Pcs', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gross Wt (g)', _ExcelStyle.tableHeader),
      _ExcelCell.text('Net Wt (g)', _ExcelStyle.tableHeader),
      _ExcelCell.text('Item Amount', _ExcelStyle.tableHeader),
    ]);
    for (final metal in snapshot.metals) {
      sheet.addRow([
        _ExcelCell.text(metal.metalType),
        _ExcelCell.number(metal.invoiceCount, _ExcelStyle.integer),
        _ExcelCell.number(metal.itemCount, _ExcelStyle.integer),
        _ExcelCell.number(metal.pieces, _ExcelStyle.integer),
        _ExcelCell.number(metal.grossWeight, _ExcelStyle.weight),
        _ExcelCell.number(metal.netWeight, _ExcelStyle.weight),
        _ExcelCell.number(metal.salesAmount, _ExcelStyle.money),
      ]);
    }
    sheet.addRow([
      _ExcelCell.text('UNIQUE TOTAL', _ExcelStyle.totalText),
      _ExcelCell.number(
        snapshot.summary.invoiceCount,
        _ExcelStyle.integerStrong,
      ),
      _ExcelCell.number(
        snapshot.metals.fold(0, (sum, metal) => sum + metal.itemCount),
        _ExcelStyle.integerStrong,
      ),
      _ExcelCell.number(
        snapshot.metals.fold(0, (sum, metal) => sum + metal.pieces),
        _ExcelStyle.integerStrong,
      ),
      _ExcelCell.number(
        snapshot.metals.fold(0, (sum, metal) => sum + metal.grossWeight),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.number(
        snapshot.metals.fold(0, (sum, metal) => sum + metal.netWeight),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.number(
        snapshot.metals.fold(0, (sum, metal) => sum + metal.salesAmount),
        _ExcelStyle.totalMoney,
      ),
    ]);
    sheet.addBlankRow();
  }

  static void _addInvoiceLedger(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    sheet.addSection(
      'Invoice Register',
      'CA-ready bill register with customer, tax, payment and due audit',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date/Time', _ExcelStyle.tableHeader),
      _ExcelCell.text('Status', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Mobile', _ExcelStyle.tableHeader),
      _ExcelCell.text('GSTIN', _ExcelStyle.tableHeader),
      _ExcelCell.text('B2B/B2C', _ExcelStyle.tableHeader),
      _ExcelCell.text('Place of Supply', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gross Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('Discount', _ExcelStyle.tableHeader),
      _ExcelCell.text('Taxable', _ExcelStyle.tableHeader),
      _ExcelCell.text('CGST', _ExcelStyle.tableHeader),
      _ExcelCell.text('SGST', _ExcelStyle.tableHeader),
      _ExcelCell.text('IGST', _ExcelStyle.tableHeader),
      _ExcelCell.text('Round Off', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Total', _ExcelStyle.tableHeader),
      _ExcelCell.text('Advance', _ExcelStyle.tableHeader),
      _ExcelCell.text('Old Gold Adjustment', _ExcelStyle.tableHeader),
      _ExcelCell.text('Cash', _ExcelStyle.tableHeader),
      _ExcelCell.text('UPI', _ExcelStyle.tableHeader),
      _ExcelCell.text('Card', _ExcelStyle.tableHeader),
      _ExcelCell.text('Bank', _ExcelStyle.tableHeader),
      _ExcelCell.text('Paid', _ExcelStyle.tableHeader),
      _ExcelCell.text('Due', _ExcelStyle.tableHeader),
      _ExcelCell.text('Return/Credit Note', _ExcelStyle.tableHeader),
      _ExcelCell.text('Bill Status', _ExcelStyle.tableHeader),
    ]);
    final tableHeaderRow = sheet.currentRow;
    for (var index = 0; index < snapshot.invoices.length; index++) {
      final invoice = snapshot.invoices[index];
      final split = _gstBreakup(invoice);
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(invoice.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(invoice.billDate)),
        _ExcelCell.text(invoice.paymentStatus),
        _ExcelCell.text(invoice.customerName),
        _ExcelCell.text(invoice.mobile),
        _ExcelCell.text(invoice.customerGstin),
        _ExcelCell.text(invoice.businessType),
        _ExcelCell.text(invoice.placeOfSupply),
        _ExcelCell.number(invoice.grossAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.discountAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.taxableAmount, _ExcelStyle.money),
        _ExcelCell.number(split.cgst, _ExcelStyle.money),
        _ExcelCell.number(split.sgst, _ExcelStyle.money),
        _ExcelCell.number(split.igst, _ExcelStyle.money),
        _ExcelCell.number(invoice.roundOffAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.finalAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(invoice.advanceAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.tradeInDeduction, _ExcelStyle.money),
        _ExcelCell.number(invoice.cashAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.upiAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.cardAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.bankAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.paidAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.dueAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.returnCreditNoteAmount, _ExcelStyle.money),
        _ExcelCell.text(invoice.billStatus),
      ]);
    }
    final dataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('J', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('K', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('L', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('M', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('N', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('O', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('P', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('Q', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('R', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('S', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('T', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('U', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('V', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('W', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('X', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('Y', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('Z', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.empty(),
    ]);
    sheet.setAutoFilter(tableHeaderRow, dataEndRow, 1, sheet.columnCount);
    sheet.addBlankRow();
  }

  static void _addItemLedger(
    _WorksheetBuilder sheet,
    List<SalesReportItemRow> items,
  ) {
    sheet.addSection(
      'Item Register',
      'Item-level HUID, purity, weight, rate and value',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Type', _ExcelStyle.tableHeader),
      _ExcelCell.text('Metal', _ExcelStyle.tableHeader),
      _ExcelCell.text('Item', _ExcelStyle.tableHeader),
      _ExcelCell.text('HUID', _ExcelStyle.tableHeader),
      _ExcelCell.text('Purity', _ExcelStyle.tableHeader),
      _ExcelCell.text('Pcs', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gross Wt', _ExcelStyle.tableHeader),
      _ExcelCell.text('Less Wt', _ExcelStyle.tableHeader),
      _ExcelCell.text('Net Wt', _ExcelStyle.tableHeader),
      _ExcelCell.text('Rate', _ExcelStyle.tableHeader),
      _ExcelCell.text('Making Charges', _ExcelStyle.tableHeader),
      _ExcelCell.text('Item Amount', _ExcelStyle.tableHeader),
    ]);
    final tableHeaderRow = sheet.currentRow;
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(item.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(item.billDate)),
        _ExcelCell.text(item.customerName),
        _ExcelCell.text(item.isGst ? 'GST BILL' : 'NORMAL'),
        _ExcelCell.text(item.metalType),
        _ExcelCell.text(item.itemName),
        _ExcelCell.text(item.huid.isEmpty ? 'Not linked' : item.huid),
        _ExcelCell.text(item.purity),
        _ExcelCell.number(item.quantity, _ExcelStyle.integer),
        _ExcelCell.number(item.grossWeight, _ExcelStyle.weight),
        _ExcelCell.number(item.lessWeight, _ExcelStyle.weight),
        _ExcelCell.number(item.netWeight, _ExcelStyle.weight),
        _ExcelCell.number(item.rate, _ExcelStyle.money),
        _ExcelCell.number(item.makingCharge, _ExcelStyle.money),
        _ExcelCell.number(item.itemTotal, _ExcelStyle.totalMoney),
      ]);
    }
    final dataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('J', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.integerStrong,
      ),
      _ExcelCell.formula(
        _sumFormula('K', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.formula(
        _sumFormula('L', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.formula(
        _sumFormula('M', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('O', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('P', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
    ]);
    sheet.setAutoFilter(tableHeaderRow, dataEndRow, 1, sheet.columnCount);
  }

  static void _addGstRegister(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final gstInvoices =
        snapshot.invoices.where((invoice) => invoice.isGst).toList();
    sheet.addSection(
      'Recorded GST Register',
      'GST invoices only - use this section for output GST payable',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Taxable Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('CGST 1.5%', _ExcelStyle.tableHeader),
      _ExcelCell.text('SGST 1.5%', _ExcelStyle.tableHeader),
      _ExcelCell.text('IGST', _ExcelStyle.tableHeader),
      _ExcelCell.text('Total GST', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Total', _ExcelStyle.tableHeader),
    ]);
    final recordedHeaderRow = sheet.currentRow;
    for (var index = 0; index < gstInvoices.length; index++) {
      final invoice = gstInvoices[index];
      final split = _gstBreakup(invoice);
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(invoice.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(invoice.billDate)),
        _ExcelCell.text(invoice.customerName),
        _ExcelCell.number(invoice.taxableAmount, _ExcelStyle.money),
        _ExcelCell.number(split.cgst, _ExcelStyle.money),
        _ExcelCell.number(split.sgst, _ExcelStyle.money),
        _ExcelCell.number(split.igst, _ExcelStyle.money),
        _ExcelCell.number(invoice.gstAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(invoice.finalAmount, _ExcelStyle.totalMoney),
      ]);
    }
    final recordedDataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('E', recordedHeaderRow + 1, recordedDataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('F', recordedHeaderRow + 1, recordedDataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('G', recordedHeaderRow + 1, recordedDataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('H', recordedHeaderRow + 1, recordedDataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('I', recordedHeaderRow + 1, recordedDataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('J', recordedHeaderRow + 1, recordedDataEndRow),
        _ExcelStyle.totalMoney,
      ),
    ]);
    sheet.addBlankRow();

    final nonGstInvoices =
        snapshot.invoices.where((invoice) => !invoice.isGst).toList();
    sheet.addSection(
      'Normal Bill GST Estimate',
      'Reference only - not recorded as GST payable unless you decide to declare it',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Normal Bill Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text(
        'Estimated GST ${SalesReportExportFormatters.rate(snapshot.gstLiability.projectedGstRatePercent)}',
        _ExcelStyle.tableHeader,
      ),
      _ExcelCell.text('Estimated Total', _ExcelStyle.tableHeader),
    ]);
    final estimateHeaderRow = sheet.currentRow;
    final projectedGstRate =
        snapshot.gstLiability.projectedGstRatePercent / 100;
    for (var index = 0; index < nonGstInvoices.length; index++) {
      final invoice = nonGstInvoices[index];
      final estimatedGst =
          _roundMoney(invoice.taxableAmount * projectedGstRate);
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(invoice.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(invoice.billDate)),
        _ExcelCell.text(invoice.customerName),
        _ExcelCell.number(invoice.taxableAmount, _ExcelStyle.money),
        _ExcelCell.number(estimatedGst, _ExcelStyle.money),
        _ExcelCell.number(
          invoice.taxableAmount + estimatedGst,
          _ExcelStyle.money,
        ),
      ]);
    }
    final estimateDataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('E', estimateHeaderRow + 1, estimateDataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('F', estimateHeaderRow + 1, estimateDataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('G', estimateHeaderRow + 1, estimateDataEndRow),
        _ExcelStyle.totalMoney,
      ),
    ]);
  }

  static void _addHsnGstRegister(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final rows = _buildHsnGstRows(snapshot);
    sheet.addSection(
      'HSN GST Register',
      'Recorded GST invoice values grouped by HSN/SAC and GST rate',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('HSN/SAC', _ExcelStyle.tableHeader),
      _ExcelCell.text('GST Rate', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoices', _ExcelStyle.tableHeader),
      _ExcelCell.text('Line Items', _ExcelStyle.tableHeader),
      _ExcelCell.text('Pcs', _ExcelStyle.tableHeader),
      _ExcelCell.text('Taxable Value', _ExcelStyle.tableHeader),
      _ExcelCell.text('CGST', _ExcelStyle.tableHeader),
      _ExcelCell.text('SGST', _ExcelStyle.tableHeader),
      _ExcelCell.text('IGST', _ExcelStyle.tableHeader),
      _ExcelCell.text('Total GST', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Value', _ExcelStyle.tableHeader),
    ]);
    final tableHeaderRow = sheet.currentRow;
    if (rows.isEmpty) {
      sheet.addRow([
        _ExcelCell.text('No GST HSN records found for this period'),
      ]);
      return;
    }
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(row.hsnCode),
        _ExcelCell.text('${row.gstRate.toStringAsFixed(2)}%'),
        _ExcelCell.number(row.invoiceCount, _ExcelStyle.integer),
        _ExcelCell.number(row.lineItemCount, _ExcelStyle.integer),
        _ExcelCell.number(row.pieces, _ExcelStyle.integer),
        _ExcelCell.number(row.taxableAmount, _ExcelStyle.money),
        _ExcelCell.number(row.cgstAmount, _ExcelStyle.money),
        _ExcelCell.number(row.sgstAmount, _ExcelStyle.money),
        _ExcelCell.number(row.igstAmount, _ExcelStyle.money),
        _ExcelCell.number(row.gstAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(row.invoiceAmount, _ExcelStyle.totalMoney),
      ]);
    }
    final dataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('D', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.integerStrong,
      ),
      _ExcelCell.formula(
        _sumFormula('E', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.integerStrong,
      ),
      _ExcelCell.formula(
        _sumFormula('F', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.integerStrong,
      ),
      _ExcelCell.formula(
        _sumFormula('G', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('H', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('I', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('J', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('K', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('L', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
    ]);
    sheet.setAutoFilter(tableHeaderRow, dataEndRow, 1, sheet.columnCount);
  }

  static void _addPaymentRegister(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final invoices = snapshot.invoices;
    sheet.addSection(
      'Payment Register',
      'Cash, UPI, card, bank, advance and due reconciliation',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date/Time', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Mobile', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Total', _ExcelStyle.tableHeader),
      _ExcelCell.text('Cash', _ExcelStyle.tableHeader),
      _ExcelCell.text('UPI', _ExcelStyle.tableHeader),
      _ExcelCell.text('Card', _ExcelStyle.tableHeader),
      _ExcelCell.text('Bank', _ExcelStyle.tableHeader),
      _ExcelCell.text('Advance', _ExcelStyle.tableHeader),
      _ExcelCell.text('Old Gold Adjustment', _ExcelStyle.tableHeader),
      _ExcelCell.text('Paid', _ExcelStyle.tableHeader),
      _ExcelCell.text('Due', _ExcelStyle.tableHeader),
      _ExcelCell.text('Payment Status', _ExcelStyle.tableHeader),
      _ExcelCell.text('Bill Status', _ExcelStyle.tableHeader),
    ]);
    final tableHeaderRow = sheet.currentRow;
    if (invoices.isEmpty) {
      sheet.addRow([
        _ExcelCell.text('No payment records found for this period'),
      ]);
      return;
    }
    for (var index = 0; index < invoices.length; index++) {
      final invoice = invoices[index];
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(invoice.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(invoice.billDate)),
        _ExcelCell.text(invoice.customerName),
        _ExcelCell.text(invoice.mobile),
        _ExcelCell.number(invoice.finalAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(invoice.cashAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.upiAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.cardAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.bankAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.advanceAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.tradeInDeduction, _ExcelStyle.money),
        _ExcelCell.number(invoice.paidAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(invoice.dueAmount, _ExcelStyle.totalMoney),
        _ExcelCell.text(invoice.paymentStatus),
        _ExcelCell.text(invoice.billStatus),
      ]);
    }
    final dataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('F', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('G', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('H', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('I', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('J', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('K', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('L', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('M', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('N', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
    ]);
    sheet.setAutoFilter(tableHeaderRow, dataEndRow, 1, sheet.columnCount);
  }

  static void _addCustomerSalesRegister(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final rows = _buildCustomerSalesRows(snapshot);
    sheet.addSection(
      'Customer Sales Register',
      'Customer-wise monthly sales, GST, receipts and outstanding balance',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Mobile', _ExcelStyle.tableHeader),
      _ExcelCell.text('GSTIN', _ExcelStyle.tableHeader),
      _ExcelCell.text('B2B/B2C', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoices', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gross Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('Discount', _ExcelStyle.tableHeader),
      _ExcelCell.text('Taxable', _ExcelStyle.tableHeader),
      _ExcelCell.text('GST', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Total', _ExcelStyle.tableHeader),
      _ExcelCell.text('Paid', _ExcelStyle.tableHeader),
      _ExcelCell.text('Due', _ExcelStyle.tableHeader),
      _ExcelCell.text('Advance', _ExcelStyle.tableHeader),
      _ExcelCell.text('Old Gold Adjustment', _ExcelStyle.tableHeader),
    ]);
    final tableHeaderRow = sheet.currentRow;
    if (rows.isEmpty) {
      sheet.addRow([
        _ExcelCell.text('No customer sales found for this period'),
      ]);
      return;
    }
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(row.customerName, _ExcelStyle.strong),
        _ExcelCell.text(row.mobile),
        _ExcelCell.text(row.gstin),
        _ExcelCell.text(row.businessType),
        _ExcelCell.number(row.invoiceCount, _ExcelStyle.integerStrong),
        _ExcelCell.number(row.grossAmount, _ExcelStyle.money),
        _ExcelCell.number(row.discountAmount, _ExcelStyle.money),
        _ExcelCell.number(row.taxableAmount, _ExcelStyle.money),
        _ExcelCell.number(row.gstAmount, _ExcelStyle.money),
        _ExcelCell.number(row.finalAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(row.paidAmount, _ExcelStyle.money),
        _ExcelCell.number(row.dueAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(row.advanceAmount, _ExcelStyle.money),
        _ExcelCell.number(row.tradeInDeduction, _ExcelStyle.money),
      ]);
    }
    final dataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('F', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.integerStrong,
      ),
      _ExcelCell.formula(
        _sumFormula('G', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('H', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('I', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('J', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('K', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('L', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('M', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('N', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('O', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
    ]);
    sheet.setAutoFilter(tableHeaderRow, dataEndRow, 1, sheet.columnCount);
  }

  static void _addAdvanceRegister(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final invoices = snapshot.invoices
        .where((invoice) => invoice.advanceAmount.abs() > 0.005)
        .toList(growable: false);
    sheet.addSection(
      'Advance Register',
      'Advance amount adjusted against sales invoices',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date/Time', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Mobile', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Total', _ExcelStyle.tableHeader),
      _ExcelCell.text('Advance Adjusted', _ExcelStyle.tableHeader),
      _ExcelCell.text('Cash', _ExcelStyle.tableHeader),
      _ExcelCell.text('UPI', _ExcelStyle.tableHeader),
      _ExcelCell.text('Card', _ExcelStyle.tableHeader),
      _ExcelCell.text('Bank', _ExcelStyle.tableHeader),
      _ExcelCell.text('Paid', _ExcelStyle.tableHeader),
      _ExcelCell.text('Due', _ExcelStyle.tableHeader),
      _ExcelCell.text('Payment Status', _ExcelStyle.tableHeader),
      _ExcelCell.text('Bill Status', _ExcelStyle.tableHeader),
    ]);
    final tableHeaderRow = sheet.currentRow;
    if (invoices.isEmpty) {
      sheet.addRow([
        _ExcelCell.text('No advance adjustments found for this period'),
      ]);
      return;
    }
    for (var index = 0; index < invoices.length; index++) {
      final invoice = invoices[index];
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(invoice.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(invoice.billDate)),
        _ExcelCell.text(invoice.customerName),
        _ExcelCell.text(invoice.mobile),
        _ExcelCell.number(invoice.finalAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(invoice.advanceAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(invoice.cashAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.upiAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.cardAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.bankAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.paidAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.dueAmount, _ExcelStyle.money),
        _ExcelCell.text(invoice.paymentStatus),
        _ExcelCell.text(invoice.billStatus),
      ]);
    }
    final dataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('F', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('G', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('H', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('I', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('J', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('K', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('L', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('M', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
    ]);
    sheet.setAutoFilter(tableHeaderRow, dataEndRow, 1, sheet.columnCount);
  }

  static void _addOldGoldAdjustmentRegister(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final invoices = snapshot.invoices
        .where((invoice) => invoice.tradeInDeduction.abs() > 0.005)
        .toList(growable: false);
    sheet.addSection(
      'Old Gold Adjustment Register',
      'Old gold value adjusted against sales invoices',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date/Time', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Mobile', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gross Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('Old Gold Adjustment', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Total', _ExcelStyle.tableHeader),
      _ExcelCell.text('Cash', _ExcelStyle.tableHeader),
      _ExcelCell.text('UPI', _ExcelStyle.tableHeader),
      _ExcelCell.text('Card', _ExcelStyle.tableHeader),
      _ExcelCell.text('Paid', _ExcelStyle.tableHeader),
      _ExcelCell.text('Due', _ExcelStyle.tableHeader),
      _ExcelCell.text('Bill Status', _ExcelStyle.tableHeader),
    ]);
    final tableHeaderRow = sheet.currentRow;
    if (invoices.isEmpty) {
      sheet.addRow([
        _ExcelCell.text('No old gold adjustments found for this period'),
      ]);
      return;
    }
    for (var index = 0; index < invoices.length; index++) {
      final invoice = invoices[index];
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(invoice.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(invoice.billDate)),
        _ExcelCell.text(invoice.customerName),
        _ExcelCell.text(invoice.mobile),
        _ExcelCell.number(invoice.grossAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.tradeInDeduction, _ExcelStyle.totalMoney),
        _ExcelCell.number(invoice.finalAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(invoice.cashAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.upiAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.cardAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.paidAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.dueAmount, _ExcelStyle.money),
        _ExcelCell.text(invoice.billStatus),
      ]);
    }
    final dataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('F', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('G', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('H', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('I', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('J', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('K', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('L', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('M', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.empty(),
    ]);
    sheet.setAutoFilter(tableHeaderRow, dataEndRow, 1, sheet.columnCount);
  }

  static void _addDueRegister(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final invoices = snapshot.invoices
        .where((invoice) => invoice.dueAmount.abs() > 0.005)
        .toList(growable: false);
    sheet.addSection(
      'Due Register',
      'Outstanding invoice balances for follow-up and customer account audit',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date/Time', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Mobile', _ExcelStyle.tableHeader),
      _ExcelCell.text('GSTIN', _ExcelStyle.tableHeader),
      _ExcelCell.text('B2B/B2C', _ExcelStyle.tableHeader),
      _ExcelCell.text('Place of Supply', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Total', _ExcelStyle.tableHeader),
      _ExcelCell.text('Advance', _ExcelStyle.tableHeader),
      _ExcelCell.text('Paid', _ExcelStyle.tableHeader),
      _ExcelCell.text('Due', _ExcelStyle.tableHeader),
      _ExcelCell.text('Cash', _ExcelStyle.tableHeader),
      _ExcelCell.text('UPI/Card/Bank', _ExcelStyle.tableHeader),
      _ExcelCell.text('Bill Status', _ExcelStyle.tableHeader),
    ]);
    final tableHeaderRow = sheet.currentRow;
    if (invoices.isEmpty) {
      sheet.addRow([
        _ExcelCell.text('No due invoices found for this period'),
      ]);
      return;
    }
    for (var index = 0; index < invoices.length; index++) {
      final invoice = invoices[index];
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(invoice.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(invoice.billDate)),
        _ExcelCell.text(invoice.customerName),
        _ExcelCell.text(invoice.mobile),
        _ExcelCell.text(invoice.customerGstin),
        _ExcelCell.text(invoice.businessType),
        _ExcelCell.text(invoice.placeOfSupply),
        _ExcelCell.number(invoice.finalAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(invoice.advanceAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.paidAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.dueAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(invoice.cashAmount, _ExcelStyle.money),
        _ExcelCell.number(
          invoice.upiAmount + invoice.cardAmount + invoice.bankAmount,
          _ExcelStyle.money,
        ),
        _ExcelCell.text(invoice.billStatus),
      ]);
    }
    final dataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('I', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('J', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('K', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('L', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('M', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('N', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.empty(),
    ]);
    sheet.setAutoFilter(tableHeaderRow, dataEndRow, 1, sheet.columnCount);
  }

  static void _addReturnCreditRegister(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final invoices = snapshot.invoices
        .where((invoice) => invoice.returnCreditNoteAmount.abs() > 0.005)
        .toList(growable: false);
    sheet.addSection(
      'Return Credit Register',
      'Return and credit note adjustments mapped against sales invoices',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date/Time', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Mobile', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Total', _ExcelStyle.tableHeader),
      _ExcelCell.text('Return/Credit Note', _ExcelStyle.tableHeader),
      _ExcelCell.text('Paid', _ExcelStyle.tableHeader),
      _ExcelCell.text('Due', _ExcelStyle.tableHeader),
      _ExcelCell.text('Payment Status', _ExcelStyle.tableHeader),
      _ExcelCell.text('Bill Status', _ExcelStyle.tableHeader),
    ]);
    final tableHeaderRow = sheet.currentRow;
    if (invoices.isEmpty) {
      sheet.addRow([
        _ExcelCell.text('No return/credit notes found for this period'),
      ]);
      return;
    }
    for (var index = 0; index < invoices.length; index++) {
      final invoice = invoices[index];
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(invoice.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(invoice.billDate)),
        _ExcelCell.text(invoice.customerName),
        _ExcelCell.text(invoice.mobile),
        _ExcelCell.number(invoice.finalAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(
          invoice.returnCreditNoteAmount,
          _ExcelStyle.totalMoney,
        ),
        _ExcelCell.number(invoice.paidAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.dueAmount, _ExcelStyle.money),
        _ExcelCell.text(invoice.paymentStatus),
        _ExcelCell.text(invoice.billStatus),
      ]);
    }
    final dataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('F', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('G', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('H', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('I', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
    ]);
    sheet.setAutoFilter(tableHeaderRow, dataEndRow, 1, sheet.columnCount);
  }

  static void _addMetalGradeRegister(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final rows = _buildMetalGradeRows(snapshot.items);
    sheet.addSection(
      'Metal Grade Register',
      'Purity and grade-wise item movement with weight and sales value',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Metal', _ExcelStyle.tableHeader),
      _ExcelCell.text('Grade/Purity', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoices', _ExcelStyle.tableHeader),
      _ExcelCell.text('Line Items', _ExcelStyle.tableHeader),
      _ExcelCell.text('Pcs', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gross Wt (g)', _ExcelStyle.tableHeader),
      _ExcelCell.text('Net Wt (g)', _ExcelStyle.tableHeader),
      _ExcelCell.text('Item Amount', _ExcelStyle.tableHeader),
      _ExcelCell.text('Making Charges', _ExcelStyle.tableHeader),
    ]);
    final tableHeaderRow = sheet.currentRow;
    if (rows.isEmpty) {
      sheet.addRow([
        _ExcelCell.text('No metal grade records found for this period'),
      ]);
      return;
    }
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(row.metalType),
        _ExcelCell.text(row.purity),
        _ExcelCell.number(row.invoiceCount, _ExcelStyle.integerStrong),
        _ExcelCell.number(row.lineItemCount, _ExcelStyle.integer),
        _ExcelCell.number(row.pieces, _ExcelStyle.integer),
        _ExcelCell.number(row.grossWeight, _ExcelStyle.weight),
        _ExcelCell.number(row.netWeight, _ExcelStyle.totalWeight),
        _ExcelCell.number(row.itemAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(row.makingAmount, _ExcelStyle.money),
      ]);
    }
    final dataEndRow = sheet.currentRow;
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.formula(
        _sumFormula('D', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.integerStrong,
      ),
      _ExcelCell.formula(
        _sumFormula('E', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.integerStrong,
      ),
      _ExcelCell.formula(
        _sumFormula('F', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.integerStrong,
      ),
      _ExcelCell.formula(
        _sumFormula('G', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.formula(
        _sumFormula('H', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.formula(
        _sumFormula('I', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.formula(
        _sumFormula('J', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalMoney,
      ),
    ]);
    sheet.setAutoFilter(tableHeaderRow, dataEndRow, 1, sheet.columnCount);
  }

  static _GstBreakup _gstBreakup(SalesReportInvoiceRow invoice) {
    final total = _roundMoney(invoice.gstAmount);
    if (total.abs() <= 0.005) {
      return const _GstBreakup(cgst: 0, sgst: 0, igst: 0);
    }
    final storedIgst = _roundMoney(invoice.igstAmount);
    if (storedIgst.abs() > 0.005) {
      return _GstBreakup(cgst: 0, sgst: 0, igst: total);
    }
    var cgst = _roundMoney(invoice.cgstAmount);
    var sgst = _roundMoney(invoice.sgstAmount);
    if (cgst.abs() <= 0.005 && sgst.abs() <= 0.005) {
      cgst = _roundMoney(total / 2);
    }
    sgst = _roundMoney(total - cgst);
    return _GstBreakup(
      cgst: cgst,
      sgst: sgst,
      igst: 0,
    );
  }

  static List<_HsnGstRow> _buildHsnGstRows(SalesReportSnapshot snapshot) {
    final invoicesById = {
      for (final invoice in snapshot.invoices) invoice.billId: invoice,
    };
    final accumulators = <String, _HsnGstAccumulator>{};
    for (final item in snapshot.items) {
      final invoice = invoicesById[item.billId];
      if (invoice == null || !invoice.isGst) continue;
      final hsn =
          item.hsnCode.trim().isEmpty ? 'UNMAPPED' : item.hsnCode.trim();
      final taxableBase = _taxableBaseFor(invoice);
      final ratio = _allocationRatio(
        scopedGross: item.itemTotal,
        invoiceGross: invoice.grossAmount,
      );
      final taxable = taxableBase * ratio;
      final split = _gstBreakup(invoice);
      final cgst = split.cgst * ratio;
      final sgst = split.sgst * ratio;
      final igst = split.igst * ratio;
      final gst = cgst + sgst + igst;
      final rate = taxable.abs() <= 0.005 ? 0.0 : (gst / taxable) * 100;
      final key = '$hsn|${rate.toStringAsFixed(2)}';
      final acc = accumulators.putIfAbsent(
        key,
        () => _HsnGstAccumulator(hsnCode: hsn, gstRate: rate),
      );
      acc.invoiceIds.add(invoice.billId);
      acc.lineItemCount++;
      acc.pieces += item.quantity;
      acc.taxableAmount += taxable;
      acc.cgstAmount += cgst;
      acc.sgstAmount += sgst;
      acc.igstAmount += igst;
      acc.gstAmount += gst;
      acc.invoiceAmount += taxable + gst + (invoice.roundOffAmount * ratio);
    }
    final rows = accumulators.values.map((acc) => acc.toRow()).toList()
      ..sort((a, b) {
        final hsnCompare = a.hsnCode.compareTo(b.hsnCode);
        if (hsnCompare != 0) return hsnCompare;
        return a.gstRate.compareTo(b.gstRate);
      });
    return rows;
  }

  static double _taxableBaseFor(SalesReportInvoiceRow invoice) {
    if (invoice.taxableAmount > 0.005) return invoice.taxableAmount;
    final discountedGross = invoice.grossAmount - invoice.discountAmount;
    if (discountedGross > 0.005) return discountedGross;
    if (invoice.gstAmount <= 0.005) return invoice.finalAmount;
    return invoice.grossAmount;
  }

  static double _allocationRatio({
    required double scopedGross,
    required double invoiceGross,
  }) {
    if (scopedGross <= 0.005) return 0;
    if (invoiceGross.abs() <= 0.005) return 1;
    return scopedGross / invoiceGross;
  }

  static List<_CustomerSalesRow> _buildCustomerSalesRows(
    SalesReportSnapshot snapshot,
  ) {
    final accumulators = <String, _CustomerSalesAccumulator>{};
    for (final invoice in snapshot.invoices) {
      final normalizedName = invoice.customerName.trim().toUpperCase();
      final normalizedMobile = invoice.mobile.trim();
      final key = '$normalizedName|$normalizedMobile';
      final acc = accumulators.putIfAbsent(
        key,
        () => _CustomerSalesAccumulator(
          customerName: invoice.customerName.trim().isEmpty
              ? 'Walk-in Customer'
              : invoice.customerName.trim(),
          mobile: invoice.mobile,
        ),
      );
      acc.invoiceIds.add(invoice.billId);
      acc.businessTypes.add(invoice.businessType);
      acc.gstins.add(invoice.customerGstin);
      acc.grossAmount += invoice.grossAmount;
      acc.discountAmount += invoice.discountAmount;
      acc.taxableAmount += invoice.taxableAmount;
      acc.gstAmount += invoice.gstAmount;
      acc.finalAmount += invoice.finalAmount;
      acc.paidAmount += invoice.paidAmount;
      acc.dueAmount += invoice.dueAmount;
      acc.advanceAmount += invoice.advanceAmount;
      acc.tradeInDeduction += invoice.tradeInDeduction;
    }
    final rows = accumulators.values.map((acc) => acc.toRow()).toList()
      ..sort((a, b) {
        final amountCompare = b.finalAmount.compareTo(a.finalAmount);
        if (amountCompare != 0) return amountCompare;
        return a.customerName.compareTo(b.customerName);
      });
    return rows;
  }

  static List<_MetalGradeRow> _buildMetalGradeRows(
    List<SalesReportItemRow> items,
  ) {
    final accumulators = <String, _MetalGradeAccumulator>{};
    for (final item in items) {
      final metal = item.metalType.trim().isEmpty ? 'Unmapped' : item.metalType;
      final purity = item.purity.trim().isEmpty ? 'Unmapped' : item.purity;
      final key = '${metal.toUpperCase()}|${purity.toUpperCase()}';
      final acc = accumulators.putIfAbsent(
        key,
        () => _MetalGradeAccumulator(metalType: metal, purity: purity),
      );
      acc.invoiceIds.add(item.billId);
      acc.lineItemCount++;
      acc.pieces += item.quantity;
      acc.grossWeight += item.grossWeight;
      acc.netWeight += item.netWeight;
      acc.itemAmount += item.itemTotal;
      acc.makingAmount += item.makingCharge;
    }
    final rows = accumulators.values.map((acc) => acc.toRow()).toList()
      ..sort((a, b) {
        final metalCompare = a.metalType.compareTo(b.metalType);
        if (metalCompare != 0) return metalCompare;
        return a.purity.compareTo(b.purity);
      });
    return rows;
  }

  static String _sumFormula(String column, int startRow, int endRow) {
    if (endRow < startRow) return '0';
    return 'SUM($column$startRow:$column$endRow)';
  }

  static double _roundMoney(double value) => (value * 100).round() / 100;

  static Uint8List _buildWorkbook(Map<String, String> worksheets) {
    final entries = worksheets.entries.toList(growable: false);
    final archive = Archive()
      ..addFile(
        _archiveFile('[Content_Types].xml', _contentTypesXml(entries.length)),
      )
      ..addFile(_archiveFile('_rels/.rels', _rootRelsXml))
      ..addFile(_archiveFile('docProps/app.xml', _appXml))
      ..addFile(_archiveFile('docProps/core.xml', _coreXml))
      ..addFile(
        _archiveFile(
          'xl/workbook.xml',
          _workbookXml(entries.map((entry) => entry.key).toList()),
        ),
      )
      ..addFile(
        _archiveFile(
          'xl/_rels/workbook.xml.rels',
          _workbookRelsXml(entries.length),
        ),
      )
      ..addFile(_archiveFile('xl/styles.xml', _stylesXml));

    for (var index = 0; index < entries.length; index++) {
      archive.addFile(
        _archiveFile(
          'xl/worksheets/sheet${index + 1}.xml',
          entries[index].value,
        ),
      );
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static ArchiveFile _archiveFile(String name, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(name, bytes.length, bytes);
  }
}
