import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';

class CustomerMetalPurchaseReportPrintService {
  CustomerMetalPurchaseReportPrintService._();

  static Future<void> printReport({
    required String periodLabel,
    required CustomerMetalPurchaseDashboardSummary dashboard,
    required Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
        metalSummaries,
    required List<CustomerMetalPurchaseEntry> entries,
  }) async {
    await Printing.layoutPdf(
      name: 'customer-metal-purchase-report-$periodLabel.pdf',
      format: PdfPageFormat.a4.landscape,
      onLayout: (format) => buildReportBytes(
        pageFormat: format,
        periodLabel: periodLabel,
        dashboard: dashboard,
        metalSummaries: metalSummaries,
        entries: entries,
      ),
    );
  }

  static Future<Uint8List> buildReportBytes({
    required PdfPageFormat pageFormat,
    required String periodLabel,
    required CustomerMetalPurchaseDashboardSummary dashboard,
    required Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
        metalSummaries,
    required List<CustomerMetalPurchaseEntry> entries,
  }) async {
    final document = pw.Document(
      title: 'Customer Metal Purchase Report',
      author: 'Lotus ERP',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _header(periodLabel),
          pw.SizedBox(height: 12),
          _dashboard(dashboard),
          pw.SizedBox(height: 12),
          _metalSummary(metalSummaries),
          pw.SizedBox(height: 14),
          _ledger(entries),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
      ),
    );

    return document.save();
  }

  static pw.Widget _header(String periodLabel) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Customer Metal Purchase Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              periodLabel,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Text(
          DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _dashboard(CustomerMetalPurchaseDashboardSummary summary) {
    final metrics = [
      ['Purchase Value', _amount(summary.amount)],
      ['Paid', _amount(summary.paidAmount)],
      ['Pending', _amount(summary.pendingAmount)],
      ['Fine Weight', _weight(summary.fineWeight)],
      ['Vouchers', summary.voucherCount.toString()],
      ['Sellers', summary.customerCount.toString()],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            for (final metric in metrics)
              pw.Padding(
                padding: const pw.EdgeInsets.all(7),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      metric.first,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      metric.last,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _metalSummary(
    Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
        summaries,
  ) {
    final rows = summaries.entries.where((entry) => entry.value.hasBusiness);
    if (rows.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Metal Summary'),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          headerStyle:
              pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding: const pw.EdgeInsets.all(5),
          headers: const [
            'Metal',
            'Net Wt',
            'Fine Wt',
            'Value',
            'Paid',
            'Pending',
            'Lines',
            'Sellers',
          ],
          data: [
            for (final entry in rows)
              [
                entry.key.label,
                _weight(entry.value.netWeight),
                _weight(entry.value.fineWeight),
                _amount(entry.value.amount),
                _amount(entry.value.paidAmount),
                _amount(entry.value.pendingAmount),
                entry.value.entryCount.toString(),
                entry.value.customerCount.toString(),
              ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _ledger(List<CustomerMetalPurchaseEntry> entries) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Purchase Ledger'),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.45),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          headerStyle:
              pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          headers: const [
            'S.No',
            'Seller',
            'Invoice',
            'Date',
            'Metal',
            'Net',
            'Fine',
            'Value',
            'Paid',
            'Pending',
            'Status',
            'Photo',
          ],
          data: [
            for (var index = 0; index < entries.length; index++)
              [
                '${index + 1}',
                entries[index].customerName,
                entries[index].referenceNo,
                DateFormat('dd MMM yyyy').format(entries[index].date),
                entries[index].metalType,
                _weight(entries[index].netWeight),
                _weight(entries[index].fineWeight),
                _amount(entries[index].amount),
                _amount(entries[index].paidAmount),
                _amount(entries[index].pendingAmount),
                entries[index].resolvedPaymentStatus,
                entries[index].hasSellerPhoto ? 'Yes' : 'No',
              ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        value,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static String _amount(double value) {
    return 'Rs. ${NumberFormat('#,##,##0.00', 'en_IN').format(value)}';
  }

  static String _weight(double value) {
    return '${value.toStringAsFixed(3)} g';
  }
}
