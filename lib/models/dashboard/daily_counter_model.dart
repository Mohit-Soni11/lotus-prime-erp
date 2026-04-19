// =============================================================================
// FILE        : daily_counter_model.dart
// MODULE      : Dashboard / Daily Counter Activity
// LAYER       : Models
// DESCRIPTION : Aaj ke poore counter activity ka data snapshot.
//
//               4 SECTIONS:
//               1. Metal Sold   — BillItems se aaj ke gold/silver gross weight
//               2. Metal Bought — StockItems se aaj add kiye items (purchased)
//               3. New Due      — Bills jinka paidAmount < finalAmount (aaj)
//               4. New Girvi    — Loans aaj create kiye
// =============================================================================

/// Metal ka ek entry — weight + pieces
class MetalEntry {
  final String weightStr; // e.g. "15.200 gm"
  final String piecesStr; // e.g. "3 Pcs"
  final double weightRaw; // Calculation ke liye

  const MetalEntry({
    required this.weightStr,
    required this.piecesStr,
    required this.weightRaw,
  });

  factory MetalEntry.zero() => const MetalEntry(
    weightStr: '0.000 gm',
    piecesStr: '0 Pcs',
    weightRaw: 0.0,
  );

  factory MetalEntry.loading() => const MetalEntry(
    weightStr: '--',
    piecesStr: '--',
    weightRaw: 0.0,
  );
}

/// Metal Movement section ka data
class MetalMovementData {
  final MetalEntry soldGold;
  final MetalEntry soldSilver;
  final MetalEntry boughtGold;
  final MetalEntry boughtSilver;

  const MetalMovementData({
    required this.soldGold,
    required this.soldSilver,
    required this.boughtGold,
    required this.boughtSilver,
  });

  factory MetalMovementData.loading() => MetalMovementData(
    soldGold:    MetalEntry.loading(),
    soldSilver:  MetalEntry.loading(),
    boughtGold:  MetalEntry.loading(),
    boughtSilver:MetalEntry.loading(),
  );

  factory MetalMovementData.zero() => MetalMovementData(
    soldGold:    MetalEntry.zero(),
    soldSilver:  MetalEntry.zero(),
    boughtGold:  MetalEntry.zero(),
    boughtSilver:MetalEntry.zero(),
  );
}

/// Finance & Due section ka data
class FinanceDueData {
  final String dueCount;      // e.g. "5 Customers"
  final String dueAmount;     // e.g. "₹1,20,000"
  final String girviCount;    // e.g. "2 New Loans"
  final String girviAmount;   // e.g. "₹50,000"
  final double dueAmountRaw;
  final double girviAmountRaw;

  const FinanceDueData({
    required this.dueCount,
    required this.dueAmount,
    required this.girviCount,
    required this.girviAmount,
    required this.dueAmountRaw,
    required this.girviAmountRaw,
  });

  factory FinanceDueData.loading() => const FinanceDueData(
    dueCount: '--',
    dueAmount: '--',
    girviCount: '--',
    girviAmount: '--',
    dueAmountRaw: 0,
    girviAmountRaw: 0,
  );

  factory FinanceDueData.zero() => const FinanceDueData(
    dueCount: '0 Customers',
    dueAmount: '₹0',
    girviCount: '0 Loans',
    girviAmount: '₹0',
    dueAmountRaw: 0,
    girviAmountRaw: 0,
  );
}

/// Complete Daily Counter Card ka model
class DailyCounterModel {
  final String            dateStr;
  final MetalMovementData metalMovement;
  final FinanceDueData    financeDue;
  final bool              isLoading;

  const DailyCounterModel({
    required this.dateStr,
    required this.metalMovement,
    required this.financeDue,
    this.isLoading = false,
  });

  factory DailyCounterModel.loading() => DailyCounterModel(
    dateStr:       '--',
    metalMovement: MetalMovementData.loading(),
    financeDue:    FinanceDueData.loading(),
    isLoading:     true,
  );

  factory DailyCounterModel.empty(String dateStr) => DailyCounterModel(
    dateStr:       dateStr,
    metalMovement: MetalMovementData.zero(),
    financeDue:    FinanceDueData.zero(),
  );
}