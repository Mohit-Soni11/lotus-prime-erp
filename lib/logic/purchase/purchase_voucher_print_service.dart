import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/pdf/lotus_pdf_text_renderer.dart';
import '../../features/print_templates/application/global/lotus_print_template_renderer_registry.dart';
import '../../features/print_templates/application/global/lotus_printable_document.dart';
import '../../features/print_templates/domain/print_template_pdf_profile.dart';
import '../../features/print_templates/domain/print_template_registry.dart';
import '../../features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import '../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../models/purchase/purchase_entry/purchase_item_model.dart';
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

    final isCustomerPurchase =
        ctrl.purchaseSource == PurchaseSource.fromCustomer;
    final printableDocument = _buildPrintableDocument(
      ctrl: ctrl,
      lines: lines,
      settingsByMetal: settingsByMetal,
      shopProfile: shopProfile,
      selectedTemplate: selectedTemplate,
      templateProfile: templateProfile,
      isCustomerPurchase: isCustomerPurchase,
      documentDate: formattedDate,
    );
    await LotusPrintTemplateRendererRegistry.warmPolicyText(
      printableDocument,
      textRenderer,
    );
    final renderContext = LotusPrintTemplateRenderContext(
      document: printableDocument,
      textRenderer: textRenderer,
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
          build: (_) => LotusPrintTemplateRendererRegistry.buildA4(
            templateId: selectedTemplate.id,
            context: renderContext,
            isDuplicateCopy: includeDuplicateStamp && copyIndex > 0,
          ),
        ),
      );
    }

    return doc.save();
  }

  static LotusPrintableDocument _buildPrintableDocument({
    required PurchaseEntryController ctrl,
    required List<PurchaseItemModel> lines,
    required Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
    required ShopPrintDocumentProfile shopProfile,
    required PrintTemplateDefinition selectedTemplate,
    required PrintTemplatePdfProfile templateProfile,
    required bool isCustomerPurchase,
    required String documentDate,
  }) {
    final sourceLabel = isCustomerPurchase
        ? 'Customer Old Metal Purchase'
        : 'Supplier Stock Purchase';
    final displayDate = _displayDate(documentDate);
    return LotusPrintableDocument(
      shopProfile: shopProfile,
      template: selectedTemplate,
      profile: templateProfile,
      title: isCustomerPurchase
          ? 'Customer Metal Purchase Voucher'
          : 'Purchase Voucher',
      subtitle: '$sourceLabel | ${selectedTemplate.shortName}',
      documentNumberLabel: 'Voucher No.',
      documentNumber: ctrl.formattedPurchaseNo,
      documentDateLabel: 'Voucher Date',
      documentDate: displayDate,
      badgeLabel: 'PURCHASE VOUCHER',
      primaryPanel: LotusPrintablePanel(
        title: 'SELLER DETAILS',
        details: [
          LotusPrintableDetail(
            iconKey: 'customer',
            label: 'Seller Name',
            value: ctrl.nameCtrl.text.trim().isEmpty
                ? 'Walk-in Seller'
                : ctrl.nameCtrl.text.trim(),
          ),
          LotusPrintableDetail(
            iconKey: 'phone',
            label: 'Mobile',
            value: ctrl.mobileCtrl.text.trim(),
          ),
          LotusPrintableDetail(
            iconKey: 'location',
            label: 'Address',
            value: ctrl.cityCtrl.text.trim(),
            multiline: true,
          ),
          LotusPrintableDetail(
            iconKey: 'gst',
            label: 'PAN / Aadhaar ID',
            value: ctrl.panCtrl.text.trim(),
          ),
        ],
      ),
      secondaryPanel: LotusPrintablePanel(
        title: 'VOUCHER DETAILS',
        details: [
          LotusPrintableDetail(
            iconKey: 'invoice',
            label: 'Voucher No.',
            value: ctrl.formattedPurchaseNo,
          ),
          LotusPrintableDetail(
            iconKey: 'calendar',
            label: 'Date',
            value: displayDate,
          ),
          LotusPrintableDetail(
            iconKey: 'items',
            label: 'Purchase Type',
            value: sourceLabel,
          ),
          LotusPrintableDetail(
            iconKey: 'status',
            label: 'Payout Status',
            value: ctrl.hasPendingSellerPayout ? 'PENDING' : 'SETTLED',
            highlight: true,
          ),
        ],
      ),
      itemTable: _purchaseItemsTable(lines, settingsByMetal),
      settlementPanels: [
        LotusPrintablePanel(
          title: 'SELLER PAYOUT',
          details: [
            LotusPrintableDetail(
              iconKey: 'payment',
              label: 'Cash Payout',
              value: _money(ctrl.cashPaid),
            ),
            LotusPrintableDetail(
              iconKey: 'payment',
              label: 'UPI / Bank Payout',
              value: _money(ctrl.upiPaid),
            ),
            LotusPrintableDetail(
              iconKey: 'payment',
              label: 'Card Payout',
              value: _money(ctrl.cardPaid),
            ),
            LotusPrintableDetail(
              iconKey: 'payment',
              label: 'Payout Released',
              value: _money(ctrl.totalPaid),
            ),
          ],
        ),
        LotusPrintablePanel(
          title: 'AMOUNT SUMMARY',
          details: [
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Assessed Metal Value',
              value: _money(ctrl.grossPurchaseAmount),
            ),
            LotusPrintableDetail(
              iconKey: 'amount',
              label: 'Seller Payable',
              value: _money(ctrl.grandTotal),
              highlight: true,
            ),
            LotusPrintableDetail(
              iconKey: 'amount',
              label: _payoutBalanceLabel(ctrl),
              value: _money(ctrl.balanceDue.abs()),
              highlight: true,
            ),
            if (ctrl.hasPendingSellerPayout &&
                ctrl.payoutCommitmentDate != null)
              LotusPrintableDetail(
                iconKey: 'calendar',
                label: 'Payout Commitment',
                value: PurchaseEntryController.formatDisplayDate(
                  ctrl.payoutCommitmentDate!,
                ),
              ),
          ],
        ),
      ],
      policySections: _policySections(settingsByMetal),
      footerMessage: settingsByMetal.values
          .map((settings) => settings.footerMessage.trim())
          .where(_hasPrintableCopy)
          .toSet()
          .join(' | '),
    );
  }

  static LotusPrintableTable _purchaseItemsTable(
    List<PurchaseItemModel> lines,
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
  ) {
    final columns = _visibleColumns(lines, settingsByMetal);
    return LotusPrintableTable(
      title: 'CUSTOMER METAL ITEMS',
      headers: columns.map((column) => column.label).toList(growable: false),
      rows: lines.asMap().entries.map((entry) {
        return columns
            .map((column) =>
                _purchaseLineCell(entry.key + 1, entry.value, column))
            .toList(growable: false);
      }).toList(growable: false),
    );
  }

  static List<_PurchaseVoucherColumn> _visibleColumns(
    List<PurchaseItemModel> lines,
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
  ) {
    bool enabled(bool Function(PurchaseBillingModel settings) read) {
      if (lines.isEmpty) return true;
      return lines
          .any((item) => read(_settingsFor(item.metal, settingsByMetal)));
    }

    return [
      const _PurchaseVoucherColumn.serial(),
      const _PurchaseVoucherColumn.metal(),
      const _PurchaseVoucherColumn.description(),
      if (enabled((settings) => settings.showGrossWeight))
        const _PurchaseVoucherColumn.gross(),
      if (enabled((settings) => settings.showLessWeight))
        const _PurchaseVoucherColumn.less(),
      if (enabled((settings) => settings.showNetWeight))
        const _PurchaseVoucherColumn.net(),
      if (enabled((settings) => settings.showPurity))
        const _PurchaseVoucherColumn.purity(),
      if (enabled((settings) => settings.showFineWeight))
        const _PurchaseVoucherColumn.fine(),
      if (enabled((settings) => settings.showRate))
        const _PurchaseVoucherColumn.rate(),
      if (enabled((settings) => settings.showTotalValue))
        const _PurchaseVoucherColumn.value(),
    ];
  }

  static String _purchaseLineCell(
    int serial,
    PurchaseItemModel item,
    _PurchaseVoucherColumn column,
  ) {
    switch (column.type) {
      case _PurchaseVoucherColumnType.serial:
        return '$serial';
      case _PurchaseVoucherColumnType.metal:
        return item.metal.displayName;
      case _PurchaseVoucherColumnType.description:
        return item.descCtrl.text.trim().isEmpty
            ? '${item.metal.displayName} Purchase Item'
            : item.descCtrl.text.trim();
      case _PurchaseVoucherColumnType.gross:
        return item.grossWt.toStringAsFixed(3);
      case _PurchaseVoucherColumnType.less:
        return item.lessWt.toStringAsFixed(3);
      case _PurchaseVoucherColumnType.net:
        return item.netWt.toStringAsFixed(3);
      case _PurchaseVoucherColumnType.purity:
        return item.purity.toStringAsFixed(2);
      case _PurchaseVoucherColumnType.fine:
        return item.fineWt.toStringAsFixed(3);
      case _PurchaseVoucherColumnType.rate:
        return item.rate.toStringAsFixed(2);
      case _PurchaseVoucherColumnType.value:
        return item.totalValue.toStringAsFixed(2);
    }
  }

  static PurchaseBillingModel _settingsFor(
    PurchaseMetalType metal,
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
  ) {
    return settingsByMetal[metal] ??
        PurchaseBillingModel.defaultFor(_billingMetalFor(metal));
  }

  static List<LotusPrintablePolicySection> _policySections(
    Map<PurchaseMetalType, PurchaseBillingModel> settingsByMetal,
  ) {
    return [
      for (final entry in settingsByMetal.entries) ...[
        LotusPrintablePolicySection(
          title: '${entry.key.displayName} TERMS & SELLER DECLARATION',
          body: entry.value.termsAndConditions,
        ),
        if (entry.value.showSupplierDetails || entry.value.showPanNumber)
          LotusPrintablePolicySection(
            title: '${entry.key.displayName} SELLER OWNERSHIP DECLARATION',
            body: entry.value.sellerDeclarationText,
          ),
        LotusPrintablePolicySection(
          title: '${entry.key.displayName} SELLER RECLAIM POLICY',
          body: entry.value.returnPolicyText,
        ),
        LotusPrintablePolicySection(
          title: '${entry.key.displayName} VALUATION & PAYOUT POLICY',
          body: entry.value.buybackPolicyText,
        ),
      ],
    ]
        .where((section) => _hasPrintableCopy(section.body))
        .toList(growable: false);
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

  static String _payoutBalanceLabel(PurchaseEntryController ctrl) {
    if (ctrl.hasSellerPayoutExcess) {
      return 'Payout Excess';
    }
    if (ctrl.hasPendingSellerPayout) {
      return 'Pending Seller Payout';
    }
    return 'Payout Balance';
  }

  static String _displayDate(String ddmmyyyy) {
    final parts = ddmmyyyy.split('/');
    if (parts.length != 3) return ddmmyyyy;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = parts[2];
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (day == null || month == null || month < 1 || month > 12) {
      return ddmmyyyy;
    }
    return '${day.toString().padLeft(2, '0')} ${monthNames[month - 1]} $year';
  }

  static String _money(double value) {
    return 'Rs. ${value.toStringAsFixed(2)}';
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

enum _PurchaseVoucherColumnType {
  serial,
  metal,
  description,
  gross,
  less,
  net,
  purity,
  fine,
  rate,
  value,
}

class _PurchaseVoucherColumn {
  final _PurchaseVoucherColumnType type;
  final String label;

  const _PurchaseVoucherColumn._(this.type, this.label);

  const _PurchaseVoucherColumn.serial()
      : this._(_PurchaseVoucherColumnType.serial, '#');

  const _PurchaseVoucherColumn.metal()
      : this._(_PurchaseVoucherColumnType.metal, 'Metal');

  const _PurchaseVoucherColumn.description()
      : this._(_PurchaseVoucherColumnType.description, 'Description');

  const _PurchaseVoucherColumn.gross()
      : this._(_PurchaseVoucherColumnType.gross, 'Gross');

  const _PurchaseVoucherColumn.less()
      : this._(_PurchaseVoucherColumnType.less, 'Less');

  const _PurchaseVoucherColumn.net()
      : this._(_PurchaseVoucherColumnType.net, 'Net');

  const _PurchaseVoucherColumn.purity()
      : this._(_PurchaseVoucherColumnType.purity, 'Purity');

  const _PurchaseVoucherColumn.fine()
      : this._(_PurchaseVoucherColumnType.fine, 'Fine');

  const _PurchaseVoucherColumn.rate()
      : this._(_PurchaseVoucherColumnType.rate, 'Rate');

  const _PurchaseVoucherColumn.value()
      : this._(_PurchaseVoucherColumnType.value, 'Value');
}
