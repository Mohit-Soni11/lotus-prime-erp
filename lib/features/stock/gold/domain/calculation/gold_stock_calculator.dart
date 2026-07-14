import 'package:lotus_erp/features/stock/gold/domain/calculation/gold_stock_calculation_input.dart';
import 'package:lotus_erp/features/stock/gold/domain/calculation/gold_stock_calculation_result.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';

class GoldStockCalculator {
  const GoldStockCalculator._();

  static GoldStockCalculationResult calculate(GoldStockCalculationInput input) {
    final netWeight = _roundWeight(
        (input.grossWeight - input.lessWeight).clamp(0.0, double.infinity));
    final actualFineWeight =
        _roundWeight(netWeight * (_boundedPercent(input.purityPercent) / 100));
    final wastageFineWeight = _roundWeight(
        netWeight * (input.wastagePercent.clamp(0.0, double.infinity) / 100));
    final valuationFineWeight =
        _roundWeight(actualFineWeight + wastageFineWeight);
    final metalCost = valuationFineWeight * input.ratePerGram;
    final makingAmount = switch (input.makingType) {
      MakingChargesType.perGram => netWeight * input.makingValue,
      MakingChargesType.flat => input.makingValue,
      MakingChargesType.percent => metalCost * input.makingValue / 100,
    };
    final taxableAmount = (metalCost + makingAmount - input.discountAmount)
        .clamp(0.0, double.infinity);
    final gstAmount = taxableAmount * (_boundedPercent(input.gstPercent) / 100);

    return GoldStockCalculationResult(
      netWeight: netWeight,
      actualFineWeight: actualFineWeight,
      wastageFineWeight: wastageFineWeight,
      valuationFineWeight: valuationFineWeight,
      metalCost: metalCost,
      makingAmount: makingAmount,
      taxableAmount: taxableAmount,
      gstAmount: gstAmount,
      finalCost: taxableAmount + gstAmount,
    );
  }

  static double _boundedPercent(double value) {
    return value.clamp(0.0, 100.0).toDouble();
  }

  static double _roundWeight(double value) {
    if (value <= 0) {
      return 0.0;
    }
    return (value * 1000).roundToDouble() / 1000.0;
  }
}
