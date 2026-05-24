// =============================================================================
// FILE        : Gold_overview_logic.dart
// MODULE      : Stock & Inventory — Gold
// LAYER       : Logic / Overview
// DESCRIPTION : Isolated Overview/Stats Logic for Gold Add Stock.
//               ✅ GST toggle — enable / disable 3% on the batch.
//               ✅ All computed totals: pieces, weight, cost, sale, GST.
//               ✅ CGST / SGST split (50–50) for intra-state billing.
//               ✅ Validation error count for the save button guard.
//               ✅ Pure computation — no Flutter dependency, easily testable.
//               ✅ Reads rows by reference — no data duplication.
//
// WHY SEPARATE:
//   Overview stats are derived values — they can change without any change to
//   how rows are managed or how invoices are numbered. Keeping computation in
//   its own class means:
//     • You can unit-test totals independently.
//     • Changing GST rate from 3% to any other rate = one-line change here.
//     • Adding new stats (e.g. average rate, purity-wise split) = add here only.
//
// USAGE:
//   final overview = GoldOverviewLogic();
//   overview.toggleGst(true);
//   double total = overview.computeTotalBatchAmount(rows);
// =============================================================================

import 'gold_row_entry.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Gold OVERVIEW LOGIC
// ─────────────────────────────────────────────────────────────────────────────
class GoldOverviewLogic {
  // ── GST STATE ────────────────────────────────────────────────
  bool _gstEnabled = false;
  bool get gstEnabled => _gstEnabled;

  /// Default GST rate for Gold jewellery (3% as per Indian GST HSN 7113/7114).
  double gstRate = 3.0;

  // ─────────────────────────────────────────────────────────────
  // GST TOGGLE
  // ─────────────────────────────────────────────────────────────

  /// Enables or disables GST for this batch.
  /// Also syncs gstRate onto every existing row so per-row amounts stay live.
  /// Always call notifyListeners() on the parent controller after this.
  void toggleGst(bool value, List<GoldRowEntry> rows) {
    _gstEnabled = value;
    for (final row in rows) {
      row.gstRate = value ? gstRate : 0.0;
    }
  }

  /// Resets GST to off — called during batch reset.
  void resetGst() {
    _gstEnabled = false;
    gstRate = 3.0;
  }

  // ─────────────────────────────────────────────────────────────
  // ROW-LEVEL COMPUTATIONS
  // ─────────────────────────────────────────────────────────────

  /// Taxable subtotal for one row = metalCost + makingAmount.
  /// Stone value is included in costPrice but excluded from GST base
  /// unless specified — currently uses full costPrice as taxable.
  double rowSubtotal(GoldRowEntry row) => row.costPrice;

  /// GST amount for one row.
  double rowGstAmount(GoldRowEntry row) {
    if (!_gstEnabled) return 0.0;
    final appliedRate = row.gstRate > 0 ? row.gstRate : gstRate;
    return rowSubtotal(row) * (appliedRate / 100.0);
  }

  /// Grand total for one row including GST.
  double rowTotalAmount(GoldRowEntry row) =>
      rowSubtotal(row) + rowGstAmount(row);

  // ─────────────────────────────────────────────────────────────
  // BATCH-LEVEL TOTALS
  // These compute across all entered rows (rows with hasAnyInput == true).
  // ─────────────────────────────────────────────────────────────

  /// Total pieces across all entered rows (quantity × rows).
  int totalQuantity(List<GoldRowEntry> enteredRows) =>
      enteredRows.fold(0, (sum, row) => sum + row.quantity);

  /// Total gross weight across all entered rows.
  double totalGrossWeight(List<GoldRowEntry> enteredRows) =>
      enteredRows.fold(0.0, (sum, row) => sum + row.grossWeight * row.quantity);

  /// Total net weight (after less/stone deductions) across all entered rows.
  double totalNetWeight(List<GoldRowEntry> enteredRows) =>
      enteredRows.fold(0.0, (sum, row) => sum + row.netWeight * row.quantity);

  /// Total estimated cost value across all entered rows.
  double totalEstimatedCost(List<GoldRowEntry> enteredRows) =>
      enteredRows.fold(0.0, (sum, row) => sum + row.totalCostValue);

  /// Total estimated selling value across all entered rows.
  double totalEstimatedSelling(List<GoldRowEntry> enteredRows) =>
      enteredRows.fold(0.0, (sum, row) => sum + row.totalSellingValue);

  /// Total taxable amount (pre-GST subtotal) across all entered rows.
  double totalTaxableAmount(List<GoldRowEntry> enteredRows) =>
      enteredRows.fold(0.0, (sum, row) => sum + rowSubtotal(row));

  /// Total GST amount across all entered rows.
  double totalGstAmount(List<GoldRowEntry> enteredRows) {
    if (!_gstEnabled) return 0.0;
    return enteredRows.fold(0.0, (sum, row) => sum + rowGstAmount(row));
  }

  /// CGST = 50% of total GST (intra-state split).
  double cgstAmount(List<GoldRowEntry> enteredRows) =>
      totalGstAmount(enteredRows) / 2.0;

  /// SGST = 50% of total GST (intra-state split).
  double sgstAmount(List<GoldRowEntry> enteredRows) =>
      totalGstAmount(enteredRows) / 2.0;

  /// Grand total payable = taxable amount + GST.
  double totalBatchAmount(List<GoldRowEntry> enteredRows) =>
      totalTaxableAmount(enteredRows) + totalGstAmount(enteredRows);

  // ─────────────────────────────────────────────────────────────
  // VALIDATION SUMMARY
  // ─────────────────────────────────────────────────────────────

  /// Count of entered rows that have validation errors.
  /// Used to show error badge on the Save button.
  int rowsWithErrorsCount(
    List<GoldRowEntry> enteredRows,
    String? Function(GoldRowEntry) validateRow,
  ) =>
      enteredRows.where((row) => validateRow(row) != null).length;

  // ─────────────────────────────────────────────────────────────
  // STATS SNAPSHOT (for GoldBatchOverviewCard)
  // ─────────────────────────────────────────────────────────────

  /// Returns a ready-to-display stats map for the overview card.
  /// All values are pre-formatted strings — card just renders them.
  GoldBatchStats buildStats(List<GoldRowEntry> enteredRows) {
    return GoldBatchStats(
      pieces: totalQuantity(enteredRows),
      grossWeightGrams: totalGrossWeight(enteredRows),
      netWeightGrams: totalNetWeight(enteredRows),
      estimatedCost: totalEstimatedCost(enteredRows),
      estimatedSelling: totalEstimatedSelling(enteredRows),
      taxableAmount: totalTaxableAmount(enteredRows),
      gstAmount: totalGstAmount(enteredRows),
      cgstAmount: cgstAmount(enteredRows),
      sgstAmount: sgstAmount(enteredRows),
      grandTotal: totalBatchAmount(enteredRows),
      gstEnabled: _gstEnabled,
      gstRate: gstRate,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gold BATCH STATS  (immutable snapshot — passed to UI widgets)
// ─────────────────────────────────────────────────────────────────────────────
class GoldBatchStats {
  final int pieces;
  final double grossWeightGrams;
  final double netWeightGrams;
  final double estimatedCost;
  final double estimatedSelling;
  final double taxableAmount;
  final double gstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double grandTotal;
  final bool gstEnabled;
  final double gstRate;

  const GoldBatchStats({
    required this.pieces,
    required this.grossWeightGrams,
    required this.netWeightGrams,
    required this.estimatedCost,
    required this.estimatedSelling,
    required this.taxableAmount,
    required this.gstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.grandTotal,
    required this.gstEnabled,
    required this.gstRate,
  });

  // ── FORMATTED DISPLAY HELPERS ─────────────────────────────────
  String get piecesDisplay => pieces.toString();
  String get grossWeightDisplay => '${grossWeightGrams.toStringAsFixed(3)} g';
  String get netWeightDisplay => '${netWeightGrams.toStringAsFixed(3)} g';
  String get estimatedCostDisplay => '₹ ${estimatedCost.toStringAsFixed(2)}';
  String get estimatedSellingDisplay =>
      '₹ ${estimatedSelling.toStringAsFixed(2)}';
  String get taxableAmountDisplay => '₹ ${taxableAmount.toStringAsFixed(2)}';
  String get gstAmountDisplay => '₹ ${gstAmount.toStringAsFixed(2)}';
  String get cgstDisplay => '₹ ${cgstAmount.toStringAsFixed(2)}';
  String get sgstDisplay => '₹ ${sgstAmount.toStringAsFixed(2)}';
  String get grandTotalDisplay => '₹ ${grandTotal.toStringAsFixed(2)}';
  String get gstRateDisplay => '${gstRate.toStringAsFixed(0)}%';
}
