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
      ...SalesReportExportFormatters.salesSummaryRows(snapshot.summary),
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
    final weightsByBill = SalesReportExportFormatters.invoiceWeights(items);
    return [
      ['INVOICE LEDGER'],
      [
        'S.No',
        'Invoice No',
        'Date',
        'Customer',
        'Mobile',
        'Type',
        'Metals',
        'Metal Net Weight',
        'Gross',
        'Discount',
        'Taxable',
        'GST',
        'Round Off',
        'Final',
      ],
      for (var index = 0; index < invoices.length; index++)
        _invoiceRow(index + 1, invoices[index], weightsByBill),
      _invoiceTotalRow(invoices, items),
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
    ];
  }

  static List<String> _invoiceRow(
    int serialNo,
    SalesReportInvoiceRow invoice,
    Map<int, Map<String, double>> weightsByBill,
  ) {
    final weights = weightsByBill[invoice.billId] ?? const {};
    return [
      '$serialNo',
      invoice.billNo,
      SalesReportExportFormatters.dateTime(invoice.billDate),
      invoice.customerName,
      invoice.mobile,
      invoice.isGst ? 'GST' : 'NON-GST',
      invoice.metalMix,
      SalesReportExportFormatters.weightSummary(weights),
      SalesReportExportFormatters.money(invoice.grossAmount),
      SalesReportExportFormatters.money(invoice.discountAmount),
      SalesReportExportFormatters.money(invoice.taxableAmount),
      SalesReportExportFormatters.money(invoice.gstAmount),
      SalesReportExportFormatters.money(invoice.roundOffAmount),
      SalesReportExportFormatters.money(invoice.finalAmount),
    ];
  }

  static List<String> _invoiceTotalRow(
    List<SalesReportInvoiceRow> invoices,
    List<SalesReportItemRow> items,
  ) {
    return [
      'TOTAL',
      '',
      '',
      '',
      '',
      '',
      '',
      SalesReportExportFormatters.invoiceWeightTotal(items),
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
        invoices.fold(0, (sum, row) => sum + row.gstAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.roundOffAmount),
      ),
      SalesReportExportFormatters.money(
        invoices.fold(0, (sum, row) => sum + row.finalAmount),
      ),
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

  static String _csvRow(List<String> row) {
    return row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',');
  }
}
