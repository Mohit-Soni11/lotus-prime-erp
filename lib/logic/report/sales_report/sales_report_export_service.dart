import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/sales_report/sales_report_models.dart';

class SalesReportExportService {
  SalesReportExportService._();

  static Future<String?> exportCsv(SalesReportSnapshot snapshot) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Sales Report',
      fileName: _fileName(snapshot.filter),
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      lockParentWindow: true,
    );
    if (path == null) return null;

    final exportPath = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(exportPath).writeAsString(_buildCsv(snapshot));
    return exportPath;
  }

  static String _fileName(SalesReportFilter filter) {
    final start = DateFormat('yyyyMMdd').format(filter.startDate);
    final end = DateFormat('yyyyMMdd').format(filter.endDate);
    return 'lotus-sales-report-$start-$end.csv';
  }

  static String _buildCsv(SalesReportSnapshot snapshot) {
    final rows = <List<String>>[
      ['LOTUS ERP SALES REPORT'],
      ['From', _date(snapshot.filter.startDate)],
      ['To', _date(snapshot.filter.endDate)],
      ['Tax Filter', snapshot.filter.taxMode.name],
      ['Payment Filter', snapshot.filter.paymentFilter.name],
      ['Metal Filter', snapshot.filter.metalType],
      [],
      ['SUMMARY'],
      ['Invoices', '${snapshot.summary.invoiceCount}'],
      ['GST Invoices', '${snapshot.summary.gstInvoiceCount}'],
      ['Non-GST Invoices', '${snapshot.summary.nonGstInvoiceCount}'],
      ['Gross Amount', _money(snapshot.summary.grossAmount)],
      ['Discount', _money(snapshot.summary.discountAmount)],
      ['Taxable Amount', _money(snapshot.summary.taxableAmount)],
      ['GST Amount', _money(snapshot.summary.gstAmount)],
      ['Round Off', _money(snapshot.summary.roundOffAmount)],
      ['Final Amount', _money(snapshot.summary.finalAmount)],
      ['Paid Amount', _money(snapshot.summary.paidAmount)],
      ['Due Amount', _money(snapshot.summary.dueAmount)],
      ['Making Amount', _money(snapshot.summary.makingAmount)],
      ['Stock Cost', _money(snapshot.summary.stockCostAmount)],
      ['Profit', _money(snapshot.summary.profitAmount)],
      [],
      ['METAL SUMMARY'],
      [
        'Metal',
        'Invoices',
        'Items',
        'Pcs',
        'Gross Weight',
        'Net Weight',
        'Making',
        'Sales',
        'Cost',
        'Profit',
      ],
      for (final metal in snapshot.metals)
        [
          metal.metalType,
          '${metal.invoiceCount}',
          '${metal.itemCount}',
          '${metal.pieces}',
          _weight(metal.grossWeight),
          _weight(metal.netWeight),
          _money(metal.makingAmount),
          _money(metal.salesAmount),
          _money(metal.stockCostAmount),
          _money(metal.profitAmount),
        ],
      [],
      ['INVOICE LEDGER'],
      [
        'Invoice No',
        'Date',
        'Customer',
        'Mobile',
        'Type',
        'Metals',
        'Gross',
        'Discount',
        'Taxable',
        'GST',
        'Round Off',
        'Final',
        'Paid',
        'Due',
        'Cash',
        'UPI',
        'Card',
        'Advance',
      ],
      for (final invoice in snapshot.invoices)
        [
          invoice.billNo,
          _dateTime(invoice.billDate),
          invoice.customerName,
          invoice.mobile,
          invoice.isGst ? 'GST' : 'NON-GST',
          invoice.metalMix,
          _money(invoice.grossAmount),
          _money(invoice.discountAmount),
          _money(invoice.taxableAmount),
          _money(invoice.gstAmount),
          _money(invoice.roundOffAmount),
          _money(invoice.finalAmount),
          _money(invoice.paidAmount),
          _money(invoice.dueAmount),
          _money(invoice.cashAmount),
          _money(invoice.upiAmount),
          _money(invoice.cardAmount),
          _money(invoice.advanceAmount),
        ],
      [],
      ['ITEM LEDGER'],
      [
        'Invoice No',
        'Date',
        'Customer',
        'Metal',
        'Item',
        'HUID',
        'Purity',
        'Pcs',
        'Gross Weight',
        'Less Weight',
        'Net Weight',
        'Fine Weight',
        'Rate',
        'Making',
        'Item Total',
        'Stock SKU',
        'Stock Cost',
        'Profit',
      ],
      for (final item in snapshot.items)
        [
          item.billNo,
          _dateTime(item.billDate),
          item.customerName,
          item.metalType,
          item.itemName,
          item.huid,
          item.purity,
          '${item.quantity}',
          _weight(item.grossWeight),
          _weight(item.lessWeight),
          _weight(item.netWeight),
          _weight(item.fineWeight),
          _money(item.rate),
          _money(item.makingCharge),
          _money(item.itemTotal),
          item.stockSku,
          _money(item.stockCostAmount),
          _money(item.profitAmount),
        ],
    ];

    return rows.map(_csvRow).join('\n');
  }

  static String _csvRow(List<String> row) {
    return row.map((cell) {
      final escaped = cell.replaceAll('"', '""');
      return '"$escaped"';
    }).join(',');
  }

  static String _date(DateTime value) =>
      DateFormat('dd MMM yyyy').format(value);

  static String _dateTime(DateTime value) =>
      DateFormat('dd MMM yyyy hh:mm a').format(value);

  static String _money(double value) => value.toStringAsFixed(2);

  static String _weight(double value) => value.toStringAsFixed(3);
}
