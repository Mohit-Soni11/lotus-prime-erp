import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/pdf/lotus_pdf_text_renderer.dart';
import '../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../models/setting/billing_setup/sales_billing_model.dart';
import '../../features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import '../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../repositories/setting/billing_setup/purchase_billing_repo.dart';
import 'purchase_entry_controller.dart';

class PurchaseVoucherPrintService {
  PurchaseVoucherPrintService._();

  static final PurchaseBillingRepo _billingRepo = PurchaseBillingRepo();
  static final ShopPrintInformationRepository _shopPrintRepo =
      ShopPrintInformationRepository();

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
    final shopProfile = await _shopPrintRepo.loadDocumentProfile();
    final textRenderer = await LotusPdfTextRenderer.create();
    await _warmPolicyText(settingsByMetal, textRenderer);
    final isCustomerPurchase =
        ctrl.purchaseSource == PurchaseSource.fromCustomer;
    final sourceLabel = isCustomerPurchase
        ? 'Customer Old Metal Purchase'
        : 'Supplier Stock Purchase';
    final doc = pw.Document(
      theme: await _buildTheme(await _loadDevanagariFont()),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _shopHeader(
            profile: shopProfile,
            documentTitle: isCustomerPurchase
                ? 'Customer Metal Purchase Voucher'
                : 'Purchase Voucher',
            documentSubtitle: sourceLabel,
            documentNumber: ctrl.formattedPurchaseNo,
            documentDate: formattedDate,
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
                  _summaryRow('Net Purchase', ctrl.netPurchaseAmount),
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
          ..._policySections(settingsByMetal, textRenderer),
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

  static pw.Widget _shopHeader({
    required ShopPrintDocumentProfile profile,
    required String documentTitle,
    required String documentSubtitle,
    required String documentNumber,
    required String documentDate,
  }) {
    final title =
        profile.primaryName.isEmpty ? 'Lotus ERP' : profile.primaryName;
    final headerLines = profile.headerLines;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                for (final line in headerLines.take(6))
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(
                        fontSize: 8.8,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                documentTitle,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(documentSubtitle),
              pw.SizedBox(height: 8),
              pw.Text('Voucher: $documentNumber'),
              pw.Text('Date: $documentDate'),
            ],
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
    LotusPdfTextRenderer textRenderer,
  ) {
    final entries = <pw.Widget>[];

    for (final entry in settingsByMetal.entries) {
      final metalName = entry.key.displayName;
      final settings = entry.value;
      _addPolicyEntry(
        entries,
        title: '$metalName TERMS & SELLER DECLARATION',
        body: settings.termsAndConditions,
        textRenderer: textRenderer,
      );
      _addPolicyEntry(
        entries,
        title: '$metalName SELLER OWNERSHIP DECLARATION',
        body: settings.sellerDeclarationText,
        textRenderer: textRenderer,
      );
      _addPolicyEntry(
        entries,
        title: '$metalName SELLER RECLAIM POLICY',
        body: settings.returnPolicyText,
        textRenderer: textRenderer,
      );
      _addPolicyEntry(
        entries,
        title: '$metalName VALUATION & PAYOUT POLICY',
        body: settings.buybackPolicyText,
        textRenderer: textRenderer,
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
    required LotusPdfTextRenderer textRenderer,
  }) {
    if (!_hasPrintableCopy(body)) return;

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
    entries.addAll(_policyBodyLines(body, textRenderer));
  }

  static List<pw.Widget> _policyBodyLines(
    String body,
    LotusPdfTextRenderer textRenderer,
  ) {
    const style = pw.TextStyle(
      fontSize: 8.8,
      color: PdfColors.black,
      lineSpacing: 1.3,
    );
    final lines = body
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trimRight())
        .toList(growable: false);

    return [
      for (final line in lines)
        if (line.trim().isEmpty)
          pw.SizedBox(height: 4)
        else
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2.5),
            child: textRenderer.text(
              line,
              style: style,
              maxWidth: 500,
            ),
          ),
    ];
  }

  static Future<void> _warmPolicyText(
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
    LotusPdfTextRenderer textRenderer,
  ) async {
    final lines = settingsByMetal.values
        .expand(
          (settings) => <String>[
            settings.termsAndConditions,
            settings.sellerDeclarationText,
            settings.returnPolicyText,
            settings.buybackPolicyText,
          ],
        )
        .expand(
          (body) => body
              .replaceAll('\r\n', '\n')
              .replaceAll('\r', '\n')
              .split('\n')
              .map((line) => line.trimRight()),
        )
        .toSet();

    await textRenderer.warmTextLines(
      lines,
      specs: const [
        LotusPdfTextSpec(
          fontSize: 8.8,
          color: PdfColors.black,
          bold: false,
          maxWidth: 500,
        ),
      ],
    );
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
