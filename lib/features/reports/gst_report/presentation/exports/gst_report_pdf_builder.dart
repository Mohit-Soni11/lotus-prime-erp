import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import 'gst_report_csv_builder.dart';

class GstReportPdfBuilder {
  GstReportPdfBuilder._();

  static const PdfColor _ink = PdfColor.fromInt(0xFF111827);
  static const PdfColor _muted = PdfColor.fromInt(0xFF475569);
  static const PdfColor _gold = PdfColor.fromInt(0xFFF2C94C);
  static const PdfColor _green = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor _paper = PdfColor.fromInt(0xFFF8FAF5);
  static const PdfColor _white = PdfColors.white;

  static Future<Uint8List> buildSummary(GstReportSnapshot snapshot) async {
    final document = pw.Document(
      title: 'GST Summary - ${GstReportFormatters.monthLabel(snapshot.period)}',
      author: snapshot.identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (_) => [
          _header('GST Summary', snapshot),
          pw.SizedBox(height: 14),
          _section(
            'GST Dashboard',
            const ['Metric', 'Value'],
            GstReportCsvBuilder.summaryRows(snapshot).skip(1).toList(),
          ),
          pw.SizedBox(height: 12),
          _section(
            'GSTR-3B Summary',
            const ['Section', 'Taxable', 'IGST', 'CGST', 'SGST', 'Total'],
            GstReportCsvBuilder.gstr3bRows(snapshot.gstr3b).skip(2).toList(),
          ),
          pw.SizedBox(height: 12),
          _section(
            'Audit Snapshot',
            const ['Severity', 'Invoice', 'Title', 'Message'],
            GstReportCsvBuilder.auditRows(snapshot.auditFindings)
                .skip(2)
                .take(12)
                .toList(),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildInvoiceLedger(
    GstReportSnapshot snapshot,
  ) async {
    final document = pw.Document(
      title:
          'GST Invoice Ledger - ${GstReportFormatters.monthLabel(snapshot.period)}',
      author: snapshot.identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        footer: _footer,
        build: (_) => [
          _header('GST Invoice Ledger', snapshot),
          pw.SizedBox(height: 12),
          _section(
            'GSTR-1 B2B Invoices',
            const [
              'S.No',
              'Invoice',
              'Date',
              'Customer',
              'GSTIN',
              'Place',
              'Taxable',
              'CGST',
              'SGST',
              'IGST',
              'GST',
              'Value',
            ],
            GstReportCsvBuilder.invoiceLedgerRows(
              'GSTR-1 B2B INVOICES',
              snapshot.gstr1B2bInvoices,
            ).skip(2).toList(),
          ),
          pw.SizedBox(height: 12),
          _section(
            'GSTR-1 B2C Invoices',
            const [
              'S.No',
              'Invoice',
              'Date',
              'Customer',
              'GSTIN',
              'Place',
              'Taxable',
              'CGST',
              'SGST',
              'IGST',
              'GST',
              'Value',
            ],
            GstReportCsvBuilder.invoiceLedgerRows(
              'GSTR-1 B2C INVOICES',
              snapshot.gstr1B2cInvoices,
            ).skip(2).toList(),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildHsnRegister(GstReportSnapshot snapshot) async {
    final document = pw.Document(
      title:
          'HSN GST Register - ${GstReportFormatters.monthLabel(snapshot.period)}',
      author: snapshot.identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        footer: _footer,
        build: (_) => [
          _header('HSN GST Register', snapshot),
          pw.SizedBox(height: 12),
          _section(
            'HSN/SAC Summary',
            const [
              'Type',
              'HSN',
              'Description',
              'Rate',
              'Inv.',
              'Lines',
              'Qty',
              'Taxable',
              'CGST',
              'SGST',
              'IGST',
              'GST',
              'Value',
            ],
            GstReportCsvBuilder.hsnRows(snapshot.hsnSummary).skip(2).toList(),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _header(String title, GstReportSnapshot snapshot) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: const pw.BoxDecoration(color: _green),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  snapshot.identity.shopName.toUpperCase(),
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (snapshot.identity.gstin.isNotEmpty)
                  pw.Text(
                    'GSTIN: ${snapshot.identity.gstin}',
                    style: const pw.TextStyle(color: _white, fontSize: 8.5),
                  ),
              ],
            ),
          ),
          pw.Text(
            GstReportFormatters.periodLabel(snapshot.period),
            style: pw.TextStyle(
              color: _white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _section(
    String title,
    List<String> headers,
    List<List<String>> rows,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _paper,
        border: pw.Border.all(color: _muted, width: 0.35),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows.isEmpty
                ? [List.filled(headers.length, 'No records')]
                : rows,
            headerDecoration: const pw.BoxDecoration(color: _gold),
            headerStyle: pw.TextStyle(
              color: _ink,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(color: _ink, fontSize: 7.6),
            border: pw.TableBorder.all(color: _muted, width: 0.28),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ],
    );
  }
}
