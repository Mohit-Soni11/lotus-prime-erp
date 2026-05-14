// =============================================================================
// FILE        : silver_item_model.dart
// MODULE      : Stock & Inventory — Silver
// LAYER       : Logic / Data Model
// DESCRIPTION : Self-contained row model for Silver Invoice Items table.
//               ✅ EXACT same pattern as SaleItemModel in POS.
//               ✅ TextEditingControllers + FocusNodes LIVE INSIDE this model.
//               ✅ No sync required — computed values derive directly from
//                  controller text, so UI and model are always in sync.
//               ✅ ChangeNotifier so rows can be individually listened to.
//               ✅ Computed: netWeight, metalCost, makingAmount, totalAmount.
//               ✅ Making charge type toggle: /g → Flat → %.
//               ✅ hasAnyInput guard for dirty-check (save validation).
//               ✅ disposeAll() releases every controller + focus node.
//
// WHY NOT USE StockRowEntry:
//   StockRowEntry has no controllers or focus nodes. The old SilverItemRow
//   created them locally in State, which caused sync bugs and broke delete.
//   This model owns its own widgets — zero sync needed.
//
// USAGE (in SilverStockController):
//   final model = SilverItemModel(id: uniqueId);
//   model.addListener(notifyListeners); // bubble up for totals
//   _silverRows.add(model);
//
// USAGE (in SilverItemRow):
//   TextField(controller: model.grossCtrl, focusNode: model.grossFocus, ...)
//   Text('${model.netWeight.toStringAsFixed(3)} g')
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

class SilverItemModel extends ChangeNotifier {
  // ── IDENTITY ─────────────────────────────────────────────────
  final String id;

  // ── TEXT CONTROLLERS (owned by model, not by widget state) ───
  final TextEditingController itemNameCtrl = TextEditingController();
  final TextEditingController huidCtrl = TextEditingController();
  final TextEditingController grossCtrl = TextEditingController();
  final TextEditingController lessCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();
  final TextEditingController makingCtrl = TextEditingController();

  // ── FOCUS NODES (owned by model, not by widget state) ────────
  final FocusNode itemNameFocus = FocusNode();
  final FocusNode huidFocus = FocusNode();
  final FocusNode grossFocus = FocusNode();
  final FocusNode lessFocus = FocusNode();
  final FocusNode rateFocus = FocusNode();
  final FocusNode makingFocus = FocusNode();

  // ── MAKING CHARGE TYPE ───────────────────────────────────────
  MakingChargesType makingChargesType = MakingChargesType.perGram;

  // ─────────────────────────────────────────────────────────────
  // CONSTRUCTOR
  // ─────────────────────────────────────────────────────────────

  SilverItemModel({required this.id}) {
    // Wire auto-recalculation on every field change.
    // Same as POS SaleItemModel — no setState needed in the row widget.
    grossCtrl.addListener(notifyListeners);
    lessCtrl.addListener(notifyListeners);
    rateCtrl.addListener(notifyListeners);
    makingCtrl.addListener(notifyListeners);
    itemNameCtrl.addListener(notifyListeners);
  }

  // ─────────────────────────────────────────────────────────────
  // COMPUTED WEIGHT FIELDS
  // ─────────────────────────────────────────────────────────────

  double get grossWeight => double.tryParse(grossCtrl.text) ?? 0.0;
  double get lessWeight => double.tryParse(lessCtrl.text) ?? 0.0;

  /// Net weight = gross − less, clamped to zero.
  double get netWeight =>
      (grossWeight - lessWeight).clamp(0.0, double.infinity);

  // ─────────────────────────────────────────────────────────────
  // COMPUTED PRICE FIELDS
  // ─────────────────────────────────────────────────────────────

  double get purchaseRate => double.tryParse(rateCtrl.text) ?? 0.0;
  double get makingValue => double.tryParse(makingCtrl.text) ?? 0.0;

  /// Metal cost = netWeight × rate per gram.
  double get metalCost => netWeight * purchaseRate;

  /// Making charge — computed based on current makingChargesType.
  double get makingAmount {
    return switch (makingChargesType) {
      MakingChargesType.perGram => netWeight * makingValue,
      MakingChargesType.flat => makingValue,
      MakingChargesType.percent => metalCost * makingValue / 100.0,
    };
  }

  /// Total = metalCost + makingAmount.
  /// This is the line-total for one row (single piece, qty=1 for silver stock entry).
  double get totalAmount => metalCost + makingAmount;

  // ─────────────────────────────────────────────────────────────
  // IDENTITY GETTERS (trimmed & normalised)
  // ─────────────────────────────────────────────────────────────

  String get itemName => itemNameCtrl.text.trim();
  String get huid => huidCtrl.text.trim().toUpperCase();

  // ─────────────────────────────────────────────────────────────
  // DIRTY CHECK
  // ─────────────────────────────────────────────────────────────

  /// True if the operator has entered anything in this row.
  /// Empty rows are placeholder rows — not saved, not validated.
  bool get hasAnyInput =>
      itemName.isNotEmpty ||
      huid.isNotEmpty ||
      grossWeight > 0 ||
      lessWeight > 0 ||
      purchaseRate > 0 ||
      makingValue > 0;

  // ─────────────────────────────────────────────────────────────
  // MAKING CHARGE TYPE TOGGLE (/g → Flat → % → /g)
  // ─────────────────────────────────────────────────────────────

  void toggleMakingType() {
    makingChargesType = switch (makingChargesType) {
      MakingChargesType.perGram => MakingChargesType.flat,
      MakingChargesType.flat => MakingChargesType.percent,
      MakingChargesType.percent => MakingChargesType.perGram,
    };
    notifyListeners();
  }

  /// Short symbol displayed on the toggle button.
  String get makingTypeSymbol {
    return switch (makingChargesType) {
      MakingChargesType.perGram => '/g',
      MakingChargesType.flat => 'Flat',
      MakingChargesType.percent => '%',
    };
  }

  /// Placeholder hint inside the making charge text field.
  String get makingHint {
    return switch (makingChargesType) {
      MakingChargesType.perGram => 'Rate/g',
      MakingChargesType.flat => 'Flat Amt',
      MakingChargesType.percent => 'Rate %',
    };
  }

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE — must call disposeAll() when the row is removed
  // ─────────────────────────────────────────────────────────────

  /// Disposes all controllers, focus nodes, and the ChangeNotifier itself.
  /// Call this from SilverStockController.removeRow() after unlinking the listener.
  void disposeAll() {
    // Controllers
    grossCtrl.removeListener(notifyListeners);
    lessCtrl.removeListener(notifyListeners);
    rateCtrl.removeListener(notifyListeners);
    makingCtrl.removeListener(notifyListeners);
    itemNameCtrl.removeListener(notifyListeners);

    itemNameCtrl.dispose();
    huidCtrl.dispose();
    grossCtrl.dispose();
    lessCtrl.dispose();
    rateCtrl.dispose();
    makingCtrl.dispose();

    // Focus nodes
    itemNameFocus.dispose();
    huidFocus.dispose();
    grossFocus.dispose();
    lessFocus.dispose();
    rateFocus.dispose();
    makingFocus.dispose();

    // ChangeNotifier
    dispose();
  }
}
