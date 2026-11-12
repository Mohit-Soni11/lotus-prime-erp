import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/pdf/lotus_pdf_theme.dart';
import 'day_book_report_model.dart';

class DayBookPdfExport {
  const DayBookPdfExport._();

  static Future<Uint8List> build(
      DateTime date, List<DayBookReportSection> sections) async {
    final document = pw.Document(
      title: 'Day Book - ${DateFormat('d MMM yyyy').format(date)}',
      author: 'Lotus ERP',
    );
    final theme = await LotusPdfTheme.reportTheme();
    document.addPage(pw.MultiPage(
      maxPages: 200,
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 30),
      theme: theme,
      header: (_) => _header(date),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('LOTUS ERP  |  Day Book',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
      build: (_) => [
        pw.SizedBox(height: 6),
        for (final section in sections) ...[
          if (section.rows.length <= 8)
            pw.Inseparable(
              child: pw.Column(children: [
                _sectionHeader(section),
                _sectionBody(section),
                pw.SizedBox(height: 9),
              ]),
            )
          else ...[
            _sectionHeader(section),
            _sectionBody(section),
            pw.SizedBox(height: 9),
          ],
        ],
      ],
    ));
    return document.save();
  }

  static pw.Widget _header(DateTime date) => pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFF172236),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('LOTUS ERP  /  DAY BOOK',
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
            pw.Text(DateFormat('d MMM yyyy').format(date),
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          ],
        ),
      );

  static pw.Widget _sectionHeader(DayBookReportSection section) => pw.Header(
        level: 1,
        child: pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 6),
          color: const PdfColor.fromInt(0xFFF6F0E2),
          child: pw.Text(section.title,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF142033),
              )),
        ),
      );

  static pw.Widget _sectionBody(DayBookReportSection section) =>
      section.rows.isEmpty
          ? pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(8, 3, 8, 5),
              child: pw.Text('No records for the selected day.',
                  style: const pw.TextStyle(fontSize: 8.5)),
            )
          : _table(section);

  static pw.Widget _table(DayBookReportSection section) {
    final fontSize = section.headers.length >= 9
        ? 6.7
        : section.headers.length >= 7
            ? 7.2
            : 8.2;
    return pw.TableHelper.fromTextArray(
      headers: section.headers,
      data: [
        for (final row in section.rows)
          [for (final value in row) value.display],
      ],
      headerStyle: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0xFF142033)),
      cellStyle: pw.TextStyle(
          fontSize: fontSize, color: const PdfColor.fromInt(0xFF142033)),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE7EBEF)),
      oddRowDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFAFAF8)),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    );
  }
}
