class GoldStockCalculationResult {
  final double netWeight;
  final double actualFineWeight;
  final double wastageFineWeight;
  final double valuationFineWeight;
  final double metalCost;
  final double makingAmount;
  final double taxableAmount;
  final double gstAmount;
  final double finalCost;

  const GoldStockCalculationResult({
    required this.netWeight,
    required this.actualFineWeight,
    required this.wastageFineWeight,
    required this.valuationFineWeight,
    required this.metalCost,
    required this.makingAmount,
    required this.taxableAmount,
    required this.gstAmount,
    required this.finalCost,
  });
}
