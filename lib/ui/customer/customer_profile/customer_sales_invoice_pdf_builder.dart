import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../models/customer/customer_profile/customer_profile_model.dart';
import 'customer_pdf_elements.dart';

enum SalesInvoicePdfMode { postedOriginal, currentStatement }

class CustomerSalesInvoicePdfBuilder extends CustomerPdfElements {
  Future<Uint8List?> buildSalesInvoicePdf({
    required CustomerBillDetailModel detail,
    required SalesInvoicePdfMode mode,
  }) async {
    final doc = pw.Document();
    final isCurrent = mode == SalesInvoicePdfMode.currentStatement;
    final activeItems =
        detail.items.where((item) => !item.isReturned).toList(growable: false);
    final returnedItems =
        detail.items.where((item) => item.isReturned).toList(growable: false);
    final printableItems = isCurrent ? activeItems : detail.items;
    final grossSource = detail.bill.grossAmount > 0
        ? detail.bill.grossAmount
        : detail.items.fold<double>(0, (sum, item) => sum + item.itemTotal);
    final paidTotal = detail.bill.cashPaid +
        detail.bill.upiPaid +
        detail.bill.cardPaid +
        detail.bill.advancePaid;
    final returnValue = detail.bill.linkedReturnValue;
    final currentInvoiceValue = detail.bill.currentInvoiceValue;

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          pdfHeader(
            isCurrent ? 'UPDATED SALES STATEMENT' : 'ORIGINAL TAX INVOICE',
            detail.bill.billNo,
          ),
          pw.SizedBox(height: 14),
          _pdfStatusStrip(
            isCurrent
                ? 'Return adjusted view. Original invoice remains locked.'
                : 'Immutable posted invoice snapshot. Return documents are linked separately.',
            detail.bill.hasLinkedDocuments
                ? detail.bill.lifecycleLabel
                : detail.bill.paymentLabel,
          ),
          pw.SizedBox(height: 14),
          pdfInfoGrid([
            ['Customer', detail.customerName],
            ['Mobile', detail.customerMobile],
            ['Invoice Date', detail.bill.formattedDate],
            ['Payment Status', detail.bill.paymentLabel],
            [
              'Place of Supply',
              detail.bill.placeOfSupply.isEmpty
                  ? '-'
                  : detail.bill.placeOfSupply
            ],
            [
              'Document Type',
              detail.bill.documentType.isEmpty
                  ? 'TAX INVOICE'
                  : detail.bill.documentType
            ],
          ]),
          pw.SizedBox(height: 16),
          pdfSectionTitle(
            isCurrent ? 'Active Item Details' : 'Original Item Details',
          ),
          pw.SizedBox(height: 8),
          _pdfSalesItemsTable(printableItems, showReturnStatus: !isCurrent),
          if (isCurrent && returnedItems.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pdfSectionTitle('Returned Item Adjustments'),
            pw.SizedBox(height: 8),
            _pdfSalesItemsTable(returnedItems, showReturnStatus: true),
          ],
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _pdfPaymentPanel(detail.bill, paidTotal)),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: isCurrent
                    ? _pdfCurrentAmountPanel(
                        bill: detail.bill,
                        grossSource: grossSource,
                        returnValue: returnValue,
                        currentInvoiceValue: currentInvoiceValue,
                      )
                    : _pdfOriginalAmountPanel(
                        bill: detail.bill,
                        grossSource: grossSource,
                      ),
              ),
            ],
          ),
          if (detail.bill.linkedDocuments.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfLinkedDocumentsSummary(detail.bill.linkedDocuments),
          ],
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _pdfStatusStrip(String note, String status) {
    final cleanStatus = status.trim().isEmpty ? 'POSTED' : status.trim();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFAEC),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5B04C)),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              note,
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFF111827),
                fontSize: 9,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFFFFF),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5B04C)),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              cleanStatus.toUpperCase(),
              style: pw.TextStyle(
                color: const PdfColor.fromInt(0xFF8A5D0A),
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSalesItemsTable(
    List<CustomerBillLineItemModel> items, {
    required bool showReturnStatus,
  }) {
    if (items.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE1E7F0)),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'No active invoice items in this view.',
          style: const pw.TextStyle(
            color: PdfColor.fromInt(0xFF111827),
            fontSize: 10,
          ),
        ),
      );
    }

    final headers = [
      'No',
      'Metal',
      'Item Detail',
      'Unit',
      'Purity',
      'Net Wt',
      'Rate',
      'Making',
      'Amount',
      if (showReturnStatus) 'Status',
    ];
    final data = items.map((item) {
      return [
        item.lineNo.toString(),
        item.metalType.toUpperCase(),
        _pdfItemDescription(item),
        item.unitLabel,
        item.purity?.trim().isEmpty ?? true ? '-' : item.purity!,
        '${item.netWeight.toStringAsFixed(3)} g',
        formatRupees(item.rate),
        _makingDisplay(item),
        formatRupees(item.displayInvoiceValue),
        if (showReturnStatus)
          item.isReturned
              ? 'RETURNED ${item.returnVoucherNo}'.trim()
              : 'ACTIVE',
      ];
    }).toList(growable: false);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(
        color: const PdfColor.fromInt(0xFFE2E8F0),
        width: 0.6,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF7F3EA),
      ),
      headerStyle: pw.TextStyle(
        color: const PdfColor.fromInt(0xFF111827),
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        color: PdfColor.fromInt(0xFF111827),
        fontSize: 7,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      columnWidths: {
        0: const pw.FixedColumnWidth(22),
        1: const pw.FixedColumnWidth(44),
        2: const pw.FlexColumnWidth(2.3),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(38),
        5: const pw.FixedColumnWidth(52),
        6: const pw.FixedColumnWidth(54),
        7: const pw.FixedColumnWidth(58),
        8: const pw.FixedColumnWidth(58),
        if (showReturnStatus) 9: const pw.FixedColumnWidth(62),
      },
    );
  }

  String _pdfItemDescription(CustomerBillLineItemModel item) {
    final lines = <String>[item.itemName];
    final hsn = item.hsnCode.trim();
    final huid = item.huid?.trim() ?? '';
    if (hsn.isNotEmpty) lines.add('HSN $hsn');
    if (huid.isNotEmpty) lines.add('HUID $huid');
    return lines.join('\n');
  }

  String _makingDisplay(CustomerBillLineItemModel item) {
    final input = item.makingChargeInput;
    final type = item.makingChargeType.trim().toUpperCase();
    final prefix = switch (type) {
      'PERCENTAGE' => '${formatAmount(input)}%',
      'PER_PIECE' => '${formatAmount(input)}/pc',
      'PER_KG' => '${formatAmount(input)}/kg',
      _ => input > 0 ? '${formatAmount(input)}/g' : '',
    };
    if (prefix.isEmpty) return formatRupees(item.makingCharge);
    return '$prefix\n${formatRupees(item.makingCharge)}';
  }

  pw.Widget _pdfPaymentPanel(CustomerBillModel bill, double paidTotal) {
    final rows = <List<String>>[
      if (bill.cashPaid > 0.005) ['Cash', formatRupees(bill.cashPaid)],
      if (bill.upiPaid > 0.005) ['UPI / Bank', formatRupees(bill.upiPaid)],
      if (bill.cardPaid > 0.005) ['Card', formatRupees(bill.cardPaid)],
      if (bill.advancePaid > 0.005) ['Advance', formatRupees(bill.advancePaid)],
      [
        'Total Received',
        formatRupees(paidTotal > 0 ? paidTotal : bill.paidAmount)
      ],
      ['Current Due', formatRupees(bill.dueAmount)],
    ];
    return _pdfSummaryPanel(
      title: 'Payment Received',
      rows: rows,
      footerLabel: 'Payment Status',
      footerValue: bill.paymentLabel,
    );
  }

  pw.Widget _pdfOriginalAmountPanel({
    required CustomerBillModel bill,
    required double grossSource,
  }) {
    return _pdfSummaryPanel(
      title: 'Original Amount Summary',
      rows: [
        ['Gross Sale Value', formatRupees(grossSource)],
        ['Making Charges', formatRupees(bill.makingTotal)],
        ['Invoice Discount', '- ${formatRupees(bill.discountAmount)}'],
        ['Taxable Value', formatRupees(bill.taxableAmount)],
        if (bill.igstAmount > 0.005)
          ['IGST', formatRupees(bill.igstAmount)]
        else ...[
          ['CGST', formatRupees(bill.cgstAmount)],
          ['SGST', formatRupees(bill.sgstAmount)],
        ],
        if (bill.tradeInDeduction > 0.005)
          [
            'Customer Metal Settlement',
            '- ${formatRupees(bill.tradeInDeduction)}'
          ],
        if (bill.roundOffAmount.abs() > 0.005)
          ['Round Off', formatRupees(bill.roundOffAmount)],
      ],
      footerLabel: 'Original Invoice Total',
      footerValue: formatRupees(bill.totalAmount),
    );
  }

  pw.Widget _pdfCurrentAmountPanel({
    required CustomerBillModel bill,
    required double grossSource,
    required double returnValue,
    required double currentInvoiceValue,
  }) {
    return _pdfSummaryPanel(
      title: 'Updated Statement Summary',
      rows: [
        ['Original Invoice Total', formatRupees(bill.totalAmount)],
        ['Linked Return Value', '- ${formatRupees(returnValue)}'],
        ['Current Sale Value', formatRupees(currentInvoiceValue)],
        ['Amount Received', formatRupees(bill.paidAmount)],
        ['Current Due', formatRupees(bill.dueAmount)],
      ],
      footerLabel: 'Current Customer Position',
      footerValue:
          bill.dueAmount <= 0.5 ? 'SETTLED' : formatRupees(bill.dueAmount),
    );
  }

  pw.Widget _pdfSummaryPanel({
    required String title,
    required List<List<String>> rows,
    required String footerLabel,
    required String footerValue,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE1E7F0)),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              color: const PdfColor.fromInt(0xFF8A5D0A),
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...rows.map(
            (row) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    row[0],
                    style: const pw.TextStyle(
                      color: PdfColor.fromInt(0xFF344256),
                      fontSize: 8.5,
                    ),
                  ),
                  pw.Text(
                    row[1],
                    style: pw.TextStyle(
                      color: const PdfColor.fromInt(0xFF111827),
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Divider(color: const PdfColor.fromInt(0xFFE5B04C)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                footerLabel,
                style: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF111827),
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                footerValue,
                style: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF8A5D0A),
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfLinkedDocumentsSummary(
    List<CustomerLinkedDocumentModel> documents,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF6F0FF),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFC4B5FD)),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'LINKED RETURN / REVERSAL DOCUMENTS',
            style: pw.TextStyle(
              color: const PdfColor.fromInt(0xFF4C1D95),
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          ...documents.map(
            (document) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '${document.documentNo} | ${document.documentTitle} | ${document.lineCountLabel}',
                      style: const pw.TextStyle(
                        color: PdfColor.fromInt(0xFF111827),
                        fontSize: 8,
                      ),
                    ),
                  ),
                  pw.Text(
                    document.formattedReturnValue.replaceFirst('\u20B9', 'Rs'),
                    style: pw.TextStyle(
                      color: const PdfColor.fromInt(0xFF111827),
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
