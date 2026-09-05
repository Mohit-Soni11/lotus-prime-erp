import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/print_templates/application/global/lotus_printable_document.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_pdf_profile.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/pdf/return_reversal_voucher_pdf_service.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_state.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_item_unit_profile.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_pdf_builder.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_print_config.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/repositories/sales_orders/pos/pos_checkout_repository.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/sales_billing_repo.dart';

enum ReturnReversalSalesInvoiceCopyMode {
  original,
  updatedAfterReturn,
}

extension ReturnReversalSalesInvoiceCopyModeX
    on ReturnReversalSalesInvoiceCopyMode {
  String get title {
    return switch (this) {
      ReturnReversalSalesInvoiceCopyMode.original => 'Sales Invoice',
      ReturnReversalSalesInvoiceCopyMode.updatedAfterReturn =>
        'Updated Sales Invoice',
    };
  }

  String get badgeLabel {
    return switch (this) {
      ReturnReversalSalesInvoiceCopyMode.original => 'ORIGINAL COPY',
      ReturnReversalSalesInvoiceCopyMode.updatedAfterReturn => 'AFTER RETURN',
    };
  }

  String get tableTitle {
    return switch (this) {
      ReturnReversalSalesInvoiceCopyMode.original => 'SALES ITEMS',
      ReturnReversalSalesInvoiceCopyMode.updatedAfterReturn =>
        'AVAILABLE ITEMS AFTER RETURN',
    };
  }
}

class ReturnReversalSalesInvoicePdfService {
  ReturnReversalSalesInvoicePdfService._();

  static final ShopPrintInformationRepository _shopProfileRepository =
      ShopPrintInformationRepository();

  static Future<Uint8List> buildInvoiceBytes({
    required ReturnReversalState state,
    required ReturnReversalVoucherPrintOptions options,
    required ReturnReversalSalesInvoiceCopyMode mode,
    PdfPageFormat? pageFormat,
    PosCheckoutRepository? checkoutRepository,
    SalesBillingRepo? salesBillingRepo,
    ShopPrintDocumentProfile? shopProfileOverride,
    MetalType? activeMetal,
    bool includeAllMetals = true,
  }) async {
    final sourceDocument = state.selectedSourceDocument;
    if (sourceDocument == null) {
      throw StateError('Select a sales invoice before generating PDF.');
    }
    if (sourceDocument.type != ReturnReversalSourceDocumentType.salesInvoice) {
      throw StateError(
          'Sales invoice PDFs are available only for sales return.');
    }

    final shopProfile = shopProfileOverride ?? await _loadShopProfile();
    if (mode == ReturnReversalSalesInvoiceCopyMode.original) {
      return _buildOriginalPosInvoiceBytes(
        state: state,
        sourceDocument: sourceDocument,
        shopProfile: shopProfile,
        options: options,
        checkoutRepository: checkoutRepository ?? PosCheckoutRepository(),
        salesBillingRepo: salesBillingRepo ?? SalesBillingRepo(),
        activeMetal: activeMetal,
        includeAllMetals: includeAllMetals,
      );
    }

    return _buildUpdatedPosInvoiceBytes(
      state: state,
      sourceDocument: sourceDocument,
      shopProfile: shopProfile,
      options: options,
      checkoutRepository: checkoutRepository ?? PosCheckoutRepository(),
      salesBillingRepo: salesBillingRepo ?? SalesBillingRepo(),
      activeMetal: activeMetal,
      includeAllMetals: includeAllMetals,
    );
  }

  @visibleForTesting
  static LotusPrintableDocument buildPrintableDocumentForTesting({
    required ReturnReversalState state,
    required ReturnReversalSalesInvoiceCopyMode mode,
    ShopPrintDocumentProfile shopProfile = ShopPrintDocumentProfile.empty,
    String templateId = PrintTemplateRegistry.defaultTemplateId,
  }) {
    final sourceDocument = state.selectedSourceDocument;
    if (sourceDocument == null) {
      throw StateError('Select a sales invoice before generating PDF.');
    }
    return _printableDocument(
      shopProfile: shopProfile,
      sourceDocument: sourceDocument,
      invoiceData: _InvoiceCopyData.fromState(state, mode),
      mode: mode,
      templateId: PrintTemplateRegistry.byId(templateId).id,
    );
  }

  static Future<ShopPrintDocumentProfile> _loadShopProfile() async {
    try {
      return await _shopProfileRepository.loadDocumentProfile();
    } catch (_) {
      return ShopPrintDocumentProfile.empty;
    }
  }

  static Future<Uint8List> _buildOriginalPosInvoiceBytes({
    required ReturnReversalState state,
    required ReturnReversalSourceDocument sourceDocument,
    required ShopPrintDocumentProfile shopProfile,
    required ReturnReversalVoucherPrintOptions options,
    required PosCheckoutRepository checkoutRepository,
    required SalesBillingRepo salesBillingRepo,
    required MetalType? activeMetal,
    required bool includeAllMetals,
  }) async {
    final details = await checkoutRepository.fetchEditableBill(
      sourceDocument.id,
    );
    if (details == null) {
      throw StateError(
        'Original sales invoice ${sourceDocument.documentNo} was not found.',
      );
    }

    final saleItems = await checkoutRepository.fetchPrintableSaleItems(
      sourceDocument.id,
    );
    if (saleItems.isEmpty) {
      throw StateError(
        'Original sales invoice ${sourceDocument.documentNo} has no printable items.',
      );
    }

    final invoice = _posInvoiceFromPersistedBill(
      details: details,
      sourceDocument: sourceDocument,
      shopProfile: shopProfile,
      saleItems: saleItems,
    );
    return _buildPosInvoiceBytes(
      invoice: invoice,
      state: state,
      sourceDocument: sourceDocument,
      options: options,
      salesBillingRepo: salesBillingRepo,
      activeMetal: activeMetal,
      includeAllMetals: includeAllMetals,
      watermarkText: _hasPostedReturn(state, sourceDocument) ? 'RETURNED' : '',
      suppressPaymentSettlement: false,
    );
  }

  static Future<Uint8List> _buildUpdatedPosInvoiceBytes({
    required ReturnReversalState state,
    required ReturnReversalSourceDocument sourceDocument,
    required ShopPrintDocumentProfile shopProfile,
    required ReturnReversalVoucherPrintOptions options,
    required PosCheckoutRepository checkoutRepository,
    required SalesBillingRepo salesBillingRepo,
    required MetalType? activeMetal,
    required bool includeAllMetals,
  }) async {
    final details = await checkoutRepository.fetchEditableBill(
      sourceDocument.id,
    );
    if (details == null) {
      throw StateError(
        'Sales invoice ${sourceDocument.documentNo} was not found.',
      );
    }

    final availableLines = _availableSourceLinesAfterReturn(state);
    if (availableLines.isEmpty) {
      throw StateError(
        'No available invoice items remain after this return.',
      );
    }
    final invoice = _posInvoiceFromPersistedBill(
      details: details,
      sourceDocument: sourceDocument,
      shopProfile: shopProfile,
      saleItems:
          availableLines.map(_saleItemFromSourceLine).toList(growable: false),
      overrideGrossAmount:
          _sum(availableLines, (line) => line.displayLineTotal),
      overrideDiscountAmount:
          _sum(availableLines, (line) => line.discountAmount),
      overrideTaxableAmount: _sum(availableLines, (line) => line.taxableAmount),
      overrideTotalGst: _sum(availableLines, (line) => line.gstAmount),
      overrideMakingTotal: _sum(availableLines, (line) => line.makingAmount),
    );

    return _buildPosInvoiceBytes(
      invoice: invoice,
      state: state,
      sourceDocument: sourceDocument,
      options: options,
      salesBillingRepo: salesBillingRepo,
      activeMetal: activeMetal,
      includeAllMetals: includeAllMetals,
      watermarkText: 'UPDATED AFTER RETURN',
      suppressPaymentSettlement: true,
    );
  }

  static Future<Uint8List> _buildPosInvoiceBytes({
    required PosInvoiceModel invoice,
    required ReturnReversalState state,
    required ReturnReversalSourceDocument sourceDocument,
    required ReturnReversalVoucherPrintOptions options,
    required SalesBillingRepo salesBillingRepo,
    required MetalType? activeMetal,
    required bool includeAllMetals,
    required String watermarkText,
    required bool suppressPaymentSettlement,
  }) async {
    final settings = await _loadSalesBillingSettings(
      invoice,
      salesBillingRepo,
    );
    final resolvedActiveMetal = _resolveActiveMetal(
      invoice,
      activeMetal,
      includeAllMetals,
    );
    final templateId = _templateForInvoiceScope(
      settings: settings,
      invoice: invoice,
      activeMetal: resolvedActiveMetal,
      includeAllMetals: includeAllMetals,
      fallbackTemplateId: options.templateId,
    );
    return const PosInvoicePdfBuilder().build(
      invoice: invoice,
      options: PosInvoicePdfBuildOptions(
        format: options.format,
        copies: options.copies,
        includeDuplicateStamp: options.includeDuplicateStamp,
        activeMetal: resolvedActiveMetal,
        includeAllMetals: includeAllMetals,
        templateId: templateId,
        metalPrintSettings: settings,
        watermarkText: watermarkText,
        suppressPaymentSettlement: suppressPaymentSettlement,
      ),
    );
  }

  static PosInvoiceModel _posInvoiceFromPersistedBill({
    required PosEditableBill details,
    required ReturnReversalSourceDocument sourceDocument,
    required ShopPrintDocumentProfile shopProfile,
    required List<SaleItemModel> saleItems,
    double? overrideGrossAmount,
    double? overrideDiscountAmount,
    double? overrideTaxableAmount,
    double? overrideTotalGst,
    double? overrideMakingTotal,
  }) {
    final bill = details.bill;
    final adjusted = overrideGrossAmount != null ||
        overrideDiscountAmount != null ||
        overrideTaxableAmount != null ||
        overrideTotalGst != null ||
        overrideMakingTotal != null;
    final grossAmount = overrideGrossAmount ?? bill.totalAmount;
    final discountAmount = overrideDiscountAmount ?? bill.discount;
    final taxableAmount = overrideTaxableAmount ?? bill.taxableAmount;
    final totalGst = overrideTotalGst ?? bill.gstAmount;
    final makingTotal = overrideMakingTotal ?? bill.makingTotal;
    final finalAmount = adjusted
        ? math.max(0.0, taxableAmount + totalGst + bill.roundOffAmount)
        : bill.finalAmount;
    return PosInvoiceModel(
      invoiceNumber: bill.billNo,
      invoiceDate: bill.billDate,
      billType: _billTypeFromDb(bill.billType),
      gstPricingMode: _gstPricingModeFromDb(bill.gstPricingMode),
      documentType: _documentTypeFromDb(bill.documentType),
      billingMode: _billingModeFromDb(bill.billingMode),
      shopName: _shopName(shopProfile),
      shopAddress: shopProfile.primaryAddress,
      shopPhone: shopProfile.primaryPhone,
      shopGstin: bill.shopGstinSnapshot ?? shopProfile.gstin,
      shopStateCode: bill.shopStateCodeSnapshot ?? '',
      shopLogoPath: shopProfile.logoPath ?? '',
      shopLogoShape: shopProfile.logoShape,
      shopPrintFields: shopProfile.fields,
      shopPrintProfileApplied: shopProfile.tenantId.isNotEmpty,
      shopSignaturePath: shopProfile.signaturePath ?? '',
      shopSignatureShape: shopProfile.signatureShape,
      customerName: bill.customerName ?? sourceDocument.customerName,
      customerMobile: bill.mobile ?? sourceDocument.mobile,
      customerCity: bill.placeOfSupplySnapshot ?? sourceDocument.address,
      customerPan: '',
      customerGstin: bill.customerGstinSnapshot ?? '',
      customerStateCode: bill.customerStateCodeSnapshot ?? '',
      placeOfSupply: bill.placeOfSupplySnapshot ?? '',
      tradeInMode: _tradeInModeFromDb(bill.tradeInMode),
      customerMetalSettlementType:
          _customerMetalSettlementTypeFromRows(details.tradeInItems),
      saleItems: saleItems,
      tradeInItems: details.tradeInItems
          .map(_tradeInItemFromBillTradeInItem)
          .toList(growable: false),
      grossAmount: grossAmount,
      discountAmount: discountAmount,
      taxableAmount: taxableAmount,
      cgst: totalGst / 2,
      sgst: totalGst / 2,
      totalGst: totalGst,
      totalTradeInDeduction: adjusted ? 0 : bill.tradeInDeduction,
      grandTotal: adjusted
          ? finalAmount - bill.roundOffAmount
          : bill.finalAmount + bill.tradeInDeduction - bill.roundOffAmount,
      roundOffAmount: bill.roundOffAmount,
      cashPaid:
          adjusted ? math.min(bill.paidAmount, finalAmount) : bill.cashPaid,
      upiPaid: adjusted ? 0 : bill.upiPaid,
      cardPaid: adjusted ? 0 : bill.cardPaid,
      advancePaid: adjusted ? 0 : bill.advancePaid,
      balanceDue: adjusted
          ? math.max(0.0, finalAmount - bill.paidAmount)
          : bill.dueAmount,
      totalMakingCharge: makingTotal,
      promiseDate: bill.promiseDate,
    );
  }

  static List<ReturnReversalSourceLineItem> _availableSourceLinesAfterReturn(
    ReturnReversalState state,
  ) {
    final sourceDocument = state.selectedSourceDocument!;
    final removedLineNumbers = <int>{
      for (final line in sourceDocument.lineItems)
        if (line.isReversed) line.lineNo,
      ...state.returnCartLineNumbers,
    };
    return sourceDocument.lineItems
        .where((line) => !removedLineNumbers.contains(line.lineNo))
        .toList(growable: false);
  }

  static SaleItemModel _saleItemFromSourceLine(
    ReturnReversalSourceLineItem line,
  ) {
    final item = SaleItemModel(
      metal: _metalFromDb(line.metalType),
      makingChargeType: _makingChargeTypeFromDb(line.makingChargeType),
      isLessPerPiece: line.lessWeightPerPiece,
    );
    item.descCtrl.text = line.description;
    item.pcsCtrl.text = line.quantity.toString();
    item.setInvoiceHsnCode(line.hsnCode);
    item.setHuidText(line.huidNumber);
    item.purityCtrl.text = line.purity;
    item.grossCtrl.text = _compactNumber(line.grossWeight);
    item.lessCtrl.text = _compactNumber(line.lessWeight);
    item.rateCtrl.text = _compactNumber(line.rate);
    item.makingCtrl.text = _compactNumber(line.makingChargeInput);
    final unitProfile = PosItemUnitProfile.fromStorageValue(
      line.quantityUnitCode,
    );
    if (unitProfile != null) {
      item.setUnitProfile(unitProfile);
    }
    if (line.linkedStockItemId != null) {
      item.attachStockReference(
        stockItemId: line.linkedStockItemId!,
        stockUnitId: line.linkedStockUnitId,
        stockUnitCost: 0,
        stockSnapshotNetWeight: line.netWeight,
        sku: line.linkedStockSku,
      );
    }
    return item;
  }

  static Future<Map<MetalType, BillSettings>> _loadSalesBillingSettings(
    PosInvoiceModel invoice,
    SalesBillingRepo salesBillingRepo,
  ) async {
    final settings = <MetalType, BillSettings>{};
    for (final metal in _collectMetals(invoice)) {
      try {
        settings[metal] = BillSettings.fromSalesBilling(
          await salesBillingRepo.fetchForMetal(metal.name),
        );
      } catch (_) {
        settings[metal] = BillSettings();
      }
    }
    return settings;
  }

  static List<MetalType> _collectMetals(PosInvoiceModel invoice) {
    final metals = <MetalType>{};
    for (final item in invoice.saleItems) {
      metals.add(item.metal);
    }
    for (final item in invoice.tradeInItems) {
      metals.add(item.metal);
    }
    return metals.toList(growable: false);
  }

  static MetalType? _resolveActiveMetal(
    PosInvoiceModel invoice,
    MetalType? activeMetal,
    bool includeAllMetals,
  ) {
    if (includeAllMetals) return null;
    final metals = _collectMetals(invoice);
    if (metals.isEmpty) return null;
    if (activeMetal != null && metals.contains(activeMetal)) {
      return activeMetal;
    }
    return metals.first;
  }

  static String _templateForInvoiceScope({
    required Map<MetalType, BillSettings> settings,
    required PosInvoiceModel invoice,
    required MetalType? activeMetal,
    required bool includeAllMetals,
    required String fallbackTemplateId,
  }) {
    final metals = _collectMetals(invoice);
    final metal =
        includeAllMetals ? (metals.isEmpty ? null : metals.first) : activeMetal;
    final configuredTemplate =
        metal == null ? '' : settings[metal]?.selectedTemplate.trim() ?? '';
    return PrintTemplateRegistry.byId(
      configuredTemplate.isEmpty ? fallbackTemplateId : configuredTemplate,
    ).id;
  }

  static bool _hasPostedReturn(
    ReturnReversalState state,
    ReturnReversalSourceDocument sourceDocument,
  ) {
    return sourceDocument.reversedLineCount > 0 ||
        sourceDocument.lineItems.any((line) => line.isReversed) ||
        state.lastProcessResult != null;
  }

  static double _sum(
    Iterable<ReturnReversalSourceLineItem> lines,
    double Function(ReturnReversalSourceLineItem line) selector,
  ) {
    return lines.fold(0, (sum, line) => sum + selector(line));
  }

  static TradeInItemModel _tradeInItemFromBillTradeInItem(
    BillTradeInItem row,
  ) {
    final item = TradeInItemModel(metal: _metalFromDb(row.metalType));
    item.descCtrl.text = row.itemDescription;
    item.grossCtrl.text = _compactNumber(row.grossWeight);
    item.lessCtrl.text = _compactNumber(row.lessWeight);
    item.purityCtrl.text = _compactNumber(row.purity);
    item.rateCtrl.text = _compactNumber(row.rate);
    return item;
  }

  static BillType _billTypeFromDb(String value) {
    return value.trim().toUpperCase() == 'GST' ? BillType.gst : BillType.normal;
  }

  static GstPricingMode _gstPricingModeFromDb(String value) {
    return value.trim().toUpperCase() == 'GST_INCLUSIVE'
        ? GstPricingMode.inclusive
        : GstPricingMode.exclusive;
  }

  static SalesDocumentType _documentTypeFromDb(String value) {
    return value.trim().toUpperCase() == 'QUOTATION'
        ? SalesDocumentType.quotation
        : SalesDocumentType.taxInvoice;
  }

  static BillingMode _billingModeFromDb(String value) {
    return value.trim().toUpperCase() == 'WHOLESALE'
        ? BillingMode.wholesale
        : BillingMode.retail;
  }

  static TradeInAdjustMode _tradeInModeFromDb(String value) {
    return value.trim().toUpperCase() == 'METAL_ADJUST'
        ? TradeInAdjustMode.metalAdjust
        : TradeInAdjustMode.cashAdjust;
  }

  static CustomerMetalSettlementType _customerMetalSettlementTypeFromRows(
    List<BillTradeInItem> rows,
  ) {
    if (rows.any(
      (row) =>
          row.settlementType.trim().toUpperCase() == 'PURCHASE_FROM_CUSTOMER',
    )) {
      return CustomerMetalSettlementType.purchaseFromCustomer;
    }
    return CustomerMetalSettlementType.exchangeAdjustment;
  }

  static MetalType _metalFromDb(String value) {
    return switch (value.trim().toUpperCase()) {
      'SILVER' => MetalType.silver,
      'PLATINUM' => MetalType.platinum,
      'DIAMOND' => MetalType.diamond,
      _ => MetalType.gold,
    };
  }

  static MakingChargeType _makingChargeTypeFromDb(String value) {
    return switch (value.trim().toUpperCase()) {
      'PERCENTAGE' => MakingChargeType.percentage,
      'PER_KG' => MakingChargeType.perKg,
      'PER_PIECE' => MakingChargeType.perPiece,
      _ => MakingChargeType.perGram,
    };
  }

  static LotusPrintableDocument _printableDocument({
    required ShopPrintDocumentProfile shopProfile,
    required ReturnReversalSourceDocument sourceDocument,
    required _InvoiceCopyData invoiceData,
    required ReturnReversalSalesInvoiceCopyMode mode,
    required String templateId,
  }) {
    final template = PrintTemplateRegistry.byId(templateId);
    return LotusPrintableDocument(
      shopProfile: shopProfile,
      template: template,
      profile: PrintTemplatePdfProfile.forTemplate(template.id),
      title: mode.title,
      subtitle: mode == ReturnReversalSalesInvoiceCopyMode.original
          ? 'Original bill copy'
          : 'Return deducted bill copy',
      documentNumberLabel: 'Invoice No',
      documentNumber: sourceDocument.documentNo,
      documentDateLabel: 'Invoice Date',
      documentDate: _formatDate(sourceDocument.documentDate),
      badgeLabel: mode.badgeLabel,
      primaryPanel: _customerPanel(sourceDocument),
      secondaryPanel: _invoicePanel(sourceDocument, invoiceData, mode),
      itemTable: _itemTable(invoiceData.lines, mode),
      settlementPanels: [
        _totalsPanel(sourceDocument, invoiceData, mode),
        if (mode == ReturnReversalSalesInvoiceCopyMode.updatedAfterReturn)
          _returnAdjustmentPanel(invoiceData),
      ],
      policySections: const [],
      footerMessage:
          'Computer generated ${mode.title.toLowerCase()} from Lotus ERP.',
      showHeaderDocumentMeta: true,
      showHeaderBadge: true,
      useFallbackShopName: true,
      renderPolicySectionsAsPages: false,
      startPolicySectionsOnNewPage: false,
      showLegalSignatureFooter: true,
    );
  }

  static LotusPrintablePanel _customerPanel(
    ReturnReversalSourceDocument sourceDocument,
  ) {
    return LotusPrintablePanel(
      title: 'CUSTOMER DETAILS',
      details: [
        LotusPrintableDetail(
          iconKey: 'customer',
          label: 'Customer',
          value: _fallback(sourceDocument.customerName, 'Walk-in Customer'),
          highlight: true,
        ),
        if (sourceDocument.mobile.trim().isNotEmpty)
          LotusPrintableDetail(
            iconKey: 'phone',
            label: 'Mobile',
            value: sourceDocument.mobile.trim(),
          ),
        if (sourceDocument.address.trim().isNotEmpty)
          LotusPrintableDetail(
            iconKey: 'location',
            label: 'Address',
            value: sourceDocument.address.trim(),
            multiline: true,
          ),
      ],
    );
  }

  static LotusPrintablePanel _invoicePanel(
    ReturnReversalSourceDocument sourceDocument,
    _InvoiceCopyData invoiceData,
    ReturnReversalSalesInvoiceCopyMode mode,
  ) {
    return LotusPrintablePanel(
      title: 'INVOICE DETAILS',
      details: [
        LotusPrintableDetail(
          iconKey: 'invoice',
          label: 'Invoice No',
          value: sourceDocument.documentNo,
          highlight: true,
        ),
        LotusPrintableDetail(
          iconKey: 'calendar',
          label: 'Invoice Date',
          value: _formatDate(sourceDocument.documentDate),
        ),
        LotusPrintableDetail(
          iconKey: 'items',
          label: 'Invoice Type',
          value: mode == ReturnReversalSalesInvoiceCopyMode.original
              ? 'Original Sales Invoice'
              : 'Updated After Return',
          highlight: true,
        ),
        LotusPrintableDetail(
          iconKey: 'status',
          label: 'Active Lines',
          value: '${invoiceData.lines.length}',
        ),
      ],
    );
  }

  static LotusPrintableTable _itemTable(
    List<ReturnReversalSourceLineItem> lines,
    ReturnReversalSalesInvoiceCopyMode mode,
  ) {
    final rows = lines.isEmpty
        ? const [
            ['-', 'No available items', '-', '-', '-', '-', '-'],
          ]
        : [
            for (final line in lines)
              [
                line.lineNo.toString(),
                line.description,
                line.metalType,
                _quantity(line),
                '${_formatWeight(line.netWeight)} g',
                _formatMoney(line.rate),
                _formatMoney(line.displayLineTotal),
              ],
          ];
    return LotusPrintableTable(
      title: mode.tableTitle,
      headers: const ['#', 'Item', 'Metal', 'Qty', 'Net Wt', 'Rate', 'Amount'],
      rows: rows,
    );
  }

  static LotusPrintablePanel _totalsPanel(
    ReturnReversalSourceDocument sourceDocument,
    _InvoiceCopyData invoiceData,
    ReturnReversalSalesInvoiceCopyMode mode,
  ) {
    final documentLabel = mode == ReturnReversalSalesInvoiceCopyMode.original
        ? 'Invoice Total'
        : 'Updated Invoice Total';
    return LotusPrintablePanel(
      title: 'PAYMENT SUMMARY',
      details: [
        LotusPrintableDetail(
          iconKey: 'amount',
          label: documentLabel,
          value: _formatMoney(invoiceData.finalAmount),
          highlight: true,
        ),
        LotusPrintableDetail(
          iconKey: 'payment',
          label: 'Collected',
          value: _formatMoney(sourceDocument.paidAmount),
        ),
        if (sourceDocument.cashPaid > 0.005)
          LotusPrintableDetail(
            iconKey: 'payment',
            label: 'Cash',
            value: _formatMoney(sourceDocument.cashPaid),
          ),
        if (sourceDocument.upiPaid > 0.005)
          LotusPrintableDetail(
            iconKey: 'payment',
            label: 'UPI / Bank',
            value: _formatMoney(sourceDocument.upiPaid),
          ),
        if (sourceDocument.cardPaid > 0.005)
          LotusPrintableDetail(
            iconKey: 'payment',
            label: 'Card',
            value: _formatMoney(sourceDocument.cardPaid),
          ),
        if (sourceDocument.dueAmount > 0.005)
          LotusPrintableDetail(
            iconKey: 'amount',
            label: 'Original Due',
            value: _formatMoney(sourceDocument.dueAmount),
          ),
      ],
    );
  }

  static LotusPrintablePanel _returnAdjustmentPanel(
    _InvoiceCopyData invoiceData,
  ) {
    return LotusPrintablePanel(
      title: 'RETURN ADJUSTMENT',
      details: [
        LotusPrintableDetail(
          iconKey: 'amount',
          label: 'Original Invoice',
          value: _formatMoney(invoiceData.originalFinalAmount),
        ),
        LotusPrintableDetail(
          iconKey: 'amount',
          label: 'Return Deducted',
          value: _formatMoney(invoiceData.deductedAmount),
          highlight: true,
        ),
        LotusPrintableDetail(
          iconKey: 'items',
          label: 'Removed Lines',
          value: '${invoiceData.removedLineCount}',
        ),
        const LotusPrintableDetail(
          iconKey: 'status',
          label: 'Copy Status',
          value: 'After Return',
          highlight: true,
        ),
      ],
    );
  }

  static String _shopName(ShopPrintDocumentProfile profile) {
    return profile.invoiceHeaderName.trim().ifBlank('Lotus ERP');
  }

  static String _quantity(ReturnReversalSourceLineItem line) {
    final unit = line.quantityUnitCode.trim();
    if (unit.isEmpty) return '${line.quantity}';
    return '${line.quantity} $unit';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthShort[date.month - 1];
    return '$day $month ${date.year}';
  }

  static String _formatMoney(double value) {
    final rounded = value.round();
    final negative = rounded < 0;
    final digits = negative ? (-rounded).toString() : rounded.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${negative ? '-' : ''}Rs ${buffer.toString()}';
  }

  static String _formatWeight(double value) => value.toStringAsFixed(3);

  static String _compactNumber(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) {
      return rounded.toInt().toString();
    }
    return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}

class _InvoiceCopyData {
  final List<ReturnReversalSourceLineItem> lines;
  final double originalFinalAmount;
  final double finalAmount;
  final double deductedAmount;
  final int removedLineCount;

  const _InvoiceCopyData({
    required this.lines,
    required this.originalFinalAmount,
    required this.finalAmount,
    required this.deductedAmount,
    required this.removedLineCount,
  });

  factory _InvoiceCopyData.fromState(
    ReturnReversalState state,
    ReturnReversalSalesInvoiceCopyMode mode,
  ) {
    final sourceDocument = state.selectedSourceDocument!;
    final removedLineNumbers = <int>{
      for (final line in sourceDocument.lineItems)
        if (line.isReversed) line.lineNo,
      ...state.returnCartLineNumbers,
    };
    final lines = mode == ReturnReversalSalesInvoiceCopyMode.original
        ? sourceDocument.lineItems
        : sourceDocument.lineItems
            .where((line) => !removedLineNumbers.contains(line.lineNo))
            .toList(growable: false);
    final originalLineTotal = sourceDocument.lineItems.fold<double>(
      0,
      (sum, line) => sum + line.displayLineTotal,
    );
    final availableLineTotal = lines.fold<double>(
      0,
      (sum, line) => sum + line.displayLineTotal,
    );
    final ratio = originalLineTotal.abs() <= 0.005
        ? (mode == ReturnReversalSalesInvoiceCopyMode.original ? 1.0 : 0.0)
        : availableLineTotal / originalLineTotal;
    final finalAmount = mode == ReturnReversalSalesInvoiceCopyMode.original
        ? sourceDocument.finalAmount
        : math.max(0.0, sourceDocument.finalAmount * ratio);

    return _InvoiceCopyData(
      lines: lines,
      originalFinalAmount: sourceDocument.finalAmount,
      finalAmount: finalAmount,
      deductedAmount: math.max(0.0, sourceDocument.finalAmount - finalAmount),
      removedLineCount: mode == ReturnReversalSalesInvoiceCopyMode.original
          ? 0
          : removedLineNumbers.length,
    );
  }
}

const List<String> _monthShort = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

extension _ReturnReversalSalesInvoiceStringX on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
