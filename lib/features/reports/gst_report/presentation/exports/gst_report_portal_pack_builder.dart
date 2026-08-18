import 'package:intl/intl.dart';

import '../../domain/gstr1_filing_models.dart';
import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';

class GstPortalCsvDocument {
  const GstPortalCsvDocument({
    required this.fileName,
    required this.rows,
  });

  final String fileName;
  final List<List<String>> rows;

  String get contents =>
      rows.map(GstReportPortalPackBuilder.csvRow).join('\r\n');
}

class GstReportPortalPackBuilder {
  GstReportPortalPackBuilder._();

  static List<GstPortalCsvDocument> documents(
    GstReportSnapshot snapshot, {
    GstFilingSegment? segment,
  }) {
    final gstr1 = Gstr1FilingSnapshot.fromReport(snapshot);
    final period = GstReportFormatters.filePart(snapshot.period);
    final includeB2b = segment == null || segment == GstFilingSegment.b2b;
    final includeB2c = segment == null || segment == GstFilingSegment.b2c;

    final documents = <GstPortalCsvDocument>[];
    void addWhenRequired(String fileName, List<List<String>> rows) {
      if (_hasDataRows(rows)) {
        documents.add(GstPortalCsvDocument(fileName: fileName, rows: rows));
      }
    }

    if (includeB2b) {
      addWhenRequired(
        '01-gstr1-b2b-invoices-$period.csv',
        _b2bRows(gstr1.b2bInvoices),
      );
      addWhenRequired(
        '04-gstr1-hsn-b2b-table12-$period.csv',
        _hsnRows(gstr1.hsnB2bSummary),
      );
    }

    if (includeB2c) {
      addWhenRequired(
        '02-gstr1-b2cl-invoices-$period.csv',
        _b2cLargeRows(gstr1.b2cLargeInvoices),
      );
      addWhenRequired(
        '03-gstr1-b2cs-summary-$period.csv',
        _b2cSmallRows(gstr1.b2cSmallSummary),
      );
      addWhenRequired(
        '05-gstr1-hsn-b2c-table12-$period.csv',
        _hsnRows(gstr1.hsnB2cSummary),
      );
    }

    if (segment == null) {
      addWhenRequired(
        '06-gstr1-documents-issued-$period.csv',
        _documentRows(gstr1.documentSummary),
      );
    }

    return documents;
  }

  static bool _hasDataRows(List<List<String>> rows) {
    return rows.skip(1).any((row) => row.any((cell) => cell.trim().isNotEmpty));
  }

  static List<GstPortalCsvDocument> allTemplates(GstReportSnapshot snapshot) {
    final gstr1 = Gstr1FilingSnapshot.fromReport(snapshot);
    final period = GstReportFormatters.filePart(snapshot.period);
    return [
      GstPortalCsvDocument(
        fileName: '01-gstr1-b2b-invoices-$period.csv',
        rows: _b2bRows(gstr1.b2bInvoices),
      ),
      GstPortalCsvDocument(
        fileName: '02-gstr1-b2cl-invoices-$period.csv',
        rows: _b2cLargeRows(gstr1.b2cLargeInvoices),
      ),
      GstPortalCsvDocument(
        fileName: '03-gstr1-b2cs-summary-$period.csv',
        rows: _b2cSmallRows(gstr1.b2cSmallSummary),
      ),
      GstPortalCsvDocument(
        fileName: '04-gstr1-hsn-b2b-table12-$period.csv',
        rows: _hsnRows(gstr1.hsnB2bSummary),
      ),
      GstPortalCsvDocument(
        fileName: '05-gstr1-hsn-b2c-table12-$period.csv',
        rows: _hsnRows(gstr1.hsnB2cSummary),
      ),
      GstPortalCsvDocument(
        fileName: '06-gstr1-documents-issued-$period.csv',
        rows: _documentRows(gstr1.documentSummary),
      ),
    ];
  }

  static List<List<String>> b2bRows(GstReportSnapshot snapshot) =>
      _b2bRows(Gstr1FilingSnapshot.fromReport(snapshot).b2bInvoices);

  static List<List<String>> b2cLargeRows(GstReportSnapshot snapshot) =>
      _b2cLargeRows(Gstr1FilingSnapshot.fromReport(snapshot).b2cLargeInvoices);

  static List<List<String>> b2cSmallRows(GstReportSnapshot snapshot) =>
      _b2cSmallRows(Gstr1FilingSnapshot.fromReport(snapshot).b2cSmallSummary);

  static List<List<String>> hsnB2bRows(GstReportSnapshot snapshot) =>
      _hsnRows(Gstr1FilingSnapshot.fromReport(snapshot).hsnB2bSummary);

  static List<List<String>> hsnB2cRows(GstReportSnapshot snapshot) =>
      _hsnRows(Gstr1FilingSnapshot.fromReport(snapshot).hsnB2cSummary);

  static List<List<String>> documentIssuedRows(GstReportSnapshot snapshot) {
    return _documentRows(
        Gstr1FilingSnapshot.fromReport(snapshot).documentSummary);
  }

  static String csvRow(List<String> row) {
    return row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',');
  }

  static List<List<String>> _b2bRows(List<GstInvoiceRow> invoices) {
    return [
      [
        'GSTIN/UIN of Recipient',
        'Receiver Name',
        'Invoice Number',
        'Invoice Date',
        'Invoice Value',
        'Place Of Supply',
        'Reverse Charge',
        'Applicable % of Tax Rate',
        'Invoice Type',
        'E-Commerce GSTIN',
        'Rate',
        'Taxable Value',
        'Cess Amount',
      ],
      for (final invoice in invoices)
        [
          invoice.customerGstin,
          invoice.customerName,
          invoice.invoiceNo,
          _portalDate(invoice.invoiceDate),
          _money(invoice.invoiceValue),
          _portalPlace(invoice.placeOfSupplyStateCode, invoice.placeOfSupply),
          'N',
          '',
          'Regular B2B',
          '',
          _rate(invoice),
          _money(invoice.taxableAmount),
          '0.00',
        ],
    ];
  }

  static List<List<String>> _b2cLargeRows(List<GstInvoiceRow> invoices) {
    return [
      [
        'Invoice Number',
        'Invoice Date',
        'Invoice Value',
        'Place Of Supply',
        'Applicable % of Tax Rate',
        'Rate',
        'Taxable Value',
        'Cess Amount',
        'E-Commerce GSTIN',
      ],
      for (final invoice in invoices)
        [
          invoice.invoiceNo,
          _portalDate(invoice.invoiceDate),
          _money(invoice.invoiceValue),
          _portalPlace(invoice.placeOfSupplyStateCode, invoice.placeOfSupply),
          '',
          _rate(invoice),
          _money(invoice.taxableAmount),
          '0.00',
          '',
        ],
    ];
  }

  static List<List<String>> _b2cSmallRows(List<Gstr1B2cSmallSummaryRow> rows) {
    return [
      [
        'Type',
        'Place Of Supply',
        'Applicable % of Tax Rate',
        'Rate',
        'Taxable Value',
        'Cess Amount',
        'E-Commerce GSTIN',
      ],
      for (final row in rows)
        [
          'OE',
          _portalPlace(row.placeOfSupplyStateCode, row.placeOfSupply),
          '',
          row.rate.toStringAsFixed(2),
          _money(row.taxableValue),
          '0.00',
          '',
        ],
    ];
  }

  static List<List<String>> _hsnRows(List<GstHsnSummaryRow> rows) {
    return [
      [
        'HSN',
        'Description',
        'UQC',
        'Total Quantity',
        'Total Value',
        'Taxable Value',
        'Integrated Tax Amount',
        'Central Tax Amount',
        'State/UT Tax Amount',
        'Cess Amount',
      ],
      for (final row in rows)
        [
          row.hsnCode,
          row.description,
          'PCS',
          '${row.quantity}',
          _money(row.invoiceValue),
          _money(row.taxableAmount),
          _money(row.igstAmount),
          _money(row.cgstAmount),
          _money(row.sgstAmount),
          '0.00',
        ],
    ];
  }

  static List<List<String>> _documentRows(List<Gstr1DocumentSummaryRow> rows) {
    return [
      [
        'Nature of Document',
        'Sr. No. From',
        'Sr. No. To',
        'Total Number',
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

  static String _portalDate(DateTime value) {
    return DateFormat('dd-MM-yyyy').format(value);
  }

  static String _portalPlace(String stateCode, String placeOfSupply) {
    final cleanPlace = placeOfSupply.trim();
    final code = stateCode.trim();
    if (code.isEmpty || cleanPlace.isEmpty) return cleanPlace;
    if (cleanPlace.startsWith('$code-')) return cleanPlace;
    return '$code-$cleanPlace';
  }

  static String _rate(GstInvoiceRow invoice) {
    if (invoice.taxableAmount.abs() <= 0.005) return '0.00';
    return ((invoice.gstAmount / invoice.taxableAmount) * 100)
        .toStringAsFixed(2);
  }

  static String _money(double value) => value.toStringAsFixed(2);
}
