import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
import '../../models/purchase/purchase_entry/purchase_item_model.dart';
import '../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'purchase_entry_controller.dart';

class CustomerMetalPurchaseInvoiceLine {
  final String metalKey;
  final String metalName;
  final String description;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double purity;
  final double fineWeight;
  final double rate;
  final double totalValue;

  const CustomerMetalPurchaseInvoiceLine({
    this.metalKey = '',
    required this.metalName,
    required this.description,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.purity,
    required this.fineWeight,
    required this.rate,
    required this.totalValue,
  });

  factory CustomerMetalPurchaseInvoiceLine.fromItem(PurchaseItemModel item) {
    return CustomerMetalPurchaseInvoiceLine(
      metalKey: item.metal.name,
      metalName: item.metal.displayName,
      description: item.descCtrl.text,
      grossWeight: item.grossWt,
      lessWeight: item.lessWt,
      netWeight: item.netWt,
      purity: item.purity,
      fineWeight: item.fineWt,
      rate: item.rate,
      totalValue: item.totalValue,
    );
  }
}

class CustomerMetalPurchaseInvoiceData {
  final String purchaseNo;
  final String sellerName;
  final String sellerMobile;
  final String sellerAddress;
  final String sellerPanOrAadhaar;
  final String sellerPhotoPath;
  final DateTime? payoutCommitmentDate;
  final List<CustomerMetalPurchaseInvoiceLine> lineItems;
  final double grossPurchaseAmount;
  final double sellerPayable;
  final double cashPaid;
  final double upiPaid;
  final double cardPaid;
  final double totalPaid;
  final double balanceDue;
  final bool hasPendingSellerPayout;
  final bool hasSellerPayoutExcess;

  const CustomerMetalPurchaseInvoiceData({
    required this.purchaseNo,
    required this.sellerName,
    required this.sellerMobile,
    required this.sellerAddress,
    required this.sellerPanOrAadhaar,
    this.sellerPhotoPath = '',
    required this.payoutCommitmentDate,
    required this.lineItems,
    required this.grossPurchaseAmount,
    required this.sellerPayable,
    required this.cashPaid,
    required this.upiPaid,
    required this.cardPaid,
    required this.totalPaid,
    required this.balanceDue,
    required this.hasPendingSellerPayout,
    required this.hasSellerPayoutExcess,
  });

  factory CustomerMetalPurchaseInvoiceData.fromController(
    PurchaseEntryController controller,
  ) {
    return CustomerMetalPurchaseInvoiceData(
      purchaseNo: controller.formattedPurchaseNo,
      sellerName: controller.nameCtrl.text,
      sellerMobile: controller.mobileCtrl.text,
      sellerAddress: controller.cityCtrl.text,
      sellerPanOrAadhaar: controller.panCtrl.text,
      sellerPhotoPath: controller.sellerPhotoPath ?? '',
      payoutCommitmentDate: controller.payoutCommitmentDate,
      lineItems: controller.items
          .where((item) => item.hasContent)
          .map(CustomerMetalPurchaseInvoiceLine.fromItem)
          .toList(growable: false),
      grossPurchaseAmount: controller.grossPurchaseAmount,
      sellerPayable: controller.grandTotal,
      cashPaid: controller.cashPaid,
      upiPaid: controller.upiPaid,
      cardPaid: controller.cardPaid,
      totalPaid: controller.totalPaid,
      balanceDue: controller.balanceDue,
      hasPendingSellerPayout: controller.hasPendingSellerPayout,
      hasSellerPayoutExcess: controller.hasSellerPayoutExcess,
    );
  }

  CustomerMetalPurchaseInvoiceData scopedToMetal(String? metalKey) {
    final normalized = metalKey?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return this;

    final scopedItems = lineItems
        .where((item) =>
            item.metalKey.trim().toLowerCase() == normalized ||
            item.metalName.trim().toLowerCase() == normalized)
        .toList(growable: false);
    if (scopedItems.isEmpty || scopedItems.length == lineItems.length) {
      return this;
    }

    final scopedGross = scopedItems.fold<double>(
      0,
      (sum, item) => sum + item.totalValue,
    );
    final ratio = grossPurchaseAmount.abs() <= 0.005
        ? 0.0
        : scopedGross / grossPurchaseAmount;
    final scopedPayable = _roundCurrency(sellerPayable * ratio);
    final scopedCashPaid = _roundCurrency(cashPaid * ratio);
    final scopedUpiPaid = _roundCurrency(upiPaid * ratio);
    final scopedCardPaid = _roundCurrency(cardPaid * ratio);
    final scopedTotalPaid =
        _roundCurrency(scopedCashPaid + scopedUpiPaid + scopedCardPaid);
    final scopedBalanceDue = _roundCurrency(scopedPayable - scopedTotalPaid);

    return CustomerMetalPurchaseInvoiceData(
      purchaseNo: purchaseNo,
      sellerName: sellerName,
      sellerMobile: sellerMobile,
      sellerAddress: sellerAddress,
      sellerPanOrAadhaar: sellerPanOrAadhaar,
      sellerPhotoPath: sellerPhotoPath,
      payoutCommitmentDate: payoutCommitmentDate,
      lineItems: scopedItems,
      grossPurchaseAmount: _roundCurrency(scopedGross),
      sellerPayable: scopedPayable,
      cashPaid: scopedCashPaid,
      upiPaid: scopedUpiPaid,
      cardPaid: scopedCardPaid,
      totalPaid: scopedTotalPaid,
      balanceDue: scopedBalanceDue,
      hasPendingSellerPayout: scopedBalanceDue > 0.005,
      hasSellerPayoutExcess: scopedBalanceDue < -0.005,
    );
  }

  static double _roundCurrency(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}

class _PurchaseInvoiceColumn {
  final String key;
  final String label;
  final double width;
  final bool alignRight;

  const _PurchaseInvoiceColumn({
    required this.key,
    required this.label,
    required this.width,
    this.alignRight = true,
  });
}

class CustomerMetalPurchaseInvoiceService {
  CustomerMetalPurchaseInvoiceService._();

  static final NumberFormat _amountFormat =
      NumberFormat('#,##,##0.00', 'en_IN');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final ShopPrintInformationRepository _shopProfileRepository =
      ShopPrintInformationRepository();

  static const PdfColor _ink = PdfColor.fromInt(0xFF111827);
  static const PdfColor _muted = PdfColor.fromInt(0xFF4B5563);
  static const PdfColor _line = PdfColor.fromInt(0xFFD8DEE8);
  static const PdfColor _gold = PdfColor.fromInt(0xFFC89421);
  static const PdfColor _goldSoft = PdfColor.fromInt(0xFFFBF6E9);

  static Future<void> printInvoice(PurchaseEntryController controller) async {
    final invoice = CustomerMetalPurchaseInvoiceData.fromController(controller);
    final bytes = await buildInvoiceBytesForData(invoice);
    await Printing.layoutPdf(
      name: _fileName(invoice),
      onLayout: (_) async => bytes,
    );
  }

  static Future<Uint8List> buildInvoiceBytes(
    PurchaseEntryController controller, {
    ShopPrintDocumentProfile? shopProfileOverride,
    DateTime? invoiceDate,
    String templateId = PrintTemplateRegistry.defaultTemplateId,
    PrintFormat format = PrintFormat.a4,
    Map<String, PurchaseBillingModel> displaySettings =
        const <String, PurchaseBillingModel>{},
    int copies = 1,
    bool includeDuplicateStamp = false,
    String? metalScope,
  }) async {
    return buildInvoiceBytesForData(
      CustomerMetalPurchaseInvoiceData.fromController(controller),
      shopProfileOverride: shopProfileOverride,
      invoiceDate: invoiceDate,
      templateId: templateId,
      format: format,
      displaySettings: displaySettings,
      copies: copies,
      includeDuplicateStamp: includeDuplicateStamp,
      metalScope: metalScope,
    );
  }

  static Future<Uint8List> buildInvoiceBytesForData(
    CustomerMetalPurchaseInvoiceData invoice, {
    ShopPrintDocumentProfile? shopProfileOverride,
    DateTime? invoiceDate,
    String templateId = PrintTemplateRegistry.defaultTemplateId,
    PrintFormat format = PrintFormat.a4,
    Map<String, PurchaseBillingModel> displaySettings =
        const <String, PurchaseBillingModel>{},
    int copies = 1,
    bool includeDuplicateStamp = false,
    String? metalScope,
  }) async {
    final scopedInvoice = invoice.scopedToMetal(metalScope);

    if (scopedInvoice.lineItems.isEmpty) {
      throw StateError(
          'Add at least one metal item before generating invoice.');
    }

    final shopProfile = shopProfileOverride ??
        await _shopProfileRepository.loadDocumentProfile();
    final resolvedTemplate = PrintTemplateRegistry.byId(templateId);
    final printableDocument = format == PrintFormat.a4
        ? _printableDocument(
            shopProfile: shopProfile,
            invoice: scopedInvoice,
            invoiceDate: invoiceDate ?? DateTime.now(),
            templateId: resolvedTemplate.id,
            displaySettings: displaySettings,
          )
        : null;
    final textRenderer =
        printableDocument == null ? null : await LotusPdfTextRenderer.create();
    if (printableDocument != null && textRenderer != null) {
      await LotusPrintTemplateRendererRegistry.warmPolicyText(
        printableDocument,
        textRenderer,
      );
    }

    final document = pw.Document(
      title: 'Customer Metal Purchase ${invoice.purchaseNo}',
      author: _shopName(shopProfile),
      creator: 'Lotus ERP',
      subject:
          'Customer Metal Purchase Invoice (${PrintTemplateRegistry.labelFor(templateId)})',
      theme: await _documentTheme(),
    );

    final normalizedCopies = copies.clamp(1, 5).toInt();
    for (var copyIndex = 0; copyIndex < normalizedCopies; copyIndex++) {
      final duplicate = includeDuplicateStamp && copyIndex > 0;
      document.addPage(
        pw.MultiPage(
          pageFormat: _pageFormatFor(format),
          margin: _pageMarginFor(format),
          build: (_) {
            if (format == PrintFormat.a4 &&
                printableDocument != null &&
                textRenderer != null) {
              return LotusPrintTemplateRendererRegistry.buildA4(
                templateId: resolvedTemplate.id,
                context: LotusPrintTemplateRenderContext(
                  document: printableDocument,
                  textRenderer: textRenderer,
                ),
                isDuplicateCopy: duplicate,
              );
            }

            final content = _thermalContent(
              shopProfile,
              scopedInvoice,
              invoiceDate ?? DateTime.now(),
              format,
              displaySettings,
            );
            return [
              if (duplicate) _duplicateStamp(format),
              ...content,
            ];
          },
        ),
      );
    }

    return document.save();
  }

  @visibleForTesting
  static LotusPrintableDocument buildPrintableDocumentForTesting(
    CustomerMetalPurchaseInvoiceData invoice, {
    ShopPrintDocumentProfile shopProfile = ShopPrintDocumentProfile.empty,
    DateTime? invoiceDate,
    String templateId = PrintTemplateRegistry.defaultTemplateId,
    Map<String, PurchaseBillingModel> displaySettings =
        const <String, PurchaseBillingModel>{},
    String? metalScope,
  }) {
    final scopedInvoice = invoice.scopedToMetal(metalScope);
    return _printableDocument(
      shopProfile: shopProfile,
      invoice: scopedInvoice,
      invoiceDate: invoiceDate ?? DateTime.now(),
      templateId: PrintTemplateRegistry.byId(templateId).id,
      displaySettings: displaySettings,
    );
  }

  static List<pw.Widget> _thermalContent(
    ShopPrintDocumentProfile shopProfile,
    CustomerMetalPurchaseInvoiceData invoice,
    DateTime invoiceDate,
    PrintFormat format,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    final compact = format == PrintFormat.thermal2inch;
    return [
      _thermalHeader(shopProfile, invoice, invoiceDate, compact: compact),
      _thermalDivider(),
      _thermalSeller(
        invoice,
        displaySettings: displaySettings,
        compact: compact,
      ),
      _thermalDivider(),
      _thermalItems(
        invoice.lineItems,
        displaySettings: displaySettings,
        compact: compact,
      ),
      _thermalDivider(),
      _thermalTotals(invoice, compact: compact),
      pw.SizedBox(height: compact ? 8 : 10),
      pw.Text(
        'Computer generated customer metal purchase invoice.',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(color: _muted, fontSize: compact ? 6.8 : 7.5),
      ),
      pw.SizedBox(height: compact ? 16 : 20),
      pw.Container(height: 0.7, color: _ink),
      pw.SizedBox(height: 4),
      pw.Text(
        'Authorised Signatory',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: _ink,
          fontSize: compact ? 7 : 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ];
  }

  static LotusPrintableDocument _printableDocument({
    required ShopPrintDocumentProfile shopProfile,
    required CustomerMetalPurchaseInvoiceData invoice,
    required DateTime invoiceDate,
    required String templateId,
    required Map<String, PurchaseBillingModel> displaySettings,
  }) {
    final template = PrintTemplateRegistry.byId(templateId);
    final settings = _settingsForInvoice(invoice, displaySettings);
    return LotusPrintableDocument(
      shopProfile: shopProfile,
      template: template,
      profile: PrintTemplatePdfProfile.forTemplate(template.id),
      title: '',
      subtitle: '',
      documentNumberLabel: 'Invoice No',
      documentNumber: invoice.purchaseNo,
      documentDateLabel: 'Invoice Date',
      documentDate: _dateFormat.format(invoiceDate),
      badgeLabel: _payoutStatus(invoice),
      primaryPanel: _printableSellerPanel(invoice, displaySettings),
      secondaryPanel: _printableInvoicePanel(invoice, invoiceDate),
      itemTable: _printableItemTable(invoice.lineItems, displaySettings),
      settlementPanels: [
        _printablePayoutPanel(invoice),
      ],
      showHeaderDocumentMeta: false,
      showHeaderBadge: false,
      useFallbackShopName: false,
      renderPolicySectionsAsPages: true,
      startPolicySectionsOnNewPage: false,
      showLegalSignatureFooter: true,
      policySections: _printablePolicySections(settings),
      footerMessage: _purchaseFooterMessage(settings),
    );
  }

  static LotusPrintablePanel _printableSellerPanel(
    CustomerMetalPurchaseInvoiceData invoice,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    final settings = _settingsForInvoice(invoice, displaySettings);
    return LotusPrintablePanel(
      title: 'SELLER DETAILS',
      photoPath: invoice.sellerPhotoPath,
      photoLabel: 'Seller Photo',
      details: [
        if (settings.showSupplierDetails)
          LotusPrintableDetail(
            iconKey: 'customer',
            label: 'Seller Name',
            value: _fallback(invoice.sellerName, 'Walk-in Seller'),
            highlight: true,
          ),
        if (settings.showSupplierDetails &&
            invoice.sellerMobile.trim().isNotEmpty)
          LotusPrintableDetail(
            iconKey: 'phone',
            label: 'Mobile',
            value: invoice.sellerMobile.trim(),
          ),
        if (settings.showSupplierDetails &&
            invoice.sellerAddress.trim().isNotEmpty)
          LotusPrintableDetail(
            iconKey: 'location',
            label: 'Address',
            value: invoice.sellerAddress.trim(),
            multiline: true,
          ),
        if (settings.showPanNumber &&
            invoice.sellerPanOrAadhaar.trim().isNotEmpty)
          LotusPrintableDetail(
            iconKey: 'gst',
            label: 'PAN / ID',
            value: invoice.sellerPanOrAadhaar.trim(),
          ),
      ],
    );
  }

  static LotusPrintablePanel _printableInvoicePanel(
    CustomerMetalPurchaseInvoiceData invoice,
    DateTime invoiceDate,
  ) {
    return LotusPrintablePanel(
      title: 'INVOICE DETAILS',
      details: [
        LotusPrintableDetail(
          iconKey: 'invoice',
          label: 'Invoice No',
          value: invoice.purchaseNo,
          highlight: true,
        ),
        LotusPrintableDetail(
          iconKey: 'calendar',
          label: 'Date',
          value: _dateFormat.format(invoiceDate),
        ),
        const LotusPrintableDetail(
          iconKey: 'items',
          label: 'Type',
          value: 'Customer Sold Metal',
        ),
        if (invoice.payoutCommitmentDate != null)
          LotusPrintableDetail(
            iconKey: 'calendar',
            label: 'Commitment',
            value: PurchaseEntryController.formatDisplayDate(
              invoice.payoutCommitmentDate!,
            ),
          ),
      ],
    );
  }

  static List<LotusPrintablePolicySection> _printablePolicySections(
    PurchaseBillingModel settings,
  ) {
    final sellerDeclaration = _sellerDeclarationText(settings);
    return [
      if (settings.printSellerDeclaration && sellerDeclaration.isNotEmpty)
        LotusPrintablePolicySection(
          title: 'Seller Declaration',
          body: sellerDeclaration,
        ),
      if (settings.printTermsAndConditions &&
          settings.termsAndConditions.trim().isNotEmpty)
        LotusPrintablePolicySection(
          title: 'Terms & Conditions',
          body: settings.termsAndConditions.trim(),
        ),
      if (settings.printBuybackPolicy &&
          settings.buybackPolicyText.trim().isNotEmpty)
        LotusPrintablePolicySection(
          title: 'Payout Policy',
          body: settings.buybackPolicyText.trim(),
        ),
      if (settings.printReturnPolicy &&
          settings.returnPolicyText.trim().isNotEmpty)
        LotusPrintablePolicySection(
          title: 'Seller Reclaim Policy',
          body: settings.returnPolicyText.trim(),
        ),
    ];
  }

  static LotusPrintableTable _printableItemTable(
    List<CustomerMetalPurchaseInvoiceLine> items,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    final columns = _visibleColumns(items, displaySettings);
    return LotusPrintableTable(
      title: 'CUSTOMER METAL ITEMS',
      headers: columns.map((column) => column.label).toList(growable: false),
      rows: [
        for (final entry in items.asMap().entries)
          [
            for (final column in columns)
              _columnValue(column, entry.value, entry.key + 1),
          ],
      ],
    );
  }

  static LotusPrintablePanel _printablePayoutPanel(
    CustomerMetalPurchaseInvoiceData invoice,
  ) {
    return LotusPrintablePanel(
      title: 'PAYOUT SUMMARY',
      details: [
        LotusPrintableDetail(
          iconKey: 'amount',
          label: 'Assessed Value',
          value: _amount(invoice.grossPurchaseAmount),
          highlight: true,
        ),
        if (_amountsDiffer(invoice.grossPurchaseAmount, invoice.sellerPayable))
          LotusPrintableDetail(
            iconKey: 'amount',
            label: 'Seller Payable',
            value: _amount(invoice.sellerPayable),
            highlight: true,
          ),
        if (invoice.cashPaid > 0.005)
          LotusPrintableDetail(
            iconKey: 'payment',
            label: 'Cash Paid',
            value: _amount(invoice.cashPaid),
          ),
        if (invoice.upiPaid > 0.005)
          LotusPrintableDetail(
            iconKey: 'payment',
            label: 'UPI / Bank Paid',
            value: _amount(invoice.upiPaid),
          ),
        if (invoice.cardPaid > 0.005)
          LotusPrintableDetail(
            iconKey: 'payment',
            label: 'Card Paid',
            value: _amount(invoice.cardPaid),
          ),
        if (!invoice.hasPendingSellerPayout &&
            !invoice.hasSellerPayoutExcess &&
            invoice.totalPaid > 0.005)
          const LotusPrintableDetail(
            iconKey: 'status',
            label: 'Settlement',
            value: 'Paid in Full',
            highlight: true,
          ),
        if (invoice.balanceDue.abs() > 0.005)
          LotusPrintableDetail(
            iconKey: 'amount',
            label: invoice.hasSellerPayoutExcess
                ? 'Payout Excess'
                : 'Pending Payout',
            value: _amount(invoice.balanceDue.abs()),
            highlight: true,
          ),
      ],
    );
  }

  static List<_PurchaseInvoiceColumn> _visibleColumns(
    List<CustomerMetalPurchaseInvoiceLine> items,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    bool visible(bool Function(PurchaseBillingModel settings) test) {
      return items.any((item) => test(_settingsForLine(item, displaySettings)));
    }

    return [
      const _PurchaseInvoiceColumn(
        key: 'index',
        label: 'S. No.',
        width: 0.45,
      ),
      const _PurchaseInvoiceColumn(
        key: 'metal',
        label: 'Metal',
        width: 0.85,
        alignRight: false,
      ),
      const _PurchaseInvoiceColumn(
        key: 'description',
        label: 'Description',
        width: 2.15,
        alignRight: false,
      ),
      if (visible((settings) => settings.showGrossWeight))
        const _PurchaseInvoiceColumn(key: 'gross', label: 'Gross', width: 0.95),
      if (visible((settings) => settings.showLessWeight))
        const _PurchaseInvoiceColumn(key: 'less', label: 'Less', width: 0.95),
      if (visible((settings) => settings.showNetWeight))
        const _PurchaseInvoiceColumn(key: 'net', label: 'Net', width: 0.95),
      if (visible((settings) => settings.showPurity))
        const _PurchaseInvoiceColumn(
          key: 'purity',
          label: 'Purity',
          width: 0.9,
        ),
      if (visible((settings) => settings.showFineWeight))
        const _PurchaseInvoiceColumn(key: 'fine', label: 'Fine', width: 0.95),
      if (visible((settings) => settings.showRate))
        const _PurchaseInvoiceColumn(key: 'rate', label: 'Rate', width: 1.05),
      if (visible((settings) => settings.showTotalValue))
        const _PurchaseInvoiceColumn(key: 'value', label: 'Value', width: 1.15),
    ];
  }

  static String _columnValue(
    _PurchaseInvoiceColumn column,
    CustomerMetalPurchaseInvoiceLine item,
    int rowNumber,
  ) {
    switch (column.key) {
      case 'index':
        return '$rowNumber';
      case 'metal':
        return item.metalName;
      case 'description':
        return _fallback(item.description, '${item.metalName} Purchase');
      case 'gross':
        return _weight(item.grossWeight);
      case 'less':
        return _weight(item.lessWeight);
      case 'net':
        return _weight(item.netWeight);
      case 'purity':
        return item.purity.toStringAsFixed(2);
      case 'fine':
        return _weight(item.fineWeight);
      case 'rate':
        return _plainAmount(item.rate);
      case 'value':
        return _plainAmount(item.totalValue);
    }
    return '';
  }

  static pw.Widget _thermalHeader(
    ShopPrintDocumentProfile profile,
    CustomerMetalPurchaseInvoiceData invoice,
    DateTime invoiceDate, {
    required bool compact,
  }) {
    final lines = _headerLines(profile).take(compact ? 2 : 3);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (_shopName(profile).isNotEmpty) ...[
          pw.Text(
            _shopName(profile).toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              color: _ink,
              fontSize: compact ? 10.5 : 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
        ],
        for (final line in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(
              line,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: _muted,
                fontSize: compact ? 6.4 : 7.2,
              ),
            ),
          ),
        pw.SizedBox(height: 5),
        pw.Text(
          'CUSTOMER METAL PURCHASE',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            color: _ink,
            fontSize: compact ? 8.2 : 9.2,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        _thermalKeyValue(
          'Invoice',
          invoice.purchaseNo,
          compact: compact,
          strong: true,
        ),
        _thermalKeyValue(
          'Date',
          _dateFormat.format(invoiceDate),
          compact: compact,
        ),
      ],
    );
  }

  static pw.Widget _thermalSeller(
    CustomerMetalPurchaseInvoiceData invoice, {
    required Map<String, PurchaseBillingModel> displaySettings,
    required bool compact,
  }) {
    final settings = _settingsForInvoice(invoice, displaySettings);
    final rows = <pw.Widget>[
      if (settings.showSupplierDetails)
        _thermalKeyValue(
          'Name',
          _fallback(invoice.sellerName, 'Walk-in Seller'),
          compact: compact,
          strong: true,
        ),
      if (settings.showSupplierDetails)
        _thermalKeyValue('Mobile', invoice.sellerMobile, compact: compact),
      if (settings.showSupplierDetails)
        _thermalKeyValue('Address', invoice.sellerAddress, compact: compact),
      if (settings.showPanNumber)
        _thermalKeyValue(
          'PAN/ID',
          invoice.sellerPanOrAadhaar,
          compact: compact,
        ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _thermalSectionTitle('SELLER', compact: compact),
        ...rows,
      ],
    );
  }

  static pw.Widget _thermalItems(
    List<CustomerMetalPurchaseInvoiceLine> items, {
    required Map<String, PurchaseBillingModel> displaySettings,
    required bool compact,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _thermalSectionTitle('METAL ITEMS', compact: compact),
        for (final entry in items.asMap().entries)
          _thermalItem(
            entry.key + 1,
            entry.value,
            settings: _settingsForLine(entry.value, displaySettings),
            compact: compact,
          ),
      ],
    );
  }

  static pw.Widget _thermalItem(
    int index,
    CustomerMetalPurchaseInvoiceLine item, {
    required PurchaseBillingModel settings,
    required bool compact,
  }) {
    final fontSize = compact ? 6.6 : 7.5;
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: compact ? 6 : 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$index. ${item.metalName} - ${_fallback(item.description, '${item.metalName} Purchase')}',
            style: pw.TextStyle(
              color: _ink,
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          if (settings.showGrossWeight)
            _thermalKeyValue('Gross', _weight(item.grossWeight),
                compact: compact),
          if (settings.showLessWeight)
            _thermalKeyValue('Less', _weight(item.lessWeight),
                compact: compact),
          if (settings.showNetWeight)
            _thermalKeyValue('Net', _weight(item.netWeight), compact: compact),
          if (settings.showPurity)
            _thermalKeyValue(
              'Purity',
              item.purity.toStringAsFixed(2),
              compact: compact,
            ),
          if (settings.showFineWeight)
            _thermalKeyValue('Fine', _weight(item.fineWeight),
                compact: compact),
          if (settings.showRate)
            _thermalKeyValue('Rate', _amount(item.rate), compact: compact),
          if (settings.showTotalValue)
            _thermalKeyValue(
              'Value',
              _amount(item.totalValue),
              compact: compact,
              strong: true,
            ),
        ],
      ),
    );
  }

  static pw.Widget _thermalTotals(
    CustomerMetalPurchaseInvoiceData invoice, {
    required bool compact,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _thermalSectionTitle('SUMMARY', compact: compact),
        _thermalKeyValue(
          'Metal Value',
          _amount(invoice.grossPurchaseAmount),
          compact: compact,
        ),
        _thermalKeyValue(
          'Seller Payable',
          _amount(invoice.sellerPayable),
          compact: compact,
          strong: true,
        ),
        _thermalKeyValue('Cash', _amount(invoice.cashPaid), compact: compact),
        _thermalKeyValue(
          'UPI/Bank',
          _amount(invoice.upiPaid),
          compact: compact,
        ),
        _thermalKeyValue('Card', _amount(invoice.cardPaid), compact: compact),
        _thermalKeyValue(
          'Released',
          _amount(invoice.totalPaid),
          compact: compact,
          strong: true,
        ),
        _thermalKeyValue(
          _payoutStatus(invoice),
          _amount(invoice.balanceDue.abs()),
          compact: compact,
          strong: true,
        ),
      ],
    );
  }

  static pw.Widget _thermalKeyValue(
    String label,
    String value, {
    required bool compact,
    bool strong = false,
  }) {
    final clean = value.trim();
    if (clean.isEmpty) return pw.SizedBox.shrink();
    final fontSize = compact ? 6.7 : 7.6;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2.4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: compact ? 45 : 58,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: _muted,
                fontSize: fontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              clean,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                color: _ink,
                fontSize: fontSize,
                fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _thermalSectionTitle(
    String title, {
    required bool compact,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: compact ? 4 : 5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: _ink,
          fontSize: compact ? 7.2 : 8.2,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _thermalDivider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      child: pw.Container(height: 0.6, color: _line),
    );
  }

  static pw.Widget _duplicateStamp(PrintFormat format) {
    final compact = format == PrintFormat.thermal2inch;
    final isThermal = format != PrintFormat.a4;
    return pw.Container(
      width: double.infinity,
      margin: pw.EdgeInsets.only(bottom: isThermal ? 6 : 10),
      padding: pw.EdgeInsets.symmetric(
        horizontal: isThermal ? 5 : 9,
        vertical: isThermal ? 3 : 5,
      ),
      decoration: pw.BoxDecoration(
        color: _goldSoft,
        border: pw.Border.all(color: _gold, width: 0.7),
        borderRadius: pw.BorderRadius.circular(isThermal ? 3 : 5),
      ),
      child: pw.Text(
        'DUPLICATE COPY',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: _ink,
          fontSize: compact
              ? 6.8
              : isThermal
                  ? 7.6
                  : 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static List<String> _headerLines(ShopPrintDocumentProfile profile) {
    final selectedLines = profile.headerLines
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (selectedLines.isNotEmpty) return selectedLines;

    return [
      if (profile.primaryAddress.trim().isNotEmpty) profile.primaryAddress,
      if (profile.primaryPhone.trim().isNotEmpty)
        'Mobile: ${profile.primaryPhone.trim()}',
      if (profile.valueOf('business_email').trim().isNotEmpty)
        'Email: ${profile.valueOf('business_email').trim()}',
      if (profile.gstin.trim().isNotEmpty) 'GSTIN: ${profile.gstin.trim()}',
    ];
  }

  static Future<pw.ThemeData> _documentTheme() async {
    final devanagariFont = await _loadFont(
      'assets/fonts/lohit_devanagari/Lohit-Devanagari.ttf',
    );
    final windowsDirectory = Platform.environment['WINDIR'];
    if (windowsDirectory != null) {
      final regularFile = File('$windowsDirectory\\Fonts\\segoeui.ttf');
      final boldFile = File('$windowsDirectory\\Fonts\\segoeuib.ttf');
      if (regularFile.existsSync() && boldFile.existsSync()) {
        try {
          return pw.ThemeData.withFont(
            base: pw.Font.ttf(_asByteData(await regularFile.readAsBytes())),
            bold: pw.Font.ttf(_asByteData(await boldFile.readAsBytes())),
            fontFallback:
                devanagariFont == null ? null : <pw.Font>[devanagariFont],
          );
        } catch (_) {}
      }
    }

    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      fontFallback: devanagariFont == null ? null : <pw.Font>[devanagariFont],
    );
  }

  static Future<pw.Font?> _loadFont(String assetPath) async {
    try {
      return pw.Font.ttf(await rootBundle.load(assetPath));
    } catch (_) {
      try {
        final file = File(assetPath);
        if (!file.existsSync()) return null;
        final bytes = await file.readAsBytes();
        return pw.Font.ttf(_asByteData(bytes));
      } catch (_) {
        return null;
      }
    }
  }

  static ByteData _asByteData(Uint8List bytes) {
    return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
  }

  static PdfPageFormat _pageFormatFor(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return PdfPageFormat.a4;
      case PrintFormat.thermal3inch:
        return const PdfPageFormat(
          80 * PdfPageFormat.mm,
          250 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        );
      case PrintFormat.thermal2inch:
        return const PdfPageFormat(
          57 * PdfPageFormat.mm,
          250 * PdfPageFormat.mm,
          marginAll: 3 * PdfPageFormat.mm,
        );
    }
  }

  static pw.EdgeInsets _pageMarginFor(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return const pw.EdgeInsets.all(24);
      case PrintFormat.thermal3inch:
        return const pw.EdgeInsets.all(4 * PdfPageFormat.mm);
      case PrintFormat.thermal2inch:
        return const pw.EdgeInsets.all(3 * PdfPageFormat.mm);
    }
  }

  static String _shopName(ShopPrintDocumentProfile profile) {
    return profile.invoiceHeaderName.trim();
  }

  static String _fileName(CustomerMetalPurchaseInvoiceData invoice) {
    final seller = _fallback(invoice.sellerName, 'customer-metal');
    final cleanSeller = seller
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '')
        .toLowerCase();
    return '${cleanSeller}_${invoice.purchaseNo}_invoice.pdf';
  }

  static String _payoutStatus(CustomerMetalPurchaseInvoiceData invoice) {
    if (invoice.hasSellerPayoutExcess) return 'PAYOUT EXCESS';
    if (invoice.hasPendingSellerPayout) return 'PENDING';
    return 'SETTLED';
  }

  static PurchaseBillingModel _settingsForInvoice(
    CustomerMetalPurchaseInvoiceData invoice,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    if (invoice.lineItems.isNotEmpty) {
      return _settingsForLine(invoice.lineItems.first, displaySettings);
    }
    return PurchaseBillingModel.defaultFor('gold');
  }

  static PurchaseBillingModel _settingsForLine(
    CustomerMetalPurchaseInvoiceLine line,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    final key = _metalKeyForLine(line);
    return displaySettings[key] ?? PurchaseBillingModel.defaultFor(key);
  }

  static String _metalKeyForLine(CustomerMetalPurchaseInvoiceLine line) {
    final key = line.metalKey.trim().toLowerCase();
    if (key.isNotEmpty) return key;
    return line.metalName.trim().toLowerCase();
  }

  static String _amount(double value) => 'Rs. ${_amountFormat.format(value)}';

  static String _plainAmount(double value) => _amountFormat.format(value);

  static String _weight(double value) => value.toStringAsFixed(3);

  static String _fallback(String value, String fallback) {
    final clean = value.trim();
    return clean.isEmpty ? fallback : clean;
  }

  static String _sellerDeclarationText(PurchaseBillingModel settings) {
    final text = settings.sellerDeclarationText.trim();
    if (text.isEmpty || _isLegacySellerDeclaration(text)) {
      return _legalSellerDeclarationText;
    }
    return text;
  }

  static bool _isLegacySellerDeclaration(String value) {
    return value.contains(
          'Seller declares that the item is his or her lawful property',
        ) ||
        value.contains(
          'I, the seller, confirm that the metal item(s) described in this purchase invoice',
        );
  }

  static String _purchaseFooterMessage(PurchaseBillingModel settings) {
    if (!settings.printFooterMessage) return '';
    final text = settings.footerMessage.trim();
    if (text.isEmpty || text.contains('Thank you for trusting us')) {
      return _legalPurchaseFooterMessage;
    }
    return text;
  }

  static bool _amountsDiffer(double first, double second) {
    return (first - second).abs() > 0.005;
  }

  static const String _legalSellerDeclarationText =
      'The seller confirms lawful ownership of the listed metal item(s), voluntary sale to the business, and acceptance of the verified weight, purity, value, payout mode and commitment date, if any.\n'
      'विक्रेता listed metal item(s) के lawful ownership, business को voluntary sale, verified weight, purity, value, payout mode और commitment date, यदि कोई हो, को स्वीकार करता/करती है.\n'
      'The seller declares that the item(s) are free from theft, dispute, pledge, loan, lien, police case or third-party claim, and accepts full responsibility for any false declaration or future claim.\n'
      'विक्रेता घोषणा करता/करती है कि item(s) theft, dispute, pledge, loan, lien, police case या third-party claim से मुक्त हैं और false declaration या future claim की पूरी जिम्मेदारी स्वीकार करता/करती है.\n'
      'After the agreed payout is released or recorded, ownership and possession rights of the item(s) stand transferred to the business.\n'
      'Agreed payout release या record होने के बाद item(s) का ownership और possession rights business को transfer माना जाएगा.';

  static const String _legalPurchaseFooterMessage =
      'The seller/customer confirms that all invoice terms, policies, metal valuation and payout details have been read, verified and accepted, and accepts full responsibility for the declaration and ownership claim.\n'
      'विक्रेता/customer पुष्टि करता/करती है कि सभी invoice terms, policies, metal valuation और payout details पढ़कर verify और accept कर लिए गए हैं, और declaration तथा ownership claim की पूरी जिम्मेदारी स्वीकार करता/करती है.';
}
