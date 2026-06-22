import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/girvi/girvi_account_lifecycle_summary.dart';
import '../../models/girvi/girvi_invoice_branding.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../repositories/girvi/girvi_details_repository.dart';

class GirviPaymentRecordPdfService {
  static final _moneyFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static const _navy = PdfColor.fromInt(0xFF172437);
  static const _gold = PdfColor.fromInt(0xFFC89421);
  static const _goldLight = PdfColor.fromInt(0xFFFBF6E9);
  static const _ink = PdfColor.fromInt(0xFF172033);
  static const _muted = PdfColor.fromInt(0xFF111111);
  static const _line = PdfColor.fromInt(0xFFB8C0CC);
  static const _rowTint = PdfColor.fromInt(0xFFF3F6FA);
  static const _success = PdfColor.fromInt(0xFF047857);
  static const _warning = PdfColor.fromInt(0xFFB7791F);
  static const _danger = PdfColor.fromInt(0xFFB91C1C);

  Future<Uint8List> build({
    required GirviLoanWithCustomer account,
    required List<GirviPaymentModel> payments,
    GirviLoanDetails? details,
    GirviInvoiceBranding branding = GirviInvoiceBranding.fallback,
  }) async {
    final devanagariFont = await _loadDevanagariFont();
    final brandLogo = _loadBrandLogo(branding);
    final photos = _loadItemPhotos(account, details);
    final sortedPayments = List<GirviPaymentModel>.from(payments)
      ..sort((a, b) {
        final byDate = a.paymentDate.compareTo(b.paymentDate);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });

    final pdf = pw.Document(
      theme: await _buildTheme(devanagariFont),
      title: 'Girvi Payment Record ${account.loan.ticketNo}',
      author: branding.shopName,
      creator: branding.shopName,
      subject: 'Girvi account payment record',
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(28, 24, 28, 22),
        ),
        footer: (context) => _buildFooter(context, branding),
        build: (_) {
          final widgets = <pw.Widget>[
            _buildHeroHeader(account, branding, brandLogo),
            pw.SizedBox(height: 10),
            _buildCustomerAndLoanPanel(account),
            pw.SizedBox(height: 12),
            _buildSectionHeading(
              title: 'PLEDGED ITEMS',
              subtitle: _pledgedItemsSubtitle(account, details),
            ),
            pw.SizedBox(height: 8),
            _buildPledgedItemsTable(account, details),
          ];

          if (photos.isNotEmpty) {
            widgets
              ..add(pw.SizedBox(height: 12))
              ..add(pw.NewPage(freeSpace: 140))
              ..add(
                _buildSectionHeading(
                  title: 'PLEDGED ITEM PHOTOS',
                  subtitle: 'Photos attached with this Girvi account',
                ),
              )
              ..add(pw.SizedBox(height: 8))
              ..add(_buildPhotoSection(photos));
          }

          widgets
            ..add(pw.SizedBox(height: 12))
            ..add(pw.NewPage(freeSpace: 155))
            ..add(
              _buildSectionHeading(
                title: 'PAYMENT RECORD',
                subtitle:
                    '${sortedPayments.length} date-wise payment entr${sortedPayments.length == 1 ? 'y' : 'ies'}',
              ),
            )
            ..add(pw.SizedBox(height: 8))
            ..add(_buildFinancialStrip(account, sortedPayments))
            ..add(pw.SizedBox(height: 8))
            ..addAll(_buildPaymentRecord(sortedPayments))
            ..add(pw.SizedBox(height: 14))
            ..add(pw.NewPage(freeSpace: 115))
            ..add(_buildSettlementDeliveryPanel(account))
            ..add(pw.SizedBox(height: 8))
            ..add(_buildSignatureBlock());

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  Future<pw.Font?> _loadDevanagariFont() async {
    const assetPath = 'assets/fonts/lohit_devanagari/Lohit-Devanagari.ttf';
    try {
      return pw.Font.ttf(await rootBundle.load(assetPath));
    } catch (_) {
      try {
        final fontFile = File(assetPath);
        if (fontFile.existsSync()) {
          return pw.Font.ttf(_asByteData(await fontFile.readAsBytes()));
        }
      } catch (_) {
        // English-only records can still be generated.
      }
    }
    return null;
  }

  Future<pw.ThemeData> _buildTheme(pw.Font? devanagariFont) async {
    final windowsDirectory = Platform.environment['WINDIR'];
    if (windowsDirectory != null) {
      final regularFile = File('$windowsDirectory\\Fonts\\segoeui.ttf');
      final boldFile = File('$windowsDirectory\\Fonts\\segoeuib.ttf');
      if (regularFile.existsSync() && boldFile.existsSync()) {
        try {
          return pw.ThemeData.withFont(
            base: pw.Font.ttf(_asByteData(await regularFile.readAsBytes())),
            bold: pw.Font.ttf(_asByteData(await boldFile.readAsBytes())),
            fontFallback: devanagariFont == null ? null : [devanagariFont],
          );
        } catch (_) {
          // Fall back to bundled PDF fonts.
        }
      }
    }

    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      fontFallback: devanagariFont == null ? null : [devanagariFont],
    );
  }

  ByteData _asByteData(Uint8List bytes) {
    return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
  }

  pw.MemoryImage? _loadBrandLogo(GirviInvoiceBranding branding) {
    final path = branding.logoPath?.trim() ?? '';
    if (path.isEmpty) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      return pw.MemoryImage(file.readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  pw.Widget _buildHeroHeader(
    GirviLoanWithCustomer account,
    GirviInvoiceBranding branding,
    pw.MemoryImage? brandLogo,
  ) {
    final metadata = [
      (label: 'TICKET NUMBER', value: account.loan.ticketNo),
      (label: 'PRINT DATE', value: _dateTimeFormat.format(DateTime.now())),
      (label: 'START DATE', value: _date(account.loan.startDate)),
      (label: 'MATURITY', value: _date(account.loan.maturityDate)),
    ];

    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _buildBrandMark(branding, brandLogo),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        branding.shopName.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 19,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (branding.shopAddress.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          branding.shopAddress.trim(),
                          maxLines: 2,
                          overflow: pw.TextOverflow.clip,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9.2,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                      if (branding.detailLine.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          branding.detailLine,
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                          style: pw.TextStyle(
                            color: _gold,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: _goldLight,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Text(
                        'PAYMENT RECORD',
                        style: pw.TextStyle(
                          color: _navy,
                          fontSize: 9.4,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'ACCOUNT LEDGER COPY',
                      style: pw.TextStyle(
                        color: _gold,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Container(height: 1.4, color: _gold),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: pw.Row(
              children: [
                for (var index = 0; index < metadata.length; index++) ...[
                  if (index > 0) _buildHeaderDivider(),
                  pw.Expanded(
                    child: _buildHeaderMeta(
                      label: metadata[index].label,
                      value: metadata[index].value,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBrandMark(
    GirviInvoiceBranding branding,
    pw.MemoryImage? brandLogo,
  ) {
    final content = brandLogo == null
        ? pw.Container(
            alignment: pw.Alignment.center,
            color: _gold,
            child: pw.Text(
              branding.initial,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          )
        : pw.Container(
            color: PdfColors.white,
            child: pw.Image(brandLogo, fit: pw.BoxFit.cover),
          );

    final clipped = branding.logoShape == 'square'
        ? pw.ClipRRect(
            horizontalRadius: 7,
            verticalRadius: 7,
            child: content,
          )
        : pw.ClipOval(child: content);

    return pw.Container(
      width: 52,
      height: 52,
      padding: const pw.EdgeInsets.all(2),
      decoration: pw.BoxDecoration(
        color: _gold,
        shape: branding.logoShape == 'square'
            ? pw.BoxShape.rectangle
            : pw.BoxShape.circle,
        borderRadius: branding.logoShape == 'square'
            ? const pw.BorderRadius.all(pw.Radius.circular(8))
            : null,
      ),
      child: clipped,
    );
  }

  pw.Widget _buildHeaderDivider() {
    return pw.Container(
      width: 0.7,
      height: 27,
      margin: const pw.EdgeInsets.symmetric(horizontal: 14),
      color: _gold,
    );
  }

  pw.Widget _buildHeaderMeta({
    required String label,
    required String value,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            color: _goldLight,
            fontSize: 7.3,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 9.2,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerAndLoanPanel(GirviLoanWithCustomer account) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            height: 112,
            padding: const pw.EdgeInsets.all(13),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _line),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildEyebrow('CUSTOMER DETAILS'),
                pw.SizedBox(height: 7),
                pw.Text(
                  account.customerName,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Spacer(),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: _buildCustomerMeta(
                        label: 'MOBILE',
                        value: account.customerMobile.trim().isEmpty
                            ? '--'
                            : account.customerMobile.trim(),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      flex: 6,
                      child: _buildCustomerMeta(
                        label: 'ADDRESS',
                        value: _emptyFallback(account.customerAddress),
                        maxLines: 2,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            height: 112,
            padding: const pw.EdgeInsets.all(13),
            decoration: pw.BoxDecoration(
              color: _goldLight,
              border: pw.Border.all(color: _gold, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildEyebrow('LOAN AMOUNT', color: _gold),
                pw.SizedBox(height: 6),
                pw.Text(
                  _money(account.originalPrincipal),
                  style: pw.TextStyle(
                    color: _navy,
                    fontSize: 19,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Spacer(),
                pw.Container(
                  width: double.infinity,
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFEAD6A0),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'MONTHLY INTEREST',
                            style: pw.TextStyle(
                              color: _muted,
                              fontSize: 7.2,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          pw.Spacer(),
                          pw.Text(
                            '${account.loan.interestRate.toStringAsFixed(2)}% monthly',
                            style: pw.TextStyle(
                              color: _navy,
                              fontSize: 9.2,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Current payable ${_money(account.totalPayable)}',
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                          color:
                              account.totalPayable <= 0.01 ? _success : _danger,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerMeta({
    required String label,
    required String value,
    int maxLines = 1,
    double fontSize = 9.5,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: _muted,
            fontSize: 7.2,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          maxLines: maxLines,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            color: _ink,
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildEyebrow(String label, {PdfColor color = _muted}) {
    return pw.Text(
      label,
      style: pw.TextStyle(
        color: color,
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.45,
      ),
    );
  }

  pw.Widget _buildSettlementDeliveryPanel(GirviLoanWithCustomer account) {
    final summary = GirviAccountLifecycleSummary.fromAccount(
      account,
      dateLabel: _date,
      dateTimeLabel: _dateTime,
      moneyLabel: _money,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          title: 'SETTLEMENT & DELIVERY',
          subtitle: 'Current closure status for this Girvi account',
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _statusCard(
                label: summary.settlement.title,
                value: summary.settlement.value,
                subtitle: summary.settlement.subtitle,
                color: summary.settlementComplete ? _success : _warning,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _statusCard(
                label: summary.delivery.title,
                value: summary.delivery.value,
                subtitle: summary.delivery.subtitle,
                color: summary.delivered ? _success : _warning,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _statusCard(
                label: summary.period.title,
                value: summary.period.value,
                subtitle: summary.period.subtitle,
                color: _navy,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        _detailTable([
          ['Release Date', _date(account.loan.releaseDate)],
          ['Expected Pickup', _date(account.loan.expectedDeliveryDate)],
          ['Delivered At', _dateTime(account.loan.deliveredAt)],
          ['Processed By', _emptyFallback(account.loan.releasedBy)],
        ]),
      ],
    );
  }

  pw.Widget _statusCard({
    required String label,
    required String value,
    required String subtitle,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: color, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            style: const pw.TextStyle(
              color: _muted,
              fontSize: 7.6,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFinancialStrip(
    GirviLoanWithCustomer account,
    List<GirviPaymentModel> payments,
  ) {
    final totalReceived =
        payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    final totalDiscount = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.discountAmount,
    );
    final balanceColor = account.totalPayable <= 0.01 ? _success : _danger;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Row(
        children: [
          _metricBox('Total Received', _money(totalReceived), _success),
          _metricBox(
            'Principal Paid',
            _money(account.principalPaidTotal +
                account.legacyPrincipalRepaidTotal),
            _ink,
          ),
          _metricBox('Interest Paid', _money(account.interestPaidTotal), _gold),
          _metricBox('Discount', _money(totalDiscount), _warning),
          _metricBox('Net Payable', _money(account.totalPayable), balanceColor),
        ],
      ),
    );
  }

  pw.Widget _metricBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionHeading({
    required String title,
    required String subtitle,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 4,
          height: 24,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(
            color: _gold,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(width: 9),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: _navy,
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(color: _muted, fontSize: 8.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<pw.Widget> _buildPaymentRecord(List<GirviPaymentModel> payments) {
    if (payments.isEmpty) {
      return [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: _line),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
          ),
          child: pw.Text(
            'No payment has been recorded for this Girvi account.',
            style: const pw.TextStyle(color: _ink, fontSize: 10),
          ),
        ),
      ];
    }

    return [
      _paymentHeaderRow(),
      for (var index = 0; index < payments.length; index++)
        _paymentDataRow(payments[index], index),
    ];
  }

  pw.Widget _paymentHeaderRow() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: const pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
      ),
      child: pw.Row(
        children: [
          _cell('Date', 1.05, header: true),
          _cell('Entry Details', 2.25, header: true),
          _cell('Mode / Coverage', 1.55, header: true),
          _cell('Principal', 1, header: true, alignRight: true),
          _cell('Interest', 1, header: true, alignRight: true),
          _cell('Discount', 1, header: true, alignRight: true),
          _cell('Received', 1, header: true, alignRight: true),
          _cell('Balance', 1, header: true, alignRight: true),
        ],
      ),
    );
  }

  pw.Widget _paymentDataRow(GirviPaymentModel payment, int index) {
    final receipt = payment.receiptNo?.trim();
    final hasReceipt = receipt != null && receipt.isNotEmpty;
    final coverage = _coverage(payment);
    final bgColor = index.isEven ? PdfColors.white : _rowTint;
    final notes = payment.notes?.trim();

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: const pw.Border(
          left: pw.BorderSide(color: _line, width: 0.6),
          right: pw.BorderSide(color: _line, width: 0.6),
          bottom: pw.BorderSide(color: _line, width: 0.6),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _cell(_date(payment.paymentDate), 1.05),
          _richCell(
            flex: 2.25,
            title: payment.type.displayName,
            subtitle: [
              if (hasReceipt) 'Receipt: $receipt',
              if (notes != null && notes.isNotEmpty) notes,
            ].join(' | '),
          ),
          _richCell(
            flex: 1.55,
            title: payment.mode.displayName,
            subtitle: coverage,
          ),
          _cell(_money(payment.principalComponent), 1, alignRight: true),
          _cell(_money(payment.interestComponent), 1, alignRight: true),
          _cell(_money(payment.discountAmount), 1, alignRight: true),
          _cell(_money(payment.amount), 1,
              alignRight: true, valueColor: _success),
          _cell(_money(payment.balanceAfter), 1, alignRight: true),
        ],
      ),
    );
  }

  pw.Widget _cell(
    String value,
    double flex, {
    bool header = false,
    bool alignRight = false,
    PdfColor? valueColor,
  }) {
    return pw.Expanded(
      flex: (flex * 100).round(),
      child: pw.Text(
        value,
        maxLines: header ? 1 : 2,
        overflow: pw.TextOverflow.clip,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          color: header ? PdfColors.white : valueColor ?? _muted,
          fontSize: header ? 7.3 : 7.5,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _richCell({
    required double flex,
    required String title,
    required String subtitle,
  }) {
    return pw.Expanded(
      flex: (flex * 100).round(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 7.7,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 1.5),
            pw.Text(
              subtitle,
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
              style: const pw.TextStyle(color: _muted, fontSize: 7),
            ),
          ],
        ],
      ),
    );
  }

  String _pledgedItemsSubtitle(
    GirviLoanWithCustomer account,
    GirviLoanDetails? details,
  ) {
    final count = details?.items.length ?? account.loan.itemCount;
    return '$count item${count == 1 ? '' : 's'} | Net weight ${_weight(account.loan.netWeight)}';
  }

  pw.Widget _buildPledgedItemsTable(
    GirviLoanWithCustomer account,
    GirviLoanDetails? details,
  ) {
    final rows = _pledgedItemRows(account, details);
    return pw.TableHelper.fromTextArray(
      headers: const [
        'S/N',
        'Metal',
        'Item',
        'Pcs',
        'Purity',
        'Gross Wt.',
        'Less Wt.',
        'Net Wt.',
        'Rate / Gram',
        'Value',
      ],
      data: rows
          .map(
            (row) => [
              row.serialNo.toString().padLeft(2, '0'),
              row.metal,
              row.itemName,
              row.pieces.toString(),
              row.purity,
              _weight(row.grossWeight),
              row.lessWeight > 0.001 ? _weight(row.lessWeight) : '-',
              _weight(row.netWeight),
              _money(row.ratePerGram),
              _money(row.value),
            ],
          )
          .toList(growable: false),
      border: pw.TableBorder.all(color: _line, width: 0.55),
      headerDecoration: const pw.BoxDecoration(color: _navy),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 7.4,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        color: _muted,
        fontSize: 7.8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      oddRowDecoration: const pw.BoxDecoration(color: _rowTint),
      cellAlignments: const {
        0: pw.Alignment.center,
        3: pw.Alignment.center,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
        7: pw.Alignment.centerRight,
        8: pw.Alignment.centerRight,
        9: pw.Alignment.centerRight,
      },
      columnWidths: const {
        0: pw.FlexColumnWidth(0.58),
        1: pw.FlexColumnWidth(0.85),
        2: pw.FlexColumnWidth(1.55),
        3: pw.FlexColumnWidth(0.55),
        4: pw.FlexColumnWidth(0.75),
        5: pw.FlexColumnWidth(0.85),
        6: pw.FlexColumnWidth(0.8),
        7: pw.FlexColumnWidth(0.85),
        8: pw.FlexColumnWidth(1),
        9: pw.FlexColumnWidth(1),
      },
    );
  }

  List<_PledgedPaymentRecordItem> _pledgedItemRows(
    GirviLoanWithCustomer account,
    GirviLoanDetails? details,
  ) {
    final detailedItems = details?.items ?? const <GirviLoanItemDetails>[];
    if (detailedItems.isNotEmpty) {
      return detailedItems
          .map(
            (details) => _PledgedPaymentRecordItem(
              serialNo: details.item.serialNo,
              metal: details.item.metalType,
              itemName: details.item.itemName,
              pieces: details.item.pieces,
              purity: details.item.purity,
              grossWeight: details.item.grossWeight,
              lessWeight: details.item.lessWeight,
              netWeight: details.item.netWeight,
              ratePerGram: details.item.ratePerGram,
              value: details.item.valuationAmount,
            ),
          )
          .toList(growable: false);
    }

    return [
      _PledgedPaymentRecordItem(
        serialNo: 1,
        metal: account.loan.metalTypeEnum.displayName,
        itemName: account.loan.itemDescription,
        pieces: account.loan.itemCount,
        purity: account.loan.metalPurity,
        grossWeight: account.loan.grossWeight,
        lessWeight: account.loan.stoneWeight,
        netWeight: account.loan.netWeight,
        ratePerGram: account.loan.ratePerGram,
        value: account.loan.totalValue,
      ),
    ];
  }

  List<_PaymentRecordPhoto> _loadItemPhotos(
    GirviLoanWithCustomer account,
    GirviLoanDetails? details,
  ) {
    final photos = <_PaymentRecordPhoto>[];
    for (final itemDetails
        in details?.items ?? const <GirviLoanItemDetails>[]) {
      for (final photo in itemDetails.photos) {
        final loaded = _loadPhoto(
          path: photo.filePath,
          serialNo: itemDetails.item.serialNo,
          title: itemDetails.item.itemName,
        );
        if (loaded != null) photos.add(loaded);
      }
    }

    if (photos.isEmpty) {
      final loaded = _loadPhoto(
        path: account.loan.itemPhotoPath,
        serialNo: 1,
        title: account.loan.itemDescription,
      );
      if (loaded != null) photos.add(loaded);
    }
    return photos;
  }

  _PaymentRecordPhoto? _loadPhoto({
    required String? path,
    required int serialNo,
    required String title,
  }) {
    final resolved = path?.trim() ?? '';
    if (resolved.isEmpty) return null;
    final file = File(resolved);
    if (!file.existsSync()) return null;
    try {
      return _PaymentRecordPhoto(
        serialNo: serialNo,
        title: title,
        image: pw.MemoryImage(file.readAsBytesSync()),
      );
    } catch (_) {
      return null;
    }
  }

  pw.Widget _buildPhotoSection(List<_PaymentRecordPhoto> photos) {
    const columns = 3;
    return pw.Column(
      children: [
        for (var start = 0; start < photos.length; start += columns) ...[
          if (start > 0) pw.SizedBox(height: 9),
          _buildPhotoRow(
            photos.sublist(
              start,
              start + columns < photos.length ? start + columns : photos.length,
            ),
            columns,
          ),
        ],
      ],
    );
  }

  pw.Widget _buildPhotoRow(List<_PaymentRecordPhoto> photos, int columns) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < columns; index++) ...[
          if (index > 0) pw.SizedBox(width: 9),
          pw.Expanded(
            child: index < photos.length
                ? _buildPhotoCard(photos[index])
                : pw.SizedBox(),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildPhotoCard(_PaymentRecordPhoto photo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            height: 94,
            width: double.infinity,
            padding: const pw.EdgeInsets.all(3),
            decoration: const pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Image(photo.image, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: const pw.BoxDecoration(
                  color: _goldLight,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  '#${photo.serialNo}',
                  style: pw.TextStyle(
                    color: _gold,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 5),
              pw.Expanded(
                child: pw.Text(
                  photo.title,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: 9.2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _detailTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headers: null,
      data: rows,
      border: pw.TableBorder.all(color: _line, width: 0.6),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      cellStyle: pw.TextStyle(
        fontSize: 9,
        color: _ink,
        fontWeight: pw.FontWeight.bold,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.05),
        1: pw.FlexColumnWidth(1.45),
      },
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
      oddRowDecoration: const pw.BoxDecoration(color: _rowTint),
    );
  }

  pw.Widget _buildSignatureBlock() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureLine('Customer Signature'),
        _signatureLine('Authorized Signature'),
      ],
    );
  }

  pw.Widget _signatureLine(String label) {
    return pw.SizedBox(
      width: 190,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 1, color: _line),
          pw.SizedBox(height: 5),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, GirviInvoiceBranding branding) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated by ${branding.shopName}',
          style: const pw.TextStyle(color: _muted, fontSize: 8),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(color: _muted, fontSize: 8),
        ),
      ],
    );
  }

  String _coverage(GirviPaymentModel payment) {
    final from = payment.interestFromDate;
    final to = payment.interestToDate;
    if (from != null && to != null) {
      return '${_date(from)} to ${_date(to)}';
    }

    final months = payment.monthsCovered ?? 0;
    if (months > 0) return '$months month${months == 1 ? '' : 's'} covered';
    return '';
  }

  String _money(double value) => 'Rs ${_moneyFormat.format(value)}';

  String _date(DateTime? value) {
    if (value == null) return '-';
    return _dateFormat.format(value);
  }

  String _dateTime(DateTime? value) {
    if (value == null) return '-';
    return _dateTimeFormat.format(value);
  }

  String _weight(double value) => '${value.toStringAsFixed(2)} g';

  String _emptyFallback(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '-';
    return trimmed;
  }
}

class _PledgedPaymentRecordItem {
  final int serialNo;
  final String metal;
  final String itemName;
  final int pieces;
  final String purity;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double ratePerGram;
  final double value;

  const _PledgedPaymentRecordItem({
    required this.serialNo,
    required this.metal,
    required this.itemName,
    required this.pieces,
    required this.purity,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.ratePerGram,
    required this.value,
  });
}

class _PaymentRecordPhoto {
  final int serialNo;
  final String title;
  final pw.MemoryImage image;

  const _PaymentRecordPhoto({
    required this.serialNo,
    required this.title,
    required this.image,
  });
}
