// =============================================================================
// FILE        : daily_counter_model.dart
// MODULE      : Dashboard / Daily Counter Activity
// LAYER       : Models
// DESCRIPTION : Data snapshot for today's counter activity.
//
//               4 SECTIONS:
//               1. Metal Sold   — Today's gold/silver gross weight from BillItems.
//               2. Metal Bought — customer-received metal and sales returns
//               3. New Due      — Today's bills where paidAmount is below finalAmount.
//               4. New Pledge   — Pledge loans created today.
// =============================================================================

/// One metal activity entry containing weight and pieces.
class MetalEntry {
  final String weightStr; // e.g. "15.200 gm"
  final String piecesStr; // e.g. "3 Pcs"
  final double weightRaw; // Used for calculations.

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

/// Metal movement section data.
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
        soldGold: MetalEntry.loading(),
        soldSilver: MetalEntry.loading(),
        boughtGold: MetalEntry.loading(),
        boughtSilver: MetalEntry.loading(),
      );

  factory MetalMovementData.zero() => MetalMovementData(
        soldGold: MetalEntry.zero(),
        soldSilver: MetalEntry.zero(),
        boughtGold: MetalEntry.zero(),
        boughtSilver: MetalEntry.zero(),
      );
}

/// Finance and due section data.
class FinanceDueData {
  final String dueCount; // e.g. "5 Customers"
  final String dueAmount; // e.g. "₹1,20,000"
  final String girviCount; // e.g. "2 New Loans"
  final String girviAmount; // e.g. "₹50,000"
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

/// Complete daily counter card model.
class DailyCounterModel {
  final String dateStr;
  final MetalMovementData metalMovement;
  final FinanceDueData financeDue;
  final bool isLoading;

  const DailyCounterModel({
    required this.dateStr,
    required this.metalMovement,
    required this.financeDue,
    this.isLoading = false,
  });

  factory DailyCounterModel.loading() => DailyCounterModel(
        dateStr: '--',
        metalMovement: MetalMovementData.loading(),
        financeDue: FinanceDueData.loading(),
        isLoading: true,
      );

  factory DailyCounterModel.empty(String dateStr) => DailyCounterModel(
        dateStr: dateStr,
        metalMovement: MetalMovementData.zero(),
        financeDue: FinanceDueData.zero(),
      );
}
