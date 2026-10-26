import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../models/customer/customer_profile/customer_profile_model.dart';
import 'customer_pdf_elements.dart';

class CustomerRelatedDocumentPdfBuilder extends CustomerPdfElements {
  Future<Uint8List> buildLinkedDocumentPdf(
    CustomerLinkedDocumentModel document,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        build: (context) => [
          pdfHeader(document.documentTitle.toUpperCase(), document.documentNo),
          pw.SizedBox(height: 18),
          pdfSectionTitle('Document Link'),
          pw.SizedBox(height: 8),
          pdfInfoGrid([
            ['Source Invoice', document.sourceNumber],
            ['Document Status', document.statusLabel],
            ['Document Date', document.formattedDate],
            ['Returned Items', document.lineCountLabel],
            [
              'Received Net Weight',
              '${document.netWeight.toStringAsFixed(3)} g'
            ],
            ['Return Value', document.formattedReturnValue],
            ['Making Returned', document.formattedMakingReturned],
            ['Due Adjusted', document.formattedDueAdjusted],
            ['Customer Credit', document.formattedCustomerCredit],
          ]),
          pw.SizedBox(height: 18),
          pdfSectionTitle('Audit Note'),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF7F3EA),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFE1E7F0)),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Text(
              'Original sales invoice remains locked. This linked document records the return settlement, inventory routing, due adjustment, and customer credit impact.',
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFF111827),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> buildAdvanceOrderPdf(
    CustomerAdvanceOrderModel order,
    CustomerProfileModel? profile,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        build: (context) => [
          pdfHeader('BOOKING ADVANCE RECEIPT', order.orderNo),
          pw.SizedBox(height: 18),
          pdfInfoGrid([
            ['Customer', profile?.name ?? 'Customer'],
            ['Mobile', profile?.mobile ?? '-'],
            ['City', profile?.city.isNotEmpty == true ? profile!.city : '-'],
            ['Order Number', order.orderNo],
            ['Item', order.itemName],
            ['Metal', order.metalType],
            ['Purity', order.purity],
            ['Approx Weight', '${order.approxWeight.toStringAsFixed(3)} g'],
            ['Locked Rate', formatRupees(order.lockedRate)],
            ['Booking Type', order.bookingType],
            ['Status', order.status.label],
            ['Created On', order.formattedDate],
            ['Delivery Date', order.formattedDelivery],
            ['Estimated Total', formatRupees(order.estimatedTotal)],
            ['Advance Paid', formatRupees(order.totalAdvancePaid)],
            ['Remaining Balance', formatRupees(order.remainingBalance)],
          ]),
          if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pdfSectionTitle('Order Notes'),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border:
                    pw.Border.all(color: const PdfColor.fromInt(0xFFD8DEE9)),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(order.notes!.trim()),
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }
}
