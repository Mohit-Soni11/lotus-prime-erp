/// One posted Add Stock voucher, summarized without duplicating its item list.
class DayBookStockAddedBatch {
  const DayBookStockAddedBatch({
    required this.voucherId,
    required this.batchCode,
    required this.metal,
    required this.postedAt,
    required this.pieces,
    required this.netWeightGrams,
    required this.purchaseValue,
    this.ratePerGram,
    this.hasMixedRates = false,
    this.makingTotal,
  });

  final int voucherId;
  final String batchCode;
  final String metal;
  final DateTime postedAt;
  final int pieces;
  final double netWeightGrams;
  final double? ratePerGram;
  final bool hasMixedRates;
  final double? makingTotal;
  final double purchaseValue;

  bool get canOpenInventory =>
      batchCode.trim().isNotEmpty &&
      (metal.toLowerCase() == 'gold' || metal.toLowerCase() == 'silver');
}
