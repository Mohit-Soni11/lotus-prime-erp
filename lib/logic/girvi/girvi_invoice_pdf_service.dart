import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/girvi/girvi_invoice_draft.dart';
import '../../models/setting/billing_setup/girvi_billing_model.dart';

enum GirviInvoiceFormat {
  a4,
  compactA5;

  String get label => this == a4 ? 'A4 Size' : 'Compact A5';

  String get subtitle =>
      this == a4 ? 'Full detail loan invoice' : 'Smaller counter copy';

  PdfPageFormat get pageFormat =>
      this == a4 ? PdfPageFormat.a4 : PdfPageFormat.a5;
}

class GirviInvoicePdfService {
  static final _amountFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _dateFormat = DateFormat('dd MMM yyyy');

  Future<Uint8List> build({
    required GirviInvoiceDraft draft,
    required GirviInvoiceFormat format,
    GirviBillingModel settings = const GirviBillingModel(),
    int copies = 1,
    bool duplicateStamp = false,
  }) async {
    final pdf = pw.Document();
    final safeCopies = copies.clamp(1, 5);

    for (var copy = 0; copy < safeCopies; copy++) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: format.pageFormat,
          margin: pw.EdgeInsets.all(format == GirviInvoiceFormat.a4 ? 28 : 20),
          header: duplicateStamp || copy > 0
              ? (_) => pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey500),
                      ),
                      child: pw.Text(
                        copy == 0 ? 'DUPLICATE' : 'COPY ${copy + 1}',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  )
              : null,
          build: (_) => _buildDocument(draft, format, settings),
        ),
      );
    }

    return pdf.save();
  }

  List<pw.Widget> _buildDocument(
    GirviInvoiceDraft draft,
    GirviInvoiceFormat format,
    GirviBillingModel settings,
  ) {
    final compact = format == GirviInvoiceFormat.compactA5;
    final sectionGap = compact ? 10.0 : 16.0;

    return [
      _buildHeader(draft, compact),
      pw.SizedBox(height: sectionGap),
      _buildCustomerAndLoanSummary(draft, compact),
      pw.SizedBox(height: sectionGap),
      _sectionTitle('Pledged Item Ledger', compact),
      _buildItemsTable(draft, compact, settings),
      if (settings.showDisbursementDetails && draft.payments.isNotEmpty) ...[
        pw.SizedBox(height: sectionGap),
        _buildPaymentBlock(draft, compact),
      ],
      if (settings.showItemPhotos && draft.photoCount > 0) ...[
        pw.SizedBox(height: sectionGap),
        _sectionTitle('Pledged Item Photos', compact),
        _buildPhotoGrid(draft, compact),
      ],
      if ((settings.showKycDetails && (draft.idProofType ?? '').isNotEmpty) ||
          (draft.notes ?? '').isNotEmpty) ...[
        pw.SizedBox(height: sectionGap),
        _buildKycAndNotes(draft, compact, settings),
      ],
      if (settings.printTermsAndConditions &&
          settings.termsAndConditions.trim().isNotEmpty) ...[
        pw.SizedBox(height: sectionGap),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(9),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF9FAFB),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle('Terms & Conditions', compact),
              pw.Text(
                settings.termsAndConditions,
                style: pw.TextStyle(
                  fontSize: compact ? 6.5 : 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
      ],
      pw.SizedBox(height: compact ? 22 : 32),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _signatureLine('Customer Signature', compact),
          _signatureLine('Authorized Signature', compact),
        ],
      ),
      if (settings.printFooterMessage &&
          settings.footerMessage.trim().isNotEmpty) ...[
        pw.SizedBox(height: compact ? 10 : 14),
        pw.Divider(color: PdfColors.grey300),
        pw.Center(
          child: pw.Text(
            settings.footerMessage,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: compact ? 6.5 : 8,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ],
    ];
  }

  pw.Widget _buildHeader(GirviInvoiceDraft draft, bool compact) {
    return pw.Container(
      padding: pw.EdgeInsets.all(compact ? 10 : 14),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF202A3A),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LOTUS ERP',
                style: pw.TextStyle(
                  color: PdfColors.amber,
                  fontSize: compact ? 7 : 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'GIRVI LOAN INVOICE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: compact ? 13 : 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Pawn ticket and pledged item receipt',
                style: pw.TextStyle(
                  color: PdfColors.grey300,
                  fontSize: compact ? 6.5 : 8,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                draft.ticketNo,
                style: pw.TextStyle(
                  color: PdfColors.amber,
                  fontSize: compact ? 8 : 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _dateFormat.format(draft.createdAt),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: compact ? 6.5 : 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerAndLoanSummary(
    GirviInvoiceDraft draft,
    bool compact,
  ) {
    final customer = _infoCard(
      title: 'Customer Details',
      compact: compact,
      rows: [
        ('Name', draft.customerName),
        ('Mobile', draft.customerMobile),
        ('City', draft.customerCity.isEmpty ? '-' : draft.customerCity),
        if ((draft.idProofType ?? '').isNotEmpty)
          (
            'KYC',
            '${draft.idProofType}${(draft.idProofNumber ?? '').isEmpty ? '' : ' - ${draft.idProofNumber}'}',
          ),
      ],
    );
    final summary = _infoCard(
      title: 'Loan Summary',
      compact: compact,
      highlighted: true,
      rows: [
        ('Principal', _amount(draft.loanAmount)),
        ('Interest', '${draft.interestRate.toStringAsFixed(2)}% / month'),
        ('Duration', '${draft.durationMonths} months'),
        ('Start Date', _dateFormat.format(draft.startDate)),
        ('Maturity', _dateFormat.format(draft.maturityDate)),
        ('Maturity Due', _amount(draft.totalDue)),
      ],
    );

    if (compact) {
      return pw.Column(
        children: [
          customer,
          pw.SizedBox(height: 8),
          summary,
        ],
      );
    }
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: customer),
        pw.SizedBox(width: 12),
        pw.Expanded(child: summary),
      ],
    );
  }

  pw.Widget _infoCard({
    required String title,
    required bool compact,
    required List<(String, String)> rows,
    bool highlighted = false,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(compact ? 9 : 12),
      decoration: pw.BoxDecoration(
        color:
            highlighted ? const PdfColor.fromInt(0xFFFBF7ED) : PdfColors.white,
        border: pw.Border.all(
          color: highlighted ? PdfColors.amber100 : PdfColors.grey300,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, compact),
          ...rows.map(
            (row) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    row.$1,
                    style: pw.TextStyle(
                      fontSize: compact ? 6.5 : 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Text(
                      row.$2,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: compact ? 7 : 8.5,
                        fontWeight: row.$1 == 'Principal' ||
                                row.$1 == 'Maturity Due' ||
                                row.$1 == 'Name'
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                      ),
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

  pw.Widget _buildItemsTable(
    GirviInvoiceDraft draft,
    bool compact,
    GirviBillingModel settings,
  ) {
    final headers = <String>['#', 'Item'];
    if (settings.showMetal) headers.add('Metal');
    if (settings.showPieces) headers.add('Pcs');
    if (settings.showGrossWeight) headers.add('Gross');
    if (settings.showLessWeight) headers.add('Less');
    if (settings.showNetWeight) headers.add('Net');
    if (settings.showPurity) headers.add('Purity');
    if (settings.showValuationPurity) headers.add('Val. Purity');
    if (settings.showFineWeight) headers.add('Fine');
    if (settings.showRate) headers.add('Rate / g');
    if (settings.showHuid) headers.add('HUID');
    if (settings.showTotalValue) headers.add('Value');

    final data = draft.items.map((item) {
      final row = <String>[
        item.serialNo.toString(),
        item.description,
      ];
      if (settings.showMetal) row.add(item.metal);
      if (settings.showPieces) row.add(item.pieces.toString());
      if (settings.showGrossWeight) {
        row.add('${item.grossWeight.toStringAsFixed(3)} g');
      }
      if (settings.showLessWeight) {
        row.add('${item.lessWeight.toStringAsFixed(3)} g');
      }
      if (settings.showNetWeight) {
        row.add('${item.netWeight.toStringAsFixed(3)} g');
      }
      if (settings.showPurity) row.add(item.purity);
      if (settings.showValuationPurity) row.add(item.valuationPurity);
      if (settings.showFineWeight) {
        row.add('${item.fineWeight.toStringAsFixed(3)} g');
      }
      if (settings.showRate) row.add(_amount(item.ratePerGram));
      if (settings.showHuid) row.add(item.huid.isEmpty ? '-' : item.huid);
      if (settings.showTotalValue) row.add(_amount(item.value));
      return row;
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: compact ? 6 : 7.2,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: compact ? 5.8 : 6.8),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF1EDE4),
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: pw.EdgeInsets.all(compact ? 3 : 4),
    );
  }

  pw.Widget _buildPaymentBlock(GirviInvoiceDraft draft, bool compact) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(compact ? 9 : 11),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Disbursement Details', compact),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: draft.payments
                .map(
                  (payment) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF9FAFB),
                      border: pw.Border.all(color: PdfColors.grey200),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      '${payment.label}: ${_amount(payment.amount)}',
                      style: pw.TextStyle(
                        fontSize: compact ? 6.5 : 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPhotoGrid(GirviInvoiceDraft draft, bool compact) {
    final photos = draft.items
        .expand(
          (item) => item.photoPaths.map((path) => (item.serialNo, path)),
        )
        .where((entry) => File(entry.$2).existsSync())
        .toList();

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: photos.map((entry) {
        final bytes = File(entry.$2).readAsBytesSync();
        return pw.Container(
          width: compact ? 92 : 126,
          height: compact ? 82 : 108,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Item #${entry.$1}',
                style: pw.TextStyle(
                  fontSize: compact ? 5.5 : 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Expanded(
                child: pw.Image(
                  pw.MemoryImage(bytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildKycAndNotes(
    GirviInvoiceDraft draft,
    bool compact,
    GirviBillingModel settings,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(compact ? 9 : 11),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('KYC & Remarks', compact),
          if (settings.showKycDetails && (draft.idProofType ?? '').isNotEmpty)
            pw.Text(
              '${draft.idProofType}: ${draft.idProofNumber?.isNotEmpty == true ? draft.idProofNumber : 'Number not provided'}',
              style: pw.TextStyle(fontSize: compact ? 6.5 : 8),
            ),
          if ((draft.notes ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              draft.notes!,
              style: pw.TextStyle(
                fontSize: compact ? 6.5 : 8,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String value, bool compact) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: compact ? 8 : 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _signatureLine(String label, bool compact) {
    return pw.SizedBox(
      width: compact ? 115 : 170,
      child: pw.Column(
        children: [
          pw.Container(height: 1, color: PdfColors.grey500),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: compact ? 6.5 : 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  String _amount(double value) => 'Rs ${_amountFormat.format(value)}';
}
