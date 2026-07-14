import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';

class GoldStockCalculationInput {
  final double grossWeight;
  final double lessWeight;
  final double purityPercent;
  final double wastagePercent;
  final double ratePerGram;
  final MakingChargesType makingType;
  final double makingValue;
  final double gstPercent;
  final double discountAmount;

  const GoldStockCalculationInput({
    required this.grossWeight,
    required this.lessWeight,
    required this.purityPercent,
    required this.wastagePercent,
    required this.ratePerGram,
    required this.makingType,
    required this.makingValue,
    this.gstPercent = 0,
    this.discountAmount = 0,
  });
}
