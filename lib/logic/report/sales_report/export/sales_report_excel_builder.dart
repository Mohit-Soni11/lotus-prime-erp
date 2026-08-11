import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../../models/reports/sales_report/sales_report_models.dart';
import 'sales_report_export_formatters.dart';

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
        28,
        16,
        14,
        14,
        15,
        15,
        15,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
        16,
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
      columnWidths: const [8, 24, 22, 28, 15, 17, 17, 17, 17],
    );
    _addReportHeader(gstSheet, snapshot, identity, 'GST Register');
    _addGstRegister(gstSheet, snapshot);

    return _buildWorkbook({
      'Sales Summary': summarySheet.toXml(),
      'Invoice Register': invoiceSheet.toXml(),
      'Item Register': itemSheet.toXml(),
      'GST Register': gstSheet.toXml(),
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
      _ExcelCell.text('Non-GST Bills', _ExcelStyle.tableHeader),
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
      'GST Summary',
      'Recorded GST is payable from GST invoices; non-GST estimate is shown separately',
    );
    sheet.addRow([
      _ExcelCell.text('Recorded GST Bills', _ExcelStyle.tableHeader),
      _ExcelCell.text('Recorded Taxable', _ExcelStyle.tableHeader),
      _ExcelCell.text('Recorded GST', _ExcelStyle.tableHeader),
      _ExcelCell.text('Recorded Invoice Total', _ExcelStyle.tableHeader),
      _ExcelCell.text('Non-GST Bills', _ExcelStyle.tableHeader),
      _ExcelCell.text('Non-GST Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('Optional GST Estimate', _ExcelStyle.tableHeader),
    ]);
    sheet.addRow([
      _ExcelCell.number(gst.gstInvoiceCount, _ExcelStyle.integerStrong),
      _ExcelCell.number(gst.gstTaxableAmount, _ExcelStyle.moneyStrong),
      _ExcelCell.number(gst.recordedGstAmount, _ExcelStyle.totalMoney),
      _ExcelCell.number(gst.gstFinalAmount, _ExcelStyle.moneyStrong),
      _ExcelCell.number(gst.nonGstInvoiceCount, _ExcelStyle.integerStrong),
      _ExcelCell.number(gst.nonGstSalesAmount, _ExcelStyle.moneyStrong),
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
      _ExcelCell.text('Bills', _ExcelStyle.tableHeader),
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
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.number(
        snapshot.metals.fold(0, (sum, metal) => sum + metal.invoiceCount),
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
    final weightsByBill =
        SalesReportExportFormatters.invoiceWeights(snapshot.items);
    sheet.addSection(
      'Invoice Register',
      'Every sales bill with metal weight, tax and due amount',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Mobile', _ExcelStyle.tableHeader),
      _ExcelCell.text('Type', _ExcelStyle.tableHeader),
      _ExcelCell.text('Status', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gold Net Wt (g)', _ExcelStyle.tableHeader),
      _ExcelCell.text('Silver Net Wt (g)', _ExcelStyle.tableHeader),
      _ExcelCell.text('Other Net Wt (g)', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gross Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('Discount', _ExcelStyle.tableHeader),
      _ExcelCell.text('Taxable Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('Output GST', _ExcelStyle.tableHeader),
      _ExcelCell.text('Round Off', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Total', _ExcelStyle.tableHeader),
      _ExcelCell.text('Received', _ExcelStyle.tableHeader),
      _ExcelCell.text('Due', _ExcelStyle.tableHeader),
    ]);
    final tableHeaderRow = sheet.currentRow;
    for (var index = 0; index < snapshot.invoices.length; index++) {
      final invoice = snapshot.invoices[index];
      final weights = weightsByBill[invoice.billId] ?? const <String, double>{};
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(invoice.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(invoice.billDate)),
        _ExcelCell.text(invoice.customerName),
        _ExcelCell.text(invoice.mobile),
        _ExcelCell.text(invoice.isGst ? 'GST' : 'NON-GST'),
        _ExcelCell.text(invoice.paymentStatus),
        _ExcelCell.number(_metalWeight(weights, 'gold'), _ExcelStyle.weight),
        _ExcelCell.number(_metalWeight(weights, 'silver'), _ExcelStyle.weight),
        _ExcelCell.number(_otherMetalWeight(weights), _ExcelStyle.weight),
        _ExcelCell.number(invoice.grossAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.discountAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.taxableAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.gstAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.roundOffAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.finalAmount, _ExcelStyle.totalMoney),
        _ExcelCell.number(invoice.paidAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.dueAmount, _ExcelStyle.money),
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
      _ExcelCell.formula(
        _sumFormula('H', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.formula(
        _sumFormula('I', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.formula(
        _sumFormula('J', tableHeaderRow + 1, dataEndRow),
        _ExcelStyle.totalWeight,
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
        _ExcelCell.text(item.isGst ? 'GST' : 'NON-GST'),
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
      _ExcelCell.text('Total GST', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice Total', _ExcelStyle.tableHeader),
    ]);
    final recordedHeaderRow = sheet.currentRow;
    for (var index = 0; index < gstInvoices.length; index++) {
      final invoice = gstInvoices[index];
      final cgst = _roundMoney(invoice.gstAmount / 2);
      final sgst = _roundMoney(invoice.gstAmount - cgst);
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(invoice.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(invoice.billDate)),
        _ExcelCell.text(invoice.customerName),
        _ExcelCell.number(invoice.taxableAmount, _ExcelStyle.money),
        _ExcelCell.number(cgst, _ExcelStyle.money),
        _ExcelCell.number(sgst, _ExcelStyle.money),
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
    ]);
    sheet.addBlankRow();

    final nonGstInvoices =
        snapshot.invoices.where((invoice) => !invoice.isGst).toList();
    sheet.addSection(
      'Non-GST Sales Estimate',
      'Reference only - not recorded as GST payable unless you decide to declare it',
    );
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Non-GST Sales', _ExcelStyle.tableHeader),
      _ExcelCell.text('Estimated GST 3%', _ExcelStyle.tableHeader),
      _ExcelCell.text('Estimated Total', _ExcelStyle.tableHeader),
    ]);
    final estimateHeaderRow = sheet.currentRow;
    for (var index = 0; index < nonGstInvoices.length; index++) {
      final invoice = nonGstInvoices[index];
      final estimatedGst = _roundMoney(invoice.taxableAmount * 0.03);
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

  static double _metalWeight(Map<String, double> weights, String metalName) {
    return weights.entries
        .where((entry) => entry.key.toLowerCase() == metalName)
        .fold<double>(0, (total, entry) => total + entry.value);
  }

  static double _otherMetalWeight(Map<String, double> weights) {
    return weights.entries.where((entry) {
      final metal = entry.key.toLowerCase();
      return metal != 'gold' && metal != 'silver';
    }).fold<double>(0, (total, entry) => total + entry.value);
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

enum _ExcelStyle {
  normal,
  title,
  subtitle,
  muted,
  sectionLabel,
  sectionValue,
  tableHeader,
  strong,
  money,
  moneyStrong,
  weight,
  integer,
  integerStrong,
  totalText,
  totalMoney,
  totalWeight,
}

class _ExcelCell {
  final Object? value;
  final _ExcelStyle style;
  final bool isNumber;
  final bool isFormula;

  const _ExcelCell._(
    this.value,
    this.style,
    this.isNumber, {
    this.isFormula = false,
  });

  factory _ExcelCell.text(
    String value, [
    _ExcelStyle style = _ExcelStyle.normal,
  ]) =>
      _ExcelCell._(value, style, false);

  factory _ExcelCell.number(
    num value, [
    _ExcelStyle style = _ExcelStyle.normal,
  ]) =>
      _ExcelCell._(value, style, true);

  factory _ExcelCell.formula(
    String formula, [
    _ExcelStyle style = _ExcelStyle.normal,
  ]) =>
      _ExcelCell._(formula, style, true, isFormula: true);

  factory _ExcelCell.empty() =>
      const _ExcelCell._('', _ExcelStyle.normal, false);
}

class _WorksheetBuilder {
  final List<double> columnWidths;
  final List<String> _rows = [];
  final List<String> _merges = [];
  String? _autoFilterRef;
  int _rowIndex = 0;

  _WorksheetBuilder({required this.columnWidths});

  int get columnCount => columnWidths.length;

  int get currentRow => _rowIndex;

  void addMergedText(
    String value,
    int startColumn,
    int endColumn,
    _ExcelStyle style,
  ) {
    _rowIndex++;
    _rows.add(
      '<row r="$_rowIndex">${_cell(startColumn, _rowIndex, _ExcelCell.text(value, style))}</row>',
    );
    _merges.add(
      '${_columnName(startColumn)}$_rowIndex:${_columnName(endColumn)}$_rowIndex',
    );
  }

  void addSection(String title, String subtitle) {
    _rowIndex++;
    _rows.add(
      '<row r="$_rowIndex">${_cell(1, _rowIndex, _ExcelCell.text(title, _ExcelStyle.sectionLabel))}${_cell(2, _rowIndex, _ExcelCell.text(subtitle, _ExcelStyle.sectionValue))}</row>',
    );
    _merges.add('B$_rowIndex:${_columnName(columnCount)}$_rowIndex');
  }

  void addRow(List<_ExcelCell> cells) {
    _rowIndex++;
    final buffer = StringBuffer('<row r="$_rowIndex">');
    for (var index = 0; index < cells.length; index++) {
      buffer.write(_cell(index + 1, _rowIndex, cells[index]));
    }
    buffer.write('</row>');
    _rows.add(buffer.toString());
  }

  void addBlankRow() {
    _rowIndex++;
    _rows.add('<row r="$_rowIndex"/>');
  }

  void setAutoFilter(
    int startRow,
    int endRow,
    int startColumn,
    int endColumn,
  ) {
    if (endRow <= startRow) return;
    _autoFilterRef =
        '${_columnName(startColumn)}$startRow:${_columnName(endColumn)}$endRow';
  }

  String toXml() {
    final columns = [
      for (var index = 0; index < columnWidths.length; index++)
        '<col min="${index + 1}" max="${index + 1}" width="${columnWidths[index]}" customWidth="1"/>',
    ].join();
    final mergeXml = _merges.isEmpty
        ? ''
        : '<mergeCells count="${_merges.length}">${_merges.map((ref) => '<mergeCell ref="$ref"/>').join()}</mergeCells>';
    final dimension = 'A1:${_columnName(columnCount)}$_rowIndex';
    final autoFilterXml =
        _autoFilterRef == null ? '' : '<autoFilter ref="$_autoFilterRef"/>';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<dimension ref="$dimension"/>
<sheetViews><sheetView workbookViewId="0"><pane ySplit="10" topLeftCell="A11" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>
<cols>$columns</cols>
<sheetData>${_rows.join()}</sheetData>
$autoFilterXml
$mergeXml
<pageMargins left="0.3" right="0.3" top="0.5" bottom="0.5" header="0.2" footer="0.2"/>
</worksheet>''';
  }

  String _cell(int column, int row, _ExcelCell cell) {
    final ref = '${_columnName(column)}$row';
    final styleId = _styleId(cell.style);
    if (cell.isFormula) {
      final formula = _escape(cell.value?.toString() ?? '0');
      return '<c r="$ref" s="$styleId"><f>$formula</f><v>0</v></c>';
    }
    if (cell.isNumber) {
      return '<c r="$ref" s="$styleId"><v>${_numberValue(cell.value, cell.style)}</v></c>';
    }
    final text = _escape(cell.value?.toString() ?? '');
    return '<c r="$ref" s="$styleId" t="inlineStr"><is><t>$text</t></is></c>';
  }

  int _styleId(_ExcelStyle style) {
    switch (style) {
      case _ExcelStyle.normal:
        return 0;
      case _ExcelStyle.title:
        return 1;
      case _ExcelStyle.subtitle:
        return 2;
      case _ExcelStyle.muted:
        return 3;
      case _ExcelStyle.sectionLabel:
        return 4;
      case _ExcelStyle.sectionValue:
        return 5;
      case _ExcelStyle.tableHeader:
        return 6;
      case _ExcelStyle.strong:
        return 7;
      case _ExcelStyle.money:
        return 8;
      case _ExcelStyle.moneyStrong:
        return 12;
      case _ExcelStyle.weight:
        return 9;
      case _ExcelStyle.integer:
        return 10;
      case _ExcelStyle.integerStrong:
        return 11;
      case _ExcelStyle.totalText:
        return 11;
      case _ExcelStyle.totalMoney:
        return 12;
      case _ExcelStyle.totalWeight:
        return 13;
    }
  }
}

String _columnName(int index) {
  var value = index;
  final chars = <String>[];
  while (value > 0) {
    value--;
    chars.insert(0, String.fromCharCode(65 + (value % 26)));
    value ~/= 26;
  }
  return chars.join();
}

String _numberValue(Object? value, _ExcelStyle style) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (number == null) return '0';
  switch (style) {
    case _ExcelStyle.weight:
    case _ExcelStyle.totalWeight:
      return number.toStringAsFixed(3);
    case _ExcelStyle.money:
    case _ExcelStyle.moneyStrong:
    case _ExcelStyle.totalMoney:
      return number.toStringAsFixed(2);
    case _ExcelStyle.integer:
    case _ExcelStyle.integerStrong:
      return number.round().toString();
    case _ExcelStyle.normal:
    case _ExcelStyle.title:
    case _ExcelStyle.subtitle:
    case _ExcelStyle.muted:
    case _ExcelStyle.sectionLabel:
    case _ExcelStyle.sectionValue:
    case _ExcelStyle.tableHeader:
    case _ExcelStyle.strong:
    case _ExcelStyle.totalText:
      return number.toString();
  }
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String _contentTypesXml(int sheetCount) {
  final sheetOverrides = [
    for (var index = 1; index <= sheetCount; index++)
      '<Override PartName="/xl/worksheets/sheet$index.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
  ].join();
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
$sheetOverrides
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''';
}

const _rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';

String _workbookRelsXml(int sheetCount) {
  final sheetRelationships = [
    for (var index = 1; index <= sheetCount; index++)
      '<Relationship Id="rId$index" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$index.xml"/>',
  ].join();
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
$sheetRelationships
<Relationship Id="rId${sheetCount + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
}

String _workbookXml(List<String> sheetNames) {
  final sheets = [
    for (var index = 0; index < sheetNames.length; index++)
      '<sheet name="${_escape(sheetNames[index])}" sheetId="${index + 1}" r:id="rId${index + 1}"/>',
  ].join();
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets>$sheets</sheets>
</workbook>''';
}

const _appXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
<Application>Lotus ERP</Application>
</Properties>''';

const _coreXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<dc:title>Sales Report</dc:title>
<dc:creator>Lotus ERP</dc:creator>
</cp:coreProperties>''';

const _stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<numFmts count="2">
<numFmt numFmtId="164" formatCode="&quot;Rs&quot; #,##0.00"/>
<numFmt numFmtId="165" formatCode="0.000"/>
</numFmts>
<fonts count="5">
<font><sz val="11"/><color rgb="FF000000"/><name val="Calibri"/></font>
<font><b/><sz val="18"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
<font><b/><sz val="14"/><color rgb="FF000000"/><name val="Calibri"/></font>
<font><sz val="11"/><color rgb="FF000000"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><color rgb="FF000000"/><name val="Calibri"/></font>
</fonts>
<fills count="5">
<fill><patternFill patternType="none"/></fill>
<fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF111827"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFF8E7B1"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFFFFFF"/><bgColor indexed="64"/></patternFill></fill>
</fills>
<borders count="2">
<border><left/><right/><top/><bottom/><diagonal/></border>
<border><left style="thin"><color rgb="FF000000"/></left><right style="thin"><color rgb="FF000000"/></right><top style="thin"><color rgb="FF000000"/></top><bottom style="thin"><color rgb="FF000000"/></bottom><diagonal/></border>
</borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="14">
<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1"/>
<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="2" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyFont="1"/>
<xf numFmtId="0" fontId="4" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="0" fillId="4" borderId="1" xfId="0" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="4" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="4" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1"/>
<xf numFmtId="164" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1"/>
<xf numFmtId="165" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1"/>
<xf numFmtId="3" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1"/>
<xf numFmtId="0" fontId="4" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="164" fontId="4" fillId="4" borderId="1" xfId="0" applyFont="1" applyNumberFormat="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="165" fontId="4" fillId="4" borderId="1" xfId="0" applyFont="1" applyNumberFormat="1" applyFill="1" applyBorder="1"/>
</cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''';
