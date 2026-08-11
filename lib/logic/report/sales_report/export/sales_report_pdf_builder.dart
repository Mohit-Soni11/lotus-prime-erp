import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../models/reports/sales_report/sales_report_models.dart';
import 'sales_report_export_formatters.dart';

class SalesReportPdfBuilder {
  SalesReportPdfBuilder._();

  static const PdfColor _black = PdfColors.black;
  static const PdfColor _dark = PdfColors.black;
  static const PdfColor _gold = PdfColor.fromInt(0xFFF2C94C);
  static const PdfColor _softGold = PdfColor.fromInt(0xFFFFF6D8);
  static const PdfColor _white = PdfColors.white;

  static Future<Uint8List> buildComplete(
    SalesReportSnapshot snapshot, {
    required String reportTitle,
    required SalesReportExportIdentity identity,
  }) async {
    final document = pw.Document(
      title:
          '$reportTitle - ${SalesReportExportFormatters.periodLabel(snapshot.filter)}',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeader(reportTitle, snapshot.filter, identity),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Sales Summary',
            const ['Metric', 'Value'],
            SalesReportExportFormatters.salesSummaryRowsWithMetalBreakdown(
              snapshot,
            ),
          ),
          pw.SizedBox(height: 12),
          _pdfSection(
            'GST Liability',
            const ['Metric', 'Value'],
            SalesReportExportFormatters.gstLiabilityRows(snapshot.gstLiability),
          ),
          if (snapshot.metals.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _pdfSection(
              'Metal Sales Summary',
              const [
                'Metal',
                'Invoices',
                'Items',
                'Pcs',
                'Gross Wt',
                'Net Wt',
                'Making',
                'Sales',
              ],
              SalesReportExportFormatters.metalRows(snapshot.metals),
            ),
          ],
          pw.SizedBox(height: 12),
          _pdfSection(
            'Invoice Ledger',
            const [
              'S.No',
              'Invoice',
              'Date',
              'Customer',
              'Type',
              'Metal / Net Wt',
              'Taxable',
              'GST',
              'Final',
            ],
            _invoiceRows(snapshot.invoices, snapshot.items),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildGstLiability(
    SalesReportSnapshot snapshot, {
    required SalesReportExportIdentity identity,
  }) async {
    final document = pw.Document(
      title:
          'GST Liability Report - ${SalesReportExportFormatters.periodLabel(snapshot.filter)}',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeader('GST Liability Report', snapshot.filter, identity),
          pw.SizedBox(height: 16),
          _pdfSection(
            'GST Liability Summary',
            const ['Metric', 'Value'],
            SalesReportExportFormatters.gstLiabilityRows(snapshot.gstLiability),
          ),
          pw.SizedBox(height: 16),
          _pdfSection(
            'Invoice Tax Audit',
            const [
              'Invoice',
              'Date',
              'Customer',
              'Type',
              'Taxable',
              'GST',
              'Final',
            ],
            snapshot.invoices
                .map(
                  (invoice) => [
                    invoice.billNo,
                    SalesReportExportFormatters.date(invoice.billDate),
                    invoice.customerName,
                    invoice.isGst ? 'GST' : 'NON-GST',
                    SalesReportExportFormatters.money(invoice.taxableAmount),
                    SalesReportExportFormatters.money(invoice.gstAmount),
                    SalesReportExportFormatters.money(invoice.finalAmount),
                  ],
                )
                .toList(growable: false),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildInvoiceLedger(
    SalesReportSnapshot snapshot, {
    required SalesReportExportIdentity identity,
    String reportTitle = 'Invoice Ledger',
  }) async {
    final document = pw.Document(
      title:
          '$reportTitle - ${SalesReportExportFormatters.periodLabel(snapshot.filter)}',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a3.landscape,
        margin: const pw.EdgeInsets.all(24),
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeader(reportTitle, snapshot.filter, identity),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Invoice Ledger',
            const [
              'S.No',
              'Invoice',
              'Date',
              'Customer',
              'Type',
              'Metal / Net Wt',
              'Gross',
              'Discount',
              'Taxable',
              'GST',
              'Final',
            ],
            _invoiceLedgerRows(snapshot.invoices, snapshot.items),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildItemLedger(
    SalesReportSnapshot snapshot, {
    required SalesReportExportIdentity identity,
    String reportTitle = 'Item Ledger',
  }) async {
    final document = pw.Document(
      title:
          '$reportTitle - ${SalesReportExportFormatters.periodLabel(snapshot.filter)}',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeader(reportTitle, snapshot.filter, identity),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Item Ledger',
            const [
              'S.No',
              'Invoice',
              'Date',
              'Customer',
              'Type',
              'Metal',
              'Item',
              'HUID',
              'Purity',
              'Pcs',
              'Gross',
              'Less',
              'Net',
              'Rate',
              'Making',
              'Total',
            ],
            _itemLedgerRows(snapshot.items),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildGradeWise(
    SalesReportSnapshot snapshot, {
    required String metalTitle,
    required SalesReportExportIdentity identity,
  }) async {
    final document = pw.Document(
      title: '$metalTitle Grade-wise Sales Report',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeader(
            '$metalTitle Grade-wise Sales Report',
            snapshot.filter,
            identity,
          ),
          pw.SizedBox(height: 14),
          _pdfSection(
            '$metalTitle Grade Summary',
            const [
              'Grade',
              'Invoices',
              'Items',
              'Pcs',
              'Gross Wt',
              'Net Wt',
              'Making',
              'Sales',
            ],
            SalesReportExportFormatters.gradeRows(snapshot.items),
          ),
          pw.SizedBox(height: 14),
          _pdfSection(
            '$metalTitle Item Ledger',
            const [
              'S.No',
              'Invoice',
              'Customer',
              'Item',
              'HUID',
              'Grade',
              'Pcs',
              'Gross',
              'Net',
              'Rate',
              'Total',
            ],
            _gradeItemRows(snapshot.items),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _pdfHeader(
    String title,
    SalesReportFilter filter,
    SalesReportExportIdentity identity,
  ) {
    final shopName = identity.shopName.trim().isEmpty
        ? 'Sales Report'
        : identity.shopName.trim();
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: const pw.BoxDecoration(color: _dark),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: _white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: _white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                for (final line in identity.headerLines.take(2))
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: _white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Text(
            SalesReportExportFormatters.periodLabel(filter),
            style: pw.TextStyle(
              fontSize: 10,
              color: _white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: _black),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: _black),
        ),
      ],
    );
  }

  static pw.Widget _pdfSection(
    String title,
    List<String> headers,
    List<List<String>> rows,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12.5,
            color: _black,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data:
              rows.isEmpty ? [List.filled(headers.length, 'No records')] : rows,
          headerStyle: pw.TextStyle(
            fontSize: 8.6,
            fontWeight: pw.FontWeight.bold,
            color: _black,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8.2, color: _black),
          headerDecoration: const pw.BoxDecoration(color: _gold),
          oddRowDecoration: const pw.BoxDecoration(color: _softGold),
          border: pw.TableBorder.all(color: _black, width: 0.35),
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        ),
      ],
    );
  }

  static List<List<String>> _invoiceLedgerRows(
    List<SalesReportInvoiceRow> invoices,
    List<SalesReportItemRow> items,
  ) {
    final weightsByBill = SalesReportExportFormatters.invoiceWeights(items);
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.date(invoices[index].billDate),
          invoices[index].customerName,
          invoices[index].isGst ? 'GST' : 'NON-GST',
          '${invoices[index].metalMix}\n${SalesReportExportFormatters.weightSummary(weightsByBill[invoices[index].billId] ?? const {})}',
          SalesReportExportFormatters.money(invoices[index].grossAmount),
          SalesReportExportFormatters.money(invoices[index].discountAmount),
          SalesReportExportFormatters.money(invoices[index].taxableAmount),
          SalesReportExportFormatters.money(invoices[index].gstAmount),
          SalesReportExportFormatters.money(invoices[index].finalAmount),
        ],
      [
        'TOTAL',
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
          invoices.fold(0, (sum, row) => sum + row.finalAmount),
        ),
      ],
    ];
  }

  static List<List<String>> _itemLedgerRows(List<SalesReportItemRow> items) {
    return [
      for (var index = 0; index < items.length; index++)
        [
          '${index + 1}',
          items[index].billNo,
          SalesReportExportFormatters.date(items[index].billDate),
          items[index].customerName,
          items[index].isGst ? 'GST' : 'NON-GST',
          items[index].metalType,
          items[index].itemName,
          items[index].huid.isEmpty ? 'Not linked' : items[index].huid,
          items[index].purity,
          '${items[index].quantity}',
          SalesReportExportFormatters.weight(items[index].grossWeight),
          SalesReportExportFormatters.weight(items[index].lessWeight),
          SalesReportExportFormatters.weight(items[index].netWeight),
          SalesReportExportFormatters.money(items[index].rate),
          SalesReportExportFormatters.money(items[index].makingCharge),
          SalesReportExportFormatters.money(items[index].itemTotal),
        ],
      [
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
        SalesReportExportFormatters.totalNetWeightWithBreakdown(items),
        '',
        SalesReportExportFormatters.money(
          items.fold(0, (sum, item) => sum + item.makingCharge),
        ),
        SalesReportExportFormatters.money(
          items.fold(0, (sum, item) => sum + item.itemTotal),
        ),
      ],
    ];
  }

  static List<List<String>> _invoiceRows(
    List<SalesReportInvoiceRow> invoices,
    List<SalesReportItemRow> items,
  ) {
    final weightsByBill = SalesReportExportFormatters.invoiceWeights(items);
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.date(invoices[index].billDate),
          invoices[index].customerName,
          invoices[index].isGst ? 'GST' : 'NON-GST',
          '${invoices[index].metalMix}\n${SalesReportExportFormatters.weightSummary(weightsByBill[invoices[index].billId] ?? const {})}',
          SalesReportExportFormatters.money(invoices[index].taxableAmount),
          SalesReportExportFormatters.money(invoices[index].gstAmount),
          SalesReportExportFormatters.money(invoices[index].finalAmount),
        ],
      [
        'TOTAL',
        '',
        '',
        '',
        '',
        SalesReportExportFormatters.invoiceWeightTotal(items),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + row.taxableAmount),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + row.gstAmount),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + row.finalAmount),
        ),
      ],
    ];
  }

  static List<List<String>> _gradeItemRows(List<SalesReportItemRow> items) {
    return [
      for (var index = 0; index < items.length; index++)
        [
          '${index + 1}',
          items[index].billNo,
          items[index].customerName,
          items[index].itemName,
          items[index].huid.isEmpty ? 'Not linked' : items[index].huid,
          items[index].purity,
          '${items[index].quantity}',
          SalesReportExportFormatters.weight(items[index].grossWeight),
          SalesReportExportFormatters.weight(items[index].netWeight),
          SalesReportExportFormatters.money(items[index].rate),
          SalesReportExportFormatters.money(items[index].itemTotal),
        ],
      [
        'TOTAL',
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
          items.fold(0, (sum, item) => sum + item.netWeight),
        ),
        '',
        SalesReportExportFormatters.money(
          items.fold(0, (sum, item) => sum + item.itemTotal),
        ),
      ],
    ];
  }
}
