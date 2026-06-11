import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/girvi/girvi_invoice_draft.dart';
import '../../models/girvi/girvi_invoice_branding.dart';
import '../../models/setting/billing_setup/girvi_billing_model.dart';

enum GirviInvoiceFormat {
  a4,
  compactA5;

  String get label => this == a4 ? 'A4 Size' : 'Compact A5';

  String get subtitle =>
      this == a4 ? 'Premium full-page invoice' : 'Landscape counter copy';

  PdfPageFormat get pageFormat =>
      this == a4 ? PdfPageFormat.a4 : PdfPageFormat.a5.landscape;
}

class GirviInvoicePdfService {
  static final _amountFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _compactAmountFormat = NumberFormat('#,##,##0', 'en_IN');
  static final _dateFormat = DateFormat('dd MMM yyyy');

  static const _navy = PdfColor.fromInt(0xFF172437);
  static const _navySoft = PdfColor.fromInt(0xFF22344E);
  static const _gold = PdfColor.fromInt(0xFFC89421);
  static const _goldLight = PdfColor.fromInt(0xFFFBF6E9);
  static const _ink = PdfColor.fromInt(0xFF172033);
  static const _muted = PdfColor.fromInt(0xFF667085);
  static const _line = PdfColor.fromInt(0xFFD8DEE8);
  static const _surface = PdfColor.fromInt(0xFFF6F8FB);

  static const customerItemHeaders = <String>[
    'S/N',
    'Metal',
    'Item',
    'Pcs',
    'HUID',
    'Purity',
    'Gross Wt.',
    'Less Wt.',
    'Net Wt.',
  ];

  Future<Uint8List> build({
    required GirviInvoiceDraft draft,
    required GirviInvoiceFormat format,
    GirviBillingModel settings = const GirviBillingModel(),
    GirviInvoiceBranding branding = GirviInvoiceBranding.fallback,
    int copies = 1,
    bool duplicateStamp = false,
  }) async {
    final devanagariFont = await _loadDevanagariFont();
    final brandLogo = _loadBrandLogo(branding);
    final pdf = pw.Document(
      theme: await _buildTheme(devanagariFont),
      title: 'Pledge Receipt ${draft.ticketNo}',
      author: branding.shopName,
      creator: branding.shopName,
      subject: 'Customer pledge receipt',
    );
    final safeCopies = copies.clamp(1, 5);

    for (var copy = 0; copy < safeCopies; copy++) {
      final copyLabel = duplicateStamp && copy == 0
          ? 'DUPLICATE COPY'
          : copy > 0
              ? 'COPY ${copy + 1}'
              : 'ORIGINAL';
      final compact = format == GirviInvoiceFormat.compactA5;

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: format.pageFormat,
            margin: pw.EdgeInsets.fromLTRB(
              compact ? 18 : 28,
              compact ? 16 : 24,
              compact ? 18 : 28,
              compact ? 18 : 22,
            ),
          ),
          footer: (context) => _buildPageFooter(
            context,
            draft,
            compact,
          ),
          build: (_) => _buildDocument(
            draft,
            format,
            copyLabel,
            settings,
            branding,
            brandLogo,
            devanagariFont,
          ),
        ),
      );
    }

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
        // The caller can still generate an English-only invoice.
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
          final regularBytes = await regularFile.readAsBytes();
          final boldBytes = await boldFile.readAsBytes();
          return pw.ThemeData.withFont(
            base: pw.Font.ttf(_asByteData(regularBytes)),
            bold: pw.Font.ttf(_asByteData(boldBytes)),
            fontFallback: devanagariFont == null ? null : [devanagariFont],
          );
        } catch (_) {
          // The built-in fonts remain a reliable fallback.
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

  List<pw.Widget> _buildDocument(
    GirviInvoiceDraft draft,
    GirviInvoiceFormat format,
    String copyLabel,
    GirviBillingModel settings,
    GirviInvoiceBranding branding,
    pw.MemoryImage? brandLogo,
    pw.Font? devanagariFont,
  ) {
    final compact = format == GirviInvoiceFormat.compactA5;
    final sectionGap = compact ? 8.0 : 10.0;
    final itemSettings = _combinedItemSettings(draft.items, settings);
    final photos = _loadPhotos(draft, settings);
    var nextSection = 1;
    final widgets = <pw.Widget>[
      _buildHeroHeader(
        draft,
        compact,
        copyLabel,
        settings,
        branding,
        brandLogo,
      ),
      pw.SizedBox(height: sectionGap),
      _buildCustomerAndLoanPanel(draft, compact, settings),
    ];
    final paymentStrip = _buildPaymentStrip(draft, settings, compact);
    if (paymentStrip != null) {
      widgets
        ..add(pw.SizedBox(height: compact ? 5 : 7))
        ..add(paymentStrip);
    }
    final compactMetrics = _buildCompactLoanMetrics(
      draft,
      settings,
      compact,
    );
    if (compactMetrics != null) {
      widgets
        ..add(pw.SizedBox(height: compact ? 5 : 7))
        ..add(compactMetrics);
    }

    if (draft.items.isNotEmpty) {
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(pw.NewPage(freeSpace: compact ? 110 : 145))
        ..add(
          _buildSectionHeading(
            number: (nextSection++).toString().padLeft(2, '0'),
            title: 'PLEDGED ITEMS',
            subtitle:
                '${draft.items.length} item${draft.items.length == 1 ? '' : 's'} recorded',
            compact: compact,
          ),
        )
        ..add(pw.SizedBox(height: compact ? 7 : 9))
        ..add(
          _buildItemsTable(
            draft.items,
            itemSettings,
            compact,
          ),
        );
      if (_hasValuationFields(itemSettings)) {
        widgets
          ..add(pw.SizedBox(height: compact ? 7 : 9))
          ..add(pw.NewPage(freeSpace: compact ? 70 : 95))
          ..add(_buildSubsectionLabel('VALUATION DETAILS', compact))
          ..add(pw.SizedBox(height: compact ? 5 : 7))
          ..add(_buildValuationTable(draft.items, itemSettings, compact));
      }
    }

    final kycSection = _buildKycSection(draft, settings, compact);
    if (kycSection != null) {
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(pw.NewPage(freeSpace: compact ? 115 : 150))
        ..add(
          _buildSectionHeading(
            number: (nextSection++).toString().padLeft(2, '0'),
            title: 'CUSTOMER KYC',
            subtitle: 'Identity document recorded with this pledge ticket',
            compact: compact,
          ),
        )
        ..add(pw.SizedBox(height: compact ? 7 : 9))
        ..add(kycSection);
    }

    if (settings.showNotes && (draft.notes?.trim().isNotEmpty ?? false)) {
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(
          _buildTextSection(
            number: (nextSection++).toString().padLeft(2, '0'),
            title: 'NOTES & REMARKS',
            subtitle: 'Remarks recorded for this Girvi ticket',
            body: draft.notes!.trim(),
            compact: compact,
          ),
        );
    }

    if (photos.isNotEmpty) {
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(pw.NewPage(freeSpace: compact ? 115 : 145))
        ..add(
          _buildPhotoSection(
            photos,
            compact,
            sectionNumber: (nextSection++).toString().padLeft(2, '0'),
          ),
        );
    }

    if (settings.printTermsAndConditions &&
        (settings.termsAndConditions.trim().isNotEmpty ||
            settings.termsAndConditionsHindi.trim().isNotEmpty)) {
      final terms = pairBilingualLines(
        settings.termsAndConditions,
        settings.termsAndConditionsHindi,
      );
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(pw.NewPage(freeSpace: compact ? 105 : 135))
        ..add(
          _buildSectionHeading(
            number: (nextSection++).toString().padLeft(2, '0'),
            title: 'TERMS & CONDITIONS',
            subtitle:
                'Each condition is printed separately in English and Hindi',
            compact: compact,
          ),
        )
        ..add(pw.SizedBox(height: compact ? 7 : 9));
      for (var index = 0; index < terms.length; index++) {
        if (index > 0) widgets.add(pw.SizedBox(height: compact ? 5 : 7));
        widgets.add(
          _buildBilingualTermRow(
            index: index + 1,
            english: terms[index].english,
            hindi: terms[index].hindi,
            compact: compact,
            devanagariFont: devanagariFont,
          ),
        );
      }
    }

    if (settings.printCustomerDeclaration &&
        (settings.customerDeclaration.trim().isNotEmpty ||
            settings.customerDeclarationHindi.trim().isNotEmpty)) {
      widgets
        ..add(pw.SizedBox(height: sectionGap))
        ..add(pw.NewPage(freeSpace: compact ? 78 : 105))
        ..add(
          _buildCustomerDeclaration(
            number: (nextSection++).toString().padLeft(2, '0'),
            english: settings.customerDeclaration,
            hindi: settings.customerDeclarationHindi,
            compact: compact,
            devanagariFont: devanagariFont,
          ),
        );
    }
    widgets
      ..add(pw.SizedBox(height: sectionGap))
      ..add(pw.NewPage(freeSpace: compact ? 68 : 96))
      ..add(_buildDocumentSignoff(compact, settings));
    return widgets;
  }

  static List<({String english, String hindi})> pairBilingualLines(
    String english,
    String hindi,
  ) {
    List<String> lines(String value) => value
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    final englishLines = lines(english);
    final hindiLines = lines(hindi);
    final count = englishLines.length > hindiLines.length
        ? englishLines.length
        : hindiLines.length;
    return List.generate(
      count,
      (index) => (
        english: index < englishLines.length ? englishLines[index] : '',
        hindi: index < hindiLines.length ? hindiLines[index] : '',
      ),
      growable: false,
    );
  }

  pw.Widget _buildHeroHeader(
    GirviInvoiceDraft draft,
    bool compact,
    String copyLabel,
    GirviBillingModel settings,
    GirviInvoiceBranding branding,
    pw.MemoryImage? brandLogo,
  ) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Padding(
            padding: pw.EdgeInsets.fromLTRB(
              compact ? 12 : 16,
              compact ? 11 : 15,
              compact ? 12 : 16,
              compact ? 9 : 12,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _buildBrandMark(
                  branding,
                  brandLogo,
                  compact,
                ),
                pw.SizedBox(width: compact ? 10 : 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        branding.shopName.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: compact ? 14 : 19,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (branding.shopAddress.trim().isNotEmpty) ...[
                        pw.SizedBox(height: compact ? 2 : 3),
                        pw.Text(
                          branding.shopAddress.trim(),
                          maxLines: compact ? 1 : 2,
                          overflow: pw.TextOverflow.clip,
                          style: pw.TextStyle(
                            color: PdfColors.grey200,
                            fontSize: compact ? 7 : 8.5,
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
                            fontSize: compact ? 6.2 : 7.2,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: compact ? 8 : 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 11,
                        vertical: compact ? 5 : 7,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: _goldLight,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Text(
                        'PLEDGE RECEIPT',
                        style: pw.TextStyle(
                          color: _navy,
                          fontSize: compact ? 7 : 8.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: compact ? 4 : 5),
                    pw.Text(
                      copyLabel,
                      style: pw.TextStyle(
                        color: _gold,
                        fontSize: compact ? 5.5 : 6.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Container(
            height: 1.4,
            color: _gold,
          ),
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 7 : 9,
            ),
            child: pw.Row(
              children: [
                _buildHeaderMeta(
                  label: 'RECEIPT NUMBER',
                  value: draft.ticketNo,
                  compact: compact,
                ),
                _buildHeaderDivider(compact),
                _buildHeaderMeta(
                  label: 'ISSUE DATE',
                  value: _dateFormat.format(draft.createdAt),
                  compact: compact,
                ),
                if (settings.showStartDate) ...[
                  _buildHeaderDivider(compact),
                  _buildHeaderMeta(
                    label: 'START DATE',
                    value: _dateFormat.format(draft.startDate),
                    compact: compact,
                  ),
                ],
                if (settings.showMaturityDate || settings.showDuration) ...[
                  _buildHeaderDivider(compact),
                  _buildHeaderMeta(
                    label: settings.showMaturityDate
                        ? 'MATURITY DATE'
                        : 'LOAN TENURE',
                    value: settings.showMaturityDate
                        ? '${_dateFormat.format(draft.maturityDate)}'
                            '${settings.showDuration ? ' | ${draft.durationMonths} months' : ''}'
                        : '${draft.durationMonths} months',
                    compact: compact,
                  ),
                ],
                pw.Spacer(),
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
    bool compact,
  ) {
    final size = compact ? 40.0 : 52.0;
    final content = brandLogo == null
        ? pw.Container(
            alignment: pw.Alignment.center,
            color: _gold,
            child: pw.Text(
              branding.initial,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: compact ? 17 : 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          )
        : pw.Container(
            color: PdfColors.white,
            child: pw.Image(
              brandLogo,
              fit: pw.BoxFit.cover,
            ),
          );
    final clipped = branding.logoShape == 'square'
        ? pw.ClipRRect(
            horizontalRadius: compact ? 5 : 7,
            verticalRadius: compact ? 5 : 7,
            child: content,
          )
        : pw.ClipOval(child: content);

    return pw.Container(
      width: size,
      height: size,
      padding: pw.EdgeInsets.all(compact ? 1.5 : 2),
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

  pw.Widget _buildHeaderDivider(bool compact) {
    return pw.Container(
      width: 0.7,
      height: compact ? 22 : 27,
      margin: pw.EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
      ),
      color: PdfColors.grey700,
    );
  }

  pw.Widget _buildHeaderMeta({
    required String label,
    required String value,
    required bool compact,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColors.grey400,
            fontSize: compact ? 6.5 : 7.5,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: compact ? 8.5 : 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerAndLoanPanel(
    GirviInvoiceDraft draft,
    bool compact,
    GirviBillingModel settings,
  ) {
    final panelHeight = compact ? 90.0 : 112.0;
    final showLoanPanel = settings.showLoanAmount ||
        settings.showInterestRate ||
        settings.showMonthlyInterest;
    final customerMeta = <pw.Widget>[
      if (settings.showCustomerMobile)
        pw.Expanded(
          flex: 4,
          child: _buildCustomerMeta(
            label: 'MOBILE',
            value: draft.customerMobile,
            compact: compact,
          ),
        ),
      if (settings.showCustomerMobile && settings.showCustomerCity)
        pw.SizedBox(width: compact ? 8 : 12),
      if (settings.showCustomerCity)
        pw.Expanded(
          flex: 6,
          child: _buildCustomerMeta(
            label: 'CITY',
            value: draft.customerCity.isEmpty ? '-' : draft.customerCity,
            compact: compact,
          ),
        ),
    ];
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: showLoanPanel ? 5 : 1,
          child: pw.Container(
            height: panelHeight,
            padding: pw.EdgeInsets.all(compact ? 10 : 13),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _line),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildEyebrow('CUSTOMER DETAILS', compact),
                pw.SizedBox(height: compact ? 5 : 7),
                pw.Text(
                  draft.customerName,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: compact ? 11 : 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (customerMeta.isNotEmpty) ...[
                  pw.Spacer(),
                  pw.Row(children: customerMeta),
                ],
              ],
            ),
          ),
        ),
        if (showLoanPanel) ...[
          pw.SizedBox(width: compact ? 9 : 12),
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              height: panelHeight,
              padding: pw.EdgeInsets.all(compact ? 10 : 13),
              decoration: pw.BoxDecoration(
                color: _goldLight,
                border: pw.Border.all(
                  color: _gold,
                  width: 0.8,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildEyebrow(
                    settings.showLoanAmount
                        ? 'LOAN AMOUNT'
                        : settings.showMonthlyInterest
                            ? 'MONTHLY INTEREST'
                            : 'INTEREST RATE',
                    compact,
                    color: _gold,
                  ),
                  pw.SizedBox(height: compact ? 4 : 6),
                  pw.Text(
                    settings.showLoanAmount
                        ? _amount(draft.loanAmount)
                        : settings.showMonthlyInterest
                            ? _amount(draft.monthlyInterest)
                            : '${draft.interestRate.toStringAsFixed(2)}% monthly',
                    style: pw.TextStyle(
                      color: _navy,
                      fontSize: compact ? 14 : 19,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if ((settings.showLoanAmount &&
                          (settings.showInterestRate ||
                              settings.showMonthlyInterest)) ||
                      (!settings.showLoanAmount &&
                          settings.showInterestRate &&
                          settings.showMonthlyInterest)) ...[
                    pw.Spacer(),
                    pw.Container(
                      width: double.infinity,
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: compact ? 7 : 9,
                        vertical: compact ? 5 : 6,
                      ),
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
                                  fontSize: compact ? 5.5 : 6.5,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              pw.Spacer(),
                              if (settings.showInterestRate)
                                pw.Text(
                                  '${draft.interestRate.toStringAsFixed(2)}% monthly',
                                  style: pw.TextStyle(
                                    color: _navy,
                                    fontSize: compact ? 7 : 8.2,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          if (settings.showMonthlyInterest) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Rs ${_compactAmountFormat.format(draft.monthlyInterest)} per month',
                              maxLines: 1,
                              overflow: pw.TextOverflow.clip,
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                color: _gold,
                                fontSize: compact ? 7 : 8.4,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildEyebrow(
    String value,
    bool compact, {
    PdfColor color = _muted,
  }) {
    return pw.Text(
      value,
      style: pw.TextStyle(
        color: color,
        fontSize: compact ? 7 : 8.2,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.7,
      ),
    );
  }

  pw.Widget _buildCustomerMeta({
    required String label,
    required String value,
    required bool compact,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildEyebrow(label, compact),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            color: _ink,
            fontSize: compact ? 8.5 : 10.2,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSectionHeading({
    required String number,
    required String title,
    required String subtitle,
    required bool compact,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: compact ? 24 : 29,
          height: compact ? 24 : 29,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Text(
            number,
            style: pw.TextStyle(
              color: _gold,
              fontSize: compact ? 7 : 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: compact ? 8 : 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: _ink,
                fontSize: compact ? 9.5 : 11.5,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                color: _muted,
                fontSize: compact ? 6.8 : 8,
              ),
            ),
          ],
        ),
        pw.SizedBox(width: compact ? 10 : 14),
        pw.Expanded(
          child: pw.Container(
            height: 0.7,
            color: _line,
          ),
        ),
      ],
    );
  }

  GirviInvoiceFieldSettings _combinedItemSettings(
    List<GirviInvoiceItemDraft> items,
    GirviBillingModel settings,
  ) {
    final metals =
        items.map((item) => GirviBillingMetal.normalize(item.metal)).toSet();
    if (metals.isEmpty) return const GirviInvoiceFieldSettings();

    final metalSettings = [
      for (final metal in metals) settings.settingsForMetal(metal),
    ];
    bool enabled(bool Function(GirviInvoiceFieldSettings value) read) =>
        metalSettings.any(read);

    return GirviInvoiceFieldSettings(
      showSerialNumber: enabled((value) => value.showSerialNumber),
      showMetal: enabled((value) => value.showMetal),
      showItemName: enabled((value) => value.showItemName),
      showPieces: enabled((value) => value.showPieces),
      showHuid: enabled((value) => value.showHuid),
      showPurity: enabled((value) => value.showPurity),
      showGrossWeight: enabled((value) => value.showGrossWeight),
      showLessWeight: enabled((value) => value.showLessWeight),
      showNetWeight: enabled((value) => value.showNetWeight),
      showValuationPurity: enabled((value) => value.showValuationPurity),
      showFineWeight: enabled((value) => value.showFineWeight),
      showRatePerGram: enabled((value) => value.showRatePerGram),
      showValuationAmount: enabled((value) => value.showValuationAmount),
      showItemPhotos: enabled((value) => value.showItemPhotos),
    );
  }

  pw.Widget _buildItemsTable(
    List<GirviInvoiceItemDraft> items,
    GirviInvoiceFieldSettings settings,
    bool compact,
  ) {
    final columns = _visibleColumns(settings);
    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: _navySoft),
        children: [
          for (final column in columns)
            _buildTableCell(
              column.header,
              compact: compact,
              header: true,
              alignment: column.alignment,
            ),
        ],
      ),
      for (var index = 0; index < items.length; index++)
        _buildItemRow(items[index], index, columns, compact),
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Table(
        columnWidths: {
          for (var index = 0; index < columns.length; index++)
            index: pw.FlexColumnWidth(columns[index].width),
        },
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _line, width: 0.45),
          verticalInside: pw.BorderSide(color: _line, width: 0.45),
        ),
        children: rows,
      ),
    );
  }

  bool _hasValuationFields(GirviInvoiceFieldSettings settings) {
    return settings.showValuationPurity ||
        settings.showFineWeight ||
        settings.showRatePerGram ||
        settings.showValuationAmount;
  }

  pw.Widget _buildSubsectionLabel(String label, bool compact) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: const pw.BoxDecoration(
        color: _goldLight,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          color: _gold,
          fontSize: compact ? 6.8 : 7.8,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  pw.Widget _buildValuationTable(
    List<GirviInvoiceItemDraft> items,
    GirviInvoiceFieldSettings settings,
    bool compact,
  ) {
    final columns = <_GirviInvoiceColumn>[
      if (settings.showSerialNumber)
        _GirviInvoiceColumn(
          header: 'S/N',
          width: 0.45,
          alignment: pw.Alignment.center,
          strong: true,
          value: (item) => item.serialNo.toString(),
        ),
      if (settings.showItemName)
        _GirviInvoiceColumn(
          header: 'Item',
          width: 2.4,
          alignment: pw.Alignment.centerLeft,
          strong: true,
          value: (item) => item.description,
        ),
      if (settings.showNetWeight)
        _GirviInvoiceColumn(
          header: 'Net Wt.',
          width: 0.9,
          alignment: pw.Alignment.centerRight,
          value: (item) => '${item.netWeight.toStringAsFixed(3)} g',
        ),
      if (settings.showValuationPurity)
        _GirviInvoiceColumn(
          header: 'Val. Purity',
          width: 0.85,
          alignment: pw.Alignment.center,
          value: (item) => item.valuationPurity,
        ),
      if (settings.showFineWeight)
        _GirviInvoiceColumn(
          header: 'Fine Wt.',
          width: 0.9,
          alignment: pw.Alignment.centerRight,
          value: (item) => '${item.fineWeight.toStringAsFixed(3)} g',
        ),
      if (settings.showRatePerGram)
        _GirviInvoiceColumn(
          header: 'Rate / g',
          width: 1.0,
          alignment: pw.Alignment.centerRight,
          value: (item) => _amount(item.ratePerGram),
        ),
      if (settings.showValuationAmount)
        _GirviInvoiceColumn(
          header: 'Valuation',
          width: 1.15,
          alignment: pw.Alignment.centerRight,
          strong: true,
          value: (item) => _amount(item.value),
        ),
    ];

    if (!settings.showSerialNumber && !settings.showItemName) {
      columns.insert(
        0,
        _GirviInvoiceColumn(
          header: 'Item',
          width: 2.4,
          alignment: pw.Alignment.centerLeft,
          strong: true,
          value: (item) => item.description,
        ),
      );
    }

    return _buildColumnTable(items, columns, compact);
  }

  pw.Widget _buildColumnTable(
    List<GirviInvoiceItemDraft> items,
    List<_GirviInvoiceColumn> columns,
    bool compact,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Table(
        columnWidths: {
          for (var index = 0; index < columns.length; index++)
            index: pw.FlexColumnWidth(columns[index].width),
        },
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _line, width: 0.45),
          verticalInside: pw.BorderSide(color: _line, width: 0.45),
        ),
        children: [
          pw.TableRow(
            repeat: true,
            decoration: const pw.BoxDecoration(color: _navySoft),
            children: [
              for (final column in columns)
                _buildTableCell(
                  column.header,
                  compact: compact,
                  header: true,
                  alignment: column.alignment,
                ),
            ],
          ),
          for (var index = 0; index < items.length; index++)
            _buildItemRow(items[index], index, columns, compact),
        ],
      ),
    );
  }

  pw.TableRow _buildItemRow(
    GirviInvoiceItemDraft item,
    int index,
    List<_GirviInvoiceColumn> columns,
    bool compact,
  ) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: index.isEven ? PdfColors.white : _surface,
      ),
      children: [
        for (final column in columns)
          _buildTableCell(
            column.value(item),
            compact: compact,
            alignment: column.alignment,
            strong: column.strong,
          ),
      ],
    );
  }

  List<_GirviInvoiceColumn> _visibleColumns(
    GirviInvoiceFieldSettings settings,
  ) {
    final columns = <_GirviInvoiceColumn>[
      if (settings.showSerialNumber)
        _GirviInvoiceColumn(
          header: 'S/N',
          width: 0.46,
          alignment: pw.Alignment.center,
          strong: true,
          value: (item) => item.serialNo.toString(),
        ),
      if (settings.showMetal)
        _GirviInvoiceColumn(
          header: 'Metal',
          width: 0.72,
          alignment: pw.Alignment.center,
          value: (item) => item.metal,
        ),
      if (settings.showItemName)
        _GirviInvoiceColumn(
          header: 'Item',
          width: 2.35,
          alignment: pw.Alignment.centerLeft,
          strong: true,
          value: (item) => item.description,
        ),
      if (settings.showPieces)
        _GirviInvoiceColumn(
          header: 'Pcs',
          width: 0.48,
          alignment: pw.Alignment.center,
          value: (item) => item.pieces.toString(),
        ),
      if (settings.showHuid)
        _GirviInvoiceColumn(
          header: 'HUID',
          width: 0.9,
          alignment: pw.Alignment.center,
          value: (item) => item.huid.isEmpty ? '-' : item.huid,
        ),
      if (settings.showPurity)
        _GirviInvoiceColumn(
          header: 'Purity',
          width: 0.7,
          alignment: pw.Alignment.center,
          value: (item) => item.purity,
        ),
      if (settings.showGrossWeight)
        _GirviInvoiceColumn(
          header: 'Gross Wt.',
          width: 0.92,
          alignment: pw.Alignment.centerRight,
          value: (item) => '${item.grossWeight.toStringAsFixed(3)} g',
        ),
      if (settings.showLessWeight)
        _GirviInvoiceColumn(
          header: 'Less Wt.',
          width: 0.86,
          alignment: pw.Alignment.centerRight,
          value: (item) => '${item.lessWeight.toStringAsFixed(3)} g',
        ),
      if (settings.showNetWeight)
        _GirviInvoiceColumn(
          header: 'Net Wt.',
          width: 0.92,
          alignment: pw.Alignment.centerRight,
          strong: true,
          value: (item) => '${item.netWeight.toStringAsFixed(3)} g',
        ),
    ];
    if (columns.isNotEmpty) return columns;
    return [
      _GirviInvoiceColumn(
        header: 'Item',
        width: 1,
        alignment: pw.Alignment.centerLeft,
        strong: true,
        value: (item) => item.description,
      ),
    ];
  }

  pw.Widget _buildTableCell(
    String value, {
    required bool compact,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    bool header = false,
    bool strong = false,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: pw.EdgeInsets.symmetric(
        horizontal: compact ? 3 : 4,
        vertical: compact ? 5 : 6.5,
      ),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          color: header ? PdfColors.white : _ink,
          fontSize: header ? (compact ? 7.2 : 8) : (compact ? 7.4 : 8.4),
          fontWeight:
              header || strong ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  List<_GirviPhoto> _loadPhotos(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
  ) {
    final photos = <_GirviPhoto>[];
    for (final item in draft.items) {
      if (!settings.settingsForMetal(item.metal).showItemPhotos) continue;
      for (final path in item.photoPaths) {
        final file = File(path);
        if (!file.existsSync()) continue;
        try {
          photos.add(
            _GirviPhoto(
              serialNo: item.serialNo,
              title: item.description,
              image: pw.MemoryImage(file.readAsBytesSync()),
            ),
          );
        } catch (_) {
          // A damaged image should not stop the customer invoice.
        }
      }
    }
    return photos;
  }

  pw.Widget? _buildPaymentStrip(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
    bool compact,
  ) {
    if (!settings.showDisbursementDetails) return null;
    final value = draft.payments.isNotEmpty
        ? draft.payments
            .map((payment) => '${payment.label} ${_amount(payment.amount)}')
            .join('  |  ')
        : draft.disbursementSummary.trim();
    if (value.isEmpty) return null;

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: pw.BoxDecoration(
        color: _surface,
        border: pw.Border.all(color: _line, width: 0.65),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'DISBURSEMENT',
            style: pw.TextStyle(
              color: _muted,
              fontSize: compact ? 6 : 7,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(width: compact ? 8 : 11),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                color: _ink,
                fontSize: compact ? 7.2 : 8.3,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget? _buildCompactLoanMetrics(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
    bool compact,
  ) {
    final entries = <_GirviDetailEntry>[
      if (settings.showTotalInterest)
        _GirviDetailEntry(
          label: 'Total Interest at Maturity',
          value: _amount(draft.totalInterest),
        ),
      if (settings.showTotalDue)
        _GirviDetailEntry(
          label: 'Total Amount Due',
          value: _amount(draft.totalDue),
          strong: true,
        ),
      if (settings.showTotalValue)
        _GirviDetailEntry(
          label: 'Total Pledged Valuation',
          value: _amount(draft.totalValue),
          strong: true,
        ),
    ];
    if (entries.isEmpty) return null;
    return pw.Row(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0) pw.SizedBox(width: compact ? 5 : 7),
          pw.Expanded(child: _buildDetailCard(entries[index], compact)),
        ],
      ],
    );
  }

  pw.Widget _buildDetailCard(_GirviDetailEntry entry, bool compact) {
    return pw.Container(
      padding: pw.EdgeInsets.all(compact ? 7 : 9),
      decoration: pw.BoxDecoration(
        color: entry.strong ? _goldLight : _surface,
        border: pw.Border.all(
          color: entry.strong ? _gold : _line,
          width: 0.65,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildEyebrow(entry.label.toUpperCase(), compact),
          pw.SizedBox(height: compact ? 3 : 4),
          pw.Text(
            entry.value,
            style: pw.TextStyle(
              color: _ink,
              fontSize: compact ? 8 : 9.5,
              fontWeight:
                  entry.strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBilingualTermRow({
    required int index,
    required String english,
    required String hindi,
    required bool compact,
    required pw.Font? devanagariFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(compact ? 7 : 9),
      decoration: pw.BoxDecoration(
        color: index.isOdd ? _goldLight : _surface,
        border: pw.Border.all(
          color: index.isOdd ? const PdfColor.fromInt(0xFFEAD6A0) : _line,
          width: 0.65,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: compact ? 18 : 22,
            height: compact ? 18 : 22,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              color: _navy,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              index.toString(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: compact ? 6.5 : 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: compact ? 7 : 9),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (english.isNotEmpty)
                  pw.Text(
                    english,
                    style: pw.TextStyle(
                      color: _ink,
                      fontSize: compact ? 7 : 8.2,
                      lineSpacing: 1.8,
                    ),
                  ),
                if (english.isNotEmpty && hindi.isNotEmpty)
                  pw.SizedBox(height: compact ? 3 : 4),
                if (hindi.isNotEmpty)
                  pw.Text(
                    hindi,
                    style: pw.TextStyle(
                      font: devanagariFont,
                      color: _navySoft,
                      fontSize: compact ? 7.2 : 8.5,
                      lineSpacing: 2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerDeclaration({
    required String number,
    required String english,
    required String hindi,
    required bool compact,
    required pw.Font? devanagariFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          number: number,
          title: 'CUSTOMER DECLARATION',
          subtitle: 'Bilingual acknowledgement before signing',
          compact: compact,
        ),
        pw.SizedBox(height: compact ? 7 : 9),
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(compact ? 8 : 11),
          decoration: pw.BoxDecoration(
            color: _surface,
            border: pw.Border.all(color: _line, width: 0.7),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (english.trim().isNotEmpty)
                pw.Text(
                  english.trim(),
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: compact ? 7.2 : 8.5,
                    lineSpacing: 2,
                  ),
                ),
              if (english.trim().isNotEmpty && hindi.trim().isNotEmpty)
                pw.SizedBox(height: compact ? 5 : 7),
              if (hindi.trim().isNotEmpty)
                pw.Text(
                  hindi.trim(),
                  style: pw.TextStyle(
                    font: devanagariFont,
                    color: _navySoft,
                    fontSize: compact ? 7.4 : 8.8,
                    lineSpacing: 2.2,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget? _buildKycSection(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
    bool compact,
  ) {
    final showDetails = settings.showKycDetails &&
        ((draft.idProofType?.trim().isNotEmpty ?? false) ||
            (draft.idProofNumber?.trim().isNotEmpty ?? false));
    pw.MemoryImage? image;
    if (settings.showKycPhoto &&
        (draft.idProofImagePath?.trim().isNotEmpty ?? false)) {
      final file = File(draft.idProofImagePath!.trim());
      if (file.existsSync()) {
        try {
          image = pw.MemoryImage(file.readAsBytesSync());
        } catch (_) {
          image = null;
        }
      }
    }
    if (!showDetails && image == null) return null;

    final details = pw.Container(
      padding: pw.EdgeInsets.all(compact ? 8 : 11),
      decoration: pw.BoxDecoration(
        color: _surface,
        border: pw.Border.all(color: _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (showDetails) ...[
            _buildCustomerMeta(
              label: 'DOCUMENT TYPE',
              value: draft.idProofType?.trim().isEmpty ?? true
                  ? '-'
                  : draft.idProofType!.trim(),
              compact: compact,
            ),
            pw.SizedBox(height: compact ? 7 : 9),
            _buildCustomerMeta(
              label: 'DOCUMENT NUMBER',
              value: draft.idProofNumber?.trim().isEmpty ?? true
                  ? '-'
                  : draft.idProofNumber!.trim(),
              compact: compact,
            ),
          ] else
            pw.Text(
              'KYC document photo attached',
              style: pw.TextStyle(
                color: _ink,
                fontSize: compact ? 8 : 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
        ],
      ),
    );

    if (image == null) return details;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 5, child: details),
        pw.SizedBox(width: compact ? 8 : 11),
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            height: compact ? 80 : 110,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _line),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTextSection({
    required String number,
    required String title,
    required String subtitle,
    required String body,
    required bool compact,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          number: number,
          title: title,
          subtitle: subtitle,
          compact: compact,
        ),
        pw.SizedBox(height: compact ? 7 : 9),
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(compact ? 8 : 11),
          decoration: pw.BoxDecoration(
            color: _surface,
            border: pw.Border.all(color: _line),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Text(
            body,
            style: pw.TextStyle(
              color: _ink,
              fontSize: compact ? 7.5 : 8.8,
              lineSpacing: compact ? 2 : 3,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPhotoSection(
    List<_GirviPhoto> photos,
    bool compact, {
    required String sectionNumber,
  }) {
    const columns = 3;
    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionHeading(
                number: sectionNumber,
                title: 'PLEDGED ITEM PHOTOS',
                subtitle: 'Visual reference attached with this receipt',
                compact: compact,
              ),
              pw.SizedBox(height: compact ? 7 : 9),
            ],
          ),
        ],
      ),
    ];
    for (var start = 0; start < photos.length; start += columns) {
      final end =
          (start + columns < photos.length) ? start + columns : photos.length;
      final rowPhotos = photos.sublist(start, end);
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.only(
                bottom: start + columns < photos.length ? (compact ? 7 : 9) : 0,
              ),
              child: _buildPhotoRow(rowPhotos, columns, compact),
            ),
          ],
        ),
      );
    }
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
      },
      children: rows,
    );
  }

  pw.Widget _buildPhotoRow(
    List<_GirviPhoto> photos,
    int columns,
    bool compact,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < columns; index++) ...[
          if (index > 0) pw.SizedBox(width: compact ? 7 : 9),
          pw.Expanded(
            child: index < photos.length
                ? _buildPhotoCard(photos[index], compact)
                : pw.SizedBox(),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildPhotoCard(
    _GirviPhoto photo,
    bool compact,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(compact ? 4 : 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            height: compact ? 70 : 94,
            width: double.infinity,
            padding: const pw.EdgeInsets.all(3),
            decoration: const pw.BoxDecoration(
              color: _surface,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Image(
              photo.image,
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(height: compact ? 4 : 5),
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: const pw.BoxDecoration(
                  color: _goldLight,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  '#${photo.serialNo}',
                  style: pw.TextStyle(
                    color: _gold,
                    fontSize: compact ? 7 : 8,
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
                    fontSize: compact ? 7 : 8.2,
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

  pw.Widget _buildPageFooter(
    pw.Context context,
    GirviInvoiceDraft draft,
    bool compact,
  ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        '${draft.ticketNo}  |  Page ${context.pageNumber}',
        style: pw.TextStyle(
          color: _muted,
          fontSize: compact ? 6.5 : 7.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildDocumentSignoff(
    bool compact,
    GirviBillingModel settings,
  ) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (settings.printFooterMessage &&
            settings.footerMessage.trim().isNotEmpty) ...[
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(
              horizontal: compact ? 7 : 9,
              vertical: compact ? 5 : 6,
            ),
            decoration: const pw.BoxDecoration(
              color: _goldLight,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              settings.footerMessage.trim(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: _ink,
                fontSize: compact ? 7 : 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: compact ? 8 : 11),
        ],
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSignature('Customer Signature', compact),
            _buildSignature('Authorized Signature / Stamp', compact),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSignature(String label, bool compact) {
    return pw.SizedBox(
      width: compact ? 128 : 165,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(height: compact ? 21 : 30),
          pw.Container(height: 0.7, color: _muted),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              color: _muted,
              fontSize: compact ? 7.5 : 8.5,
            ),
          ),
        ],
      ),
    );
  }

  String _amount(double value) => 'Rs ${_amountFormat.format(value)}';
}

class _GirviInvoiceColumn {
  const _GirviInvoiceColumn({
    required this.header,
    required this.width,
    required this.alignment,
    required this.value,
    this.strong = false,
  });

  final String header;
  final double width;
  final pw.Alignment alignment;
  final String Function(GirviInvoiceItemDraft item) value;
  final bool strong;
}

class _GirviDetailEntry {
  const _GirviDetailEntry({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;
}

class _GirviPhoto {
  const _GirviPhoto({
    required this.serialNo,
    required this.title,
    required this.image,
  });

  final int serialNo;
  final String title;
  final pw.MemoryImage image;
}
