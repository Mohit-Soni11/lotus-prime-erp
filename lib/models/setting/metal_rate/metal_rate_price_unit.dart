import 'metal_rate_model.dart';

/// Rates are persisted in the market unit: silver per kg, gold/platinum per
/// 10g and diamond per carat. Billing uses grams for metals and carats for
/// diamonds; stock costing uses a per-100g rate.
class MetalRatePriceUnit {
  final String label;
  final double gramsPerMarketUnit;
  final double billingUnitsPerMarketUnit;

  const MetalRatePriceUnit._(
    this.label,
    this.gramsPerMarketUnit,
    this.billingUnitsPerMarketUnit,
  );

  static MetalRatePriceUnit forMetal(MetalRateMetal metal) => switch (metal) {
        MetalRateMetal.silver => const MetalRatePriceUnit._('kg', 1000, 1000),
        MetalRateMetal.diamond => const MetalRatePriceUnit._('ct', 0.2, 1),
        _ => const MetalRatePriceUnit._('10g', 10, 10),
      };

  double toMarket(double storedRate) => storedRate;

  double toStored(double marketRate) => marketRate;

  double toBillingRate(double marketRate) =>
      marketRate / billingUnitsPerMarketUnit;

  double toCostingRatePer100g(double marketRate) =>
      marketRate / gramsPerMarketUnit * 100;
}
