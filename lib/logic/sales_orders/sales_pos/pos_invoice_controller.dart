//  Database persistence dependencies
import '../../../database/db/app_database.dart';
import '../../../features/sales_pos/application/pdf/pos_invoice_pdf_builder.dart';
import '../../../features/sales_pos/application/pdf/pos_invoice_print_config.dart';
import '../../../features/sales_pos/application/services/pos_invoice_output_service.dart';
import '../../../features/sales_pos/application/services/pos_invoice_scope_service.dart';

import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../repositories/sales_orders/pos/pos_checkout_repository.dart';
import '../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../repositories/setting/billing_setup/sales_billing_repo.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart';
import '../../../repositories/setting/shop_setup/shop_session_manager.dart';
import '../../../core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';

export '../../../features/sales_pos/application/pdf/pos_invoice_print_config.dart';

enum InvoiceGenState { idle, generating, ready, error }

class PosInvoiceController extends ChangeNotifier {
  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (_isDisposed) {
      return;
    }
    super.notifyListeners();
  }

  final PosBillingController billing;
  final ShopSetupRepository _shopRepo = ShopSetupRepository();
  final SalesBillingRepo _salesBillingRepo = SalesBillingRepo();
  final PosInvoiceScopeService _scopeService = const PosInvoiceScopeService();
  final PosInvoicePdfBuilder _pdfBuilder = const PosInvoicePdfBuilder();
  final PosInvoiceOutputService _outputService =
      const PosInvoiceOutputService();

  final InvoicePrintConfig printConfig = InvoicePrintConfig();
  final Map<MetalType, BillSettings> metalPrintSettings = {};

  PosInvoiceController({required this.billing});

  InvoiceGenState genState = InvoiceGenState.idle;
  PosInvoiceModel? invoice;
  Uint8List? pdfBytes;
  String? errorMessage;

  //  Database save state
  bool isSavedToDb = false;
  int? savedBillDbId;
  final AppDatabase _db = AppDatabase();
  final PosCheckoutRepository _checkoutRepo = PosCheckoutRepository();

  PrintFormat selectedFormat = PrintFormat.a4;
  int printCopies = 1;
  bool includeDuplicateStamp = false;
  MetalType? activePrintMetal;

  DateTime? dueDate;

  String _realShopName = "Lotus Jewellers";
  String _realShopAddress = "Address not set";
  String _realShopPhone = "Phone not set";
  String _realShopGstin = "Not Registered";

  BillSettings getActiveConfig(BillingMode mode, BillType type) {
    if (mode == BillingMode.retail) {
      return type == BillType.normal
          ? printConfig.retailNormal
          : printConfig.retailGst;
    } else {
      return type == BillType.normal
          ? printConfig.wholesaleNormal
          : printConfig.wholesaleGst;
    }
  }

  List<MetalType> get presentMetals {
    final saleItems = invoice?.saleItems ?? billing.saleItems;
    final oldGoldItems = invoice?.oldGoldItems ?? billing.oldGoldItems;
    final present = <MetalType>{
      ...saleItems.map((item) => item.metal),
      ...oldGoldItems.map((item) => item.metal),
    };

    const ordered = [
      MetalType.gold,
      MetalType.silver,
      MetalType.platinum,
      MetalType.diamond,
    ];
    return ordered.where(present.contains).toList();
  }

  MetalType? get effectiveActiveMetal {
    final metals = presentMetals;
    if (metals.isEmpty) return null;
    if (activePrintMetal != null && metals.contains(activePrintMetal)) {
      return activePrintMetal;
    }
    return metals.first;
  }

  bool get hasMultipleMetalInvoices => presentMetals.length > 1;

  Future<void> setActivePrintMetal(MetalType metal) async {
    if (activePrintMetal == metal) return;
    activePrintMetal = metal;
    notifyListeners();
    await _refreshActivePreviewPdf();
  }

  BillSettings getMetalConfig(MetalType metal) {
    return metalPrintSettings.putIfAbsent(
      metal,
      () => _defaultSettingsForMetal(metal),
    );
  }

  bool getMetalCustomizationValue(MetalType metal, String key) {
    final config = getMetalConfig(metal);
    switch (key) {
      case 'huid':
        return config.showHuid;
      case 'pcs':
        return config.showPcs;
      case 'gw':
        return config.showGrossWt;
      case 'lw':
        return config.showLessWt;
      case 'net':
        return config.showNetWt;
      case 'purity':
        return config.showPurity;
      case 'rate':
        return config.showRate;
      case 'making':
        return config.showMaking;
      case 'makingType':
        return config.showMakingType;
      case 'amount':
        return config.showAmount;
      case 'exchange':
        return config.showExchangeBreakdown;
      case 'printTerms':
        return config.printTermsAndConditions;
      case 'printReturnPolicy':
        return config.printReturnPolicy;
      case 'printBuybackPolicy':
        return config.printBuybackPolicy;
      case 'printFooter':
        return config.printFooterMessage;
      default:
        return false;
    }
  }

  Future<void> setMetalCustomization(
    MetalType metal,
    String key,
    bool value,
  ) async {
    final config = getMetalConfig(metal);
    metalPrintSettings[metal] = config;

    switch (key) {
      case 'huid':
        config.showHuid = value;
        break;
      case 'pcs':
        config.showPcs = value;
        break;
      case 'gw':
        config.showGrossWt = value;
        break;
      case 'lw':
        config.showLessWt = value;
        break;
      case 'net':
        config.showNetWt = value;
        break;
      case 'purity':
        config.showPurity = value;
        break;
      case 'rate':
        config.showRate = value;
        break;
      case 'making':
        config.showMaking = value;
        break;
      case 'makingType':
        config.showMakingType = value;
        break;
      case 'amount':
        config.showAmount = value;
        break;
      case 'exchange':
        config.showExchangeBreakdown = value;
        break;
      case 'printTerms':
        config.printTermsAndConditions = value;
        break;
      case 'printReturnPolicy':
        config.printReturnPolicy = value;
        break;
      case 'printBuybackPolicy':
        config.printBuybackPolicy = value;
        break;
      case 'printFooter':
        config.printFooterMessage = value;
        break;
    }

    if (invoice != null) {
      await _refreshActivePreviewPdf();
    }
    notifyListeners();
  }

  Future<void> toggleMetalCustomization(MetalType metal, String key) async {
    final value = !getMetalCustomizationValue(metal, key);
    await setMetalCustomization(metal, key, value);
  }

  Future<void> restoreMetalSavedSetup(MetalType metal) async {
    final current = getMetalConfig(metal);
    final printTerms = current.printTermsAndConditions;
    final printReturn = current.printReturnPolicy;
    final printBuyback = current.printBuybackPolicy;
    final printFooter = current.printFooterMessage;

    late BillSettings restored;
    try {
      final setup = await _salesBillingRepo.fetchForMetal(metal.name);
      restored = _settingsFromBillingSetup(setup);
    } catch (_) {
      restored = _defaultSettingsForMetal(metal);
    }

    restored.printTermsAndConditions = printTerms;
    restored.printReturnPolicy = printReturn;
    restored.printBuybackPolicy = printBuyback;
    restored.printFooterMessage = printFooter;
    metalPrintSettings[metal] = restored;

    if (invoice != null) {
      await _refreshActivePreviewPdf();
    }
    notifyListeners();
  }

  Future<void> setMetalCopySuiteEnabled(MetalType metal, bool enabled) async {
    final config = getMetalConfig(metal);
    config.printTermsAndConditions = enabled;
    config.printReturnPolicy = enabled;
    config.printBuybackPolicy = enabled;
    config.printFooterMessage = enabled;

    if (invoice != null) {
      await _refreshActivePreviewPdf();
    }
    notifyListeners();
  }

  Future<void> _loadMetalBillingSettings(PosInvoiceModel inv) async {
    final settings = <MetalType, BillSettings>{};
    final metals = _collectMetals(inv);

    for (final metal in metals) {
      try {
        final setup = await _salesBillingRepo.fetchForMetal(metal.name);
        settings[metal] = _settingsFromBillingSetup(setup);
      } catch (_) {
        settings[metal] = _defaultSettingsForMetal(metal);
      }
    }

    metalPrintSettings
      ..clear()
      ..addAll(settings);
    if (metals.isEmpty) {
      activePrintMetal = null;
    } else if (activePrintMetal == null || !metals.contains(activePrintMetal)) {
      activePrintMetal = metals.first;
    }
  }

  List<MetalType> _collectMetals(PosInvoiceModel inv) {
    return _scopeService.collectMetals(inv);
  }

  BillSettings _settingsFromBillingSetup(SalesBillingModel model) {
    return BillSettings.fromSalesBilling(model);
  }

  BillSettings _defaultSettingsForMetal(MetalType metal) {
    return BillSettings.fromSalesBilling(
      SalesBillingModel.defaultFor(metal.name),
    );
  }

  Future<void> updatePrintOptions(
      {required int copies, required bool duplicate}) async {
    printCopies = copies;
    includeDuplicateStamp = duplicate;
    if (invoice != null) {
      await _refreshActivePreviewPdf();
      notifyListeners();
    }
  }

  Future<void> toggleCustomization(
      String key, BillingMode mode, BillType type) async {
    BillSettings config = getActiveConfig(mode, type);

    switch (key) {
      case 'huid':
        config.showHuid = !config.showHuid;
        break;
      case 'pcs':
        config.showPcs = !config.showPcs;
        break;
      case 'gw':
        config.showGrossWt = !config.showGrossWt;
        break;
      case 'lw':
        config.showLessWt = !config.showLessWt;
        break;
      case 'making':
        config.showMaking = !config.showMaking;
        break;
      case 'makingType':
        config.showMakingType = !config.showMakingType;
        break;
      case 'exchange':
        config.showExchangeBreakdown = !config.showExchangeBreakdown;
        break;
      case 'printTerms':
        config.printTermsAndConditions = !config.printTermsAndConditions;
        break;
      case 'printReturnPolicy':
        config.printReturnPolicy = !config.printReturnPolicy;
        break;
      case 'printBuybackPolicy':
        config.printBuybackPolicy = !config.printBuybackPolicy;
        break;
      case 'printFooter':
        config.printFooterMessage = !config.printFooterMessage;
        break;
    }

    if (invoice != null &&
        invoice!.billingMode == mode &&
        invoice!.billType == type) {
      await _refreshActivePreviewPdf();
    }
    notifyListeners();
  }

  Future<void> _fetchRealShopData() async {
    try {
      final String activeTenantId =
          await ShopSessionManager.getPermanentTenantId();
      final shopData = await _shopRepo.fetchExistingSetup(activeTenantId);

      if (shopData != null) {
        final basicInfo = shopData['basic_info'] as Map<String, dynamic>?;
        final addressData = shopData['address'] as Map<String, dynamic>?;
        final taxData = shopData['tax_compliance'] as Map<String, dynamic>?;

        if (basicInfo != null) {
          final brandName = basicInfo['brand_display_name']?.toString() ?? '';
          final displayName = basicInfo['display_name']?.toString() ?? '';
          _realShopName = brandName.isNotEmpty
              ? brandName
              : displayName.isNotEmpty
                  ? displayName
                  : "Lotus Jewellers";

          final shopPhone = basicInfo['shop_phone']?.toString() ?? '';
          final ownerPhone = basicInfo['owner_phone']?.toString() ?? '';
          _realShopPhone = shopPhone.isNotEmpty
              ? shopPhone
              : ownerPhone.isNotEmpty
                  ? ownerPhone
                  : "Phone not set";
        }

        if (addressData != null) {
          final addrLine = addressData['addr1']?.toString() ?? '';
          final city = addressData['city']?.toString() ?? '';
          final state = addressData['state']?.toString() ?? '';
          final pincode = addressData['pincode']?.toString() ?? '';

          final parts = [addrLine, city, state, pincode]
              .where((p) => p.isNotEmpty)
              .toList();
          _realShopAddress =
              parts.isNotEmpty ? parts.join(', ') : "Address not set";
        }

        if (taxData != null) {
          final gstin = taxData['gstin']?.toString() ?? '';
          _realShopGstin = gstin.isNotEmpty ? gstin : "Not Registered";
        }

        AppLogger.debug(
            " [INVOICE] Shop data loaded: $_realShopName | $_realShopPhone | $_realShopAddress");
      } else {
        AppLogger.debug(
            " [INVOICE] No shop profile found in DB. Using defaults.");
        _realShopName = "Shop Name Not Set";
        _realShopAddress = "Please complete Shop Setup";
        _realShopPhone = "Phone not set";
      }
    } catch (e) {
      AppLogger.error(" [INVOICE] Error fetching shop data: $e");
      _realShopName =
          billing.shopName.isNotEmpty ? billing.shopName : "Lotus Jewellers";
    }
  }

  PosInvoiceModel _buildInvoiceSnapshot() {
    return PosInvoiceModel(
      invoiceNumber: billing.formattedInvoice,
      invoiceDate: billing.editingBillDate ?? DateTime.now(),
      billType: billing.billType,
      billingMode: billing.billingMode,
      shopName: _realShopName,
      shopAddress: _realShopAddress,
      shopPhone: _realShopPhone,
      shopGstin: _realShopGstin,
      customerName: billing.nameCtrl.text,
      customerMobile: billing.mobileCtrl.text,
      customerCity: billing.cityCtrl.text,
      customerPan: billing.panCtrl.text,
      customerGstin: billing.gstCtrl.text,
      oldGoldMode: billing.oldGoldMode,
      saleItems: List.from(billing.saleItems),
      oldGoldItems: List.from(billing.oldGoldItems),
      grossAmount: billing.grossAmount,
      discountAmount: billing.discountAmount,
      taxableAmount: billing.taxableAmount,
      cgst: billing.cgst,
      sgst: billing.sgst,
      totalGst: billing.totalGst,
      totalOldGoldDeduction: billing.oldGoldCashDeduction,
      grandTotal: billing.grandTotal,
      totalMakingCharge: billing.totalMakingCharge,
      cashPaid: billing.cashPaidAmount,
      upiPaid: billing.upiPaidAmount,
      cardPaid: billing.cardPaidAmount,
      advancePaid: billing.advancePaidAmount,
      balanceDue: billing.invoiceBalanceDue,
      changeSettlementMethod: billing.changeReturnMethod,
      changeSettlementAmount: billing.changeReturnAmount,
      changeSettlementPaymentMode: billing.changeCreditSourcePaymentMode,
      promiseDate: dueDate,
    );
  }

  // ==========================================
  //  STEP 1: Reserve the next sequence number from the database.
  // Drift tables do not expose count() directly here.
  //         select().get() se list lo, .length lo
  // ==========================================
  Future<void> _syncNextInvoicePreview() async {
    if (billing.isCurrentSaleCommitted) {
      return;
    }

    try {
      final nextSequence = await _checkoutRepo.fetchNextInvoiceSequence(
        invoicePrefix: billing.invoicePrefix,
        shopInitials: billing.shopInitials,
        financialYear: billing.currentFinancialYear,
      );
      billing.updateInvoiceSequencePreview(nextSequence);
    } catch (_) {
      // Fall back to the invoice already held in preview memory.
    }
  }

  // ==========================================
  //  STEP 2: Persist the bill and line items to the database.
  // ==========================================
  PosInvoiceModel _copyInvoiceWithNumber(
    PosInvoiceModel source,
    String invoiceNumber,
  ) {
    return PosInvoiceModel(
      invoiceNumber: invoiceNumber,
      invoiceDate: source.invoiceDate,
      billType: source.billType,
      billingMode: source.billingMode,
      shopName: source.shopName,
      shopAddress: source.shopAddress,
      shopPhone: source.shopPhone,
      shopGstin: source.shopGstin,
      customerName: source.customerName,
      customerMobile: source.customerMobile,
      customerCity: source.customerCity,
      customerPan: source.customerPan,
      customerGstin: source.customerGstin,
      oldGoldMode: source.oldGoldMode,
      saleItems: source.saleItems,
      oldGoldItems: source.oldGoldItems,
      grossAmount: source.grossAmount,
      discountAmount: source.discountAmount,
      taxableAmount: source.taxableAmount,
      cgst: source.cgst,
      sgst: source.sgst,
      totalGst: source.totalGst,
      totalOldGoldDeduction: source.totalOldGoldDeduction,
      grandTotal: source.grandTotal,
      cashPaid: source.cashPaid,
      upiPaid: source.upiPaid,
      cardPaid: source.cardPaid,
      advancePaid: source.advancePaid,
      balanceDue: source.balanceDue,
      changeSettlementMethod: source.changeSettlementMethod,
      changeSettlementAmount: source.changeSettlementAmount,
      changeSettlementPaymentMode: source.changeSettlementPaymentMode,
      totalMakingCharge: source.totalMakingCharge,
      promiseDate: source.promiseDate,
    );
  }

  Future<void> _saveBillToDatabase(PosInvoiceModel inv) async {
    if (isSavedToDb) return;

    final editingBillId = billing.editingBillId;
    if (editingBillId != null) {
      await _checkoutRepo.updateSale(
        billId: editingBillId,
        invoice: inv,
        customerId: billing.selectedCustomer?.id,
      );
      savedBillDbId = editingBillId;
      billing.markCurrentSaleCommitted(inv.invoiceNumber);
      isSavedToDb = true;
      return;
    }

    if (billing.isCurrentSaleCommitted) {
      final existingBill = await (_db.select(_db.bills)
            ..where((tbl) => tbl.billNo.equals(inv.invoiceNumber)))
          .getSingleOrNull();
      savedBillDbId = existingBill?.id;
      isSavedToDb = true;
      return;
    }

    // --- Insert the bill header record. ---
    final result = await _checkoutRepo.finalizeSale(
      invoice: inv,
      customerId: billing.selectedCustomer?.id,
      sourceAdvanceOrderId: billing.convertedAdvanceOrderId,
      sourceAdvanceOrderNo: billing.convertedAdvanceOrderNo,
    );

    savedBillDbId = result.billId;

    // --- Insert each sale line item. ---
    /*
    for (final item in billing.saleItems) {
      final grossWt = double.tryParse(item.grossCtrl.text) ?? 0.0;
      final itemName = item.descCtrl.text.isNotEmpty
          ? item.descCtrl.text
          : item.metal.displayName;

      await _db.into(_db.billItems).insert(
            BillItemsCompanion(
              billId: Value(billId),
              itemName: Value(itemName),
              huid: Value(
                  item.huidCtrl.text.isNotEmpty ? item.huidCtrl.text : null),
              purity: Value(
                  item.purityCtrl.text.isNotEmpty ? item.purityCtrl.text : ''),
              grossWeight: Value(grossWt),
              netWeight: Value(item.netWt),
              rate: Value(item.rate),
              makingCharge: Value(item.makingAmt),
              itemTotal: Value(item.totalValue),
            ),
          );
    }

    */
    billing.markCurrentSaleCommitted(result.invoiceNumber);
    billing.updateInvoiceSequencePreview(result.invoiceSequence + 1);
    await billing.markConvertedAdvanceDeliveredIfNeeded(result.invoiceNumber);

    if (result.invoiceNumber != inv.invoiceNumber) {
      invoice = _copyInvoiceWithNumber(inv, result.invoiceNumber);
      await _refreshActivePreviewPdf();
    }

    isSavedToDb = true;
  }

  Future<void> finalizeInvoiceIfNeeded() async {
    if (invoice == null) {
      await generateInvoice();
    }
    if (invoice == null) return;
    try {
      await _saveBillToDatabase(invoice!);
    } catch (e) {
      errorMessage = e.toString();
      genState = InvoiceGenState.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> generateInvoice() async {
    genState = InvoiceGenState.generating;
    errorMessage = null;
    if (!billing.isCurrentSaleCommitted) {
      isSavedToDb = false;
      savedBillDbId = null;
    }
    notifyListeners();
    try {
      await Future.wait([
        _fetchRealShopData(),
        _syncNextInvoicePreview(),
      ]);

      dueDate = billing.promiseDate;
      invoice = _buildInvoiceSnapshot();
      await _loadMetalBillingSettings(invoice!);

      await _refreshActivePreviewPdf();
      genState = InvoiceGenState.ready;
    } catch (e) {
      errorMessage = e.toString();
      genState = InvoiceGenState.error;
    }
    notifyListeners();
  }

  Future<Uint8List?> generatePreviewPdfBytes({
    PrintFormat format = PrintFormat.a4,
    bool includeAllMetals = true,
  }) async {
    selectedFormat = format;
    await generateInvoice();
    final currentInvoice = invoice;
    if (currentInvoice == null || genState == InvoiceGenState.error) {
      return null;
    }
    return _buildPdf(
      currentInvoice,
      format,
      includeAllMetals: includeAllMetals,
    );
  }

  Future<void> _refreshActivePreviewPdf() async {
    if (invoice == null) return;
    pdfBytes = await _buildPdf(
      invoice!,
      selectedFormat,
      activeMetal: effectiveActiveMetal,
    );
  }

  Future<Uint8List> _buildPdf(
    PosInvoiceModel inv,
    PrintFormat fmt, {
    MetalType? activeMetal,
    bool includeAllMetals = false,
  }) {
    return _pdfBuilder.build(
      invoice: inv,
      options: PosInvoicePdfBuildOptions(
        format: fmt,
        copies: printCopies,
        includeDuplicateStamp: includeDuplicateStamp,
        activeMetal: activeMetal,
        includeAllMetals: includeAllMetals,
        metalPrintSettings: metalPrintSettings,
      ),
    );
  }

  Future<void> printInvoice(PrintFormat format) async {
    await finalizeInvoiceIfNeeded();
    if (invoice == null) return;
    if (format != selectedFormat) {
      selectedFormat = format;
      await _refreshActivePreviewPdf();
      notifyListeners();
    }
    final printBytes = await _buildPdf(
      invoice!,
      format,
      includeAllMetals: true,
    );
    await _outputService.printPdf(printBytes);
  }

  Future<void> openDirectWhatsAppChat() async {
    await finalizeInvoiceIfNeeded();
    if (invoice == null) return;
    await _outputService.openWhatsAppInvoice(invoice!);
  }

  Future<String?> downloadPdf() async {
    await finalizeInvoiceIfNeeded();
    if (pdfBytes == null || invoice == null) return null;

    return _outputService.downloadPdf(
      invoice: invoice!,
      buildPdfBytes: () => _buildPdf(
        invoice!,
        selectedFormat,
        includeAllMetals: true,
      ),
    );
  }

  Future<void> switchFormat(PrintFormat fmt) async {
    selectedFormat = fmt;
    notifyListeners();
    if (invoice != null) {
      await _refreshActivePreviewPdf();
      notifyListeners();
    }
  }

  Future<void> setDueDate(DateTime? date) async {
    dueDate = date;
    if (invoice != null) {
      invoice = PosInvoiceModel(
        invoiceNumber: invoice!.invoiceNumber,
        invoiceDate: invoice!.invoiceDate,
        billType: invoice!.billType,
        billingMode: invoice!.billingMode,
        shopName: invoice!.shopName,
        shopAddress: invoice!.shopAddress,
        shopPhone: invoice!.shopPhone,
        shopGstin: invoice!.shopGstin,
        customerName: invoice!.customerName,
        customerMobile: invoice!.customerMobile,
        customerCity: invoice!.customerCity,
        customerPan: invoice!.customerPan,
        customerGstin: invoice!.customerGstin,
        oldGoldMode: invoice!.oldGoldMode,
        saleItems: invoice!.saleItems,
        oldGoldItems: invoice!.oldGoldItems,
        grossAmount: invoice!.grossAmount,
        discountAmount: invoice!.discountAmount,
        taxableAmount: invoice!.taxableAmount,
        cgst: invoice!.cgst,
        sgst: invoice!.sgst,
        totalGst: invoice!.totalGst,
        totalOldGoldDeduction: invoice!.totalOldGoldDeduction,
        grandTotal: invoice!.grandTotal,
        cashPaid: invoice!.cashPaid,
        upiPaid: invoice!.upiPaid,
        cardPaid: invoice!.cardPaid,
        advancePaid: invoice!.advancePaid,
        balanceDue: invoice!.balanceDue,
        changeSettlementMethod: invoice!.changeSettlementMethod,
        changeSettlementAmount: invoice!.changeSettlementAmount,
        changeSettlementPaymentMode: invoice!.changeSettlementPaymentMode,
        totalMakingCharge: invoice!.totalMakingCharge,
        promiseDate: dueDate,
      );
      await _refreshActivePreviewPdf();
    }
    notifyListeners();
  }

  void reset() {
    _resetState();
    notifyListeners();
  }

  void _resetState() {
    genState = InvoiceGenState.idle;
    invoice = null;
    pdfBytes = null;
    errorMessage = null;
    isSavedToDb = false;
    savedBillDbId = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _resetState();
    super.dispose();
  }
}
