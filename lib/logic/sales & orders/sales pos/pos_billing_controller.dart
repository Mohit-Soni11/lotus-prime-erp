// ==========================================
// FILE: pos_billing_controller.dart
// TYPE: Master Business Logic Controller
// AUTHOR: Senior System Architect
// DESCRIPTION: Zero-lag State Manager.
//              ✅ MEMORY CRASH FIXED FOR HOLD SYSTEM.
//              ✅ DELETE HELD BILL FUNCTION ADDED.
// ==========================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales & orders/sales_pos_models/sales_pos_models.dart';
import '../../../models/sales & orders/sales_pos_models/pos_hold_bill_model.dart';
import '../../../database/db/app_database.dart';
import '../../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../../models/customer/customer_enums/customer_list_enums.dart';

class PosBillingController extends ChangeNotifier {
  // --- GLOBAL CONFIG ---
  final String shopName = "Lotus Jewellers";
  final String currentFinancialYear = "2526";
  int nextSequence = 1;

  // --- DATABASE ---
  final AppDatabase _db = AppDatabase();

  // ==========================================
  // CUSTOMER SEARCH FEATURE
  // ==========================================
  List<CustomerListItemModel> customerSuggestions = [];
  bool isSearchingCustomer = false;
  CustomerListItemModel? selectedCustomer;

  Future<void> searchCustomersByName(String query) async {
    final term = query.toLowerCase().trim();
    if (term.length < 2) {
      customerSuggestions = [];
      notifyListeners();
      return;
    }
    try {
      final rows = await (_db.select(_db.customers)
            ..where(
                (tbl) => tbl.name.contains(term) | tbl.mobile.contains(term))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.name)])
            ..limit(8))
          .get();

      customerSuggestions = rows.map((row) {
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
    } catch (e) {
      customerSuggestions = [];
    }
    notifyListeners();
  }

  void selectCustomer(CustomerListItemModel customer) {
    selectedCustomer = customer;
    nameCtrl.text = customer.name;
    mobileCtrl.text = customer.mobile;
    cityCtrl.text = customer.city;
    customerSuggestions = [];
    notifyListeners();
  }

  void clearCustomerSuggestions() {
    customerSuggestions = [];
    notifyListeners();
  }

  // ==========================================
  // ITEM DESCRIPTION SUGGESTIONS FEATURE
  // Per-row: sirf active row mein suggestions dikhti hain
  // ==========================================
  List<String> descriptionSuggestions = [];
  int _descSuggestionRowIndex = -1; // kis row ke liye suggestions hain

  Future<void> searchDescriptions(String query, int rowIndex) async {
    final term = query.toLowerCase().trim();
    if (term.length < 2) {
      descriptionSuggestions = [];
      _descSuggestionRowIndex = -1;
      notifyListeners();
      return;
    }
    try {
      final rows = await (_db.select(_db.stockItems)
            ..where((tbl) =>
                tbl.itemName.contains(term) | tbl.description.contains(term))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.itemName)])
            ..limit(8))
          .get();

      final seen = <String>{};
      descriptionSuggestions =
          rows.map((r) => r.itemName).where((name) => seen.add(name)).toList();
      _descSuggestionRowIndex = rowIndex;
    } catch (e) {
      descriptionSuggestions = [];
      _descSuggestionRowIndex = -1;
    }
    notifyListeners();
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

  String get shopInitials =>
      shopName.split(' ').map((e) => e[0]).join('').toUpperCase();
  String get invoicePrefix => billType == BillType.gst ? "TAX" : "EST";
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

// 1. pos_billing_controller.dart
// In "1. RETAIL ENGINE (B2C)" section, add these 4 new getters just below the total amounts:

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

  double get discountAmount => discountType == DiscountType.percentage
      ? (grossAmount * _discountInput / 100)
      : _discountInput;

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
  double get totalPaid => _cashInput + _upiInput + _cardInput + _advInput;

  double get balanceDue {
    if (billingMode == BillingMode.wholesale) {
      return grandTotal - totalPaid;
    }
    return grandTotal - oldGoldCashDeduction - totalPaid;
  }

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

  // ==========================================
  // 4. HOLD INVOICE SYSTEM LOGIC
  // ==========================================
  final List<PosHoldBillModel> heldBills = [];

  void holdCurrentBill() {
    if (saleItems.isEmpty && oldGoldItems.isEmpty) return;

    final newHold = PosHoldBillModel(
      holdId: DateTime.now().millisecondsSinceEpoch.toString(),
      holdTime: DateTime.now(),
      customerName: nameCtrl.text,
      customerMobile: mobileCtrl.text,
      totalItems: saleItems.length + oldGoldItems.length,
      grandTotal: grandTotal,
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

    heldBills.removeAt(targetBillIndex);
    notifyListeners();
  }

  // --- NEW: CLEAN DELETE FUNCTION FOR UI ---
  void deleteHeldBill(String holdId) {
    heldBills.removeWhere((b) => b.holdId == holdId);
    notifyListeners(); // Now it's safe and legal to notify from here
  }

  void clearEntirePOS({bool isHolding = false}) {
    selectedCustomer = null;
    customerSuggestions = [];
    descriptionSuggestions = [];
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
    clearEntirePOS(isHolding: false);
    _db.close();
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
