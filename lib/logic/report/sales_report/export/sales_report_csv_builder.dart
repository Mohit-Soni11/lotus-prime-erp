import '../../../../models/reports/sales_report/sales_report_models.dart';
import 'sales_report_export_formatters.dart';

class SalesReportCsvBuilder {
  SalesReportCsvBuilder._();

  static String buildComplete(SalesReportSnapshot snapshot) {
    final rows = <List<String>>[
      ['SALES REPORT'],
      ['Period', SalesReportExportFormatters.periodLabel(snapshot.filter)],
      ['From', SalesReportExportFormatters.date(snapshot.filter.startDate)],
      ['To', SalesReportExportFormatters.date(snapshot.filter.endDate)],
      [
        'Tax View',
        SalesReportExportFormatters.taxModeLabel(snapshot.filter.taxMode),
      ],
      ['Metal Filter', snapshot.filter.metalType],
      [],
      ['SALES SUMMARY'],
      ...SalesReportExportFormatters.salesSummaryRowsWithMetalBreakdown(
        snapshot,
      ),
      [],
      ['GST LIABILITY'],
      ...SalesReportExportFormatters.gstLiabilityRows(snapshot.gstLiability),
      [],
      ['METAL SALES SUMMARY'],
      [
        'Metal',
        'Invoices',
        'Items',
        'Pcs',
        'Gross Weight',
        'Net Weight',
        'Making',
        'Sales',
      ],
      ...SalesReportExportFormatters.metalRows(snapshot.metals),
      [
        'Total Net Weight',
        SalesReportExportFormatters.totalNetWeightWithBreakdown(
          snapshot.items,
        ),
      ],
      [],
      ...invoiceLedgerRows(snapshot.invoices, snapshot.items),
      [],
      ...itemLedgerRows(snapshot.items),
    ];

    return rows.map(_csvRow).join('\r\n');
  }

  static String buildMetalComplete(
    SalesReportSnapshot snapshot, {
    required String metalTitle,
  }) {
    final rows = <List<String>>[
      ['METAL SALES REPORT'],
      ['Metal', metalTitle],
      ['Period', SalesReportExportFormatters.periodLabel(snapshot.filter)],
      ['From', SalesReportExportFormatters.date(snapshot.filter.startDate)],
      ['To', SalesReportExportFormatters.date(snapshot.filter.endDate)],
      [
        'Tax View',
        SalesReportExportFormatters.taxModeLabel(snapshot.filter.taxMode),
      ],
      [],
      ['METAL SALES LEDGER'],
      ['Metric', 'Value'],
      ['Invoices', '${snapshot.summary.invoiceCount}'],
      ['GST Invoices', '${snapshot.summary.gstInvoiceCount}'],
      ['Non-GST Invoices', '${snapshot.summary.nonGstInvoiceCount}'],
      [
        'Pieces',
        '${snapshot.metals.fold(0, (sum, metal) => sum + metal.pieces)}'
      ],
      [
        'Gross Weight',
        SalesReportExportFormatters.weight(
            snapshot.metals.fold(0, (sum, metal) => sum + metal.grossWeight))
      ],
      [
        'Net Weight',
        SalesReportExportFormatters.totalNetWeightWithBreakdown(snapshot.items)
      ],
      [
        'Making',
        SalesReportExportFormatters.money(snapshot.summary.makingAmount)
      ],
      [
        'Sales Value',
        SalesReportExportFormatters.money(snapshot.summary.grossAmount)
      ],
      [
        'Taxable',
        SalesReportExportFormatters.money(snapshot.summary.taxableAmount)
      ],
      ['GST', SalesReportExportFormatters.money(snapshot.summary.gstAmount)],
      [
        'Final Amount',
        SalesReportExportFormatters.money(snapshot.summary.finalAmount)
      ],
      [],
      ['GRADE-WISE SALES'],
      [
        'Grade',
        'Invoices',
        'Items',
        'Pcs',
        'Gross Weight',
        'Net Weight',
        'Making',
        'Sales',
      ],
      ...SalesReportExportFormatters.gradeRows(snapshot.items),
      [],
      ...invoiceLedgerRows(snapshot.invoices, snapshot.items),
      [],
      ...itemLedgerRows(snapshot.items),
    ];

    return rows.map(_csvRow).join('\r\n');
  }

  static String buildInvoiceLedger(
    List<SalesReportInvoiceRow> invoices,
    List<SalesReportItemRow> items,
  ) {
    return invoiceLedgerRows(invoices, items).map(_csvRow).join('\r\n');
  }

  static String buildItemLedger(List<SalesReportItemRow> items) {
    return itemLedgerRows(items).map(_csvRow).join('\r\n');
  }

  static List<List<String>> invoiceLedgerRows(
    List<SalesReportInvoiceRow> invoices,
    List<SalesReportItemRow> items,
  ) {
    return [
      ['INVOICE LEDGER'],
      [
        'S.No',
        'Invoice No',
        'Date/Time',
        'Status',
        'Customer',
        'Mobile',
        'GSTIN',
        'B2B/B2C',
        'Place of Supply',
        'Gross Sales',
        'Discount',
        'Taxable',
        'CGST',
        'SGST',
        'IGST',
        'Round Off',
        'Invoice Total',
        'Advance',
        'Old Gold Adjustment',
        'Cash',
        'UPI',
        'Card',
        'Bank',
        'Paid',
        'Due',
        'Return/Credit Note',
        'Bill Status',
      ],
      for (var index = 0; index < invoices.length; index++)
        _invoiceRow(index + 1, invoices[index]),
      _invoiceTotalRow(invoices),
    ];
  }

  static List<List<String>> itemLedgerRows(List<SalesReportItemRow> items) {
    return [
      ['ITEM LEDGER'],
      [
        'S.No',
        'Invoice No',
        'Date',
        'Customer',
        'Type',
        'Metal',
        'Item',
        'HUID',
        'Purity',
        'Pcs',
        'Gross Weight',
        'Less Weight',
        'Net Weight',
        'Fine Weight',
        'Rate',
        'Making',
        'Item Total',
      ],
      for (var index = 0; index < items.length; index++)
        _itemRow(index + 1, items[index]),
      _itemTotalRow(items),
      _itemWeightBreakdownRow(items),
    ];
  }

  static List<String> _invoiceRow(
    int serialNo,
    SalesReportInvoiceRow invoice,
  ) {
    final split = _gstBreakup(invoice);
    return [
      '$serialNo',
      invoice.billNo,
      SalesReportExportFormatters.dateTime(invoice.billDate),
      invoice.paymentStatus,
      invoice.customerName,
      invoice.mobile,
      invoice.customerGstin,
      invoice.businessType,
      invoice.placeOfSupply,
      SalesReportExportFormatters.money(invoice.grossAmount),
      SalesReportExportFormatters.money(invoice.discountAmount),
      SalesReportExportFormatters.money(invoice.taxableAmount),
      SalesReportExportFormatters.money(split.cgst),
      SalesReportExportFormatters.money(split.sgst),
      SalesReportExportFormatters.money(split.igst),
      SalesReportExportFormatters.money(invoice.roundOffAmount),
      SalesReportExportFormatters.money(invoice.finalAmount),
      SalesReportExportFormatters.money(invoice.advanceAmount),
      SalesReportExportFormatters.money(invoice.tradeInDeduction),
      SalesReportExportFormatters.money(invoice.cashAmount),
      SalesReportExportFormatters.money(invoice.upiAmount),
      SalesReportExportFormatters.money(invoice.cardAmount),
      SalesReportExportFormatters.money(invoice.bankAmount),
      SalesReportExportFormatters.money(invoice.paidAmount),
      SalesReportExportFormatters.money(invoice.dueAmount),
      SalesReportExportFormatters.money(invoice.returnCreditNoteAmount),
      invoice.billStatus,
    ];
  }

  static List<String> _invoiceTotalRow(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      'TOTAL',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.grossAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.discountAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.taxableAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + _gstBreakup(row).cgst),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + _gstBreakup(row).sgst),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + _gstBreakup(row).igst),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.roundOffAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.finalAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.advanceAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.tradeInDeduction),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.cashAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.upiAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.cardAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.bankAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.paidAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.dueAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.returnCreditNoteAmount),
      ),
      '',
    ];
  }

  static List<String> _itemRow(int serialNo, SalesReportItemRow item) {
    return [
      '$serialNo',
      item.billNo,
      SalesReportExportFormatters.dateTime(item.billDate),
      item.customerName,
      item.isGst ? 'GST' : 'NON-GST',
      item.metalType,
      item.itemName,
      item.huid.isEmpty ? 'Not linked' : item.huid,
      item.purity,
      '${item.quantity}',
      SalesReportExportFormatters.weight(item.grossWeight),
      SalesReportExportFormatters.weight(item.lessWeight),
      SalesReportExportFormatters.weight(item.netWeight),
      SalesReportExportFormatters.weight(item.fineWeight),
      SalesReportExportFormatters.money(item.rate),
      SalesReportExportFormatters.money(item.makingCharge),
      SalesReportExportFormatters.money(item.itemTotal),
    ];
  }

  static List<String> _itemTotalRow(List<SalesReportItemRow> items) {
    return [
      'TOTAL',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '${items.fold(0, (sum, item) => sum + item.quantity)}',
      SalesReportExportFormatters.weight(
        items.fold(0, (sum, item) => sum + item.grossWeight),
      ),
      SalesReportExportFormatters.weight(
        items.fold(0, (sum, item) => sum + item.lessWeight),
      ),
      SalesReportExportFormatters.weight(
        items.fold(0, (sum, item) => sum + item.netWeight),
      ),
      SalesReportExportFormatters.weight(
        items.fold(0, (sum, item) => sum + item.fineWeight),
      ),
      '',
      SalesReportExportFormatters.money(
        items.fold(0, (sum, item) => sum + item.makingCharge),
      ),
      SalesReportExportFormatters.money(
        items.fold(0, (sum, item) => sum + item.itemTotal),
      ),
    ];
  }

  static List<String> _itemWeightBreakdownRow(List<SalesReportItemRow> items) {
    return [
      'NET WEIGHT BY METAL',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      SalesReportExportFormatters.invoiceWeightTotal(items),
      '',
      '',
      '',
      '',
    ];
  }

  static String _csvRow(List<String> row) {
    return row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',');
  }

  static _CsvGstBreakup _gstBreakup(SalesReportInvoiceRow invoice) {
    final total = _roundMoney(invoice.gstAmount);
    if (total.abs() <= 0.005) {
      return const _CsvGstBreakup(cgst: 0, sgst: 0, igst: 0);
    }
    final storedIgst = _roundMoney(invoice.igstAmount);
    if (storedIgst.abs() > 0.005) {
      return _CsvGstBreakup(cgst: 0, sgst: 0, igst: total);
    }
    var cgst = _roundMoney(invoice.cgstAmount);
    var sgst = _roundMoney(invoice.sgstAmount);
    if (cgst.abs() <= 0.005 && sgst.abs() <= 0.005) {
      cgst = _roundMoney(total / 2);
    }
    sgst = _roundMoney(total - cgst);
    return _CsvGstBreakup(
      cgst: cgst,
      sgst: sgst,
      igst: 0,
    );
  }

  static double _roundMoney(double value) => (value * 100).round() / 100;
}

class _CsvGstBreakup {
  final double cgst;
  final double sgst;
  final double igst;

  const _CsvGstBreakup({
    required this.cgst,
    required this.sgst,
    required this.igst,
  });
}
