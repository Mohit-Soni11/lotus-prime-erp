// =============================================================================
// FILE        : inventory_stats_model.dart
// MODULE      : Stock & Inventory
// LAYER       : Models
// DESCRIPTION : Data model for Inventory Ledger summary statistics.
//               Holds opening, closing, and metal-wise breakdown.
// =============================================================================

class InventoryStats {
  // ── Opening Stock (items added before today) ──────────────────
  final int    openingCount;
  final double openingWeight;   // total gross weight in grams
  final double openingValue;    // total MRP value in ₹

  // ── Closing Stock (currently Available) ──────────────────────
  final int    closingCount;
  final double closingWeight;
  final double closingValue;

  // ── Today's movement ─────────────────────────────────────────
  final int todayAdded;    // items added today
  final int todaySold;     // items sold today (status = Sold, updatedAt today)

  // ── Metal Holdings ────────────────────────────────────────────
  final int    goldCount;
  final double goldWeight;
  final double goldValue;

  final int    silverCount;
  final double silverWeight;
  final double silverValue;

  final int    diamondCount;
  final double diamondValue;

  final int    platinumCount;
  final double platinumWeight;

  const InventoryStats({
    required this.openingCount,
    required this.openingWeight,
    required this.openingValue,
    required this.closingCount,
    required this.closingWeight,
    required this.closingValue,
    required this.todayAdded,
    required this.todaySold,
    required this.goldCount,
    required this.goldWeight,
    required this.goldValue,
    required this.silverCount,
    required this.silverWeight,
    required this.silverValue,
    required this.diamondCount,
    required this.diamondValue,
    required this.platinumCount,
    required this.platinumWeight,
  });

  // Convenience: net movement today
  int get netMovement => todayAdded - todaySold;

  bool get hasGold     => goldCount > 0;
  bool get hasSilver   => silverCount > 0;
  bool get hasDiamond  => diamondCount > 0;
  bool get hasPlatinum => platinumCount > 0;

  static InventoryStats empty() => const InventoryStats(
    openingCount: 0,   openingWeight: 0,  openingValue: 0,
    closingCount: 0,   closingWeight: 0,  closingValue: 0,
    todayAdded: 0,     todaySold: 0,
    goldCount: 0,      goldWeight: 0,     goldValue: 0,
    silverCount: 0,    silverWeight: 0,   silverValue: 0,
    diamondCount: 0,   diamondValue: 0,
    platinumCount: 0,  platinumWeight: 0,
  );
}