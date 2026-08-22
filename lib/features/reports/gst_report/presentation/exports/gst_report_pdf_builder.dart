import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../../core/pdf/lotus_pdf_theme.dart';
import '../../domain/gstr1_filing_models.dart';
import '../../domain/gstr3b_filing_models.dart';
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

  static Future<Uint8List> buildFilingGuide(
    GstReportSnapshot snapshot,
  ) async {
    final gstr1 = Gstr1FilingSnapshot.fromReport(snapshot);
    final gstr3b = Gstr3bFilingSnapshot.fromReport(snapshot);
    final document = pw.Document(
      title:
          'GST Portal Filing Guide - ${GstReportFormatters.monthLabel(snapshot.period)}',
      author: snapshot.identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: await LotusPdfTheme.reportTheme(),
        footer: _footer,
        build: (_) => [
          _header('GST Portal Filing Guide', snapshot),
          pw.SizedBox(height: 12),
          _notice(
            'Import the GSTR-1 CSV files into the GST Returns Offline Tool, generate the JSON there, then upload that JSON on the GST portal. GSTR-3B is normally entered and reviewed on the portal using the values below; it is not an invoice CSV upload.',
          ),
          pw.SizedBox(height: 12),
          _section(
            'GSTR-1 / IFF Upload Checklist',
            const ['Portal Section', 'ERP File', 'Status', 'Rows', 'Action'],
            _gstr1UploadChecklist(snapshot, gstr1),
          ),
          pw.SizedBox(height: 12),
          _section(
            'GSTR-3B Portal Entry Values',
            const [
              'Table',
              'Nature of Supply',
              'Taxable Value',
              'IGST',
              'CGST',
              'SGST',
              'Cess',
              'Portal Action',
            ],
            _gstr3bEntryRows(gstr3b),
          ),
          pw.SizedBox(height: 12),
          _section(
            'Table 6.1 Payment Working',
            const [
              'Tax Head',
              'Tax Payable',
              'ITC Available',
              'Cash Payable',
              'Interest',
              'Late Fee',
            ],
            gstr3b.paymentRows
                .map(
                  (row) => [
                    row.taxHead,
                    row.taxPayable.toStringAsFixed(2),
                    row.itcAvailable.toStringAsFixed(2),
                    row.cashPayable.toStringAsFixed(2),
                    row.interest.toStringAsFixed(2),
                    row.lateFee.toStringAsFixed(2),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 12),
          _section(
            'Portal Verification Notes',
            const ['Topic', 'When Required', 'Portal Action', 'ERP Status'],
            gstr3b.portalNotes
                .map(
                  (note) => [
                    note.title,
                    note.whenRequired,
                    note.portalAction,
                    note.erpStatus,
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildSummary(GstReportSnapshot snapshot) async {
    final document = pw.Document(
      title: 'GST Summary - ${GstReportFormatters.monthLabel(snapshot.period)}',
      author: snapshot.identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: await LotusPdfTheme.reportTheme(),
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
        theme: await LotusPdfTheme.reportTheme(),
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
        theme: await LotusPdfTheme.reportTheme(),
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

  static pw.Widget _notice(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFBEB),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFD97706),
          width: 0.35,
        ),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: _ink,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static List<List<String>> _gstr1UploadChecklist(
    GstReportSnapshot snapshot,
    Gstr1FilingSnapshot gstr1,
  ) {
    final period = GstReportFormatters.filePart(snapshot.period);
    return [
      _uploadChecklistRow(
        section: 'B2B',
        fileName: 'gstr-1-b2b-invoices-$period.csv',
        rowCount: gstr1.b2bInvoices.length,
        action: 'Upload invoice-wise registered customer sales.',
      ),
      _uploadChecklistRow(
        section: 'B2CL',
        fileName: 'gstr-1-b2cl-invoices-$period.csv',
        rowCount: gstr1.b2cLargeInvoices.length,
        action: 'Upload only large interstate B2C invoices.',
      ),
      _uploadChecklistRow(
        section: 'B2CS',
        fileName: 'gstr-1-b2cs-summary-$period.csv',
        rowCount: gstr1.b2cSmallSummary.length,
        action: 'Upload consolidated retail sales summary.',
      ),
      _uploadChecklistRow(
        section: 'HSN Table 12 B2B',
        fileName: 'gstr-1-hsn-b2b-table12-$period.csv',
        rowCount: gstr1.hsnB2bSummary.length,
        action: 'Upload HSN summary for B2B outward supplies.',
      ),
      _uploadChecklistRow(
        section: 'HSN Table 12 B2C',
        fileName: 'gstr-1-hsn-b2c-table12-$period.csv',
        rowCount: gstr1.hsnB2cSummary.length,
        action: 'Upload HSN summary for B2C outward supplies.',
      ),
      _uploadChecklistRow(
        section: 'Documents Issued',
        fileName: 'gstr-1-documents-issued-$period.csv',
        rowCount: gstr1.documentSummary.length,
        action: 'Fill document count summary for issued tax invoices/notes.',
      ),
    ];
  }

  static List<String> _uploadChecklistRow({
    required String section,
    required String fileName,
    required int rowCount,
    required String action,
  }) {
    final hasRows = rowCount > 0;
    return [
      section,
      hasRows ? fileName : 'Not generated',
      hasRows ? 'Required' : 'Skip - no data',
      '$rowCount',
      hasRows ? action : 'No portal entry required for this section.',
    ];
  }

  static List<List<String>> _gstr3bEntryRows(Gstr3bFilingSnapshot gstr3b) {
    return [
      for (final row in gstr3b.table31Rows)
        [
          row.code,
          row.title,
          row.taxableValue.toStringAsFixed(2),
          row.igst.toStringAsFixed(2),
          row.cgst.toStringAsFixed(2),
          row.sgst.toStringAsFixed(2),
          row.cess.toStringAsFixed(2),
          row.code == '3.1(a)'
              ? 'Enter outward supply liability from ERP.'
              : row.taxableValue.abs() <= 0.005 && row.totalTax.abs() <= 0.005
                  ? 'Leave zero unless business data exists.'
                  : 'Review and enter on portal.',
        ],
      if (gstr3b.table32Rows.isNotEmpty)
        for (final row in gstr3b.table32Rows)
          [
            '3.2',
            'Inter-state supply to unregistered person - ${row.placeOfSupply}',
            row.taxableValue.toStringAsFixed(2),
            row.igst.toStringAsFixed(2),
            '0.00',
            '0.00',
            '0.00',
            'Enter place-of-supply breakup on portal.',
          ],
    ];
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
