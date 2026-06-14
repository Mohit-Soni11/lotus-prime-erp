// ==========================================
// FILE: pos_billing_controller.dart
// TYPE: Master Business Logic Controller
// DESCRIPTION: Coordinates POS state, customer search, billing totals, held bills, and invoice readiness.
// ==========================================

import 'package:flutter/material.dart';
import 'dart:async'; //  Timer support for debounced input

import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales & orders/sales_pos_models/sales_pos_models.dart';
import '../../../models/sales & orders/sales_pos_models/pos_hold_bill_model.dart';
import '../../../models/sales & orders/sales_pos_models/pos_stock_lookup_model.dart';
import '../../../database/db/app_database.dart';
import '../../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../../models/customer/customer_enums/customer_list_enums.dart';

//  Fuzzy search support
import '../../../helpers/search/fuzzy_search_helper.dart';
import '../../../repositories/sales & orders/pos/pos_hold_repository.dart';
import '../../../repositories/sales & orders/pos/pos_checkout_repository.dart';
import '../../../repositories/sales & orders/pos/pos_stock_lookup_repository.dart';
import '../../../repositories/booking_advance/booking_advance_repository.dart';
import '../../../repositories/setting/metal_rate/metal_rate_quote_service.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart';
import '../../../repositories/setting/shop_setup/shop_session_manager.dart';
import '../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../models/setting/tax_gst/gst_slab_model.dart';

//  Customer history support
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../models/customer/customer_profile/customer_profile_model.dart';

class PosBillingController extends ChangeNotifier {
  // --- GLOBAL CONFIG ---
  //  Shop name is loaded from the active shop setup.
  String shopName = "Lotus Jewellers";

  //  Current financial year label used for invoice numbering.
  String get currentFinancialYear => DateTime.now().year.toString();
  int nextSequence = 1;
  String? _committedInvoiceNumber;

  // --- DATABASE ---
  final AppDatabase _db = AppDatabase();
  final PosHoldRepository _holdRepo = PosHoldRepository();
  final PosCheckoutRepository _checkoutRepo = PosCheckoutRepository();
  final BookingAdvanceRepository _bookingAdvanceRepo =
      BookingAdvanceRepository();
  final ShopSetupRepository _shopRepo = ShopSetupRepository();
  final PosStockLookupRepository _stockLookupRepo = PosStockLookupRepository();
  final MetalRateQuoteService _rateQuoteService = MetalRateQuoteService();

  static const double _defaultJewelleryGstRate = 0.03;
  static const double _defaultMakingGstRate = 0.05;
  final Map<MetalType, double> _metalGstRates = {
    MetalType.gold: _defaultJewelleryGstRate,
    MetalType.silver: _defaultJewelleryGstRate,
    MetalType.platinum: _defaultJewelleryGstRate,
    MetalType.diamond: _defaultJewelleryGstRate,
  };
  double _makingGstRate = _defaultMakingGstRate;
  bool _roundOffGstAmount = true;

  Future<void> _initShopName() async {
    try {
      final tenantId = await ShopSessionManager.getPermanentTenantId();
      final shopData = await _shopRepo.fetchExistingSetup(tenantId);
      if (shopData != null) {
        final basicInfo = shopData['basic_info'] as Map<String, dynamic>?;
        if (basicInfo != null) {
          final brand = basicInfo['brand_display_name']?.toString() ?? '';
          final display = basicInfo['display_name']?.toString() ?? '';
          final name = brand.isNotEmpty ? brand : display;
          if (name.isNotEmpty) {
            shopName = name.trim();
            notifyListeners();
          }
        }
      }
    } catch (_) {
      // Keep the default name when shop setup cannot be loaded.
    }
  }

  Future<void> _loadTaxGstConfig() async {
    try {
      final config = await _db.taxGstDao.fetchConfig();
      final slabs = gstSlabListFromJson(config?.gstSlabsJson);
      _metalGstRates[MetalType.gold] =
          _rateForCategory(slabs, const ['gold'], _defaultJewelleryGstRate);
      _metalGstRates[MetalType.silver] =
          _rateForCategory(slabs, const ['silver'], _defaultJewelleryGstRate);
      _metalGstRates[MetalType.platinum] =
          _rateForCategory(slabs, const ['platinum'], _defaultJewelleryGstRate);
      _metalGstRates[MetalType.diamond] = _rateForCategory(
        slabs,
        const ['diamond', 'gemstone'],
        _defaultJewelleryGstRate,
      );
      _makingGstRate =
          _rateForCategory(slabs, const ['making'], _defaultMakingGstRate);
      _roundOffGstAmount = config?.roundOffGstAmount ?? true;
      notifyListeners();
    } catch (_) {
      // Keep default GST rates when the settings table is unavailable.
    }
  }

  double _rateForCategory(
    List<GstSlabModel> slabs,
    List<String> keywords,
    double fallback,
  ) {
    for (final slab in slabs) {
      final category = slab.category.toLowerCase();
      if (keywords.any((keyword) => category.contains(keyword))) {
        return _parseGstRate(slab.rate, fallback);
      }
    }
    return fallback;
  }

  double _parseGstRate(String label, double fallback) {
    final normalized = label.replaceAll('%', '').trim();
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return fallback;
    }
    return parsed / 100;
  }

  double _metalGstRate(MetalType metal) =>
      _metalGstRates[metal] ?? _defaultJewelleryGstRate;

  double _taxAmount(double taxable, double rate) {
    if (taxable <= 0 || rate <= 0) {
      return 0.0;
    }
    final amount = taxable * rate;
    if (!_roundOffGstAmount) {
      return amount;
    }
    return (amount * 100).roundToDouble() / 100;
  }

  // ==========================================
  // CUSTOMER SEARCH FEATURE
  //  UPGRADED: Typo-tolerant fuzzy search
  // ==========================================
  List<CustomerListItemModel> customerSuggestions = [];
  bool isSearchingCustomer = false;
  bool customerNotFound = false;
  CustomerListItemModel? selectedCustomer;

  //  Customer POS history displayed after customer selection.
  CustomerProfileModel? customerHistory;
  bool isLoadingHistory = false;
  final CustomerProfileRepository _profileRepo = CustomerProfileRepository();

  Future<void> searchCustomersByName(String query) async {
    final term = query.toLowerCase().trim();

    //  Search begins as soon as the field contains a value.
    if (term.isEmpty) {
      customerSuggestions = [];
      customerNotFound = false;
      notifyListeners();
      return;
    }

    // Skip lookup when a customer is already selected.
    if (selectedCustomer != null) return;

    try {
      // Load customers from the local database.
      final rows = await _db.select(_db.customers).get();

      // Mobile input uses substring matching.
      // Name input uses fuzzy matching.
      final bool isNumeric = RegExp(r'^\d+$').hasMatch(term);

      List<Customer> matched;

      if (isNumeric) {
        //  Match customer mobile numbers by substring.
        matched = rows
            .where((row) => row.mobile.toLowerCase().contains(term))
            .toList();
      } else {
        //  Match customer names using fuzzy search.
        matched = FuzzySearchHelper.searchObjects(
          items: rows,
          query: term,
          getSearchText: (row) => '${row.name} ${row.mobile}',
          maxResults: 8,
          threshold: 0.30,
        );
      }

      customerSuggestions =
          matched.map(_customerListItemFromRow).toList(growable: false);

      //  Show the not-found state when no customers match.
      customerNotFound = customerSuggestions.isEmpty;
    } catch (e) {
      customerSuggestions = [];
      customerNotFound = false;
    }
    notifyListeners();
  }

  void selectCustomer(CustomerListItemModel customer) {
    selectedCustomer = customer;
    nameCtrl.text = customer.name;
    mobileCtrl.text = customer.mobile;
    cityCtrl.text = customer.city;
    customerSuggestions = [];
    customerNotFound = false;
    customerHistory = null;
    notifyListeners();

    //  Fetch customer history in the background.
    _fetchCustomerHistory(customer.id);
  }

  Future<void> selectCustomerByMobile(String mobile) async {
    final digitsOnly = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanMobile = digitsOnly.length > 10
        ? digitsOnly.substring(digitsOnly.length - 10)
        : digitsOnly;
    if (cleanMobile.isEmpty) {
      return;
    }

    try {
      final row = await (_db.select(_db.customers)
            ..where((tbl) => tbl.mobile.equals(cleanMobile)))
          .getSingleOrNull();
      if (row == null) {
        await searchCustomersByName(cleanMobile);
        return;
      }
      selectCustomer(_customerListItemFromRow(row));
    } catch (_) {
      await searchCustomersByName(cleanMobile);
    }
  }

  CustomerListItemModel _customerListItemFromRow(Customer row) {
    final name = row.name;
    return CustomerListItemModel(
      id: row.id,
      name: name,
      mobile: row.mobile,
      city: _customerAddressSummary(row),
      type: CustomerType.fromString(row.type),
      billCount: 0,
      createdAt: row.createdAt,
      initials: CustomerListItemModel.buildInitials(name),
    );
  }

  String _customerAddressSummary(Customer row) {
    final parts = <String>[
      row.addressLine1 ?? '',
      row.addressLine2 ?? '',
      row.city ?? '',
      row.state ?? '',
      row.pincode ?? '',
      row.country.trim().toLowerCase() == 'india' ? '' : row.country,
    ];
    final uniqueParts = <String>[];
    for (final part in parts) {
      final clean = part.trim();
      if (clean.isNotEmpty && !uniqueParts.contains(clean)) {
        uniqueParts.add(clean);
      }
    }
    return uniqueParts.join(', ');
  }

  //  Fetch bill history, outstanding balance, and last visit details.
  Future<void> _fetchCustomerHistory(int customerId) async {
    isLoadingHistory = true;
    notifyListeners();
    try {
      final profile = await _profileRepo.fetchProfile(customerId);
      customerHistory = profile;
    } catch (_) {
      customerHistory = null;
    }
    isLoadingHistory = false;
    notifyListeners();
  }

  void clearCustomerSuggestions() {
    customerSuggestions = [];
    customerNotFound = false;
    notifyListeners();
  }

  // ==========================================
  // ITEM DESCRIPTION SUGGESTIONS FEATURE
  // Stock-linked lookup for description and HUID.
  // Suggestions are filtered by the selected metal and only show available
  // stock. Selecting one snapshot autofills the row safely.
  // ==========================================
  List<PosStockLookupModel> _descriptionSuggestions = [];
  List<PosStockLookupModel> _huidSuggestions = [];
  int _descSuggestionRowIndex = -1;
  int _huidSuggestionRowIndex = -1;
  Timer? _descSearchTimer;
  Timer? _huidSearchTimer;

  Future<void> searchDescriptions(
    String query,
    int rowIndex,
    MetalType metal,
  ) async {
    _descSearchTimer?.cancel();
    final term = query.toLowerCase().trim();
    if (term.isEmpty) {
      _descriptionSuggestions = [];
      _descSuggestionRowIndex = -1;
      notifyListeners();
      return;
    }
    _descSearchTimer = Timer(const Duration(milliseconds: 220), () async {
      try {
        _descriptionSuggestions = await _stockLookupRepo.searchByDescription(
          query: term,
          metal: metal,
        );
        _descSuggestionRowIndex = rowIndex;
      } catch (_) {
        _descriptionSuggestions = [];
        _descSuggestionRowIndex = -1;
      }
      notifyListeners();
    });
  }

  Future<void> searchHuids(
    String query,
    int rowIndex,
    MetalType metal,
  ) async {
    _huidSearchTimer?.cancel();
    final term = query.toLowerCase().trim();
    if (term.isEmpty) {
      _huidSuggestions = [];
      _huidSuggestionRowIndex = -1;
      notifyListeners();
      return;
    }
    _huidSearchTimer = Timer(const Duration(milliseconds: 120), () async {
      try {
        _huidSuggestions = await _stockLookupRepo.searchByHuid(
          query: term,
          metal: metal,
        );
        _huidSuggestionRowIndex = rowIndex;
      } catch (_) {
        _huidSuggestions = [];
        _huidSuggestionRowIndex = -1;
      }
      notifyListeners();
    });
  }

  List<PosStockLookupModel> getDescSuggestionsForRow(int rowIndex) {
    if (_descSuggestionRowIndex == rowIndex) return _descriptionSuggestions;
    return const [];
  }

  List<PosStockLookupModel> getHuidSuggestionsForRow(int rowIndex) {
    if (_huidSuggestionRowIndex == rowIndex) return _huidSuggestions;
    return const [];
  }

  void clearDescriptionSuggestions() {
    _descriptionSuggestions = [];
    _descSuggestionRowIndex = -1;
    notifyListeners();
  }

  void clearHuidSuggestions() {
    _huidSuggestions = [];
    _huidSuggestionRowIndex = -1;
    notifyListeners();
  }

  void clearAllStockSuggestions() {
    _descriptionSuggestions = [];
    _huidSuggestions = [];
    _descSuggestionRowIndex = -1;
    _huidSuggestionRowIndex = -1;
    notifyListeners();
  }

  Future<void> tryAutofillByHuid(int rowIndex) async {
    if (rowIndex < 0 || rowIndex >= saleItems.length) {
      return;
    }

    final item = saleItems[rowIndex];
    final query = item.huidCtrl.text.trim();
    if (query.isEmpty) {
      return;
    }

    final match = await _stockLookupRepo.findExactByHuid(
      query: query,
      metal: item.metal,
    );
    if (match == null) {
      return;
    }

    applyStockSuggestionToRow(
      rowIndex: rowIndex,
      suggestion: match,
    );
  }

  void applyStockSuggestionToRow({
    required int rowIndex,
    required PosStockLookupModel suggestion,
  }) {
    if (rowIndex < 0 || rowIndex >= saleItems.length) {
      return;
    }

    final item = saleItems[rowIndex];
    item.updateMetal(suggestion.metal);
    item.pcsCtrl.text = '1';
    item.descCtrl.text = suggestion.itemName.trim().isEmpty
        ? suggestion.sku
        : suggestion.itemName;
    item.huidCtrl.text = suggestion.huid?.trim() ?? '';
    item.purityCtrl.text = suggestion.purity.trim();
    item.grossCtrl.text = _formatLookupNumber(suggestion.grossWeight);
    item.lessCtrl.text = _formatLookupNumber(suggestion.lessWeight);
    item.clearMasterRateIfOwned();
    item.makingCtrl.clear();
    item.attachStockReference(
      stockItemId: suggestion.stockItemId,
      sku: suggestion.sku,
    );
    activeRowIndex = rowIndex;
    clearAllStockSuggestions();
    unawaited(applySaleItemMasterRate(item, force: true));
  }

  String _formatLookupNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Future<void> applySaleItemMasterRate(
    SaleItemModel item, {
    bool force = false,
  }) async {
    final metalSnapshot = item.metal;
    final puritySnapshot = item.purityCtrl.text.trim();
    final quote = await _rateQuoteService.sellingQuote(
      metal: _rateMetalFromSales(metalSnapshot),
      purityLabel: puritySnapshot,
    );

    if (item.metal != metalSnapshot ||
        item.purityCtrl.text.trim() != puritySnapshot) {
      return;
    }

    if (quote == null || !quote.hasRate) {
      if (force) {
        item.clearMasterRateIfOwned();
        item.clearMasterMakingIfOwned();
      }
      return;
    }

    final changed = item.applyMasterRate(
      rate: quote.billingRate,
      sourceLabel: quote.rateSourceLabel,
      force: force,
    );

    if (billingMode == BillingMode.retail) {
      item.applyMasterMaking(
        makingPercent: quote.makingChargePercent,
        makingPerGram: quote.makingChargePerGram,
        sourceLabel: quote.rateSourceLabel,
      );
    }

    if (changed) {
      notifyListeners();
    }
  }

  Future<void> applyOldMetalMasterBuyRate(
    OldGoldItemModel item, {
    bool force = false,
  }) async {
    final metalSnapshot = item.metal;
    final purityText = item.purityCtrl.text.trim();
    final purityPercent = item.purityPercent;
    final quote = await _rateQuoteService.buyingQuote(
      metal: _rateMetalFromSales(metalSnapshot),
      purityLabel: purityText.isEmpty ? null : purityText,
      purityPercent: purityText.isEmpty ? null : purityPercent,
    );

    if (item.metal != metalSnapshot ||
        item.purityCtrl.text.trim() != purityText) {
      return;
    }

    if (quote == null || !quote.hasRate) {
      if (force) {
        item.clearMasterRateIfOwned();
      }
      return;
    }

    final changed = item.applyMasterRate(
      rate: quote.billingRate,
      sourceLabel: quote.rateSourceLabel,
      force: force,
    );
    if (changed) {
      notifyListeners();
    }
  }

  Future<void> _prefillWholesaleBhawFromMaster({bool force = false}) async {
    final quotes = await _rateQuoteService.defaultSellingQuotes();
    _setBhawIfEmpty(
      goldBhawCtrl,
      _wholesaleBhawInput(quotes[MetalRateMetal.gold]),
      force: force,
    );
    _setBhawIfEmpty(
      silverBhawCtrl,
      _wholesaleBhawInput(quotes[MetalRateMetal.silver]),
      force: force,
    );
    _setBhawIfEmpty(
      platBhawCtrl,
      _wholesaleBhawInput(quotes[MetalRateMetal.platinum]),
      force: force,
    );
    _setBhawIfEmpty(
      diaBhawCtrl,
      _wholesaleBhawInput(quotes[MetalRateMetal.diamond]),
      force: force,
    );
  }

  void _setBhawIfEmpty(
    TextEditingController controller,
    double value, {
    bool force = false,
  }) {
    if (value <= 0) {
      return;
    }
    if (!force && controller.text.trim().isNotEmpty) {
      return;
    }
    final formatted = _formatRateInput(value);
    controller.text = formatted;
    controller.selection = TextSelection.collapsed(offset: formatted.length);
  }

  double _wholesaleBhawInput(MetalRateQuote? quote) {
    if (quote == null || !quote.hasRate) {
      return 0.0;
    }
    switch (quote.metal) {
      case MetalRateMetal.gold:
      case MetalRateMetal.platinum:
        return quote.ratePer10g;
      case MetalRateMetal.silver:
        return quote.ratePer10g * 100.0;
      case MetalRateMetal.diamond:
        return quote.billingRate;
    }
  }

  MetalRateMetal _rateMetalFromSales(MetalType metal) {
    switch (metal) {
      case MetalType.gold:
        return MetalRateMetal.gold;
      case MetalType.silver:
        return MetalRateMetal.silver;
      case MetalType.platinum:
        return MetalRateMetal.platinum;
      case MetalType.diamond:
        return MetalRateMetal.diamond;
    }
  }

  String _formatRateInput(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.0001) {
      return rounded.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  double _roundWeight3(double value) {
    if (value == 0) return 0.0;
    final rounded = (value * 1000).roundToDouble() / 1000.0;
    return rounded == -0.0 ? 0.0 : rounded;
  }

  // --- CORE STATES ---
  BillingMode billingMode = BillingMode.retail;
  BillType billType = BillType.normal;
  OldGoldAdjustMode oldGoldMode = OldGoldAdjustMode.cashAdjust;
  DiscountType discountType = DiscountType.percentage;

  // --- SHARED DATA LISTS ---
  final List<SaleItemModel> saleItems = [];
  final List<OldGoldItemModel> oldGoldItems = [];

  // --- UI CONTROLLERS ---
  final ScrollController tableScrollCtrl = ScrollController();
  int activeRowIndex = -1;

  // --- CUSTOMER CONTROLLERS ---
  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController panCtrl = TextEditingController();
  final TextEditingController gstCtrl = TextEditingController();

  // --- PAYMENT CONTROLLERS ---
  final TextEditingController discountCtrl = TextEditingController();
  final TextEditingController cashCtrl = TextEditingController();
  final TextEditingController upiCtrl = TextEditingController();
  final TextEditingController cardCtrl = TextEditingController();
  final TextEditingController advCtrl = TextEditingController();

  // --- WHOLESALE BHAW (RATE) CONTROLLERS ---
  final TextEditingController goldBhawCtrl = TextEditingController();
  final TextEditingController silverBhawCtrl = TextEditingController();
  final TextEditingController platBhawCtrl = TextEditingController();
  final TextEditingController diaBhawCtrl = TextEditingController();

  // --- CACHED INPUTS (For Zero-Lag UI) ---
  double _discountInput = 0.0;
  double _cashInput = 0.0;
  double _upiInput = 0.0;
  double _cardInput = 0.0;
  double _advInput = 0.0;

  double _goldBhawInput = 0.0;
  double _silverBhawInput = 0.0;
  double _platBhawInput = 0.0;
  double _diaBhawInput = 0.0;

  PosBillingController() {
    unawaited(_initializeInvoiceNumberPreview());
    unawaited(_restoreHeldBills());
    unawaited(_loadTaxGstConfig());
    discountCtrl.addListener(() {
      _discountInput = _parseSafeNumber(discountCtrl.text);
      notifyListeners();
    });
    cashCtrl.addListener(() {
      _cashInput = _parseSafeNumber(cashCtrl.text);
      notifyListeners();
    });
    upiCtrl.addListener(() {
      _upiInput = _parseSafeNumber(upiCtrl.text);
      notifyListeners();
    });
    cardCtrl.addListener(() {
      _cardInput = _parseSafeNumber(cardCtrl.text);
      notifyListeners();
    });
    advCtrl.addListener(() {
      _advInput = _parseSafeNumber(advCtrl.text);
      notifyListeners();
    });

    goldBhawCtrl.addListener(() {
      _goldBhawInput = _parseSafeNumber(goldBhawCtrl.text);
      notifyListeners();
    });
    silverBhawCtrl.addListener(() {
      _silverBhawInput = _parseSafeNumber(silverBhawCtrl.text);
      notifyListeners();
    });
    platBhawCtrl.addListener(() {
      _platBhawInput = _parseSafeNumber(platBhawCtrl.text);
      notifyListeners();
    });
    diaBhawCtrl.addListener(() {
      _diaBhawInput = _parseSafeNumber(diaBhawCtrl.text);
      notifyListeners();
    });
    unawaited(_prefillWholesaleBhawFromMaster());
  }

  int? editingBillId;
  DateTime? editingBillDate;
  bool isLoadingEditBill = false;
  String? editLoadError;
  bool get isEditingExistingBill => editingBillId != null;

  int? convertedAdvanceOrderId;
  bool isLoadingAdvanceConversion = false;
  String? advanceConversionError;
  bool get isConvertingAdvance => convertedAdvanceOrderId != null;

  Future<bool> initializeForEdit(int billId) async {
    isLoadingEditBill = true;
    editLoadError = null;
    notifyListeners();

    try {
      final details = await _checkoutRepo.fetchEditableBill(billId);
      if (details == null) {
        editLoadError = 'Sales bill could not be loaded for editing.';
        return false;
      }

      clearEntirePOS(isHolding: false, refreshInvoicePreview: false);
      editingBillId = billId;

      final bill = details.bill;
      editingBillDate = bill.billDate;
      _committedInvoiceNumber = bill.billNo;
      billingMode = _billingModeFromDb(bill.billingMode);
      billType = _billTypeFromDb(bill.billType);
      oldGoldMode = _oldGoldModeFromDb(bill.oldGoldMode);
      discountType = DiscountType.flatAmount;
      promiseDate = bill.promiseDate;

      nameCtrl.text = bill.customerName ?? '';
      mobileCtrl.text = bill.mobile ?? '';
      cityCtrl.clear();
      discountCtrl.text = _formatEditNumber(bill.discount);
      cashCtrl.text = _formatEditNumber(bill.cashPaid);
      upiCtrl.text = _formatEditNumber(bill.upiPaid);
      cardCtrl.text = _formatEditNumber(bill.cardPaid);
      advCtrl.text = _formatEditNumber(bill.advancePaid);

      if (bill.customerId != null) {
        await _restoreSelectedCustomer(bill.customerId);
      }

      for (final row in details.items) {
        final item = SaleItemModel(
          metal: _metalFromDb(row.metalType),
          makingChargeType: _makingChargeTypeFromDb(row.makingChargeType),
          isLessPerPiece: row.lessWeightPerPiece,
        );
        item.addListener(_onChildItemChanged);
        item.descCtrl.text = row.itemName;
        item.pcsCtrl.text = row.quantity.toString();
        item.huidCtrl.text = row.huid ?? '';
        item.purityCtrl.text = row.purity;
        item.grossCtrl.text = _formatEditNumber(row.grossWeight);
        item.lessCtrl.text = _formatEditNumber(row.lessWeight);
        item.rateCtrl.text = _formatEditNumber(row.rate);
        item.makingCtrl.text = _formatEditNumber(row.makingChargeInput);
        if (row.linkedStockItemId != null && row.linkedStockSku != null) {
          item.attachStockReference(
            stockItemId: row.linkedStockItemId!,
            sku: row.linkedStockSku!,
          );
        }
        saleItems.add(item);
      }

      for (final row in details.oldGoldItems) {
        final item = OldGoldItemModel(metal: _metalFromDb(row.metalType));
        item.addListener(_onChildItemChanged);
        item.descCtrl.text = row.itemDescription;
        item.grossCtrl.text = _formatEditNumber(row.grossWeight);
        item.lessCtrl.text = _formatEditNumber(row.lessWeight);
        item.purityCtrl.text = _formatEditNumber(row.purity);
        item.rateCtrl.text = _formatEditNumber(row.rate);
        oldGoldItems.add(item);
      }

      activeRowIndex = saleItems.isEmpty ? -1 : 0;
      notifyListeners();
      return true;
    } catch (error) {
      editLoadError = 'Sales bill could not be loaded for editing.';
      return false;
    } finally {
      isLoadingEditBill = false;
      notifyListeners();
    }
  }

  Future<bool> initializeFromAdvanceOrder(int orderId) async {
    isLoadingAdvanceConversion = true;
    advanceConversionError = null;
    notifyListeners();

    try {
      final details = await _bookingAdvanceRepo.fetchEditableBooking(orderId);
      if (details == null) {
        advanceConversionError =
            'Advance order could not be loaded for conversion.';
        return false;
      }

      clearEntirePOS(isHolding: false, refreshInvoicePreview: false);
      convertedAdvanceOrderId = orderId;

      final order = details.order;
      await _restoreSelectedCustomer(order.customerId);
      billingMode = BillingMode.retail;
      billType = BillType.normal;

      final item = SaleItemModel(metal: _metalFromDb(order.metalType));
      item.addListener(_onChildItemChanged);
      item.descCtrl.text = order.itemName;
      item.pcsCtrl.text = '1';
      item.purityCtrl.text = order.purity;
      item.grossCtrl.text = _formatEditNumber(order.approxWeight);
      item.lessCtrl.clear();
      item.rateCtrl.text = _formatEditNumber(order.lockedRate);
      saleItems.add(item);
      activeRowIndex = 0;

      final totalAdvance =
          details.advances.fold<double>(0, (sum, row) => sum + row.amountPaid);
      advCtrl.text = _formatEditNumber(totalAdvance);

      notifyListeners();
      return true;
    } catch (_) {
      advanceConversionError =
          'Advance order could not be loaded for conversion.';
      return false;
    } finally {
      isLoadingAdvanceConversion = false;
      notifyListeners();
    }
  }

  Future<void> markConvertedAdvanceDeliveredIfNeeded(
    String invoiceNumber,
  ) async {
    final orderId = convertedAdvanceOrderId;
    if (orderId == null) return;

    try {
      final success = await _bookingAdvanceRepo.markConvertedToSale(
        orderId: orderId,
        invoiceNumber: invoiceNumber,
      );
      if (success) {
        convertedAdvanceOrderId = null;
        advanceConversionError = null;
      } else {
        advanceConversionError =
            'Invoice saved, but advance order status was not updated.';
      }
    } catch (_) {
      advanceConversionError =
          'Invoice saved, but advance order status was not updated.';
    }
    notifyListeners();
  }

  String _formatEditNumber(double value) {
    if (value.abs() < 0.0001) return '';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.0001) {
      return rounded.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  MetalType _metalFromDb(String value) {
    final normalized = value.trim().toUpperCase();
    for (final metal in MetalType.values) {
      if (metal.displayName == normalized ||
          metal.name.toUpperCase() == normalized) {
        return metal;
      }
    }
    return MetalType.gold;
  }

  MakingChargeType _makingChargeTypeFromDb(String value) {
    switch (value.trim().toUpperCase()) {
      case 'PERCENTAGE':
        return MakingChargeType.percentage;
      case 'PER_KG':
        return MakingChargeType.perKg;
      case 'PER_PIECE':
        return MakingChargeType.perPiece;
      case 'PER_GRAM':
      default:
        return MakingChargeType.perGram;
    }
  }

  BillingMode _billingModeFromDb(String value) {
    return value.trim().toUpperCase() == 'WHOLESALE'
        ? BillingMode.wholesale
        : BillingMode.retail;
  }

  BillType _billTypeFromDb(String value) {
    return value.trim().toUpperCase() == 'GST' ? BillType.gst : BillType.normal;
  }

  OldGoldAdjustMode _oldGoldModeFromDb(String value) {
    return value.trim().toUpperCase() == 'METAL_ADJUST'
        ? OldGoldAdjustMode.metalAdjust
        : OldGoldAdjustMode.cashAdjust;
  }

  Future<void> _initializeInvoiceNumberPreview() async {
    await _initShopName();
    await refreshInvoiceSequencePreview();
  }

  double _parseSafeNumber(String text) {
    if (text.isEmpty) return 0.0;
    String cleanText = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanText) ?? 0.0;
  }

  String get shopInitials {
    final words =
        shopName.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (words.isEmpty) return 'SH'; // Safe fallback
    return words.map((e) => e[0]).join('').toUpperCase();
  }

  String get invoicePrefix => billType == BillType.gst ? "TAX" : "INV";
  String get formattedInvoice =>
      _committedInvoiceNumber ??
      "$invoicePrefix-$shopInitials-$currentFinancialYear-${nextSequence.toString().padLeft(4, '0')}";
  bool get isCurrentSaleCommitted => _committedInvoiceNumber != null;

  Future<void> refreshInvoiceSequencePreview() async {
    if (isCurrentSaleCommitted) return;

    try {
      final sequence = await _checkoutRepo.fetchNextInvoiceSequence(
        invoicePrefix: invoicePrefix,
        shopInitials: shopInitials,
        financialYear: currentFinancialYear,
      );
      updateInvoiceSequencePreview(sequence);
    } catch (_) {
      // Keep the current preview when invoice sequence lookup is unavailable.
    }
  }

  void updateInvoiceSequencePreview(int sequence) {
    final sanitizedSequence = sequence < 1 ? 1 : sequence;
    if (nextSequence == sanitizedSequence) {
      return;
    }
    nextSequence = sanitizedSequence;
    if (!isCurrentSaleCommitted) {
      notifyListeners();
    }
  }

  void markCurrentSaleCommitted(String invoiceNumber) {
    _committedInvoiceNumber ??= invoiceNumber;
    notifyListeners();
  }

  // ==========================================
  // 1. RETAIL ENGINE (B2C)
  // ==========================================
  double get totalGoldWt => saleItems
      .where((i) => i.metal == MetalType.gold)
      .fold(0, (sum, i) => sum + i.netWt);
  double get totalSilverWt => saleItems
      .where((i) => i.metal == MetalType.silver)
      .fold(0, (sum, i) => sum + i.netWt);
  double get totalPlatinumWt => saleItems
      .where((i) => i.metal == MetalType.platinum)
      .fold(0, (sum, i) => sum + i.netWt);
  double get totalDiamondWt => saleItems
      .where((i) => i.metal == MetalType.diamond)
      .fold(0, (sum, i) => sum + i.netWt);

  double get totalGoldAmount => saleItems
      .where((i) => i.metal == MetalType.gold)
      .fold(0, (sum, i) => sum + i.totalValue);
  double get totalSilverAmount => saleItems
      .where((i) => i.metal == MetalType.silver)
      .fold(0, (sum, i) => sum + i.totalValue);
  double get totalPlatinumAmount => saleItems
      .where((i) => i.metal == MetalType.platinum)
      .fold(0, (sum, i) => sum + i.totalValue);
  double get totalDiamondAmount => saleItems
      .where((i) => i.metal == MetalType.diamond)
      .fold(0, (sum, i) => sum + i.totalValue);

  double get totalOldGoldAmount =>
      oldGoldItems.fold(0, (sum, i) => sum + i.totalValue);
  double get oldGoldCashDeduction =>
      oldGoldMode == OldGoldAdjustMode.cashAdjust ? totalOldGoldAmount : 0.0;

  double get _retailGrossAmount =>
      totalGoldAmount +
      totalSilverAmount +
      totalPlatinumAmount +
      totalDiamondAmount;

  double get pureGoldAmount => totalGoldAmount - goldMakingCharge;
  double get pureSilverAmount => totalSilverAmount - silverMakingCharge;
  double get purePlatinumAmount => totalPlatinumAmount - platinumMakingCharge;
  double get pureDiamondAmount => totalDiamondAmount - diamondMakingCharge;

  // ==========================================
  // 2. WHOLESALE ENGINE (B2B)
  // ==========================================
  double get _goldBhawPerGram => _goldBhawInput / 10.0;
  double get _platBhawPerGram => _platBhawInput / 10.0;
  double get _silverBhawPerGram => _silverBhawInput / 1000.0;
  double get _diaBhawPerCarat => _diaBhawInput;

  double get goldSoldFine => _roundWeight3(saleItems
      .where((i) => i.metal == MetalType.gold)
      .fold(0.0, (sum, i) => sum + i.fineWt));
  double get silverSoldFine => _roundWeight3(saleItems
      .where((i) => i.metal == MetalType.silver)
      .fold(0.0, (sum, i) => sum + i.fineWt));
  double get platSoldFine => _roundWeight3(saleItems
      .where((i) => i.metal == MetalType.platinum)
      .fold(0.0, (sum, i) => sum + i.fineWt));
  double get diaSoldFine => _roundWeight3(saleItems
      .where((i) => i.metal == MetalType.diamond)
      .fold(0.0, (sum, i) => sum + i.fineWt));

  double get goldJamaFine => _roundWeight3(oldGoldItems
      .where((i) => i.metal == MetalType.gold)
      .fold(0.0, (sum, i) => sum + i.fineWt));
  double get silverJamaFine => _roundWeight3(oldGoldItems
      .where((i) => i.metal == MetalType.silver)
      .fold(0.0, (sum, i) => sum + i.fineWt));
  double get platJamaFine => _roundWeight3(oldGoldItems
      .where((i) => i.metal == MetalType.platinum)
      .fold(0.0, (sum, i) => sum + i.fineWt));
  double get diaJamaFine => _roundWeight3(oldGoldItems
      .where((i) => i.metal == MetalType.diamond)
      .fold(0.0, (sum, i) => sum + i.fineWt));

  double get goldNetFine => _roundWeight3(goldSoldFine - goldJamaFine);
  double get silverNetFine => _roundWeight3(silverSoldFine - silverJamaFine);
  double get platNetFine => _roundWeight3(platSoldFine - platJamaFine);
  double get diaNetFine => _roundWeight3(diaSoldFine - diaJamaFine);

  double get goldBhawAmt => goldNetFine * _goldBhawPerGram;
  double get silverBhawAmt => silverNetFine * _silverBhawPerGram;
  double get platBhawAmt => platNetFine * _platBhawPerGram;
  double get diaBhawAmt => diaNetFine * _diaBhawPerCarat;

  double get _wholesaleTotalMetalAmount =>
      goldBhawAmt + silverBhawAmt + platBhawAmt + diaBhawAmt;

  double get goldMakingCharge =>
      saleItems.where((i) => i.metal == MetalType.gold).fold(
          0,
          (sum, i) =>
              sum +
              (billingMode == BillingMode.wholesale
                  ? i.wholesaleLabourAmt
                  : i.makingAmt));
  double get silverMakingCharge =>
      saleItems.where((i) => i.metal == MetalType.silver).fold(
          0,
          (sum, i) =>
              sum +
              (billingMode == BillingMode.wholesale
                  ? i.wholesaleLabourAmt
                  : i.makingAmt));
  double get platinumMakingCharge =>
      saleItems.where((i) => i.metal == MetalType.platinum).fold(
          0,
          (sum, i) =>
              sum +
              (billingMode == BillingMode.wholesale
                  ? i.wholesaleLabourAmt
                  : i.makingAmt));
  double get diamondMakingCharge =>
      saleItems.where((i) => i.metal == MetalType.diamond).fold(
          0,
          (sum, i) =>
              sum +
              (billingMode == BillingMode.wholesale
                  ? i.wholesaleLabourAmt
                  : i.makingAmt));

  double get totalMakingCharge =>
      goldMakingCharge +
      silverMakingCharge +
      platinumMakingCharge +
      diamondMakingCharge;

  double get _wholesaleGrossAmount =>
      _wholesaleTotalMetalAmount + totalMakingCharge;

  // ==========================================
  // 3. FACADE ROUTER & MATH ENGINE
  // ==========================================
  double get grossAmount => billingMode == BillingMode.wholesale
      ? _wholesaleGrossAmount
      : _retailGrossAmount;

  double get discountAmount {
    if (discountType == DiscountType.percentage) {
      //  Percentage discount cannot exceed 100%.
      final clampedPct = _discountInput.clamp(0.0, 100.0);
      return grossAmount * clampedPct / 100;
    } else {
      //  Flat discount cannot exceed the gross amount.
      return _discountInput.clamp(0.0, grossAmount);
    }
  }

  double get taxableAmount => grossAmount - discountAmount;

  double _proportionalRatio(double partAmount) =>
      grossAmount == 0 ? 0 : (partAmount / grossAmount);

  double get goldGst {
    if (billType != BillType.gst) return 0.0;
    if (billingMode == BillingMode.wholesale) {
      double metalTaxable = goldBhawAmt -
          (discountAmount * _proportionalRatio(_wholesaleTotalMetalAmount));
      double labourTaxable = goldMakingCharge -
          (discountAmount * _proportionalRatio(totalMakingCharge));
      return _taxAmount(metalTaxable, _metalGstRate(MetalType.gold)) +
          _taxAmount(labourTaxable, _makingGstRate);
    }
    double retailTaxable = totalGoldAmount -
        (discountAmount * _proportionalRatio(totalGoldAmount));
    return _taxAmount(retailTaxable, _metalGstRate(MetalType.gold));
  }

  double get silverGst {
    if (billType != BillType.gst) return 0.0;
    if (billingMode == BillingMode.wholesale) {
      double metalTaxable = silverBhawAmt -
          (discountAmount * _proportionalRatio(_wholesaleTotalMetalAmount));
      double labourTaxable = silverMakingCharge -
          (discountAmount * _proportionalRatio(totalMakingCharge));
      return _taxAmount(metalTaxable, _metalGstRate(MetalType.silver)) +
          _taxAmount(labourTaxable, _makingGstRate);
    }
    double retailTaxable = totalSilverAmount -
        (discountAmount * _proportionalRatio(totalSilverAmount));
    return _taxAmount(retailTaxable, _metalGstRate(MetalType.silver));
  }

  double get platinumGst {
    if (billType != BillType.gst) return 0.0;
    if (billingMode == BillingMode.wholesale) {
      double metalTaxable = platBhawAmt -
          (discountAmount * _proportionalRatio(_wholesaleTotalMetalAmount));
      double labourTaxable = platinumMakingCharge -
          (discountAmount * _proportionalRatio(totalMakingCharge));
      return _taxAmount(metalTaxable, _metalGstRate(MetalType.platinum)) +
          _taxAmount(labourTaxable, _makingGstRate);
    }
    double retailTaxable = totalPlatinumAmount -
        (discountAmount * _proportionalRatio(totalPlatinumAmount));
    return _taxAmount(retailTaxable, _metalGstRate(MetalType.platinum));
  }

  double get diamondGst {
    if (billType != BillType.gst) return 0.0;
    if (billingMode == BillingMode.wholesale) {
      double metalTaxable = diaBhawAmt -
          (discountAmount * _proportionalRatio(_wholesaleTotalMetalAmount));
      double labourTaxable = diamondMakingCharge -
          (discountAmount * _proportionalRatio(totalMakingCharge));
      return _taxAmount(metalTaxable, _metalGstRate(MetalType.diamond)) +
          _taxAmount(labourTaxable, _makingGstRate);
    }
    double retailTaxable = totalDiamondAmount -
        (discountAmount * _proportionalRatio(totalDiamondAmount));
    return _taxAmount(retailTaxable, _metalGstRate(MetalType.diamond));
  }

  double get totalGst => goldGst + silverGst + platinumGst + diamondGst;
  double get cgst => totalGst / 2;
  double get sgst => totalGst / 2;

  double get grandTotal => taxableAmount + totalGst;
  double get finalPayableAmount => billingMode == BillingMode.wholesale
      ? grandTotal
      : grandTotal - oldGoldCashDeduction;
  double get totalPaid => _cashInput + _upiInput + _cardInput + _advInput;
  double get balanceDue => finalPayableAmount - totalPaid;

  static const double _invoiceWeightTolerance = 0.0005;
  static const double _invoiceAmountTolerance = 0.005;

  bool _isBillableSaleItem(SaleItemModel item) {
    if (item.netWt <= _invoiceWeightTolerance) {
      return false;
    }
    if (billingMode == BillingMode.wholesale) {
      return true;
    }
    return item.rate > 0 && item.totalValue > _invoiceAmountTolerance;
  }

  bool _isBillableOldMetalItem(OldGoldItemModel item) {
    return item.netWt > _invoiceWeightTolerance &&
        item.rate > 0 &&
        item.totalValue > _invoiceAmountTolerance;
  }

  bool get hasBillableInvoiceItems =>
      saleItems.any(_isBillableSaleItem) ||
      oldGoldItems.any(_isBillableOldMetalItem);

  String? validateInvoiceReadiness() {
    if (saleItems.isEmpty && oldGoldItems.isEmpty) {
      return "The cart is empty. Please add at least one item before generating an invoice.";
    }

    for (int index = 0; index < saleItems.length; index++) {
      final item = saleItems[index];
      final rowNumber = index + 1;
      if (item.netWt <= _invoiceWeightTolerance) {
        return "Enter gross weight for item row $rowNumber before generating an invoice.";
      }
      if (billingMode == BillingMode.retail && item.rate <= 0) {
        return "Enter a valid rate for item row $rowNumber before generating an invoice.";
      }
      if (billingMode == BillingMode.retail &&
          item.totalValue <= _invoiceAmountTolerance) {
        return "Complete item row $rowNumber before generating an invoice.";
      }
    }

    for (int index = 0; index < oldGoldItems.length; index++) {
      final item = oldGoldItems[index];
      final rowNumber = index + 1;
      if (item.netWt <= _invoiceWeightTolerance) {
        return "Enter gross weight for exchange row $rowNumber before generating an invoice.";
      }
      if (item.rate <= 0) {
        return "Enter a valid rate for exchange row $rowNumber before generating an invoice.";
      }
      if (item.totalValue <= _invoiceAmountTolerance) {
        return "Complete exchange row $rowNumber before generating an invoice.";
      }
    }

    if (!hasBillableInvoiceItems) {
      return "Complete at least one billable item before generating an invoice.";
    }

    if (finalPayableAmount < -_invoiceAmountTolerance) {
      return "This bill creates a refund/exchange balance. Please use the separate refund or exchange flow.";
    }

    if (totalPaid - finalPayableAmount > _invoiceAmountTolerance) {
      return "Payment received is higher than the final payable amount. Reduce payment or use the separate refund flow.";
    }

    if (balanceDue > _invoiceAmountTolerance) {
      if (selectedCustomer == null) {
        return "Select or create a customer before saving a due bill.";
      }
      if (promiseDate == null) {
        return "Select a promise date before saving a due bill.";
      }
    }

    if (_advInput > _invoiceAmountTolerance && selectedCustomer == null) {
      return "Select or create a customer before using advance payment.";
    }

    return null;
  }

  void focusFirstInvoiceIssue() {
    for (int index = 0; index < saleItems.length; index++) {
      final item = saleItems[index];
      FocusNode focusNode = item.grossFocus;
      if (item.netWt <= _invoiceWeightTolerance) {
        focusNode = item.grossFocus;
      } else if (billingMode == BillingMode.retail && item.rate <= 0) {
        focusNode = item.rateFocus;
      } else if (billingMode == BillingMode.retail &&
          item.totalValue <= _invoiceAmountTolerance) {
        focusNode = item.grossFocus;
      } else {
        continue;
      }

      activeRowIndex = index;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 80), () {
        if (saleItems.contains(item)) {
          focusNode.requestFocus();
        }
      });
      return;
    }

    for (final item in oldGoldItems) {
      if (_isBillableOldMetalItem(item)) {
        continue;
      }
      Future.delayed(const Duration(milliseconds: 80), () {
        if (oldGoldItems.contains(item)) {
          item.firstFieldFocus.requestFocus();
        }
      });
      return;
    }
  }

  // ==========================================
  // UI ACTIONS & MEMORY SAFE LISTENERS
  // ==========================================
  void _onChildItemChanged() => notifyListeners();

  void addNewSaleItem() {
    var newItem = SaleItemModel();
    newItem.addListener(_onChildItemChanged);
    newItem.purityCtrl.text = '24KT';
    saleItems.add(newItem);
    activeRowIndex = saleItems.length - 1;
    notifyListeners();
    unawaited(applySaleItemMasterRate(newItem, force: true));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (tableScrollCtrl.hasClients) {
        tableScrollCtrl.animateTo(tableScrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      newItem.firstFieldFocus.requestFocus();
    });
  }

  void removeSaleItem(int index) {
    if (index < 0 || index >= saleItems.length) return;
    saleItems[index].removeListener(_onChildItemChanged);
    saleItems[index].dispose();
    saleItems.removeAt(index);
    if (activeRowIndex >= saleItems.length) {
      activeRowIndex = saleItems.length - 1;
    }
    notifyListeners();
  }

  void removeActiveItem() {
    if (activeRowIndex != -1 && saleItems.isNotEmpty) {
      int deletedIndex = activeRowIndex;
      removeSaleItem(deletedIndex);
      Future.delayed(const Duration(milliseconds: 50), () {
        if (saleItems.isNotEmpty) {
          int focusIndex = deletedIndex > 0 ? deletedIndex - 1 : 0;
          saleItems[focusIndex].firstFieldFocus.requestFocus();
          activeRowIndex = focusIndex;
        }
      });
    }
  }

  void addOldGoldItem() {
    var newItem = OldGoldItemModel();
    newItem.addListener(_onChildItemChanged);
    oldGoldItems.add(newItem);
    notifyListeners();
    unawaited(applyOldMetalMasterBuyRate(newItem, force: true));
  }

  void removeOldGoldItem(int index) {
    if (index < 0 || index >= oldGoldItems.length) return;
    oldGoldItems[index].removeListener(_onChildItemChanged);
    oldGoldItems[index].dispose();
    oldGoldItems.removeAt(index);
    notifyListeners();
  }

  void toggleOldGoldMode(OldGoldAdjustMode mode) {
    oldGoldMode = mode;
    notifyListeners();
  }

  void toggleBillingMode(BillingMode mode) {
    billingMode = mode;
    notifyListeners();
    if (mode == BillingMode.wholesale) {
      unawaited(_prefillWholesaleBhawFromMaster());
    }
  }

  void toggleBillType(BillType type) {
    billType = type;
    notifyListeners();
    unawaited(refreshInvoiceSequencePreview());
  }

  void toggleDiscountType(DiscountType type) {
    discountType = type;
    notifyListeners();
  }

  // --- HOLD INVOICE SYSTEM LOGIC ---
  final List<PosHoldBillModel> heldBills = [];

  //  Promise date is carried from the billing panel to the invoice.
  DateTime? promiseDate;

  void setPromiseDate(DateTime? date) {
    promiseDate = date;
    notifyListeners();
  }

  Future<void> _restoreHeldBills() async {
    final restored = await _holdRepo.loadHeldBills();
    restored.sort((a, b) => b.holdTime.compareTo(a.holdTime));
    heldBills
      ..clear()
      ..addAll(restored);
    notifyListeners();
  }

  Future<void> _persistHeldBills() async {
    if (heldBills.isEmpty) {
      await _holdRepo.clear();
      return;
    }
    await _holdRepo.saveHeldBills(heldBills);
  }

  Future<void> _restoreSelectedCustomer(int? customerId) async {
    if (customerId == null) {
      return;
    }

    try {
      final row = await (_db.select(_db.customers)
            ..where((tbl) => tbl.id.equals(customerId)))
          .getSingleOrNull();
      if (row == null) {
        return;
      }

      selectedCustomer = _customerListItemFromRow(row);
      nameCtrl.text = selectedCustomer!.name;
      mobileCtrl.text = selectedCustomer!.mobile;
      cityCtrl.text = selectedCustomer!.city;
      notifyListeners();
      unawaited(_fetchCustomerHistory(row.id));
    } catch (_) {
      selectedCustomer = null;
    }
  }

  PosHoldBillModel _buildHoldSnapshot() {
    return PosHoldBillModel(
      holdId: DateTime.now().millisecondsSinceEpoch.toString(),
      holdTime: DateTime.now(),
      selectedCustomerId: selectedCustomer?.id,
      customerName: nameCtrl.text,
      customerMobile: mobileCtrl.text,
      customerCity: cityCtrl.text,
      customerPan: panCtrl.text,
      customerGst: gstCtrl.text,
      billingMode: billingMode,
      billType: billType,
      oldGoldMode: oldGoldMode,
      discountType: discountType,
      promiseDate: promiseDate,
      discountInput: discountCtrl.text,
      cashInput: cashCtrl.text,
      upiInput: upiCtrl.text,
      cardInput: cardCtrl.text,
      advanceInput: advCtrl.text,
      goldBhawInput: goldBhawCtrl.text,
      silverBhawInput: silverBhawCtrl.text,
      platinumBhawInput: platBhawCtrl.text,
      diamondBhawInput: diaBhawCtrl.text,
      grandTotal: finalPayableAmount,
      savedSaleItems: saleItems
          .map(PosHoldSaleItemSnapshot.capture)
          .toList(growable: false),
      savedOldMetalItems: oldGoldItems
          .map(PosHoldOldMetalSnapshot.capture)
          .toList(growable: false),
    );
  }

  void _restoreHoldSnapshot(PosHoldBillModel holdBill) {
    billingMode = holdBill.billingMode;
    billType = holdBill.billType;
    oldGoldMode = holdBill.oldGoldMode;
    discountType = holdBill.discountType;
    promiseDate = holdBill.promiseDate;

    nameCtrl.text = holdBill.customerName;
    mobileCtrl.text = holdBill.customerMobile;
    cityCtrl.text = holdBill.customerCity;
    panCtrl.text = holdBill.customerPan;
    gstCtrl.text = holdBill.customerGst;

    discountCtrl.text = holdBill.discountInput;
    cashCtrl.text = holdBill.cashInput;
    upiCtrl.text = holdBill.upiInput;
    cardCtrl.text = holdBill.cardInput;
    advCtrl.text = holdBill.advanceInput;

    goldBhawCtrl.text = holdBill.goldBhawInput;
    silverBhawCtrl.text = holdBill.silverBhawInput;
    platBhawCtrl.text = holdBill.platinumBhawInput;
    diaBhawCtrl.text = holdBill.diamondBhawInput;

    for (final snapshot in holdBill.savedSaleItems) {
      final item = snapshot.restore();
      item.addListener(_onChildItemChanged);
      saleItems.add(item);
    }

    for (final snapshot in holdBill.savedOldMetalItems) {
      final item = snapshot.restore();
      item.addListener(_onChildItemChanged);
      oldGoldItems.add(item);
    }

    activeRowIndex = saleItems.isEmpty ? -1 : 0;
    unawaited(_restoreSelectedCustomer(holdBill.selectedCustomerId));
  }

  void holdCurrentBill() {
    if (saleItems.isEmpty && oldGoldItems.isEmpty) return;

    final newHold = _buildHoldSnapshot();
    heldBills.insert(0, newHold);
    clearEntirePOS(isHolding: false);
    notifyListeners();
    unawaited(_persistHeldBills());
  }

  void resumeBill(String holdId) {
    final targetBillIndex = heldBills.indexWhere((b) => b.holdId == holdId);
    if (targetBillIndex == -1) return;

    final targetBill = heldBills[targetBillIndex];

    // Reattach listeners because held items lose listeners during parking.
    heldBills.removeAt(targetBillIndex);
    clearEntirePOS(isHolding: false);
    _restoreHoldSnapshot(targetBill);
    notifyListeners();
    unawaited(_persistHeldBills());
  }

  void deleteHeldBill(String holdId) {
    heldBills.removeWhere((b) => b.holdId == holdId);
    notifyListeners();
    unawaited(_persistHeldBills());
  }

  void clearEntirePOS({
    bool isHolding = false,
    bool refreshInvoicePreview = true,
  }) {
    editingBillId = null;
    editingBillDate = null;
    editLoadError = null;
    convertedAdvanceOrderId = null;
    advanceConversionError = null;
    _committedInvoiceNumber = null;
    selectedCustomer = null;
    customerSuggestions = [];
    customerNotFound = false;
    customerHistory = null;
    isLoadingHistory = false;
    clearAllStockSuggestions();
    promiseDate = null; //  Reset the promise date.
    nameCtrl.clear();
    mobileCtrl.clear();
    cityCtrl.clear();
    panCtrl.clear();
    gstCtrl.clear();

    discountCtrl.clear();
    cashCtrl.clear();
    upiCtrl.clear();
    cardCtrl.clear();
    advCtrl.clear();

    goldBhawCtrl.clear();
    silverBhawCtrl.clear();
    platBhawCtrl.clear();
    diaBhawCtrl.clear();

    if (!isHolding) {
      for (var item in saleItems) {
        item.removeListener(_onChildItemChanged);
        item.dispose();
      }
      for (var item in oldGoldItems) {
        item.removeListener(_onChildItemChanged);
        item.dispose();
      }
    }

    saleItems.clear();
    oldGoldItems.clear();
    activeRowIndex = -1;
    if (refreshInvoicePreview) {
      unawaited(refreshInvoiceSequencePreview());
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _descSearchTimer?.cancel(); //  Cancel any pending debounce timer.
    _huidSearchTimer?.cancel();
    clearEntirePOS(isHolding: false, refreshInvoicePreview: false);
    //  The shared database instance must remain open for the app lifecycle.
    // AppDatabase is a Dart singleton. Calling close() here was shutting
    // down the ENTIRE app's database whenever the POS screen was exited.
    // Singleton databases must never be manually closed mid-session.
    tableScrollCtrl.dispose();
    mobileCtrl.dispose();
    nameCtrl.dispose();
    cityCtrl.dispose();
    panCtrl.dispose();
    gstCtrl.dispose();
    discountCtrl.dispose();
    cashCtrl.dispose();
    upiCtrl.dispose();
    cardCtrl.dispose();
    advCtrl.dispose();
    goldBhawCtrl.dispose();
    silverBhawCtrl.dispose();
    platBhawCtrl.dispose();
    diaBhawCtrl.dispose();
    super.dispose();
  }
}
