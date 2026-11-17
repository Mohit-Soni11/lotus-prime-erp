import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_price_unit.dart';

void main() {
  test('effective selling rate matches the rate visible to the counter', () {
    final gold = MetalRateProfile.defaultFor(MetalRateMetal.gold)
        .copyWith(physicalMarketRatePer10g: 150000);
    final silver = MetalRateProfile.defaultFor(MetalRateMetal.silver)
        .copyWith(physicalMarketRatePer10g: 175000);

    expect(gold.effectiveSellingRateFor(gold.purityPlans[1]), 137400);
    expect(silver.effectiveSellingRateFor(silver.purityPlans[1]), 161875);
    expect(silver.effectiveSellingRateFor(silver.purityPlans[3]), 0);
  });

  test('market rates convert to correct billing and costing units', () {
    final silver = MetalRatePriceUnit.forMetal(MetalRateMetal.silver);
    final gold = MetalRatePriceUnit.forMetal(MetalRateMetal.gold);
    final diamond = MetalRatePriceUnit.forMetal(MetalRateMetal.diamond);

    expect(silver.toBillingRate(175000), 175);
    expect(silver.toCostingRatePer100g(175000), 17500);
    expect(gold.toCostingRatePer100g(139000), 1390000);
    expect(diamond.toBillingRate(50000), 50000);
    expect(diamond.toCostingRatePer100g(50000), 25000000);
  });
}
