//  Database persistence dependencies
import 'package:lotus_erp/database/db/app_database.dart';
import '../../../features/print_templates/domain/print_template_registry.dart';
import '../../../features/sales_pos/application/pdf/pos_invoice_pdf_builder.dart';
import '../../../features/sales_pos/application/pdf/pos_invoice_print_config.dart';
import '../../../features/sales_pos/application/services/pos_invoice_output_service.dart';
import '../../../features/sales_pos/application/services/pos_invoice_scope_service.dart';
import '../../../features/sales_pos/domain/services/pos_invoice_file_naming.dart';
import '../../../features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import '../../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';

import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../repositories/sales_orders/pos/pos_checkout_repository.dart';
import '../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../repositories/setting/billing_setup/sales_billing_repo.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart';
import '../../../repositories/setting/shop_setup/shop_session_manager.dart';
import '../../../core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
  final ShopPrintInformationRepository _shopPrintRepo =
      ShopPrintInformationRepository();
  final SalesBillingRepo _salesBillingRepo;
  final PosInvoiceScopeService _scopeService = const PosInvoiceScopeService();
  final PosInvoicePdfBuilder _pdfBuilder = const PosInvoicePdfBuilder();
  final PosInvoiceOutputService _outputService =
      const PosInvoiceOutputService();

  final InvoicePrintConfig printConfig = InvoicePrintConfig();
  final Map<MetalType, BillSettings> metalPrintSettings = {};

  PosInvoiceController({
    required this.billing,
    AppDatabase? database,
    SalesBillingRepo? salesBillingRepo,
    PosCheckoutRepository? checkoutRepository,
  })  : _db = database ?? AppDatabase(),
        _salesBillingRepo = salesBillingRepo ?? SalesBillingRepo(db: database),
        _checkoutRepo =
            checkoutRepository ?? PosCheckoutRepository(db: database);

  InvoiceGenState genState = InvoiceGenState.idle;
  PosInvoiceModel? invoice;
  Uint8List? pdfBytes;
  String? errorMessage;

  //  Database save state
  bool isSavedToDb = false;
  int? savedBillDbId;
  final AppDatabase _db;
  final PosCheckoutRepository _checkoutRepo;

  PrintFormat selectedFormat = PrintFormat.a4;
  String selectedTemplateId = PrintTemplateRegistry.defaultTemplateId;
  int printCopies = 1;
  bool includeDuplicateStamp = false;
  MetalType? activePrintMetal;
  int _previewBuildSerial = 0;
  bool _hasWorkspaceTemplateSelection = false;

  DateTime? dueDate;

  String _realShopName = "Lotus Jewellers";
  String _realShopAddress = "Address not set";
  String _realShopPhone = "Phone not set";
  String _realShopGstin = "Not Registered";
  String _realShopStateCode = "";
  String _realShopLogoPath = "";
  String _realShopLogoShape = "square";
  ShopPrintDocumentProfile _shopPrintProfile = ShopPrintDocumentProfile.empty;
  ShopPrintInformationState? _shopPrintState;

  ShopPrintInformationState? get shopPrintInformationState => _shopPrintState;

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

  PrintTemplateDefinition get selectedTemplate {
    return PrintTemplateRegistry.byId(selectedTemplateId);
  }

  List<MetalType> get presentMetals {
    final saleItems = invoice?.saleItems ?? billing.saleItems;
    final tradeInItems = invoice?.tradeInItems ?? billing.tradeInItems;
    final present = <MetalType>{
      ...saleItems.map((item) => item.metal),
      ...tradeInItems.map((item) => item.metal),
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
    notifyListeners();
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
      case 'stoneDetails':
        return config.showStoneDetails;
      case 'stoneValue':
        return config.showStoneValue;
      case 'amount':
        return config.showAmount;
      case 'exchange':
        return config.showExchangeBreakdown;
      case 'wastage':
        return config.showWastage;
      case 'diamondClarity':
        return config.showDiamondClarity;
      case 'certificationNo':
        return config.showCertificationNo;
      case 'diamondCarats':
        return config.showDiamondCarats;
      case 'diamondPieces':
        return config.showDiamondPieces;
      case 'metalWeight':
        return config.showMetalWeight;
      case 'fineWeight':
        return config.showFineWeight;
      case 'gstBreakup':
        return config.showGstBreakup;
      case 'hsnCode':
        return config.showHsnCode;
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
      case 'stoneDetails':
        config.showStoneDetails = value;
        break;
      case 'stoneValue':
        config.showStoneValue = value;
        break;
      case 'amount':
        config.showAmount = value;
        break;
      case 'exchange':
        config.showExchangeBreakdown = value;
        break;
      case 'wastage':
        config.showWastage = value;
        break;
      case 'diamondClarity':
        config.showDiamondClarity = value;
        break;
      case 'certificationNo':
        config.showCertificationNo = value;
        break;
      case 'diamondCarats':
        config.showDiamondCarats = value;
        break;
      case 'diamondPieces':
        config.showDiamondPieces = value;
        break;
      case 'metalWeight':
        config.showMetalWeight = value;
        break;
      case 'fineWeight':
        config.showFineWeight = value;
        break;
      case 'gstBreakup':
        config.showGstBreakup = value;
        break;
      case 'hsnCode':
        config.showHsnCode = value;
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
    late BillSettings restored;
    try {
      final setup = await _salesBillingRepo.fetchForMetal(metal.name);
      restored = _settingsFromBillingSetup(setup);
    } catch (_) {
      restored = _defaultSettingsForMetal(metal);
    }

    metalPrintSettings[metal] = restored;
    _applyTemplateForActiveMetal(preferredMetal: metal);

    if (invoice != null) {
      await _refreshActivePreviewPdf();
    }
    notifyListeners();
  }

  Future<void> applySalesBillingSetupModel(SalesBillingModel model) async {
    final metal = _metalTypeFor(model.metal);
    if (metal == null) return;

    metalPrintSettings[metal] = _settingsFromBillingSetup(model);
    _applyTemplateForActiveMetal(preferredMetal: metal);

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

  bool getShopPrintFieldValue(String fieldId) {
    final state = _shopPrintState;
    if (state == null) return false;
    for (final field in state.fields) {
      if (field.id == fieldId) return state.isEnabled(field);
    }
    return false;
  }

  Future<void> setShopPrintFieldEnabled(
    ShopPrintField field,
    bool enabled,
  ) async {
    final state = _shopPrintState;
    if (state == null || !field.isConfigured) return;

    final enabledIds = {...state.enabledFieldIds};
    if (enabled) {
      enabledIds.add(field.id);
    } else {
      enabledIds.remove(field.id);
    }

    _shopPrintState = state.copyWith(enabledFieldIds: enabledIds);
    await _refreshShopPrintProfile();
    notifyListeners();
  }

  Future<void> restoreShopPrintInformationSetup() async {
    _shopPrintState = await _shopPrintRepo.load();
    await _refreshShopPrintProfile();
    notifyListeners();
  }

  Future<void> saveShopPrintInformationSetup() async {
    final state = _shopPrintState;
    if (state == null) return;
    await _shopPrintRepo.save(state);
  }

  Future<void> _ensureShopPrintStateLoaded() async {
    _shopPrintState ??= await _shopPrintRepo.load();
  }

  Future<void> _refreshShopPrintProfile() async {
    await _ensureShopPrintStateLoaded();
    final state = _shopPrintState;
    if (state == null) return;

    final printProfile = await _shopPrintRepo.buildDocumentProfile(state);
    _applyShopPrintProfile(printProfile);

    if (invoice != null) {
      invoice = _buildInvoiceSnapshot();
      await _refreshActivePreviewPdf();
    }
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
    if (metals.isNotEmpty && !_hasWorkspaceTemplateSelection) {
      _applyTemplateForActiveMetal();
    }
  }

  void _applyTemplateForActiveMetal({MetalType? preferredMetal}) {
    if (_hasWorkspaceTemplateSelection) return;
    final metal = preferredMetal ?? effectiveActiveMetal;
    if (metal == null) return;
    if (preferredMetal != null && effectiveActiveMetal != preferredMetal) {
      return;
    }

    final configuredTemplate =
        metalPrintSettings[metal]?.selectedTemplate.trim() ?? '';
    if (configuredTemplate.isEmpty) return;
    selectedTemplateId = PrintTemplateRegistry.byId(configuredTemplate).id;
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

  MetalType? _metalTypeFor(String metal) {
    for (final type in MetalType.values) {
      if (type.name == metal) return type;
    }
    return null;
  }

  Future<void> updatePrintOptions(
      {required int copies, required bool duplicate}) async {
    final normalizedCopies = copies.clamp(1, 5).toInt();
    printCopies = normalizedCopies;
    includeDuplicateStamp = normalizedCopies > 1 && duplicate;
    if (invoice != null) {
      await _refreshActivePreviewPdf();
      notifyListeners();
    }
  }

  Future<void> selectPrintTemplate(String templateId) async {
    final resolvedTemplate = PrintTemplateRegistry.byId(templateId);
    _hasWorkspaceTemplateSelection = true;
    if (selectedTemplateId == resolvedTemplate.id) return;

    selectedTemplateId = resolvedTemplate.id;
    notifyListeners();
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

          _realShopLogoPath = basicInfo['logo_path']?.toString().trim() ?? '';
          _realShopLogoShape =
              basicInfo['logo_shape']?.toString().trim().toLowerCase() ??
                  'square';
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
          _realShopStateCode =
              taxData['state_code']?.toString() ?? _stateCodeFromGstin(gstin);
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

      await _ensureShopPrintStateLoaded();
      final printProfile = await _shopPrintRepo.buildDocumentProfile(
        _shopPrintState!,
      );
      _applyShopPrintProfile(printProfile);
    } catch (e) {
      AppLogger.error(" [INVOICE] Error fetching shop data: $e");
      _realShopName =
          billing.shopName.isNotEmpty ? billing.shopName : "Lotus Jewellers";
      _realShopLogoPath = "";
      _realShopLogoShape = "square";
      _shopPrintProfile = ShopPrintDocumentProfile.empty;
    }
  }

  void _applyShopPrintProfile(ShopPrintDocumentProfile profile) {
    _shopPrintProfile = profile;
    if (profile.primaryName.isNotEmpty) {
      _realShopName = profile.primaryName;
    }
    if (profile.primaryAddress.isNotEmpty) {
      _realShopAddress = profile.primaryAddress;
    }
    if (profile.primaryPhone.isNotEmpty) {
      _realShopPhone = profile.primaryPhone;
    }
    _realShopGstin =
        profile.gstin.isNotEmpty ? profile.gstin : "Not Registered";
    _realShopLogoPath = profile.logoPath ?? '';
    _realShopLogoShape = profile.logoShape;
  }

  PosInvoiceModel _buildInvoiceSnapshot() {
    final gstPricingMode = billing.isEditingExistingBill &&
            billing.gstPricingMode == GstPricingMode.inclusive
        ? GstPricingMode.inclusive
        : GstPricingMode.exclusive;
    return PosInvoiceModel(
      invoiceNumber: billing.formattedInvoice,
      invoiceDate: billing.editingBillDate ?? DateTime.now(),
      billType: BillType.gst,
      gstPricingMode: gstPricingMode,
      documentType: SalesDocumentType.taxInvoice,
      billingMode: billing.billingMode,
      shopName: _realShopName,
      shopAddress: _realShopAddress,
      shopPhone: _realShopPhone,
      shopGstin: _realShopGstin,
      shopStateCode: _realShopStateCode,
      shopLogoPath: _realShopLogoPath,
      shopLogoShape: _realShopLogoShape,
      shopPrintFields: _shopPrintProfile.fields,
      shopPrintProfileApplied: _shopPrintProfile.tenantId.isNotEmpty,
      shopSignaturePath: _shopPrintProfile.signaturePath ?? '',
      shopSignatureShape: _shopPrintProfile.signatureShape,
      customerName: billing.nameCtrl.text,
      customerMobile: billing.mobileCtrl.text,
      customerCity: _customerAddressForInvoice(),
      customerPan: billing.panCtrl.text,
      customerGstin: billing.gstCtrl.text,
      customerStateCode: billing.placeOfSupplyStateCode,
      placeOfSupply: billing.placeOfSupplyName,
      tradeInMode: billing.tradeInMode,
      customerMetalSettlementType: billing.customerMetalSettlementType,
      saleItems: _buildPrintableSaleItemSnapshots(),
      tradeInItems: List.from(billing.tradeInItems),
      grossAmount: billing.grossAmount,
      discountAmount: billing.discountAmount,
      taxableAmount: billing.taxableAmount,
      cgst: billing.outputCgst,
      sgst: billing.outputSgst,
      totalGst: billing.totalGst,
      totalTradeInDeduction: billing.tradeInCashDeduction,
      grandTotal: billing.grandTotal,
      roundOffAmount: billing.roundOffAmount,
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
      metalPaymentAllocations: billing.metalPaymentAllocations,
    );
  }

  String _customerAddressForInvoice() {
    final enteredAddress = billing.cityCtrl.text.trim();
    final selectedAddress = billing.selectedCustomer?.city.trim() ?? '';
    if (selectedAddress.isEmpty) return enteredAddress;
    if (enteredAddress.isEmpty) return selectedAddress;

    final normalizedEntered = _normalizeAddressForComparison(enteredAddress);
    final normalizedSelected = _normalizeAddressForComparison(selectedAddress);
    if (normalizedSelected.length > normalizedEntered.length &&
        normalizedSelected.contains(normalizedEntered)) {
      return selectedAddress;
    }
    return enteredAddress;
  }

  String _normalizeAddressForComparison(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  List<SaleItemModel> _buildPrintableSaleItemSnapshots() {
    return billing.saleItems.map((source) {
      final item = SaleItemModel(
        metal: source.metal,
        makingChargeType: source.makingChargeType,
        isLessPerPiece: source.isLessPerPiece,
      );
      item.descCtrl.text = source.descCtrl.text;
      item.pcsCtrl.text = source.pcs.toString();
      item.setUnitProfile(source.unitProfile);
      item.setHuidText(source.huidText);
      item.purityCtrl.text = source.purityCtrl.text;
      item.grossCtrl.text = source.grossCtrl.text;
      item.lessCtrl.text = source.lessCtrl.text;
      item.rateCtrl.text = source.rateCtrl.text;
      item.makingCtrl.text = source.makingCtrl.text;
      item.setInvoiceHsnCode(billing.invoiceHsnCodeForMetal(source.metal));
      if (source.linkedStockItemId != null) {
        item.attachStockReference(
          stockItemId: source.linkedStockItemId!,
          stockUnitId: source.linkedStockUnitId,
          stockUnitCost: source.linkedStockUnitCost,
          stockSnapshotNetWeight: source.linkedStockSnapshotNetWeight,
          sku: source.linkedStockSku ?? '',
        );
      }
      return item;
    }).toList(growable: false);
  }

  // Reserve the next sequence number from the database for the preview invoice.
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

  // Persist the bill and line items to the database.
  PosInvoiceModel _copyInvoiceWithNumber(
    PosInvoiceModel source,
    String invoiceNumber,
  ) {
    return source.copyWith(invoiceNumber: invoiceNumber);
  }

  PosInvoiceModel _copyInvoiceWithSaleItems(
    PosInvoiceModel source,
    List<SaleItemModel> saleItems,
  ) {
    return source.copyWith(saleItems: saleItems);
  }

  Future<void> _saveBillToDatabase(PosInvoiceModel inv) async {
    if (isSavedToDb) return;

    final editingBillId = billing.editingBillId;
    if (editingBillId != null) {
      final lockedBill = await (_db.select(_db.bills)
            ..where((tbl) => tbl.id.equals(editingBillId)))
          .getSingleOrNull();
      final lockedInvoiceNumber = lockedBill?.billNo ?? inv.invoiceNumber;
      await _checkoutRepo.updateSale(
        billId: editingBillId,
        invoice: inv,
        customerId: billing.selectedCustomer?.id,
      );
      savedBillDbId = editingBillId;
      invoice = lockedInvoiceNumber == inv.invoiceNumber
          ? inv
          : _copyInvoiceWithNumber(inv, lockedInvoiceNumber);
      await _syncPrintableInvoiceLinesFromDatabase();
      billing.markCurrentSaleCommitted(lockedInvoiceNumber);
      isSavedToDb = true;
      return;
    }

    if (billing.isCurrentSaleCommitted) {
      final existingBill = await (_db.select(_db.bills)
            ..where((tbl) => tbl.billNo.equals(inv.invoiceNumber)))
          .getSingleOrNull();
      savedBillDbId = existingBill?.id;
      if (savedBillDbId != null) {
        await _syncPrintableInvoiceLinesFromDatabase();
      }
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
    } else {
      invoice = inv;
    }
    await _syncPrintableInvoiceLinesFromDatabase();
    await _refreshActivePreviewPdf();

    isSavedToDb = true;
  }

  Future<void> _syncPrintableInvoiceLinesFromDatabase() async {
    final billId = savedBillDbId;
    final currentInvoice = invoice;
    if (billId == null || currentInvoice == null) {
      return;
    }

    final persistedItems = await _checkoutRepo.fetchPrintableSaleItems(billId);
    if (persistedItems.isEmpty) {
      return;
    }

    invoice = _copyInvoiceWithSaleItems(currentInvoice, persistedItems);
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
    final buildSerial = ++_previewBuildSerial;
    final activeMetal = effectiveActiveMetal;
    final format = selectedFormat;
    final templateId = selectedTemplateId;
    final bytes = await _buildPdf(
      invoice!,
      format,
      activeMetal: activeMetal,
    );
    if (buildSerial != _previewBuildSerial ||
        activeMetal != effectiveActiveMetal ||
        format != selectedFormat ||
        templateId != selectedTemplateId) {
      return;
    }
    pdfBytes = bytes;
  }

  Future<Uint8List> _buildPdf(
    PosInvoiceModel inv,
    PrintFormat fmt, {
    MetalType? activeMetal,
    bool includeAllMetals = false,
  }) async {
    await _refreshSavedPrintCopy(inv);
    return _pdfBuilder.build(
      invoice: inv,
      options: PosInvoicePdfBuildOptions(
        format: fmt,
        copies: printCopies,
        includeDuplicateStamp: includeDuplicateStamp,
        templateId: selectedTemplateId,
        activeMetal: activeMetal,
        includeAllMetals: includeAllMetals,
        metalPrintSettings: metalPrintSettings,
      ),
    );
  }

  Future<void> _refreshSavedPrintCopy(PosInvoiceModel inv) async {
    for (final metal in _collectMetals(inv)) {
      try {
        final setup = await _salesBillingRepo.fetchForMetal(metal.name);
        final latest = _settingsFromBillingSetup(setup);
        final current = metalPrintSettings[metal];
        if (current == null) {
          metalPrintSettings[metal] = latest;
          continue;
        }

        current.termsAndConditions = latest.termsAndConditions;
        current.returnPolicyText = latest.returnPolicyText;
        current.buybackPolicyText = latest.buybackPolicyText;
        current.footerMessage = latest.footerMessage;
      } catch (_) {
        metalPrintSettings.putIfAbsent(
          metal,
          () => _defaultSettingsForMetal(metal),
        );
      }
    }
  }

  Future<bool> printInvoice(
    PrintFormat format, {
    required BuildContext context,
  }) async {
    await finalizeInvoiceIfNeeded();
    if (invoice == null) return false;
    if (format != selectedFormat) {
      selectedFormat = format;
      await _refreshActivePreviewPdf();
      notifyListeners();
    }
    final printBytes = await buildPrintPdfBytes(format);
    if (printBytes == null) return false;
    if (!context.mounted) return false;
    return _outputService.printPdf(
      context: context,
      bytes: printBytes,
      invoice: invoice!,
    );
  }

  Future<Uint8List?> buildPrintPdfBytes(PrintFormat format) async {
    await finalizeInvoiceIfNeeded();
    final currentInvoice = invoice;
    if (currentInvoice == null) return null;

    return _buildPdf(
      currentInvoice,
      format,
      includeAllMetals: true,
    );
  }

  Future<void> shareInvoicePdf() async {
    await finalizeInvoiceIfNeeded();
    if (invoice == null) return;
    await _outputService.shareInvoicePdf(
      invoice: invoice!,
      buildPdfBytes: () => _buildPdf(
        invoice!,
        selectedFormat,
        activeMetal: effectiveActiveMetal,
      ),
    );
  }

  Future<void> openDirectWhatsAppChat() async {
    await shareInvoicePdf();
  }

  Future<Uint8List?> buildExportPdfBytes({
    MetalType? metal,
    bool includeAllMetals = false,
  }) async {
    await finalizeInvoiceIfNeeded();
    final currentInvoice = invoice;
    if (currentInvoice == null) return null;

    return _buildPdf(
      currentInvoice,
      selectedFormat,
      activeMetal: includeAllMetals ? null : metal ?? effectiveActiveMetal,
      includeAllMetals: includeAllMetals,
    );
  }

  Future<String?> downloadPdf({
    MetalType? metal,
    bool includeAllMetals = false,
  }) async {
    await finalizeInvoiceIfNeeded();
    final currentInvoice = invoice;
    if (currentInvoice == null) return null;

    final targetMetal = includeAllMetals ? null : metal ?? effectiveActiveMetal;
    final downloadInvoice = includeAllMetals
        ? currentInvoice
        : _scopeService.scopedInvoiceForMetal(currentInvoice, targetMetal);

    return _outputService.downloadPdf(
      invoice: downloadInvoice,
      fileName: _exportFileNameFor(
        invoice: currentInvoice,
        metal: targetMetal,
        includeAllMetals: includeAllMetals,
      ),
      buildPdfBytes: () => _buildPdf(
        currentInvoice,
        selectedFormat,
        activeMetal: targetMetal,
        includeAllMetals: includeAllMetals,
      ),
    );
  }

  String _exportFileNameFor({
    required PosInvoiceModel invoice,
    required MetalType? metal,
    required bool includeAllMetals,
  }) {
    final baseName = PosInvoiceFileNaming.pdfBaseName(invoice);
    if (includeAllMetals) {
      return '${baseName}_All_Metals.pdf';
    }
    if (metal == null) {
      return '$baseName.pdf';
    }
    return '${baseName}_${_fileToken(metal.displayName)}.pdf';
  }

  String _fileToken(String value) {
    final clean = value
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return clean.isEmpty ? 'Invoice' : clean;
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
      invoice = invoice!.copyWith(promiseDate: dueDate);
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
    _previewBuildSerial++;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _resetState();
    super.dispose();
  }

  String _stateCodeFromGstin(String gstin) {
    final normalized = gstin.trim().toUpperCase();
    if (normalized.length < 2) return '';
    final prefix = normalized.substring(0, 2);
    return RegExp(r'^\d{2}$').hasMatch(prefix) ? prefix : '';
  }
}
