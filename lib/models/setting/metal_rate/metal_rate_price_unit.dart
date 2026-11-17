import 'metal_rate_model.dart';

/// Rates are persisted in the market unit: silver per kg, gold/platinum per
/// 10g and diamond per carat. Billing converts metal rates to a per-gram rate.
class MetalRatePriceUnit {
  final String label;
  final double gramsPerMarketUnit;

  const MetalRatePriceUnit._(this.label, this.gramsPerMarketUnit);

  static MetalRatePriceUnit forMetal(MetalRateMetal metal) => switch (metal) {
        MetalRateMetal.silver => const MetalRatePriceUnit._('kg', 1000),
        MetalRateMetal.diamond => const MetalRatePriceUnit._('ct', 1),
        _ => const MetalRatePriceUnit._('10g', 10),
      };

  double toMarket(double storedRate) => storedRate;

  double toStored(double marketRate) => marketRate;

  double toBillingRate(double marketRate) => marketRate / gramsPerMarketUnit;
}
