// =============================================================================
// FILE        : daily_counter_model.dart
// MODULE      : Dashboard / Daily Counter Activity
// LAYER       : Models
// DESCRIPTION : Data snapshot for today's counter activity.
//
//               4 SECTIONS:
//               1. Metal sold: net weight and pieces on today's invoices,
//                  adjusted for posted sales returns.
//               2. Old metal bought: customer purchase vouchers and trade-ins.
//               3. New due: current balance on today's invoices.
//               4. New girvi: current pledge tickets opened today.
// =============================================================================

/// One metal activity entry containing weight and pieces.
class MetalEntry {
  final String weightStr; // e.g. "15.200 gm"
  final String piecesStr; // e.g. "3 Pcs"
  final double weightRaw; // Used for calculations.
  final int piecesRaw;

  const MetalEntry({
    required this.weightStr,
    required this.piecesStr,
    required this.weightRaw,
    this.piecesRaw = 0,
  });

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
}

/// Finance and due section data.
class FinanceDueData {
  final String dueCount; // e.g. "5 Customers"
  final String dueAmount; // e.g. "₹1,20,000"
  final String girviCount; // e.g. "2 New Loans"
  final String girviAmount; // e.g. "₹50,000"
  final double dueAmountRaw;
  final double girviAmountRaw;
  final String girviCustomerCount;
  final int girviCustomerCountRaw;

  const FinanceDueData({
    required this.dueCount,
    required this.dueAmount,
    required this.girviCount,
    required this.girviAmount,
    required this.dueAmountRaw,
    required this.girviAmountRaw,
    this.girviCustomerCount = '0 Customers',
    this.girviCustomerCountRaw = 0,
  });

  factory FinanceDueData.loading() => const FinanceDueData(
        dueCount: '--',
        dueAmount: '--',
        girviCount: '--',
        girviAmount: '--',
        dueAmountRaw: 0,
        girviAmountRaw: 0,
        girviCustomerCount: '--',
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
}
