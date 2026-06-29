import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../models/setting/billing_setup/sales_billing_model.dart';
import '../../repositories/setting/billing_setup/purchase_billing_repo.dart';
import 'purchase_entry_controller.dart';

class PurchaseVoucherPrintService {
  PurchaseVoucherPrintService._();

  static final PurchaseBillingRepo _billingRepo = PurchaseBillingRepo();

  static Future<void> printDraft(PurchaseEntryController ctrl) async {
    final bytes = await buildDraftBytes(ctrl);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<Uint8List> buildDraftBytes(PurchaseEntryController ctrl) async {
    final createdAt = DateTime.now();
    final formattedDate =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    final lines = ctrl.items.where((item) => item.hasContent).toList();
    final settingsByMetal = await _loadBillingSettings(
      lines.map((item) => item.metal),
    );
    final sourceLabel = ctrl.purchaseSource == PurchaseSource.fromCustomer
        ? 'Seller Purchase'
        : 'Supplier Purchase';
    final doc = pw.Document(
      theme: await _buildTheme(await _loadDevanagariFont()),
    );

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
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
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
          pw.TableHelper.fromTextArray(
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
          ..._policySections(settingsByMetal),
          _footer(settingsByMetal),
        ],
      ),
    );

    return doc.save();
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

  static Future<Map<PurchaseMetalType, PurchaseBillingModel>>
      _loadBillingSettings(Iterable<PurchaseMetalType> metals) async {
    final selectedMetals = metals.toSet();
    if (selectedMetals.isEmpty) {
      selectedMetals.add(PurchaseMetalType.gold);
    }

    final settings = <PurchaseMetalType, PurchaseBillingModel>{};
    for (final metal in selectedMetals) {
      settings[metal] =
          await _billingRepo.fetchForMetal(_billingMetalFor(metal));
    }
    return settings;
  }

  static String _billingMetalFor(PurchaseMetalType metal) {
    switch (metal) {
      case PurchaseMetalType.gold:
        return BillingMetal.gold;
      case PurchaseMetalType.silver:
        return BillingMetal.silver;
      case PurchaseMetalType.platinum:
        return BillingMetal.platinum;
      case PurchaseMetalType.diamond:
        return BillingMetal.diamond;
    }
  }

  static List<pw.Widget> _policySections(
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
  ) {
    final entries = <pw.Widget>[];

    for (final entry in settingsByMetal.entries) {
      final metalName = entry.key.displayName;
      final settings = entry.value;
      _addPolicyEntry(
        entries,
        title: '$metalName TERMS & SELLER DECLARATION',
        body: settings.termsAndConditions,
      );
      _addPolicyEntry(
        entries,
        title: '$metalName SELLER OWNERSHIP DECLARATION',
        body: settings.sellerDeclarationText,
      );
      _addPolicyEntry(
        entries,
        title: '$metalName SELLER RECLAIM POLICY',
        body: _reclaimPolicyBody(settings),
      );
      _addPolicyEntry(
        entries,
        title: '$metalName VALUATION & PAYOUT POLICY',
        body: settings.buybackPolicyText,
      );
    }

    if (entries.isEmpty) return const [];

    return [
      pw.SizedBox(height: 16),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey600, width: 0.6),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: entries,
        ),
      ),
    ];
  }

  static void _addPolicyEntry(
    List<pw.Widget> entries, {
    required String title,
    required String body,
  }) {
    final text = body.trim();
    if (!_hasPrintableCopy(text)) return;

    if (entries.isNotEmpty) {
      entries.add(pw.SizedBox(height: 7));
    }
    entries.add(
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
    entries.add(pw.SizedBox(height: 2));
    entries.add(
      pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 8.8,
          color: PdfColors.black,
          lineSpacing: 1.2,
        ),
      ),
    );
  }

  static String _reclaimPolicyBody(PurchaseBillingModel settings) {
    final flatPenalty = _formatAmount(settings.lateReclaimPenaltyAmount);
    final threshold = _formatAmount(settings.highValueReclaimThreshold);
    final percent = _formatAmount(settings.highValueReclaimPenaltyPercent);
    return '${settings.returnPolicyText.trim()}\n'
        'Late reclaim penalty: Rs. $flatPenalty for regular-value payouts; '
        '$percent% for payouts above Rs. $threshold.';
  }

  static String _formatAmount(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  static pw.Widget _footer(
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
  ) {
    final footerMessage = settingsByMetal.values
        .map((settings) => settings.footerMessage.trim())
        .where(_hasPrintableCopy)
        .toSet()
        .join(' | ');

    return pw.Column(
      children: [
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey600),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                footerMessage,
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.Text(
              'E&OE',
              style: const pw.TextStyle(
                fontSize: 9.5,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static bool _hasPrintableCopy(String value) {
    final text = value.trim();
    return text.isNotEmpty && text != '0' && text != '-';
  }

  static Future<pw.Font?> _loadDevanagariFont() async {
    const assetPath = 'assets/fonts/lohit_devanagari/Lohit-Devanagari.ttf';
    try {
      return pw.Font.ttf(await rootBundle.load(assetPath));
    } catch (_) {
      try {
        final fontFile = File(assetPath);
        if (fontFile.existsSync()) {
          return pw.Font.ttf(_asByteData(await fontFile.readAsBytes()));
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<pw.ThemeData> _buildTheme(pw.Font? devanagariFont) async {
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
        } catch (_) {}
      }
    }

    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      fontFallback: devanagariFont == null ? null : [devanagariFont],
    );
  }

  static ByteData _asByteData(Uint8List bytes) {
    return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
  }
}
