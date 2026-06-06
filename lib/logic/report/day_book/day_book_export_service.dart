import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../models/reports/day_book/day_book_models.dart';

class DayBookExportService {
  DayBookExportService._();

  static Future<void> previewPdf(DayBookSummary summary) async {
    final bytes = await _buildPdf(summary);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<bool> sharePdf(DayBookSummary summary) async {
    final bytes = await _buildPdf(summary);
    return Printing.sharePdf(
      bytes: bytes,
      filename: _fileName(summary.date, 'pdf'),
      subject: 'Day Book - ${_date(summary.date)}',
      body: 'Daily operating statement for ${_date(summary.date)}.',
    );
  }

  static Future<String?> exportCsv(DayBookSummary summary) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Day Book Table',
      fileName: _fileName(summary.date, 'csv'),
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      lockParentWindow: true,
    );
    if (path == null) return null;

    final exportPath = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(exportPath).writeAsString(_buildCsv(summary));
    return exportPath;
  }

  static Future<Uint8List> _buildPdf(DayBookSummary summary) async {
    final document = pw.Document(
      title: 'Day Book - ${_date(summary.date)}',
      author: 'Lotus ERP',
    );
    final metalRows = _metalRows(summary);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1F2937),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LOTUS ERP',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey300,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'DAY BOOK',
                      style: pw.TextStyle(
                        fontSize: 19,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  _date(summary.date),
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _pdfSection(
            'Daily Position',
            const ['Metric', 'Value'],
            [
              ['Opening Cash', _money(summary.openingCash)],
              ['Cash In', _money(summary.cashIn.total)],
              ['Cash Out', _money(summary.cashOut.total)],
              ['Net Cash Flow', _signedMoney(summary.netCash)],
              ['Closing Cash', _money(summary.closingCash)],
              ['Opening Gold', _weight(summary.openingGoldGrams)],
              ['Closing Gold', _weight(summary.closingGold)],
              ['Opening Silver', _weight(summary.openingSilverGrams)],
              ['Closing Silver', _weight(summary.closingSilver)],
            ],
          ),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Sales and Tax',
            const ['Metric', 'Value'],
            [
              ['GST Invoices', summary.totalGstBills.toString()],
              ['Regular Invoices', summary.totalNonGstBills.toString()],
              [
                'GST Invoice Value',
                _money(summary.cashIn.gstSales.finalAmount),
              ],
              [
                'Regular Invoice Value',
                _money(summary.cashIn.nonGstSales.totalAmount),
              ],
              ['GST Collected', _money(summary.totalGstCollected)],
              ['Due Collection', _money(summary.cashIn.dueCollection)],
            ],
          ),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Payment Mix',
            const ['Mode', 'Amount'],
            [
              ['Cash', _money(summary.paymentBreakup.cash)],
              ['UPI', _money(summary.paymentBreakup.upi)],
              ['Card', _money(summary.paymentBreakup.card)],
              ['Bank', _money(summary.paymentBreakup.bank)],
              ['Cheque', _money(summary.paymentBreakup.cheque)],
            ],
          ),
          if (metalRows.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfSection(
              'Metal Movement',
              const ['Metal', 'Purity', 'Received', 'Issued', 'Net'],
              metalRows,
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            'Generated ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return document.save();
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
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF1EDE4),
          ),
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
            width: 0.5,
          ),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 5,
          ),
        ),
      ],
    );
  }

  static List<List<String>> _metalRows(DayBookSummary summary) {
    final incoming = summary.metalIn.total;
    final outgoing = summary.metalOut.total;
    final metals = <String>{...incoming.metals, ...outgoing.metals}.toList()
      ..sort();
    final rows = <List<String>>[];

    for (final metal in metals) {
      final purities = <String>{
        ...incoming.puritiesFor(metal).keys,
        ...outgoing.puritiesFor(metal).keys,
      }.toList()
        ..sort();
      for (final purity in purities) {
        final received = incoming.puritiesFor(metal)[purity] ?? 0;
        final issued = outgoing.puritiesFor(metal)[purity] ?? 0;
        rows.add([
          metal,
          purity,
          _weight(received),
          _weight(issued),
          _signedWeight(received - issued),
        ]);
      }
    }
    return rows;
  }

  static String _buildCsv(DayBookSummary summary) {
    final rows = <List<String>>[
      ['Section', 'Metric', 'Value'],
      ['Report', 'Date', _date(summary.date)],
      ['Opening Position', 'Cash', summary.openingCash.toStringAsFixed(2)],
      [
        'Opening Position',
        'Gold (g)',
        summary.openingGoldGrams.toStringAsFixed(3),
      ],
      [
        'Opening Position',
        'Silver (g)',
        summary.openingSilverGrams.toStringAsFixed(3),
      ],
      ['Cash Movement', 'Cash In', summary.cashIn.total.toStringAsFixed(2)],
      ['Cash Movement', 'Cash Out', summary.cashOut.total.toStringAsFixed(2)],
      ['Cash Movement', 'Net Cash', summary.netCash.toStringAsFixed(2)],
      ['Sales', 'GST Invoices', summary.totalGstBills.toString()],
      ['Sales', 'Regular Invoices', summary.totalNonGstBills.toString()],
      [
        'Sales',
        'GST Collected',
        summary.totalGstCollected.toStringAsFixed(2),
      ],
      ['Payment Mix', 'Cash', summary.paymentBreakup.cash.toStringAsFixed(2)],
      ['Payment Mix', 'UPI', summary.paymentBreakup.upi.toStringAsFixed(2)],
      ['Payment Mix', 'Card', summary.paymentBreakup.card.toStringAsFixed(2)],
      ['Payment Mix', 'Bank', summary.paymentBreakup.bank.toStringAsFixed(2)],
      [
        'Payment Mix',
        'Cheque',
        summary.paymentBreakup.cheque.toStringAsFixed(2),
      ],
    ];

    for (final row in _metalRows(summary)) {
      rows.add([
        'Metal Movement',
        '${row[0]} ${row[1]} Received',
        row[2],
      ]);
      rows.add([
        'Metal Movement',
        '${row[0]} ${row[1]} Issued',
        row[3],
      ]);
      rows.add(['Metal Movement', '${row[0]} ${row[1]} Net', row[4]]);
    }

    rows.addAll([
      ['Closing Position', 'Cash', summary.closingCash.toStringAsFixed(2)],
      ['Closing Position', 'Gold (g)', summary.closingGold.toStringAsFixed(3)],
      [
        'Closing Position',
        'Silver (g)',
        summary.closingSilver.toStringAsFixed(3),
      ],
    ]);

    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  static String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

  static String _fileName(DateTime date, String extension) =>
      'day_book_${DateFormat('yyyyMMdd').format(date)}.$extension';

  static String _date(DateTime date) => DateFormat('d MMM yyyy').format(date);

  static String _money(double value) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: 'INR ',
        decimalDigits: 2,
      ).format(value);

  static String _signedMoney(double value) =>
      '${value >= 0 ? '+' : '-'}${_money(value.abs())}';

  static String _weight(double value) => '${value.toStringAsFixed(3)} g';

  static String _signedWeight(double value) =>
      '${value >= 0 ? '+' : '-'}${_weight(value.abs())}';
}
