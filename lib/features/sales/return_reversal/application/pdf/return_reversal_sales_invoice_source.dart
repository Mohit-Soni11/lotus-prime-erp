part of 'return_reversal_sales_invoice_pdf_service.dart';

Future<ShopPrintDocumentProfile> _loadShopProfile() async {
  try {
    return await _shopProfileRepository.loadDocumentProfile();
  } catch (_) {
    return ShopPrintDocumentProfile.empty;
  }
}

Future<Uint8List> _buildOriginalPosInvoiceBytes({
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

Future<Uint8List> _buildUpdatedPosInvoiceBytes({
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
    overrideGrossAmount: _sum(availableLines, (line) => line.displayLineTotal),
    overrideDiscountAmount: _sum(availableLines, (line) => line.discountAmount),
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

Future<Uint8List> _buildPosInvoiceBytes({
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

PosInvoiceModel _posInvoiceFromPersistedBill({
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
    cashPaid: adjusted ? math.min(bill.paidAmount, finalAmount) : bill.cashPaid,
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

List<ReturnReversalSourceLineItem> _availableSourceLinesAfterReturn(
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

SaleItemModel _saleItemFromSourceLine(
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

Future<Map<MetalType, BillSettings>> _loadSalesBillingSettings(
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

List<MetalType> _collectMetals(PosInvoiceModel invoice) {
  final metals = <MetalType>{};
  for (final item in invoice.saleItems) {
    metals.add(item.metal);
  }
  for (final item in invoice.tradeInItems) {
    metals.add(item.metal);
  }
  return metals.toList(growable: false);
}

MetalType? _resolveActiveMetal(
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

String _templateForInvoiceScope({
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

bool _hasPostedReturn(
  ReturnReversalState state,
  ReturnReversalSourceDocument sourceDocument,
) {
  return sourceDocument.reversedLineCount > 0 ||
      sourceDocument.lineItems.any((line) => line.isReversed) ||
      state.lastProcessResult != null;
}

double _sum(
  Iterable<ReturnReversalSourceLineItem> lines,
  double Function(ReturnReversalSourceLineItem line) selector,
) {
  return lines.fold(0, (sum, line) => sum + selector(line));
}

TradeInItemModel _tradeInItemFromBillTradeInItem(
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

BillType _billTypeFromDb(String value) {
  return value.trim().toUpperCase() == 'GST' ? BillType.gst : BillType.normal;
}

GstPricingMode _gstPricingModeFromDb(String value) {
  return value.trim().toUpperCase() == 'GST_INCLUSIVE'
      ? GstPricingMode.inclusive
      : GstPricingMode.exclusive;
}

SalesDocumentType _documentTypeFromDb(String value) {
  return value.trim().toUpperCase() == 'QUOTATION'
      ? SalesDocumentType.quotation
      : SalesDocumentType.taxInvoice;
}

BillingMode _billingModeFromDb(String value) {
  return value.trim().toUpperCase() == 'WHOLESALE'
      ? BillingMode.wholesale
      : BillingMode.retail;
}

TradeInAdjustMode _tradeInModeFromDb(String value) {
  return value.trim().toUpperCase() == 'METAL_ADJUST'
      ? TradeInAdjustMode.metalAdjust
      : TradeInAdjustMode.cashAdjust;
}

CustomerMetalSettlementType _customerMetalSettlementTypeFromRows(
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

MetalType _metalFromDb(String value) {
  return switch (value.trim().toUpperCase()) {
    'SILVER' => MetalType.silver,
    'PLATINUM' => MetalType.platinum,
    'DIAMOND' => MetalType.diamond,
    _ => MetalType.gold,
  };
}

MakingChargeType _makingChargeTypeFromDb(String value) {
  return switch (value.trim().toUpperCase()) {
    'PERCENTAGE' => MakingChargeType.percentage,
    'PER_KG' => MakingChargeType.perKg,
    'PER_PIECE' => MakingChargeType.perPiece,
    _ => MakingChargeType.perGram,
  };
}
