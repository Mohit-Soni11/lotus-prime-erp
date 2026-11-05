import 'day_book_stock_movement.dart';

class DayBookOwnedMetalPosition {
  const DayBookOwnedMetalPosition({
    required this.openingGrams,
    required this.inwardGrams,
    required this.soldGrams,
    required this.otherOutGrams,
    required this.closingGrams,
    required this.isConsistent,
  });

  final double openingGrams;
  final double inwardGrams;
  final double soldGrams;
  final double otherOutGrams;
  final double closingGrams;
  final bool isConsistent;

  static DayBookOwnedMetalPosition fromMovements({
    required String metal,
    required double currentAvailableGrams,
    required double movementAfterDayGrams,
    required List<DayBookStockMovement> dayMovements,
  }) {
    final matching = dayMovements
        .where((row) => row.metal.trim().toLowerCase() == metal.toLowerCase());
    final dayNet = matching.fold<double>(
        0, (sum, movement) => sum + movement.netWeightDelta);
    final closing = currentAvailableGrams - movementAfterDayGrams;
    final opening = closing - dayNet;
    final inward = matching
        .where((row) => row.netWeightDelta > 0)
        .fold<double>(0, (sum, row) => sum + row.netWeightDelta);
    final sold = matching
        .where((row) =>
            row.movementType.toUpperCase() == 'SALE' && row.netWeightDelta < 0)
        .fold<double>(0, (sum, row) => sum - row.netWeightDelta);
    final otherOut = matching
        .where((row) =>
            row.netWeightDelta < 0 && row.movementType.toUpperCase() != 'SALE')
        .fold<double>(0, (sum, row) => sum - row.netWeightDelta);
    return DayBookOwnedMetalPosition(
      openingGrams: opening,
      inwardGrams: inward,
      soldGrams: sold,
      otherOutGrams: otherOut,
      closingGrams: closing,
      isConsistent: opening >= -0.001 && closing >= -0.001,
    );
  }
}

class DayBookOwnedStockPosition {
  const DayBookOwnedStockPosition({required this.gold, required this.silver});

  final DayBookOwnedMetalPosition gold;
  final DayBookOwnedMetalPosition silver;
}
