// =============================================================================
// FILE        : Gold_row_entry.dart
// MODULE      : Stock & Inventory — Gold
// LAYER       : Logic / Data Model
// DESCRIPTION : Isolated data model for a single Gold stock entry row.
//               ✅ 100% Gold-specific — no Gold touch/fine-weight fields.
//               ✅ Pure Dart class — no Flutter dependency.
//               ✅ Future-proof: extend with Gold-specific fields freely
//                  without touching Gold/Platinum/Diamond models.
//
// WHY SEPARATE FROM StockRowEntry:
//   Gold needs touch%, fineWeight, 24K rate snapshot, hallmark validation.
//   Gold needs purchaseRate per gram, NO karat math, higher qty tolerance.
//   Keeping them separate = zero cross-contamination, safe independent change.
// =============================================================================

import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Gold ROW ENTRY
// One row in the Gold stock intake table.
// ─────────────────────────────────────────────────────────────────────────────
class GoldRowEntry {
  /// Unique row identifier — microsecond timestamp string.
  final String id;

  // ── IDENTITY ─────────────────────────────────────────────────
  String itemName = '';
  String description = '';
  StockSubCategory subCategory = StockSubCategory.ring;

  // ── COMPLIANCE ───────────────────────────────────────────────
  /// HUID is optional for Gold but field is present for future BIS compliance.
  String huid = '';
  String hsnCode;

  // ── WEIGHTS ──────────────────────────────────────────────────
  double grossWeight = 0.0;

  /// Less weight = stone/setting deduction from gross.
  double lessWeight = 0.0;

  // ── STONE ────────────────────────────────────────────────────
  StoneType stoneType = StoneType.none;
  double stoneCarats = 0.0;
  int stonePieces = 0;
  double stoneValue = 0.0;

  // ── PRICING ──────────────────────────────────────────────────
  /// Purchase rate per gram in INR — operator-entered, not rate-snapshot driven.
  double purchaseRatePerGram = 0.0;
  double makingCharges = 0.0;
  MakingChargesType makingChargesType = MakingChargesType.perGram;
  double mrp = 0.0;
  double gstRate = 3.0;

  // ── INVENTORY ────────────────────────────────────────────────
  int quantity = 1;
  String location = '';

  // ── SUPPLIER (per-row override when sameForAll = false) ──────
  int? supplierId;
  String supplierName = '';

  GoldRowEntry({
    required this.id,
    required this.hsnCode,
  });

  // ── COMPUTED WEIGHTS ─────────────────────────────────────────

  /// Net weight after deducting stone/setting weight.
  double get netWeight =>
      (grossWeight - lessWeight).clamp(0.0, double.infinity);

  // ── COMPUTED PRICING ─────────────────────────────────────────

  /// Metal cost = net weight × purchase rate per gram.
  double get metalCost => netWeight * purchaseRatePerGram;

  /// Making / labour amount based on type.
  double get makingAmount {
    return switch (makingChargesType) {
      MakingChargesType.perGram => netWeight * makingCharges,
      MakingChargesType.flat => makingCharges,
      MakingChargesType.percent => metalCost * makingCharges / 100.0,
    };
  }

  /// Total cost price (metal + stone + making) for ONE piece.
  double get costPrice => metalCost + stoneValue + makingAmount;

  /// Total cost value for all quantity.
  double get totalCostValue => costPrice * quantity;

  /// Total selling value — uses MRP if set, else falls back to cost price.
  double get totalSellingValue => (mrp > 0 ? mrp : costPrice) * quantity;

  // ── DIRTY CHECK ──────────────────────────────────────────────

  /// Returns true if the operator has entered anything in this row.
  /// Used to distinguish empty placeholder rows from actual entries.
  bool get hasAnyInput {
    return itemName.trim().isNotEmpty ||
        description.trim().isNotEmpty ||
        huid.trim().isNotEmpty ||
        grossWeight > 0 ||
        lessWeight > 0 ||
        stoneValue > 0 ||
        stoneCarats > 0 ||
        stonePieces > 0 ||
        purchaseRatePerGram > 0 ||
        makingCharges > 0 ||
        mrp > 0 ||
        quantity != 1 ||
        location.trim().isNotEmpty ||
        supplierName.trim().isNotEmpty;
  }
}
