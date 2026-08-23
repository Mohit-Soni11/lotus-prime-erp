import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/pdf/lotus_pdf_text_renderer.dart';
import '../../features/print_templates/application/purchase_voucher/purchase_voucher_pdf_layout_engine.dart';
import '../../features/print_templates/application/purchase_voucher/purchase_voucher_template_context.dart';
import '../../features/print_templates/application/purchase_voucher/purchase_voucher_template_renderer_registry.dart';
import '../../features/print_templates/domain/print_template_pdf_profile.dart';
import '../../features/print_templates/domain/print_template_registry.dart';
import '../../features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import '../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../models/setting/billing_setup/sales_billing_model.dart';
import '../../repositories/setting/billing_setup/purchase_billing_repo.dart';
import 'purchase_entry_controller.dart';

class PurchaseVoucherPrintService {
  PurchaseVoucherPrintService._();

  static final PurchaseBillingRepo _billingRepo = PurchaseBillingRepo();
  static final ShopPrintInformationRepository _shopPrintRepo =
      ShopPrintInformationRepository();

  static Future<void> printDraft(
    PurchaseEntryController ctrl, {
    Map<PurchaseMetalType, PurchaseBillingModel>? settingsOverride,
    String selectedTemplateId = PrintTemplateRegistry.defaultTemplateId,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    int copies = 1,
    bool includeDuplicateStamp = false,
  }) async {
    final bytes = await buildDraftBytes(
      ctrl,
      settingsOverride: settingsOverride,
      selectedTemplateId: selectedTemplateId,
      pageFormat: pageFormat,
      copies: copies,
      includeDuplicateStamp: includeDuplicateStamp,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<Uint8List> buildDraftBytes(
    PurchaseEntryController ctrl, {
    Map<PurchaseMetalType, PurchaseBillingModel>? settingsOverride,
    String selectedTemplateId = PrintTemplateRegistry.defaultTemplateId,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    int copies = 1,
    bool includeDuplicateStamp = false,
  }) async {
    final createdAt = DateTime.now();
    final formattedDate =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    final lines = ctrl.items.where((item) => item.hasContent).toList();
    final settingsByMetal = settingsOverride ??
        await _loadBillingSettings(lines.map((item) => item.metal));
    final shopProfile = await _shopPrintRepo.loadDocumentProfile();
    final selectedTemplate = PrintTemplateRegistry.byId(selectedTemplateId);
    final templateProfile = PrintTemplatePdfProfile.forTemplate(
      selectedTemplate.id,
    );
    final textRenderer = await LotusPdfTextRenderer.create();
    await PurchaseVoucherPdfLayoutEngine.warmPolicyText(
      settingsByMetal,
      textRenderer,
      templateProfile,
    );

    final isCustomerPurchase =
        ctrl.purchaseSource == PurchaseSource.fromCustomer;
    final renderContext = PurchaseVoucherTemplateRenderContext(
      controller: ctrl,
      lines: lines,
      settingsByMetal: settingsByMetal,
      shopProfile: shopProfile,
      textRenderer: textRenderer,
      selectedTemplate: selectedTemplate,
      templateProfile: templateProfile,
      sourceLabel: isCustomerPurchase
          ? 'Customer Old Metal Purchase'
          : 'Supplier Stock Purchase',
      documentTitle: isCustomerPurchase
          ? 'Customer Metal Purchase Voucher'
          : 'Purchase Voucher',
      documentNumber: ctrl.formattedPurchaseNo,
      documentDate: formattedDate,
    );

    final doc = pw.Document(
      theme: await _buildTheme(await _loadDevanagariFont()),
    );

    final normalizedCopies = copies.clamp(1, 5).toInt();
    for (var copyIndex = 0; copyIndex < normalizedCopies; copyIndex++) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => PurchaseVoucherTemplateRendererRegistry.buildA4(
            templateId: selectedTemplate.id,
            context: renderContext,
            isDuplicateCopy: includeDuplicateStamp && copyIndex > 0,
          ),
        ),
      );
    }

    return doc.save();
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
