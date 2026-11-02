import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/pdf/lotus_pdf_theme.dart';
import '../../../models/finance/cash_book/cash_book_summary_model.dart';
import '../../../models/finance/cash_book/cash_transaction_model.dart';

class CashBookExportData {
  const CashBookExportData({
    required this.periodStart,
    required this.periodEnd,
    required this.summary,
    required this.transactions,
    required this.runningBalances,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final CashBookSummaryModel summary;
  final List<CashTransactionModel> transactions;
  final Map<int, double> runningBalances;

  String get periodLabel {
    final format = DateFormat('d MMM yyyy');
    final start = format.format(periodStart);
    final end = format.format(periodEnd);
    return start == end ? start : '$start - $end';
  }

  List<CashTransactionModel> get chronologicalTransactions =>
      [...transactions]..sort((a, b) {
          final dateOrder = a.txnDate.compareTo(b.txnDate);
          return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
        });
}

class CashBookExportService {
  CashBookExportService._();

  static Future<String?> exportCsv(CashBookExportData data) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Account Book Cash Ledger',
      fileName: _fileName(data, 'csv'),
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      lockParentWindow: true,
    );
    if (path == null) return null;
    final exportPath = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(exportPath).writeAsString(buildCsv(data), flush: true);
    return exportPath;
  }

  static Future<void> printPdf(CashBookExportData data) async {
    final bytes = await buildPdf(data);
    await Printing.layoutPdf(
      name: _fileName(data, 'pdf'),
      onLayout: (_) async => bytes,
    );
  }

  static String buildCsv(CashBookExportData data) {
    final rows = <List<String>>[
      ['Lotus ERP Account Book - Cash', data.periodLabel],
      [
        'Date',
        'Transaction ID',
        'Category',
        'Party',
        'Reference',
        'Description',
        'Cash In',
        'Cash Out',
        'Running Balance'
      ],
      [
        '',
        '',
        'Opening balance',
        '',
        '',
        '',
        '',
        '',
        _amount(data.summary.openingBalance)
      ],
      for (final txn in data.chronologicalTransactions)
        [
          DateFormat('dd-MM-yyyy HH:mm').format(txn.txnDate),
          txn.txnId,
          txn.categoryLabel,
          txn.partyName ?? '',
          txn.referenceId ?? '',
          txn.description ?? '',
          txn.isIncome ? _amount(txn.amount) : '',
          txn.isExpense ? _amount(txn.amount) : '',
          _amount(data.runningBalances[txn.id]!),
        ],
      [
        '',
        '',
        'Period totals',
        '',
        '',
        '',
        _amount(data.summary.totalIncome),
        _amount(data.summary.totalExpense),
        _amount(data.summary.closingBalance)
      ],
    ];
    return '${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}\r\n';
  }

  static Future<Uint8List> buildPdf(CashBookExportData data) async {
    final document = pw.Document(
      title: 'Account Book - Cash - ${data.periodLabel}',
      author: 'Lotus ERP',
      theme: await LotusPdfTheme.reportTheme(),
    );
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (_) => [
        pw.Text('LOTUS ERP  |  ACCOUNT BOOK - CASH',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(data.periodLabel),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headers: const [
            'Date',
            'Transaction ID',
            'Category / Party',
            'Reference',
            'Cash In',
            'Cash Out',
            'Balance',
          ],
          data: [
            [
              '',
              '',
              'Opening balance',
              '',
              '',
              '',
              _money(data.summary.openingBalance)
            ],
            for (final txn in data.chronologicalTransactions)
              [
                DateFormat('dd MMM yyyy HH:mm').format(txn.txnDate),
                txn.txnId,
                '${txn.categoryLabel}${txn.partyName == null ? '' : ' / ${txn.partyName}'}',
                txn.referenceId ?? '',
                txn.isIncome ? _money(txn.amount) : '',
                txn.isExpense ? _money(txn.amount) : '',
                _money(data.runningBalances[txn.id]!),
              ],
            [
              '',
              '',
              'Period totals',
              '',
              _money(data.summary.totalIncome),
              _money(data.summary.totalExpense),
              _money(data.summary.closingBalance)
            ],
          ],
          headerStyle:
              pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1EDE4)),
          cellPadding: const pw.EdgeInsets.all(5),
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        ),
      ],
    ));
    return document.save();
  }

  static String _fileName(CashBookExportData data, String extension) =>
      'account-book-cash-${DateFormat('yyyyMMdd').format(data.periodStart)}-${DateFormat('yyyyMMdd').format(data.periodEnd)}.$extension';

  static String _amount(double value) => value.toStringAsFixed(2);
  static String _money(double value) => 'Rs ${_amount(value)}';

  static String _csvCell(String value) {
    final unsafePrefix =
        value.startsWith(RegExp(r'[=+@\-]')) && double.tryParse(value) == null;
    final safe = unsafePrefix ? "'$value" : value;
    return '"${safe.replaceAll('"', '""')}"';
  }
}
