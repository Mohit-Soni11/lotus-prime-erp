// =============================================================================
// FILE        : purchase_entry_controller.dart
// MODULE      : Purchase Entry
// LAYER       : Logic / Controller
// DESCRIPTION : Master controller for Purchase Entry screen.
//               ChangeNotifier-based zero-lag state management.
//               Handles items, payments, invoice number, DB save.
// =============================================================================

import 'package:flutter/material.dart';
import '../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../models/purchase/purchase_entry/purchase_item_model.dart';

// ── DB imports (Drift) ───────────────────────────────────────────────────────
import 'package:lotus_erp/database/db/app_database.dart';

import 'package:drift/drift.dart' as drift;

class PurchaseEntryController extends ChangeNotifier {
  PurchaseEntryController() {
    _init();
    _addPaymentListeners();
  }

  // ── Source & Tax ────────────────────────────────────────────────────────────
  PurchaseSource purchaseSource = PurchaseSource.fromCustomer;
  PurchaseTaxType taxType = PurchaseTaxType.normal; // No GST by default

  // ── Customer / Supplier Fields ──────────────────────────────────────────────
  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController panCtrl = TextEditingController();
  final TextEditingController gstCtrl = TextEditingController();

  // ── Purchase Items ──────────────────────────────────────────────────────────
  final List<PurchaseItemModel> items = [];

  // ── Payment Controllers ─────────────────────────────────────────────────────
  final TextEditingController cashCtrl = TextEditingController();
  final TextEditingController upiCtrl = TextEditingController();
  final TextEditingController cardCtrl = TextEditingController();

  // ── Discount ────────────────────────────────────────────────────────────────
  PurchaseDiscountType discountType = PurchaseDiscountType.flatAmount;
  final TextEditingController discountCtrl = TextEditingController();

  // ── Invoice ─────────────────────────────────────────────────────────────────
  int _purchaseNo = 1;
  String get formattedPurchaseNo =>
      'PUR-${DateTime.now().year}-${_purchaseNo.toString().padLeft(4, '0')}';

  // ── Shop Name ────────────────────────────────────────────────────────────────
  String shopName = 'Lotus Prime';

  // ── Scroll ──────────────────────────────────────────────────────────────────
  final ScrollController tableScrollCtrl = ScrollController();

  // ── Init ────────────────────────────────────────────────────────────────────
  void _init() {
    addItem(); // Start with one empty row
  }

  void _addPaymentListeners() {
    cashCtrl.addListener(_notify);
    upiCtrl.addListener(_notify);
    cardCtrl.addListener(_notify);
    discountCtrl.addListener(_notify);
  }

  void _notify() => notifyListeners();

  // ── Source Toggle ────────────────────────────────────────────────────────────
  void toggleSource(PurchaseSource source) {
    purchaseSource = source;
    // When switching to supplier, allow GST; when customer, default to normal
    if (source == PurchaseSource.fromCustomer) {
      taxType = PurchaseTaxType.normal;
    }
    notifyListeners();
  }

  // ── Tax Toggle ──────────────────────────────────────────────────────────────
  void toggleTaxType(PurchaseTaxType type) {
    taxType = type;
    notifyListeners();
  }

  // ── Discount Toggle ──────────────────────────────────────────────────────────
  void toggleDiscountType(PurchaseDiscountType type) {
    discountType = type;
    notifyListeners();
  }

  // ── Items CRUD ───────────────────────────────────────────────────────────────
  void addItem() {
    final item = PurchaseItemModel();
    item.addListener(_notify);
    items.add(item);
    notifyListeners();

    // Auto-scroll to new row
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tableScrollCtrl.hasClients) {
        tableScrollCtrl.animateTo(
          tableScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void removeItem(int index) {
    if (index < 0 || index >= items.length) return;
    final item = items.removeAt(index);
    item.removeListener(_notify);
    item.dispose();
    notifyListeners();
  }

  // ── Computed: Totals by metal ─────────────────────────────────────────────
  double get totalGoldValue => _sumByMetal(PurchaseMetalType.gold);
  double get totalSilverValue => _sumByMetal(PurchaseMetalType.silver);
  double get totalPlatinumValue => _sumByMetal(PurchaseMetalType.platinum);
  double get totalDiamondValue => _sumByMetal(PurchaseMetalType.diamond);

  double get totalGoldFine => _fineByMetal(PurchaseMetalType.gold);
  double get totalSilverFine => _fineByMetal(PurchaseMetalType.silver);
  double get totalPlatinumFine => _fineByMetal(PurchaseMetalType.platinum);
  double get totalDiamondFine => _fineByMetal(PurchaseMetalType.diamond);

  double _sumByMetal(PurchaseMetalType m) =>
      items.where((i) => i.metal == m).fold(0.0, (s, i) => s + i.totalValue);

  double _fineByMetal(PurchaseMetalType m) =>
      items.where((i) => i.metal == m).fold(0.0, (s, i) => s + i.fineWt);

  double get grossPurchaseAmount => items.fold(0.0, (s, i) => s + i.totalValue);

  double get discountAmount {
    final raw = double.tryParse(discountCtrl.text) ?? 0.0;
    if (discountType == PurchaseDiscountType.percentage) {
      return grossPurchaseAmount * raw / 100.0;
    }
    return raw;
  }

  double get taxableAmount => grossPurchaseAmount - discountAmount;

  // GST on purchase (3% for jewellery)
  double get totalGst =>
      taxType == PurchaseTaxType.gst ? taxableAmount * 0.03 : 0.0;
  double get cgst => totalGst / 2.0;
  double get sgst => totalGst / 2.0;

  double get grandTotal => taxableAmount + totalGst;

  // ── Payments ──────────────────────────────────────────────────────────────
  double get cashPaid => double.tryParse(cashCtrl.text) ?? 0.0;
  double get upiPaid => double.tryParse(upiCtrl.text) ?? 0.0;
  double get cardPaid => double.tryParse(cardCtrl.text) ?? 0.0;
  double get totalPaid => cashPaid + upiPaid + cardPaid;

  /// Positive = still have to pay seller | Negative = overpaid (take change)
  double get balanceDue => grandTotal - totalPaid;

  // ── Save to DB ───────────────────────────────────────────────────────────
  Future<bool> savePurchase() async {
    try {
      final db = AppDatabase();
      final validItems =
          items.where((item) => item.netWt > 0 && item.rate > 0).toList();
      if (validItems.isEmpty) return false;

      final batchTimestamp = DateTime.now().millisecondsSinceEpoch;
      final counterpartName = nameCtrl.text.trim().isNotEmpty
          ? nameCtrl.text.trim()
          : purchaseSource == PurchaseSource.fromSupplier
              ? 'Unassigned Supplier'
              : 'Walk-in Seller';

      await db.transaction(() async {
        for (int index = 0; index < validItems.length; index++) {
          final item = validItems[index];
          final sku =
              'PUR-${item.metal.name.toUpperCase()}-$batchTimestamp-${index + 1}';

          await db.into(db.stockItems).insert(
                StockItemsCompanion(
                  sku: drift.Value(sku),
                  itemName: drift.Value(item.descCtrl.text.isNotEmpty
                      ? item.descCtrl.text
                      : '${item.metal.displayName} Purchase'),
                  category: drift.Value(item.metal.displayName),
                  subCategory: drift.Value('Purchase Inward'),
                  metalType: drift.Value(item.metal.displayName),
                  purity: drift.Value(item.purityCtrl.text),
                  grossWeight: drift.Value(item.grossWt),
                  stoneWeight: drift.Value(item.lessWt),
                  netWeight: drift.Value(item.netWt),
                  purchasePrice: drift.Value(item.totalValue),
                  supplierName: drift.Value(counterpartName),
                  quantity: const drift.Value(1),
                  status: drift.Value('Available'),
                ),
              );
        }
      });

      _purchaseNo++;
      _resetForm();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Purchase Save Error: $e');
      return false;
    }
  }

  void _resetForm() {
    for (final item in items) {
      item.removeListener(_notify);
      item.dispose();
    }
    items.clear();
    mobileCtrl.clear();
    nameCtrl.clear();
    cityCtrl.clear();
    panCtrl.clear();
    gstCtrl.clear();
    cashCtrl.clear();
    upiCtrl.clear();
    cardCtrl.clear();
    discountCtrl.clear();
    addItem();
  }

  @override
  void dispose() {
    for (final item in items) {
      item.dispose();
    }
    mobileCtrl.dispose();
    nameCtrl.dispose();
    cityCtrl.dispose();
    panCtrl.dispose();
    gstCtrl.dispose();
    cashCtrl.dispose();
    upiCtrl.dispose();
    cardCtrl.dispose();
    discountCtrl.dispose();
    tableScrollCtrl.dispose();
    super.dispose();
  }
}
