import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/purchase/purchase_enums/purchase_enums.dart';
import 'purchase_entry_controller.dart';

class PurchaseVoucherPrintService {
  PurchaseVoucherPrintService._();

  static Future<void> printDraft(PurchaseEntryController ctrl) async {
    final doc = pw.Document();
    final createdAt = DateTime.now();
    final formattedDate =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    final lines = ctrl.items.where((item) => item.hasContent).toList();
    final sourceLabel = ctrl.purchaseSource == PurchaseSource.fromCustomer
        ? 'Seller Purchase'
        : 'Supplier Purchase';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Purchase Voucher',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(sourceLabel),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Voucher: ${ctrl.formattedPurchaseNo}'),
                  pw.Text(
                    'Date: $formattedDate',
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Counterparty',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(ctrl.nameCtrl.text.trim().isEmpty
                    ? '-'
                    : ctrl.nameCtrl.text.trim()),
                if (ctrl.mobileCtrl.text.trim().isNotEmpty)
                  pw.Text('Mobile: ${ctrl.mobileCtrl.text.trim()}'),
                if (ctrl.cityCtrl.text.trim().isNotEmpty)
                  pw.Text('Location: ${ctrl.cityCtrl.text.trim()}'),
                if (ctrl.gstCtrl.text.trim().isNotEmpty)
                  pw.Text('GST: ${ctrl.gstCtrl.text.trim()}'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
            headers: const [
              '#',
              'Metal',
              'Description',
              'Gross',
              'Less',
              'Net',
              'Purity',
              'Fine',
              'Rate',
              'Value',
            ],
            data: lines.asMap().entries.map((entry) {
              final item = entry.value;
              return [
                '${entry.key + 1}',
                item.metal.displayName,
                item.descCtrl.text.trim().isEmpty
                    ? '${item.metal.displayName} Purchase Item'
                    : item.descCtrl.text.trim(),
                item.grossWt.toStringAsFixed(3),
                item.lessWt.toStringAsFixed(3),
                item.netWt.toStringAsFixed(3),
                item.purity.toStringAsFixed(2),
                item.fineWt.toStringAsFixed(3),
                item.rate.toStringAsFixed(2),
                item.totalValue.toStringAsFixed(2),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _summaryRow('Gross Purchase', ctrl.grossPurchaseAmount),
                  _summaryRow('Discount', ctrl.discountAmount),
                  _summaryRow('Taxable Value', ctrl.taxableAmount),
                  _summaryRow('GST', ctrl.totalGst),
                  pw.Divider(),
                  _summaryRow('Grand Total', ctrl.grandTotal, emphasize: true),
                  _summaryRow('Cash Paid', ctrl.cashPaid),
                  _summaryRow('UPI / Bank Paid', ctrl.upiPaid),
                  _summaryRow('Card Paid', ctrl.cardPaid),
                  pw.Divider(),
                  _summaryRow('Balance Due', ctrl.balanceDue, emphasize: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static pw.Widget _summaryRow(
    String label,
    double value, {
    bool emphasize = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            'Rs. ${value.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
