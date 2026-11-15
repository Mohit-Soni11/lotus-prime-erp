import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/pdf/lotus_pdf_theme.dart';
import '../../../models/finance/account_book/account_book_month.dart';

class AccountBookExportService {
  AccountBookExportService._();

  static Future<String?> exportCsv(AccountBookMonth report) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Monthly Account Book',
      fileName: _fileName(report, 'csv'),
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      lockParentWindow: true,
    );
    if (path == null) return null;
    final output = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(output).writeAsString(buildCsv(report), flush: true);
    return output;
  }

  static Future<void> printPdf(AccountBookMonth report) async {
    final bytes = await buildPdf(report);
    await Printing.layoutPdf(
      name: _fileName(report, 'pdf'),
      onLayout: (_) async => bytes,
    );
  }

  static String buildCsv(AccountBookMonth report) {
    final rows = <List<String>>[
      [
        'Lotus ERP Monthly Account Book',
        DateFormat('MMMM yyyy').format(report.month)
      ],
      [
        'Date',
        'Time',
        'Type',
        'Activity',
        'Reference',
        'Detail',
        'Cash In',
        'Cash Out',
        'Bank In',
        'Bank Out',
        'Document / Opening Value',
        'Closing Cash',
        'Closing Bank'
      ],
      [
        '',
        '',
        'MONTH OPEN',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        _amount(report.money.openingCash),
        _amount(report.money.openingBank)
      ],
      for (final day in report.days) ...[
        for (final item in day.activities)
          [
            DateFormat('dd-MM-yyyy').format(item.date),
            DateFormat('HH:mm').format(item.date),
            item.type.name,
            item.title,
            item.reference,
            item.detail ?? '',
            item.type == AccountBookActivityType.money &&
                    item.isCash == true &&
                    item.incoming == true
                ? _amount(item.amount)
                : '',
            item.type == AccountBookActivityType.money &&
                    item.isCash == true &&
                    item.incoming == false
                ? _amount(item.amount)
                : '',
            item.type == AccountBookActivityType.money &&
                    item.isCash == false &&
                    item.incoming == true
                ? _amount(item.amount)
                : '',
            item.type == AccountBookActivityType.money &&
                    item.isCash == false &&
                    item.incoming == false
                ? _amount(item.amount)
                : '',
            (item.type == AccountBookActivityType.document ||
                    item.type == AccountBookActivityType.balance)
                ? _amount(item.amount)
                : '',
            '',
            '',
          ],
        [
          DateFormat('dd-MM-yyyy').format(day.date),
          '',
          'DAY CLOSE',
          '',
          '',
          '',
          _amount(day.cashIn),
          _amount(day.cashOut),
          _amount(day.bankIn),
          _amount(day.bankOut),
          '',
          _amount(day.closingCash),
          _amount(day.closingBank)
        ],
      ],
      [
        '',
        '',
        'MONTH CLOSE',
        '',
        '',
        '',
        _amount(report.money.cashIn),
        _amount(report.money.cashOut),
        _amount(report.money.bankIn),
        _amount(report.money.bankOut),
        '',
        _amount(report.money.closingCash),
        _amount(report.money.closingBank)
      ],
    ];
    return '${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}\r\n';
  }

  static Future<Uint8List> buildPdf(AccountBookMonth report) async {
    final document = pw.Document(
      title:
          'Monthly Account Book - ${DateFormat('MMMM yyyy').format(report.month)}',
      author: 'Lotus ERP',
      theme: await LotusPdfTheme.reportTheme(),
    );
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(26),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (_) => [
        pw.Text('LOTUS ERP  |  MONTHLY ACCOUNT BOOK',
            style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
        pw.Text(DateFormat('MMMM yyyy').format(report.month)),
        pw.SizedBox(height: 9),
        pw.Text(
            'Opening: Cash ${_money(report.money.openingCash)}  |  Bank ${_money(report.money.openingBank)}'),
        pw.Text(
            'Closing: Cash ${_money(report.money.closingCash)}  |  Bank ${_money(report.money.closingBank)}'),
        pw.Text(
            'External money in ${_money(report.money.moneyIn)}  |  out ${_money(report.money.moneyOut)}. Internal transfers excluded.'),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: const [
            'Date',
            'Type',
            'Activity / Reference',
            'Detail',
            'Cash In',
            'Cash Out',
            'Bank In',
            'Bank Out',
            'Value / Balance'
          ],
          data: [
            for (final day in report.days) ...[
              for (final item in day.activities)
                [
                  DateFormat('dd MMM HH:mm').format(item.date),
                  item.type.name.toUpperCase(),
                  '${item.title}\n${item.reference}',
                  item.detail ?? '',
                  _entryAmount(item, cash: true, incoming: true),
                  _entryAmount(item, cash: true, incoming: false),
                  _entryAmount(item, cash: false, incoming: true),
                  _entryAmount(item, cash: false, incoming: false),
                  (item.type == AccountBookActivityType.document ||
                              item.type == AccountBookActivityType.balance) &&
                          item.amount != null
                      ? _money(item.amount!)
                      : '',
                ],
              [
                DateFormat('dd MMM').format(day.date),
                'DAY CLOSE',
                '',
                '',
                _money(day.cashIn),
                _money(day.cashOut),
                _money(day.bankIn),
                _money(day.bankOut),
                'Cash ${_money(day.closingCash)}\nBank ${_money(day.closingBank)}'
              ],
            ],
          ],
          headerStyle:
              pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 7),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1EDE4)),
          cellPadding: const pw.EdgeInsets.all(4),
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
        ),
      ],
    ));
    return document.save();
  }

  static String _entryAmount(AccountBookActivity item,
          {required bool cash, required bool incoming}) =>
      item.type == AccountBookActivityType.money &&
              item.isCash == cash &&
              item.incoming == incoming &&
              item.amount != null
          ? _money(item.amount!)
          : '';

  static String _fileName(AccountBookMonth report, String extension) =>
      'account-book-${DateFormat('yyyy-MM').format(report.month)}.$extension';
  static String _amount(double? value) => value?.toStringAsFixed(2) ?? '';
  static String _money(double value) => 'Rs ${value.toStringAsFixed(2)}';

  static String _csvCell(String value) {
    final unsafe =
        value.startsWith(RegExp(r'[=+@\-]')) && double.tryParse(value) == null;
    final safe = unsafe ? "'$value" : value;
    return '"${safe.replaceAll('"', '""')}"';
  }
}
