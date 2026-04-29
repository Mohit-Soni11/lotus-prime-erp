// ==========================================
// FILE: pos_billing_controller.dart
// TYPE: Master Business Logic Controller
// AUTHOR: Senior System Architect
// DESCRIPTION: Zero-lag State Manager.
//              ✅ MEMORY CRASH FIXED FOR HOLD SYSTEM.
//              ✅ DELETE HELD BILL FUNCTION ADDED.
//              ✅ FUZZY SEARCH ADDED (Google-style typo tolerance).
//
// BUG FIX LOG:
//   ❌ BUG  — dispose() mein _db.close() tha.
//             AppDatabase ek singleton hai, isliye isko close karne se
//             poori app ka database band ho jaata tha. Jab bhi user POS
//             screen se bahar jaata, app crash ho jaati thi with:
//             "Can't re-open a database after closing it."
//   ✅ FIX  — _db.close() line remove kar di. Singleton database app ke
//             poore lifecycle mein live rehti hai, process exit pe
//             automatically close hoti hai.
// ==========================================

import 'package:flutter/material.dart';
import 'dart:async'; // ✅ FIX: Timer for debounce

import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales & orders/sales_pos_models/sales_pos_models.dart';
import '../../../models/sales & orders/sales_pos_models/pos_hold_bill_model.dart';
import '../../../database/db/app_database.dart';
import '../../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../../models/customer/customer_enums/customer_list_enums.dart';

// ✅ NAYA IMPORT — Fuzzy Search Engine
import '../../../helpers/search/fuzzy_search_helper.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart';
import '../../../repositories/setting/shop_setup/shop_session_manager.dart';

// ✅ NAYA IMPORT — Customer History in POS
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../models/customer/customer_profile/customer_profile_model.dart';

class PosBillingController extends ChangeNotifier {
  // --- GLOBAL CONFIG ---
  // ✅ FIX: Shop name dynamically loaded from DB on init
  String shopName = "Lotus Jewellers"; // default, overridden in initShopData()

  // ✅ FIX: Financial year — current year se dynamically nikalo
  String get currentFinancialYear => DateTime.now().year.toString();
  int nextSequence = 1;

  // --- DATABASE ---
  final AppDatabase _db = AppDatabase();
  final ShopSetupRepository _shopRepo = ShopSetupRepository();

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
            shopName = name.trim(); // ✅ Extra spaces hata do
            notifyListeners();
          }
        }
      }
    } catch (_) {
      // fallback: default name rehega
    }
  }

  // ==========================================
  // CUSTOMER SEARCH FEATURE
  // ✅ UPGRADED: Google-style Fuzzy Search
  // ==========================================
  List<CustomerListItemModel> customerSuggestions = [];
  bool isSearchingCustomer = false;
  bool customerNotFound = false; // ✅ NEW: "Not Found" state
  CustomerListItemModel? selectedCustomer;

  // ✅ NAYA: Customer POS History — select hone ke baad dikhega
  CustomerProfileModel? customerHistory;
  bool isLoadingHistory = false;
  final CustomerProfileRepository _profileRepo = CustomerProfileRepository();

  Future<void> searchCustomersByName(String query) async {
    final term = query.toLowerCase().trim();

    // ✅ FIX: 1 character se hi search shuru ho
    if (term.length < 1) {
      customerSuggestions = [];
      customerNotFound = false;
      notifyListeners();
      return;
    }

    // Agar customer already select ho chuka hai to search mat karo
    if (selectedCustomer != null) return;

    try {
      // Pehle DB se saare customers load karo
      final rows = await _db.select(_db.customers).get();

      // Mobile field se search: exact prefix match pehle try karo
      // Name field se search: fuzzy match
      final bool isNumeric = RegExp(r'^\d+$').hasMatch(term);

      List matched;

      if (isNumeric) {
        // ✅ Mobile number search: jo bhi number se start kare ya contain kare
        matched = rows
            .where((row) => row.mobile.toLowerCase().contains(term))
            .toList();
      } else {
        // ✅ Name search: fuzzy search
        matched = FuzzySearchHelper.searchObjects(
          items: rows,
          query: term,
          getSearchText: (row) => '${row.name} ${row.mobile}',
          maxResults: 8,
          threshold: 0.30,
        );
      }

      customerSuggestions = matched.map((row) {
        final name = row.name;
        return CustomerListItemModel(
          id: row.id,
          name: name,
          mobile: row.mobile,
          city: row.city ?? '',
          type: CustomerType.fromString(row.type),
          billCount: 0,
          createdAt: row.createdAt,
          initials: CustomerListItemModel.buildInitials(name),
        );
      }).toList();

      // ✅ NEW: Agar koi result nahi mila to notFound = true
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
    customerNotFound = false; // ✅ Reset
    customerHistory = null; // ✅ Pehle purani history clear karo
    notifyListeners();

    // ✅ NAYA: Background mein history fetch karo
    _fetchCustomerHistory(customer.id);
  }

  // ✅ NAYA FUNCTION: Customer ka bill history, due, last visit fetch karo
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
    customerNotFound = false; // ✅ Reset
    notifyListeners();
  }

  // ==========================================
  // ITEM DESCRIPTION SUGGESTIONS FEATURE
  // ✅ UPGRADED: Google-style Fuzzy Search
  // Per-row: sirf active row mein suggestions dikhti hain
  // ==========================================
  List<String> descriptionSuggestions = [];
  int _descSuggestionRowIndex = -1;
  // ✅ FIX: Debounce timer — DB query only after user stops typing
  Timer? _descSearchTimer;

  Future<void> searchDescriptions(String query, int rowIndex) async {
    _descSearchTimer?.cancel();
    final term = query.toLowerCase().trim();
    if (term.length < 2) {
      descriptionSuggestions = [];
      _descSuggestionRowIndex = -1;
      notifyListeners();
      return;
    }
    // ✅ Wait 300ms after last keystroke before hitting DB
    _descSearchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final rows = await _db.select(_db.stockItems).get();
        final matched = FuzzySearchHelper.searchObjects(
          items: rows,
          query: term,
          getSearchText: (row) => '${row.itemName} ${row.description ?? ""}',
          maxResults: 8,
          threshold: 0.30,
        );
        final seen = <String>{};
        descriptionSuggestions = matched
            .map((r) => r.itemName as String)
            .where((name) => seen.add(name))
            .toList();
        _descSuggestionRowIndex = rowIndex;
      } catch (e) {
        descriptionSuggestions = [];
        _descSuggestionRowIndex = -1;
      }
      notifyListeners();
    });
  }

  // Sirf us row ke liye suggestions return karo
  List<String> getDescSuggestionsForRow(int rowIndex) {
    if (_descSuggestionRowIndex == rowIndex) return descriptionSuggestions;
    return [];
  }

  void clearDescriptionSuggestions() {
    descriptionSuggestions = [];
    _descSuggestionRowIndex = -1;
    notifyListeners();
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
    // ✅ FIX: Real shop name DB se load karo
    _initShopName();
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
      "$invoicePrefix-$shopInitials-$currentFinancialYear-${nextSequence.toString().padLeft(4, '0')}";

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

  double get goldSoldFine => saleItems
      .where((i) => i.metal == MetalType.gold)
      .fold(0, (sum, i) => sum + i.fineWt);
  double get silverSoldFine => saleItems
      .where((i) => i.metal == MetalType.silver)
      .fold(0, (sum, i) => sum + i.fineWt);
  double get platSoldFine => saleItems
      .where((i) => i.metal == MetalType.platinum)
      .fold(0, (sum, i) => sum + i.fineWt);
  double get diaSoldFine => saleItems
      .where((i) => i.metal == MetalType.diamond)
      .fold(0, (sum, i) => sum + i.fineWt);

  double get goldJamaFine => oldGoldItems
      .where((i) => i.metal == MetalType.gold)
      .fold(0, (sum, i) => sum + i.fineWt);
  double get silverJamaFine => oldGoldItems
      .where((i) => i.metal == MetalType.silver)
      .fold(0, (sum, i) => sum + i.fineWt);
  double get platJamaFine => oldGoldItems
      .where((i) => i.metal == MetalType.platinum)
      .fold(0, (sum, i) => sum + i.fineWt);
  double get diaJamaFine => oldGoldItems
      .where((i) => i.metal == MetalType.diamond)
      .fold(0, (sum, i) => sum + i.fineWt);

  double get goldNetFine => goldSoldFine - goldJamaFine;
  double get silverNetFine => silverSoldFine - silverJamaFine;
  double get platNetFine => platSoldFine - platJamaFine;
  double get diaNetFine => diaSoldFine - diaJamaFine;

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
      // ✅ FIX: % 100 se zyada nahi ho sakta
      final clampedPct = _discountInput.clamp(0.0, 100.0);
      return grossAmount * clampedPct / 100;
    } else {
      // ✅ FIX: Flat discount grossAmount se zyada nahi ho sakta
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
      return (metalTaxable > 0 ? metalTaxable * 0.03 : 0) +
          (labourTaxable > 0 ? labourTaxable * 0.05 : 0);
    }
    double retailTaxable = totalGoldAmount -
        (discountAmount * _proportionalRatio(totalGoldAmount));
    return retailTaxable > 0 ? retailTaxable * 0.03 : 0.0;
  }

  double get silverGst {
    if (billType != BillType.gst) return 0.0;
    if (billingMode == BillingMode.wholesale) {
      double metalTaxable = silverBhawAmt -
          (discountAmount * _proportionalRatio(_wholesaleTotalMetalAmount));
      double labourTaxable = silverMakingCharge -
          (discountAmount * _proportionalRatio(totalMakingCharge));
      return (metalTaxable > 0 ? metalTaxable * 0.03 : 0) +
          (labourTaxable > 0 ? labourTaxable * 0.05 : 0);
    }
    double retailTaxable = totalSilverAmount -
        (discountAmount * _proportionalRatio(totalSilverAmount));
    return retailTaxable > 0 ? retailTaxable * 0.03 : 0.0;
  }

  double get platinumGst {
    if (billType != BillType.gst) return 0.0;
    if (billingMode == BillingMode.wholesale) {
      double metalTaxable = platBhawAmt -
          (discountAmount * _proportionalRatio(_wholesaleTotalMetalAmount));
      double labourTaxable = platinumMakingCharge -
          (discountAmount * _proportionalRatio(totalMakingCharge));
      return (metalTaxable > 0 ? metalTaxable * 0.03 : 0) +
          (labourTaxable > 0 ? labourTaxable * 0.05 : 0);
    }
    double retailTaxable = totalPlatinumAmount -
        (discountAmount * _proportionalRatio(totalPlatinumAmount));
    return retailTaxable > 0 ? retailTaxable * 0.03 : 0.0;
  }

  double get diamondGst {
    if (billType != BillType.gst) return 0.0;
    if (billingMode == BillingMode.wholesale) {
      double metalTaxable = diaBhawAmt -
          (discountAmount * _proportionalRatio(_wholesaleTotalMetalAmount));
      double labourTaxable = diamondMakingCharge -
          (discountAmount * _proportionalRatio(totalMakingCharge));
      return (metalTaxable > 0 ? metalTaxable * 0.03 : 0) +
          (labourTaxable > 0 ? labourTaxable * 0.05 : 0);
    }
    double retailTaxable = totalDiamondAmount -
        (discountAmount * _proportionalRatio(totalDiamondAmount));
    return retailTaxable > 0 ? retailTaxable * 0.03 : 0.0;
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

  // ==========================================
  // UI ACTIONS & MEMORY SAFE LISTENERS
  // ==========================================
  void _onChildItemChanged() => notifyListeners();

  void addNewSaleItem() {
    var newItem = SaleItemModel();
    newItem.addListener(_onChildItemChanged);
    saleItems.add(newItem);
    activeRowIndex = saleItems.length - 1;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (tableScrollCtrl.hasClients)
        tableScrollCtrl.animateTo(tableScrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      newItem.firstFieldFocus.requestFocus();
    });
  }

  void removeSaleItem(int index) {
    if (index < 0 || index >= saleItems.length) return;
    saleItems[index].removeListener(_onChildItemChanged);
    saleItems[index].dispose();
    saleItems.removeAt(index);
    if (activeRowIndex >= saleItems.length)
      activeRowIndex = saleItems.length - 1;
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
  }

  void toggleBillType(BillType type) {
    billType = type;
    notifyListeners();
  }

  void toggleDiscountType(DiscountType type) {
    discountType = type;
    notifyListeners();
  }

  // --- HOLD INVOICE SYSTEM LOGIC ---
  final List<PosHoldBillModel> heldBills = [];

  // ✅ Promise Date — billing panel se invoice tak carry hoga
  DateTime? promiseDate;

  void setPromiseDate(DateTime? date) {
    promiseDate = date;
    notifyListeners();
  }

  void holdCurrentBill() {
    if (saleItems.isEmpty && oldGoldItems.isEmpty) return;

    final newHold = PosHoldBillModel(
      holdId: DateTime.now().millisecondsSinceEpoch.toString(),
      holdTime: DateTime.now(),
      customerName: nameCtrl.text,
      customerMobile: mobileCtrl.text,
      totalItems: saleItems.length + oldGoldItems.length,
      grandTotal: finalPayableAmount,
      savedSaleItems: List.from(saleItems),
      savedOldGoldItems: List.from(oldGoldItems),
    );

    heldBills.add(newHold);
    clearEntirePOS(isHolding: true);
    notifyListeners();
  }

  void resumeBill(String holdId) {
    clearEntirePOS(isHolding: false);

    final targetBillIndex = heldBills.indexWhere((b) => b.holdId == holdId);
    if (targetBillIndex == -1) return;

    final targetBill = heldBills[targetBillIndex];

    nameCtrl.text = targetBill.customerName;
    mobileCtrl.text = targetBill.customerMobile;

    saleItems.addAll(targetBill.savedSaleItems);
    oldGoldItems.addAll(targetBill.savedOldGoldItems);

    // ✅ FIX: Re-attach listeners — held items lose their listener on hold
    for (var item in saleItems) {
      item.addListener(_onChildItemChanged);
    }
    for (var item in oldGoldItems) {
      item.addListener(_onChildItemChanged);
    }

    heldBills.removeAt(targetBillIndex);
    notifyListeners();
  }

  void deleteHeldBill(String holdId) {
    heldBills.removeWhere((b) => b.holdId == holdId);
    notifyListeners();
  }

  void clearEntirePOS({bool isHolding = false}) {
    selectedCustomer = null;
    customerSuggestions = [];
    customerNotFound = false; // ✅ Reset
    customerHistory = null; // ✅ NAYA: History bhi clear karo
    isLoadingHistory = false;
    descriptionSuggestions = [];
    promiseDate = null; // ✅ Reset promise date
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
  }

  @override
  void dispose() {
    _descSearchTimer?.cancel(); // ✅ FIX: Cancel any pending debounce
    clearEntirePOS(isHolding: false);
    // ✅ BUG FIX: _db.close() intentionally removed.
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
