import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/pdf/lotus_pdf_theme.dart';
import '../../../models/finance/bank_book/bank_account_model.dart';
import '../../../models/finance/bank_book/bank_book_summary_model.dart';

class BankLedgerLine {
  const BankLedgerLine({
    required this.date,
    required this.balance,
    this.transaction,
    this.openingAdjustment = 0,
  });

  final DateTime date;
  final double balance;
  final BankTransactionModel? transaction;
  final double openingAdjustment;
}

class BankBookExportData {
  const BankBookExportData({
    required this.account,
    required this.periodStart,
    required this.periodEnd,
    required this.summary,
    required this.transactions,
  });

  final BankAccountModel account;
  final DateTime periodStart;
  final DateTime periodEnd;
  final BankBookSummaryModel summary;
  final List<BankTransactionModel> transactions;

  String get periodLabel =>
      '${DateFormat('d MMM yyyy').format(periodStart)} – ${DateFormat('d MMM yyyy').format(periodEnd)}';

  List<BankLedgerLine> get lines {
    final ordered = [...transactions]..sort((a, b) {
        final date = a.txnDate.compareTo(b.txnDate);
        return date != 0 ? date : a.id.compareTo(b.id);
      });
    final result = <BankLedgerLine>[];
    var balance = summary.openingBalance;
    final activation = DateTime(account.activeSince.year,
        account.activeSince.month, account.activeSince.day);
    var adjustmentApplied = summary.openingAdjustment == 0;
    void addAdjustment() {
      balance += summary.openingAdjustment;
      result.add(BankLedgerLine(
        date: activation,
        openingAdjustment: summary.openingAdjustment,
        balance: balance,
      ));
      adjustmentApplied = true;
    }

    for (final transaction in ordered) {
      if (!adjustmentApplied && !transaction.txnDate.isBefore(activation)) {
        addAdjustment();
      }
      balance +=
          transaction.isCredit ? transaction.amount : -transaction.amount;
      result.add(BankLedgerLine(
        date: transaction.txnDate,
        transaction: transaction,
        balance: balance,
      ));
    }
    if (!adjustmentApplied) addAdjustment();
    if ((balance - summary.closingBalance).abs() > 0.01) {
      throw StateError('Bank ledger export does not reconcile.');
    }
    return List.unmodifiable(result);
  }
}

class BankBookExportService {
  BankBookExportService._();

  static Future<String?> exportCsv(BankBookExportData data) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Bank Ledger',
      fileName: _fileName(data, 'csv'),
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      lockParentWindow: true,
    );
    if (path == null) return null;
    final output = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(output).writeAsString(buildCsv(data), flush: true);
    return output;
  }

  static Future<void> printPdf(BankBookExportData data) async {
    final bytes = await buildPdf(data);
    await Printing.layoutPdf(
      name: _fileName(data, 'pdf'),
      onLayout: (_) async => bytes,
    );
  }

  static String buildCsv(BankBookExportData data) {
    final rows = <List<String>>[
      [
        'Lotus ERP Bank Ledger',
        data.account.accountName,
        data.account.accountNumberMasked,
        data.periodLabel
      ],
      [
        'Date',
        'Transaction ID',
        'Category',
        'Party',
        'Payment Mode',
        'Reference',
        'Description',
        'Credit',
        'Debit',
        'Balance'
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
        '',
        _amount(data.summary.openingBalance)
      ],
      for (final line in data.lines)
        if (line.transaction case final txn?)
          [
            DateFormat('dd-MM-yyyy HH:mm').format(line.date),
            txn.txnId,
            txn.categoryLabel,
            txn.partyName ?? '',
            txn.paymentMode.displayLabel,
            txn.referenceId ?? '',
            txn.description ?? '',
            txn.isCredit ? _amount(txn.amount) : '',
            txn.isDebit ? _amount(txn.amount) : '',
            _amount(line.balance)
          ]
        else
          [
            DateFormat('dd-MM-yyyy').format(line.date),
            '',
            'New account opening balance',
            '',
            '',
            '',
            '',
            '',
            '',
            _amount(line.balance)
          ],
      [
        '',
        '',
        'Period totals',
        '',
        '',
        '',
        '',
        _amount(data.summary.totalCredit),
        _amount(data.summary.totalDebit),
        _amount(data.summary.closingBalance)
      ],
    ];
    return '${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}\r\n';
  }

  static Future<Uint8List> buildPdf(BankBookExportData data) async {
    final document = pw.Document(
      title: 'Bank Ledger - ${data.account.accountName} - ${data.periodLabel}',
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
        pw.Text('LOTUS ERP  |  BANK LEDGER',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text(
            '${data.account.accountName}  ·  ${data.account.accountNumberMasked}'),
        pw.Text(data.periodLabel),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: const [
            'Date',
            'Transaction ID',
            'Category / Party',
            'Mode / Reference',
            'Credit',
            'Debit',
            'Balance'
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
            for (final line in data.lines)
              if (line.transaction case final txn?)
                [
                  DateFormat('dd MMM yyyy HH:mm').format(line.date),
                  txn.txnId,
                  '${txn.categoryLabel}${txn.partyName == null ? '' : ' / ${txn.partyName}'}',
                  '${txn.paymentMode.displayLabel}${txn.referenceId == null ? '' : ' / ${txn.referenceId}'}',
                  txn.isCredit ? _money(txn.amount) : '',
                  txn.isDebit ? _money(txn.amount) : '',
                  _money(line.balance)
                ]
              else
                [
                  DateFormat('dd MMM yyyy').format(line.date),
                  '',
                  'New account opening balance',
                  '',
                  '',
                  '',
                  _money(line.balance)
                ],
            [
              '',
              '',
              'Period totals',
              '',
              _money(data.summary.totalCredit),
              _money(data.summary.totalDebit),
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

  static String _fileName(BankBookExportData data, String extension) =>
      'bank-ledger-${data.account.id}-${DateFormat('yyyyMMdd').format(data.periodStart)}-${DateFormat('yyyyMMdd').format(data.periodEnd)}.$extension';

  static String _amount(double value) => value.toStringAsFixed(2);
  static String _money(double value) => 'Rs ${_amount(value)}';
  static String _csvCell(String value) {
    final unsafe =
        value.startsWith(RegExp(r'[=+@\-]')) && double.tryParse(value) == null;
    final safe = unsafe ? "'$value" : value;
    return '"${safe.replaceAll('"', '""')}"';
  }
}
