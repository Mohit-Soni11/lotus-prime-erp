import '../../domain/gstr1_filing_models.dart';
import '../../domain/gstr3b_filing_models.dart';
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
      ...gstr3bPortalRows(snapshot),
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
      [
        'Total Invoice Value',
        GstReportFormatters.money(summary.gstInvoiceValue)
      ],
      ..._pricingSummaryRows('GST EXCLUSIVE SALES', summary.exclusive),
      ..._pricingSummaryRows('GST INCLUSIVE SALES', summary.inclusive),
      [
        'GST Exclusive Sales',
        GstReportFormatters.money(summary.gstExclusiveSales),
      ],
      [
        'GST Inclusive Sales',
        GstReportFormatters.money(summary.gstInclusiveSales),
      ],
      ['Total Taxable Value', GstReportFormatters.money(summary.taxableSales)],
      ['CGST', GstReportFormatters.money(summary.cgstAmount)],
      ['SGST', GstReportFormatters.money(summary.sgstAmount)],
      ['IGST', GstReportFormatters.money(summary.igstAmount)],
      ['Output GST Liability', GstReportFormatters.money(summary.totalGst)],
      [
        'Tax Review Sales',
        GstReportFormatters.money(summary.nonGstSalesEstimate),
      ],
      ['Audit Findings', '${snapshot.auditFindings.length}'],
    ];
  }

  static List<List<String>> _pricingSummaryRows(
    String title,
    GstPricingModeSummary summary,
  ) {
    return [
      [title],
      ['Invoice Count', '${summary.invoiceCount}'],
      ['Invoice Value', GstReportFormatters.money(summary.invoiceValue)],
      ['Taxable Value', GstReportFormatters.money(summary.taxableValue)],
      ['CGST', GstReportFormatters.money(summary.cgstAmount)],
      ['SGST', GstReportFormatters.money(summary.sgstAmount)],
      ['IGST', GstReportFormatters.money(summary.igstAmount)],
      ['Output GST', GstReportFormatters.money(summary.outputGst)],
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
        'Place State Code',
        'Shop State Code',
        'Supply Type',
        'Pricing Mode',
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
          invoices[index].placeOfSupplyStateCode,
          invoices[index].shopStateCode,
          invoices[index].supplyType == 'INTER_STATE'
              ? 'Inter-State'
              : 'Intra-State',
          _pricingLabel(invoices[index].gstPricingMode),
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

  static List<List<String>> gstr1PortalRows(GstReportSnapshot snapshot) {
    final filing = Gstr1FilingSnapshot.fromReport(snapshot);
    return [
      ['GSTR-1 PORTAL FILING WORKSPACE'],
      ['Shop', snapshot.identity.shopName],
      ['GSTIN', snapshot.identity.gstin],
      ['Period', GstReportFormatters.periodLabel(snapshot.period)],
      [
        'Portal Readiness',
        filing.readiness.isPortalReady ? 'READY' : 'ACTION REQUIRED',
      ],
      ['Blocking Issues', '${filing.readiness.blockerCount}'],
      ['Review Warnings', '${filing.readiness.warningCount}'],
      for (final blocker in filing.readiness.blockers) ['BLOCKER', blocker],
      for (final warning in filing.readiness.warnings) ['WARNING', warning],
      [],
      ...invoiceLedgerRows('4A/4B/6B/6C - B2B INVOICES', filing.b2bInvoices),
      [],
      ...invoiceLedgerRows(
          '5A/5B - B2C LARGE INVOICES', filing.b2cLargeInvoices),
      [],
      ...b2cSmallRows(filing.b2cSmallSummary),
      [],
      ...hsnRows(filing.hsnB2bSummary),
      [],
      ...hsnRows(filing.hsnB2cSummary),
      [],
      ...documentIssuedRows(filing.documentSummary),
      [],
      ...additionalGstr1Rows(),
    ];
  }

  static List<List<String>> b2cSmallRows(
    List<Gstr1B2cSmallSummaryRow> rows,
  ) {
    return [
      ['7 - B2C SMALL CONSOLIDATED SUMMARY'],
      [
        'Place of Supply',
        'Supply Type',
        'Rate',
        'Invoices',
        'Taxable Value',
        'CGST',
        'SGST',
        'IGST',
        'Output GST',
        'Invoice Value',
      ],
      for (final row in rows)
        [
          row.placeOfSupply,
          row.supplyType,
          GstReportFormatters.rate(row.rate),
          '${row.invoiceCount}',
          row.taxableValue.toStringAsFixed(2),
          row.cgstAmount.toStringAsFixed(2),
          row.sgstAmount.toStringAsFixed(2),
          row.igstAmount.toStringAsFixed(2),
          row.outputGst.toStringAsFixed(2),
          row.invoiceValue.toStringAsFixed(2),
        ],
    ];
  }

  static List<List<String>> documentIssuedRows(
    List<Gstr1DocumentSummaryRow> rows,
  ) {
    return [
      ['13 - DOCUMENTS ISSUED'],
      [
        'Document Type',
        'From Number',
        'To Number',
        'Total Issued',
        'Cancelled',
        'Net Issued',
      ],
      for (final row in rows)
        [
          row.documentType,
          row.fromNumber,
          row.toNumber,
          '${row.totalIssued}',
          '${row.cancelled}',
          '${row.netIssued}',
        ],
    ];
  }

  static List<List<String>> additionalGstr1Rows() {
    return const [
      ['ADDITIONAL GSTR-1 TABLES'],
      ['Section', 'Status', 'Note'],
      [
        '9B - Credit / Debit Notes',
        'No records',
        'Connect sales return workflow when available.',
      ],
      [
        '8 - Nil / Exempt / Non-GST Supplies',
        'No records',
        'Jewellery taxable supplies are reported in regular outward tables.',
      ],
      [
        '11A/11B - Advances / Adjustments',
        'No records',
        'Connect advance workflow when tax-on-advance is enabled.',
      ],
      [
        'Amendments',
        'No records',
        'Use only for corrections to previously filed periods.',
      ],
      ['6A - Exports / SEZ', 'Not used', 'Domestic jewellery supplies only.'],
      ['E-Commerce / 9(5)', 'Not used', 'No ECO operator configured.'],
    ];
  }

  static List<List<String>> hsnRows(List<GstHsnSummaryRow> rows) {
    return [
      ['GSTR-1 TABLE 12 - HSN SUMMARY OF OUTWARD SALES'],
      [
        'HSN/SAC',
        'Description',
        'UQC',
        'Total Quantity',
        'Total Value',
        'Total Taxable Value',
        'Rate',
        'Invoices',
        'Lines',
        'IGST',
        'CGST',
        'SGST',
        'Cess',
        'Output GST',
        'Sales Type',
      ],
      for (final row in rows)
        [
          row.hsnCode,
          row.description,
          'PCS',
          '${row.quantity}',
          row.invoiceValue.toStringAsFixed(2),
          row.taxableAmount.toStringAsFixed(2),
          GstReportFormatters.rate(row.gstRate),
          '${row.invoiceCount}',
          '${row.lineCount}',
          row.igstAmount.toStringAsFixed(2),
          row.cgstAmount.toStringAsFixed(2),
          row.sgstAmount.toStringAsFixed(2),
          '0.00',
          row.gstAmount.toStringAsFixed(2),
          row.invoiceType,
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
        '3.1(c) Nil/Exempt/Non-taxable',
        summary.nilExemptNonGstValue.toStringAsFixed(2),
        '0.00',
        '0.00',
        '0.00',
        '0.00',
      ],
      ['ITC', 'Pending purchase report integration', '', '', '', ''],
    ];
  }

  static List<List<String>> gstr3bPortalRows(GstReportSnapshot snapshot) {
    final filing = Gstr3bFilingSnapshot.fromReport(snapshot);
    return [
      ['GSTR-3B FILING WORKSPACE'],
      ['Shop', snapshot.identity.shopName],
      ['GSTIN', snapshot.identity.gstin],
      ['Period', GstReportFormatters.periodLabel(snapshot.period)],
      [
        'Readiness',
        filing.readiness.canFile ? 'READY TO REVIEW' : 'ACTION REQUIRED'
      ],
      ['Blocking Issues', '${filing.readiness.blockerCount}'],
      ['Review Warnings', '${filing.readiness.warningCount}'],
      for (final blocker in filing.readiness.blockers) ['BLOCKER', blocker],
      for (final warning in filing.readiness.warnings) ['WARNING', warning],
      [],
      ['PORTAL VERIFICATION NOTES'],
      ['Topic', 'When Required', 'Portal Action', 'ERP Status'],
      for (final note in filing.portalNotes)
        [
          note.title,
          note.whenRequired,
          note.portalAction,
          note.erpStatus,
        ],
      [],
      ['TABLE 3.1 - TAX LIABILITY SUMMARY'],
      [
        'Table',
        'Nature of Supply',
        'Taxable Value',
        'IGST',
        'CGST',
        'SGST',
        'Cess',
        'Total Tax',
        'Note',
      ],
      for (final row in filing.table31Rows)
        [
          row.code,
          row.title,
          row.taxableValue.toStringAsFixed(2),
          row.igst.toStringAsFixed(2),
          row.cgst.toStringAsFixed(2),
          row.sgst.toStringAsFixed(2),
          row.cess.toStringAsFixed(2),
          row.totalTax.toStringAsFixed(2),
          row.note,
        ],
      [],
      ['TABLE 3.2 - INTER-STATE SUPPLIES'],
      ['Place of Supply', 'Recipient Type', 'Taxable Value', 'IGST'],
      for (final row in filing.table32Rows)
        [
          row.placeOfSupply,
          'Unregistered Person',
          row.taxableValue.toStringAsFixed(2),
          row.igst.toStringAsFixed(2),
        ],
      [],
      ['TABLE 4 - ELIGIBLE ITC'],
      ['Section', 'ITC Type', 'IGST', 'CGST', 'SGST', 'Cess', 'Status'],
      for (final row in filing.itcRows)
        [
          row.section,
          row.title,
          row.igst.toStringAsFixed(2),
          row.cgst.toStringAsFixed(2),
          row.sgst.toStringAsFixed(2),
          row.cess.toStringAsFixed(2),
          row.status,
        ],
      [],
      ['TABLE 5 - EXEMPT / NIL / NON-GST INWARD SUPPLIES'],
      ['Nature of Supply', 'Inter-State Value', 'Intra-State Value', 'Status'],
      for (final row in filing.exemptInwardRows)
        [
          row.title,
          row.interStateValue.toStringAsFixed(2),
          row.intraStateValue.toStringAsFixed(2),
          row.status,
        ],
      [],
      ['TABLE 6.1 - PAYMENT OF TAX'],
      [
        'Tax Head',
        'Tax Payable',
        'ITC Available',
        'Cash Payable',
        'Interest',
        'Late Fee'
      ],
      for (final row in filing.paymentRows)
        [
          row.taxHead,
          row.taxPayable.toStringAsFixed(2),
          row.itcAvailable.toStringAsFixed(2),
          row.cashPayable.toStringAsFixed(2),
          row.interest.toStringAsFixed(2),
          row.lateFee.toStringAsFixed(2),
        ],
      [],
      ['DOCUMENTS AND PORTAL CHECKLIST'],
      ['Item', 'Required Action'],
      ['GSTR-1 / IFF Liability', 'Match outward tax with Table 3.1(a).'],
      [
        'GSTR-2B ITC Statement',
        'Download from portal before entering Table 4.'
      ],
      ['Purchase Invoices', 'Keep supplier invoices for ITC evidence.'],
      ['RCM Expenses', 'Check reverse charge purchases and expenses.'],
      ['Cash Ledger / PMT-06', 'For QRMP month 1 and 2, pay monthly challan.'],
      [
        'Interest / Late Fee',
        'Confirm portal-calculated amount before filing.'
      ],
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

  static String _pricingLabel(String value) {
    return value.trim().toUpperCase() == 'GST_INCLUSIVE'
        ? 'GST Inclusive'
        : 'GST Exclusive';
  }
}
