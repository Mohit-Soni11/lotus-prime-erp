import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';

class GstReportCsvBuilder {
  GstReportCsvBuilder._();

  static String buildComplete(GstReportSnapshot snapshot) {
    final rows = <List<String>>[
      ['GST REPORT'],
      ['Shop', snapshot.identity.shopName],
      ['GSTIN', snapshot.identity.gstin],
      ['Period', GstReportFormatters.periodLabel(snapshot.period)],
      [],
      ...summaryRows(snapshot),
      [],
      ...invoiceLedgerRows('GSTR-1 B2B INVOICES', snapshot.gstr1B2bInvoices),
      [],
      ...invoiceLedgerRows('GSTR-1 B2C INVOICES', snapshot.gstr1B2cInvoices),
      [],
      ...hsnRows(snapshot.hsnSummary),
      [],
      ...gstr3bRows(snapshot.gstr3b),
      [],
      ...auditRows(snapshot.auditFindings),
    ];
    return rows.map(_csvRow).join('\r\n');
  }

  static List<List<String>> summaryRows(GstReportSnapshot snapshot) {
    final summary = snapshot.dashboard;
    return [
      ['GST DASHBOARD'],
      ['GST Invoices', '${summary.gstInvoiceCount}'],
      ['Taxable Sales', GstReportFormatters.money(summary.taxableSales)],
      ['CGST', GstReportFormatters.money(summary.cgstAmount)],
      ['SGST', GstReportFormatters.money(summary.sgstAmount)],
      ['IGST', GstReportFormatters.money(summary.igstAmount)],
      ['Total GST Payable', GstReportFormatters.money(summary.totalGst)],
      [
        'Non-GST Sales Estimate',
        GstReportFormatters.money(summary.nonGstSalesEstimate),
      ],
      ['Audit Findings', '${snapshot.auditFindings.length}'],
    ];
  }

  static List<List<String>> invoiceLedgerRows(
    String title,
    List<GstInvoiceRow> invoices,
  ) {
    return [
      [title],
      [
        'S.No',
        'Invoice No',
        'Date',
        'Customer',
        'GSTIN',
        'Place of Supply',
        'Taxable',
        'CGST',
        'SGST',
        'IGST',
        'Total GST',
        'Invoice Value',
      ],
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].invoiceNo,
          GstReportFormatters.date(invoices[index].invoiceDate),
          invoices[index].customerName,
          invoices[index].customerGstin,
          invoices[index].placeOfSupply,
          invoices[index].taxableAmount.toStringAsFixed(2),
          invoices[index].cgstAmount.toStringAsFixed(2),
          invoices[index].sgstAmount.toStringAsFixed(2),
          invoices[index].igstAmount.toStringAsFixed(2),
          invoices[index].gstAmount.toStringAsFixed(2),
          invoices[index].invoiceValue.toStringAsFixed(2),
        ],
      _invoiceTotalRow(invoices),
    ];
  }

  static List<List<String>> hsnRows(List<GstHsnSummaryRow> rows) {
    return [
      ['HSN GST REGISTER'],
      [
        'Invoice Type',
        'HSN/SAC',
        'Description',
        'Rate',
        'Invoices',
        'Lines',
        'Quantity',
        'Taxable',
        'CGST',
        'SGST',
        'IGST',
        'Total GST',
        'Invoice Value',
      ],
      for (final row in rows)
        [
          row.invoiceType,
          row.hsnCode,
          row.description,
          GstReportFormatters.rate(row.gstRate),
          '${row.invoiceCount}',
          '${row.lineCount}',
          '${row.quantity}',
          row.taxableAmount.toStringAsFixed(2),
          row.cgstAmount.toStringAsFixed(2),
          row.sgstAmount.toStringAsFixed(2),
          row.igstAmount.toStringAsFixed(2),
          row.gstAmount.toStringAsFixed(2),
          row.invoiceValue.toStringAsFixed(2),
        ],
    ];
  }

  static List<List<String>> gstr3bRows(Gstr3bSummary summary) {
    return [
      ['GSTR-3B SUMMARY'],
      ['Section', 'Taxable', 'IGST', 'CGST', 'SGST', 'Total'],
      [
        '3.1(a) Outward Taxable Supplies',
        summary.outwardTaxableValue.toStringAsFixed(2),
        summary.outwardIgst.toStringAsFixed(2),
        summary.outwardCgst.toStringAsFixed(2),
        summary.outwardSgst.toStringAsFixed(2),
        summary.netTaxPayable.toStringAsFixed(2),
      ],
      [
        '3.1(c) Nil/Exempt/Non-GST',
        summary.nilExemptNonGstValue.toStringAsFixed(2),
        '0.00',
        '0.00',
        '0.00',
        '0.00',
      ],
      ['ITC', 'Pending purchase report integration', '', '', '', ''],
    ];
  }

  static List<List<String>> auditRows(List<GstAuditFinding> findings) {
    return [
      ['GST AUDIT CHECKS'],
      ['Severity', 'Invoice', 'Title', 'Message'],
      for (final finding in findings)
        [
          finding.severity.name.toUpperCase(),
          finding.invoiceNo,
          finding.title,
          finding.message,
        ],
    ];
  }

  static List<String> _invoiceTotalRow(List<GstInvoiceRow> invoices) {
    double sum(double Function(GstInvoiceRow row) selector) {
      return invoices.fold(0, (total, row) => total + selector(row));
    }

    return [
      'TOTAL',
      '${invoices.length} invoices',
      '',
      '',
      '',
      '',
      sum((row) => row.taxableAmount).toStringAsFixed(2),
      sum((row) => row.cgstAmount).toStringAsFixed(2),
      sum((row) => row.sgstAmount).toStringAsFixed(2),
      sum((row) => row.igstAmount).toStringAsFixed(2),
      sum((row) => row.gstAmount).toStringAsFixed(2),
      sum((row) => row.invoiceValue).toStringAsFixed(2),
    ];
  }

  static String _csvRow(List<String> row) {
    return row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',');
  }
}
