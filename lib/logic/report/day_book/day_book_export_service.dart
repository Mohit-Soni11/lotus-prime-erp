import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../models/reports/day_book/day_book_expense_classification.dart';
import '../../../models/reports/day_book/day_book_money_flow.dart';
import 'package:flutter/foundation.dart';

class DayBookExportService {
  DayBookExportService._();

  static Future<void> previewPdf(DayBookSummary summary) async {
    final bytes = await buildPdf(summary);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<bool> sharePdf(DayBookSummary summary) async {
    final bytes = await buildPdf(summary);
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
    await File(exportPath).writeAsString(buildCsv(summary));
    return exportPath;
  }

  @visibleForTesting
  static Future<Uint8List> buildPdf(DayBookSummary summary) async {
    final document = pw.Document(
      title: 'Day Book - ${_date(summary.date)}',
      author: 'Lotus ERP',
    );
    final flow = summary.moneyFlow;

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
          if (flow != null) ...[
            _pdfSection('Posted Money Position', const [
              'Metric',
              'Value'
            ], [
              ['Opening Cash', _money(flow.openingCash)],
              ['Opening Bank', _money(flow.openingBank)],
              ['Opening Total', _money(flow.openingTotal)],
              ['Money In', _money(flow.moneyIn)],
              ['Money Out', _money(flow.moneyOut)],
              ['Cash In', _money(flow.cashIn)],
              ['Cash Out', _money(flow.cashOut)],
              ['Bank In', _money(flow.bankIn)],
              ['Bank Out', _money(flow.bankOut)],
              ['Closing Cash', _money(flow.closingCash)],
              ['Closing Bank', _money(flow.closingBank)],
              ['Closing Total', _money(flow.closingTotal)],
              ['Internal Transfer In', _money(flow.internalIn)],
              ['Internal Transfer Out', _money(flow.internalOut)],
            ]),
            pw.SizedBox(height: 14),
            _pdfSection('Money In by Source', const ['Source', 'Amount'],
                _breakdownRows(flow.bySource(incoming: true))),
            pw.SizedBox(height: 14),
            _pdfSection('Money Out by Source', const ['Source', 'Amount'],
                _breakdownRows(flow.bySource(incoming: false))),
            pw.SizedBox(height: 14),
            _pdfSection('Money In by Mode', const ['Mode', 'Amount'],
                _breakdownRows(flow.byMode(incoming: true))),
            pw.SizedBox(height: 14),
            _pdfSection('Money Out by Mode', const ['Mode', 'Amount'],
                _breakdownRows(flow.byMode(incoming: false))),
            pw.SizedBox(height: 14),
            _pdfSection('Bank In by Account', const ['Account', 'Amount'],
                _breakdownRows(flow.byBankAccount(incoming: true))),
            pw.SizedBox(height: 14),
            _pdfSection('Bank Out by Account', const ['Account', 'Amount'],
                _breakdownRows(flow.byBankAccount(incoming: false))),
            pw.SizedBox(height: 14),
            _pdfSection(
                'Bank Receipt Reconciliation',
                const ['Status', 'Amount'],
                _breakdownRows(flow.byBankReconciliation(incoming: true))),
            pw.SizedBox(height: 14),
            _pdfSection('Payment Classification', const [
              'Purpose',
              'Amount'
            ], [
              for (final entry
                  in DayBookExpenseClassification.totals(flow).entries)
                [entry.key.label, _money(entry.value)],
            ]),
            pw.SizedBox(height: 14),
          ],
          _pdfSection(
            'Physical Cash and Metal Position',
            const ['Metric', 'Value'],
            [
              ['Opening Cash', _money(summary.openingCash)],
              ['Cash In', _money(summary.cashReceived)],
              ['Cash Out', _money(summary.cashPaid)],
              ['Net Cash Flow', _signedMoney(summary.netCash)],
              ['Closing Cash', _money(summary.closingCash)],
              [
                'Opening Gold',
                summary.metalPositionVerified
                    ? _weight(summary.openingGoldGrams)
                    : 'Unverified'
              ],
              [
                'Closing Gold',
                summary.metalPositionVerified
                    ? _weight(summary.closingGold)
                    : 'Unverified'
              ],
              [
                'Opening Silver',
                summary.metalPositionVerified
                    ? _weight(summary.openingSilverGrams)
                    : 'Unverified'
              ],
              [
                'Closing Silver',
                summary.metalPositionVerified
                    ? _weight(summary.closingSilver)
                    : 'Unverified'
              ],
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
              ['CGST', _money(summary.cashIn.gstSales.cgst)],
              ['SGST', _money(summary.cashIn.gstSales.sgst)],
              ['IGST', _money(summary.cashIn.gstSales.igst)],
              ['Due Collection', _money(summary.cashIn.dueCollection)],
            ],
          ),
          pw.SizedBox(height: 14),
          if (summary.documents.isNotEmpty) ...[
            _pdfSection(
              'Source Documents',
              const [
                'Kind',
                'Number',
                'Status',
                'Value',
                'Tax',
                'Collection',
                'Outstanding'
              ],
              [
                for (final document in summary.documents)
                  [
                    document.kind.label,
                    document.number,
                    document.status,
                    _money(document.amount),
                    document.tax == null ? '-' : _money(document.tax!),
                    document.collection == null
                        ? '-'
                        : _money(document.collection!),
                    document.outstanding == null
                        ? '-'
                        : _money(document.outstanding!),
                  ],
              ],
            ),
            pw.SizedBox(height: 14),
          ],
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
          if (summary.stockMovements.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfSection(
              'Posted Owned Stock Movement (Position Unverified)',
              const [
                'Metal',
                'Purity',
                'Item',
                'Source',
                'Pieces',
                'Gross',
                'Net',
                'Fine'
              ],
              [
                for (final movement in summary.stockMovements)
                  [
                    movement.metal,
                    movement.puritySnapshot ?? 'Unverified',
                    movement.itemName,
                    '${movement.sourceNumber ?? movement.sourceId}${movement.sourceLineNo == null ? '' : ' #${movement.sourceLineNo}'}',
                    movement.quantityDelta.toString(),
                    _weight(movement.grossWeightDelta),
                    _weight(movement.netWeightDelta),
                    _weight(movement.fineWeightDelta),
                  ],
              ],
            ),
          ],
          if (summary.custodyPosition case final custody?
              when custody.lines.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfSection(
              'Girvi Custody (Customer Property)',
              const [
                'Stage',
                'Ticket',
                'Metal',
                'Item',
                'Pieces',
                'Gross',
                'Net',
                'Fine'
              ],
              [
                for (final (stage, lines) in [
                  ('Opening', custody.opening),
                  ('Received', custody.received),
                  ('Released', custody.released),
                  (
                    custody.closingVerified ? 'Closing' : 'Closing Unverified',
                    custody.closing
                  ),
                ])
                  for (final line in lines)
                    [
                      stage,
                      line.ticketNo,
                      '${line.metal} ${line.purity}',
                      line.itemName,
                      line.pieces.toString(),
                      _weight(line.grossWeight),
                      _weight(line.netWeight),
                      line.fineWeight == null
                          ? 'Unverified'
                          : _weight(line.fineWeight!),
                    ],
              ],
            ),
          ],
          if (flow != null && flow.entries.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              'Posted Transactions',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Time',
                'In / Out',
                'Source',
                'Mode / Account',
                'Reference',
                'Amount',
              ],
              data: [
                for (final entry in flow.entries)
                  [
                    DateFormat('HH:mm').format(entry.date),
                    entry.incoming ? 'IN' : 'OUT',
                    entry.category,
                    '${entry.paymentMode}${entry.accountName == null ? '' : ' / ${entry.accountName}'}',
                    entry.referenceId ?? entry.transactionId,
                    _money(entry.amount),
                  ],
              ],
              headerStyle:
                  pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF1EDE4),
              ),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.all(4),
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

  static List<List<String>> _breakdownRows(Map<String, double> values) {
    if (values.isEmpty) {
      return [
        ['No movements', _money(0)]
      ];
    }
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final entry in entries) [entry.key, _money(entry.value)],
    ];
  }

  @visibleForTesting
  static String buildCsv(DayBookSummary summary) {
    final rows = <List<String>>[
      ['Section', 'Metric', 'Value'],
      ['Report', 'Date', _date(summary.date)],
      ['Opening Position', 'Cash', summary.openingCash.toStringAsFixed(2)],
      [
        'Opening Position',
        'Gold (g)',
        summary.metalPositionVerified
            ? summary.openingGoldGrams.toStringAsFixed(3)
            : 'Unverified',
      ],
      [
        'Opening Position',
        'Silver (g)',
        summary.metalPositionVerified
            ? summary.openingSilverGrams.toStringAsFixed(3)
            : 'Unverified',
      ],
      ['Cash Movement', 'Cash In', summary.cashReceived.toStringAsFixed(2)],
      ['Cash Movement', 'Cash Out', summary.cashPaid.toStringAsFixed(2)],
      ['Cash Movement', 'Net Cash', summary.netCash.toStringAsFixed(2)],
      ['Sales', 'GST Invoices', summary.totalGstBills.toString()],
      ['Sales', 'Regular Invoices', summary.totalNonGstBills.toString()],
      [
        'Sales',
        'GST Collected',
        summary.totalGstCollected.toStringAsFixed(2),
      ],
      ['Sales', 'CGST', summary.cashIn.gstSales.cgst.toStringAsFixed(2)],
      ['Sales', 'SGST', summary.cashIn.gstSales.sgst.toStringAsFixed(2)],
      ['Sales', 'IGST', summary.cashIn.gstSales.igst.toStringAsFixed(2)],
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

    final flow = summary.moneyFlow;
    for (final document in summary.documents) {
      final section = 'Source Document ${document.kind.label}';
      rows.add([section, '${document.number} Status', document.status]);
      rows.add([
        section,
        '${document.number} Value',
        document.amount.toStringAsFixed(2)
      ]);
      rows.add([
        section,
        '${document.number} Tax',
        document.tax?.toStringAsFixed(2) ?? 'Unverified'
      ]);
      rows.add([
        section,
        '${document.number} Collection',
        document.collection?.toStringAsFixed(2) ?? 'Unverified'
      ]);
      rows.add([
        section,
        '${document.number} Outstanding',
        document.outstanding?.toStringAsFixed(2) ?? 'Unverified'
      ]);
    }
    if (flow != null) {
      rows.addAll([
        ['Money Position', 'Opening Cash', flow.openingCash.toStringAsFixed(2)],
        ['Money Position', 'Opening Bank', flow.openingBank.toStringAsFixed(2)],
        [
          'Money Position',
          'Opening Total',
          flow.openingTotal.toStringAsFixed(2)
        ],
        ['Money Position', 'Money In', flow.moneyIn.toStringAsFixed(2)],
        ['Money Position', 'Money Out', flow.moneyOut.toStringAsFixed(2)],
        ['Money Position', 'Cash In', flow.cashIn.toStringAsFixed(2)],
        ['Money Position', 'Cash Out', flow.cashOut.toStringAsFixed(2)],
        ['Money Position', 'Bank In', flow.bankIn.toStringAsFixed(2)],
        ['Money Position', 'Bank Out', flow.bankOut.toStringAsFixed(2)],
        ['Money Position', 'Closing Cash', flow.closingCash.toStringAsFixed(2)],
        ['Money Position', 'Closing Bank', flow.closingBank.toStringAsFixed(2)],
        [
          'Money Position',
          'Closing Total',
          flow.closingTotal.toStringAsFixed(2)
        ],
        [
          'Money Position',
          'Internal Transfer In',
          flow.internalIn.toStringAsFixed(2)
        ],
        [
          'Money Position',
          'Internal Transfer Out',
          flow.internalOut.toStringAsFixed(2)
        ],
      ]);
      _appendBreakdown(
          rows, 'Money In by Source', flow.bySource(incoming: true));
      _appendBreakdown(
          rows, 'Money Out by Source', flow.bySource(incoming: false));
      _appendBreakdown(rows, 'Money In by Mode', flow.byMode(incoming: true));
      _appendBreakdown(rows, 'Money Out by Mode', flow.byMode(incoming: false));
      _appendBreakdown(
          rows, 'Bank In by Account', flow.byBankAccount(incoming: true));
      _appendBreakdown(
          rows, 'Bank Out by Account', flow.byBankAccount(incoming: false));
      _appendBreakdown(rows, 'Bank Receipt Reconciliation',
          flow.byBankReconciliation(incoming: true));
      _appendBreakdown(rows, 'Bank Payment Reconciliation',
          flow.byBankReconciliation(incoming: false));
      for (final entry in DayBookExpenseClassification.totals(flow).entries) {
        rows.add([
          'Payment Classification',
          entry.key.label,
          entry.value.toStringAsFixed(2)
        ]);
      }
      _appendTransactions(rows, flow);
    }

    for (final movement in summary.stockMovements) {
      final source =
          '${movement.sourceNumber ?? movement.sourceId}${movement.sourceLineNo == null ? '' : ' #${movement.sourceLineNo}'}';
      final key =
          '${movement.metal} ${movement.puritySnapshot ?? '(purity unverified)'} / ${movement.itemName} / $source';
      rows.add(
          ['Owned Stock Movement', '$key Pieces', '${movement.quantityDelta}']);
      rows.add([
        'Owned Stock Movement',
        '$key Gross (g)',
        movement.grossWeightDelta.toStringAsFixed(3)
      ]);
      rows.add([
        'Owned Stock Movement',
        '$key Net (g)',
        movement.netWeightDelta.toStringAsFixed(3)
      ]);
      rows.add([
        'Owned Stock Movement',
        '$key Fine (g)',
        movement.fineWeightDelta.toStringAsFixed(3)
      ]);
    }

    if (summary.custodyPosition case final custody?) {
      for (final (stage, lines) in [
        ('Opening', custody.opening),
        ('Received', custody.received),
        ('Released', custody.released),
        (
          custody.closingVerified ? 'Closing' : 'Closing Unverified',
          custody.closing
        ),
      ]) {
        for (final line in lines) {
          final key =
              '${line.ticketNo} / ${line.metal} ${line.purity} / ${line.itemName}';
          rows.add(['Girvi Custody $stage', '$key Pieces', '${line.pieces}']);
          rows.add([
            'Girvi Custody $stage',
            '$key Gross (g)',
            line.grossWeight.toStringAsFixed(3)
          ]);
          rows.add([
            'Girvi Custody $stage',
            '$key Net (g)',
            line.netWeight.toStringAsFixed(3)
          ]);
          rows.add([
            'Girvi Custody $stage',
            '$key Fine (g)',
            line.fineWeight?.toStringAsFixed(3) ?? 'Unverified'
          ]);
        }
      }
    }

    rows.addAll([
      ['Closing Position', 'Cash', summary.closingCash.toStringAsFixed(2)],
      [
        'Closing Position',
        'Gold (g)',
        summary.metalPositionVerified
            ? summary.closingGold.toStringAsFixed(3)
            : 'Unverified'
      ],
      [
        'Closing Position',
        'Silver (g)',
        summary.metalPositionVerified
            ? summary.closingSilver.toStringAsFixed(3)
            : 'Unverified',
      ],
    ]);

    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  static void _appendBreakdown(
      List<List<String>> rows, String section, Map<String, double> values) {
    for (final entry in values.entries) {
      rows.add([section, entry.key, entry.value.toStringAsFixed(2)]);
    }
  }

  static void _appendTransactions(
      List<List<String>> rows, DayBookMoneyFlow flow) {
    for (final entry in flow.entries) {
      final section = 'Transaction ${entry.transactionId}';
      rows.addAll([
        [section, 'Date', DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.date)],
        [section, 'Direction', entry.incoming ? 'IN' : 'OUT'],
        [section, 'Amount', entry.amount.toStringAsFixed(2)],
        [section, 'Source', entry.category],
        [section, 'Payment Mode', entry.paymentMode],
        [section, 'Account', entry.accountName ?? 'Physical Cash'],
        [section, 'Reference', entry.referenceId ?? ''],
        [section, 'Internal Transfer', entry.isInternalTransfer ? 'Yes' : 'No'],
      ]);
    }
  }

  static String _csvCell(String value) {
    final trimmed = value.trimLeft();
    final unsafe = trimmed.isNotEmpty &&
        ('=+@'.contains(trimmed[0]) ||
            (trimmed[0] == '-' && double.tryParse(trimmed) == null));
    final safe = unsafe ? "'$value" : value;
    return '"${safe.replaceAll('"', '""')}"';
  }

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
}
