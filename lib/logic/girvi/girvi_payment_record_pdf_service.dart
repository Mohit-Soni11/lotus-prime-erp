import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/girvi/girvi_account_lifecycle_summary.dart';
import '../../models/girvi/girvi_invoice_branding.dart';
import '../../models/girvi/girvi_loan_model.dart';

class GirviPaymentRecordPdfService {
  static final _moneyFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static const _navy = PdfColor.fromInt(0xFF172437);
  static const _gold = PdfColor.fromInt(0xFFC89421);
  static const _goldLight = PdfColor.fromInt(0xFFFBF6E9);
  static const _ink = PdfColor.fromInt(0xFF172033);
  static const _muted = PdfColor.fromInt(0xFF111111);
  static const _line = PdfColor.fromInt(0xFFD8DEE8);
  static const _surface = PdfColor.fromInt(0xFFF6F8FB);
  static const _success = PdfColor.fromInt(0xFF047857);
  static const _warning = PdfColor.fromInt(0xFFB7791F);
  static const _danger = PdfColor.fromInt(0xFFB91C1C);

  Future<Uint8List> build({
    required GirviLoanWithCustomer account,
    required List<GirviPaymentModel> payments,
    GirviInvoiceBranding branding = GirviInvoiceBranding.fallback,
  }) async {
    final devanagariFont = await _loadDevanagariFont();
    final brandLogo = _loadBrandLogo(branding);
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
        build: (_) => [
          _buildHeroHeader(account, branding, brandLogo),
          pw.SizedBox(height: 10),
          _buildCustomerAndLoanPanel(account),
          pw.SizedBox(height: 10),
          _buildFinancialStrip(account, sortedPayments),
          pw.SizedBox(height: 12),
          _buildSectionHeading(
            number: '01',
            title: 'PAYMENT RECORD',
            subtitle:
                '${sortedPayments.length} date-wise payment entr${sortedPayments.length == 1 ? 'y' : 'ies'}',
          ),
          pw.SizedBox(height: 8),
          ..._buildPaymentRecord(sortedPayments),
          pw.SizedBox(height: 12),
          _buildSectionHeading(
            number: '02',
            title: 'PLEDGED ITEM SNAPSHOT',
            subtitle: 'Loan and item details attached to this account',
          ),
          pw.SizedBox(height: 8),
          _buildPledgedItemSnapshot(account),
          pw.SizedBox(height: 18),
          _buildSignatureBlock(),
        ],
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
                            fontSize: 8.5,
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
                            fontSize: 7.2,
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
                          fontSize: 8.5,
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
                        fontSize: 6.5,
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
            color: PdfColors.grey300,
            fontSize: 6.5,
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
            fontSize: 8.2,
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
          child: _panel(
            title: 'CUSTOMER PROFILE',
            children: [
              _labelValue('Customer Name', account.customerName),
              _labelValue('Mobile Number', account.customerMobile),
              _labelValue(
                'Address',
                _emptyFallback(account.customerAddress),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          flex: 6,
          child: _panel(
            title: 'LOAN SUMMARY',
            children: [
              _twoColumnLine(
                'Principal',
                _money(account.originalPrincipal),
                'Interest Rate',
                '${account.loan.interestRate.toStringAsFixed(2)}% monthly',
              ),
              _twoColumnLine(
                'Item',
                '${account.loan.itemCount} item${account.loan.itemCount == 1 ? '' : 's'}',
                'Net Weight',
                _weight(account.loan.netWeight),
              ),
              _twoColumnLine(
                'Status',
                _accountStatus(account),
                'Net Payable',
                _money(account.totalPayable),
              ),
            ],
          ),
        ),
      ],
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
        color: _surface,
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
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 7),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionHeading({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 28,
          height: 28,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: _goldLight,
            border: pw.Border.all(color: _gold, width: 0.7),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            number,
            style: pw.TextStyle(
              color: _gold,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
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
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(color: _muted, fontSize: 7.5),
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
            color: _surface,
            border: pw.Border.all(color: _line),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
          ),
          child: pw.Text(
            'No payment has been recorded for this Girvi account.',
            style: const pw.TextStyle(color: _ink, fontSize: 9),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
    final bgColor = index.isEven ? PdfColors.white : _surface;
    final notes = payment.notes?.trim();

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
          fontSize: header ? 6.8 : 6.7,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
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
              fontSize: 6.9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 1.5),
            pw.Text(
              subtitle,
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
              style:
                  const pw.TextStyle(color: PdfColors.grey700, fontSize: 6.2),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPledgedItemSnapshot(GirviLoanWithCustomer account) {
    final rows = [
      ['Item Name', account.loan.itemDescription],
      ['Item Count', account.loan.itemCount.toString()],
      [
        'Metal / Purity',
        '${account.loan.metalTypeEnum.displayName} / ${account.loan.metalPurity}',
      ],
      ['Gross Weight', _weight(account.loan.grossWeight)],
      if (account.loan.stoneWeight > 0.001)
        ['Less Weight', _weight(account.loan.stoneWeight)],
      ['Net Weight', _weight(account.loan.netWeight)],
      ['Rate Per Gram', _money(account.loan.ratePerGram)],
      ['Pledged Value', _money(account.loan.totalValue)],
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _detailTable(rows.take(4).toList())),
        pw.SizedBox(width: 10),
        pw.Expanded(child: _detailTable(rows.skip(4).toList())),
      ],
    );
  }

  pw.Widget _panel({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _surface,
        border: pw.Border.all(color: _line, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _navy,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 82,
            child: pw.Text(
              label,
              style:
                  const pw.TextStyle(color: PdfColors.grey700, fontSize: 7.2),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: _ink,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _twoColumnLine(
    String firstLabel,
    String firstValue,
    String secondLabel,
    String secondValue,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Expanded(child: _compactLabelValue(firstLabel, firstValue)),
          pw.SizedBox(width: 10),
          pw.Expanded(child: _compactLabelValue(secondLabel, secondValue)),
        ],
      ),
    );
  }

  pw.Widget _compactLabelValue(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 6.7),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            color: _ink,
            fontSize: 7.8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _detailTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headers: null,
      data: rows,
      border: pw.TableBorder.all(color: _line, width: 0.6),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _ink),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.05),
        1: pw.FlexColumnWidth(1.45),
      },
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
      oddRowDecoration: const pw.BoxDecoration(color: _surface),
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
            style: const pw.TextStyle(fontSize: 8, color: _muted),
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
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 7.5),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 7.5),
        ),
      ],
    );
  }

  String _accountStatus(GirviLoanWithCustomer account) {
    final summary = GirviAccountLifecycleSummary.fromAccount(
      account,
      dateLabel: _date,
      dateTimeLabel: _dateTime,
      moneyLabel: _money,
    );
    if (summary.delivered) return 'Delivered and Closed';
    if (summary.settlementComplete) return 'Settlement Complete';
    if (account.loan.isOverdue) return 'Overdue';
    return account.loan.statusLabel;
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
