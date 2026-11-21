import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/setting/metal_rate/metal_rate_market_sync.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';

void main() {
  test('silver local market fills counter rates and leaves jewellery manual',
      () {
    final previous = MetalRateProfile.defaultFor(MetalRateMetal.silver);
    final next = MetalRateMarketSync.apply(
      previous: previous,
      next: previous.copyWith(physicalMarketRatePer10g: 180000),
    );
    expect(next.purityPlans.map((plan) => plan.manualDisplayRatePer10g),
        [180000, 166500, 144000, 0]);
    expect(next.purityPlans.map((plan) => plan.purityPercent),
        previous.purityPlans.map((plan) => plan.purityPercent));
  });

  test('silver follows later market changes while preserving custom rates', () {
    final base = MetalRateProfile.defaultFor(MetalRateMetal.silver);
    final previous = base.copyWith(
      physicalMarketRatePer10g: 175000,
      oldMetalPurchaseRatePer10g: 12000,
      purityPlans: [
        for (final plan in base.purityPlans)
          plan.copyWith(
              manualDisplayRatePer10g: switch (plan.label) {
            '999' => 175000,
            '925' => 165000,
            '800' => 140000,
            _ => 110000,
          }),
      ],
    );
    final updated = MetalRateMarketSync.apply(
      previous: previous,
      next: previous.copyWith(physicalMarketRatePer10g: 180000),
    );
    expect(updated.purityPlans.map((plan) => plan.manualDisplayRatePer10g),
        [180000, 165000, 144000, 110000]);
    expect(updated.primaryBuyRatePer10g, 12000);
    final later = MetalRateMarketSync.apply(
      previous: updated,
      next: updated.copyWith(physicalMarketRatePer10g: 190000),
    );
    expect(later.purityPlans.map((plan) => plan.manualDisplayRatePer10g),
        [190000, 165000, 152000, 110000]);
  });

  test('silver parity keeps decimals without gold rounding', () {
    final previous = MetalRateProfile.defaultFor(MetalRateMetal.silver);
    final next = MetalRateMarketSync.apply(
      previous: previous,
      next: previous.copyWith(physicalMarketRatePer10g: 175000),
    );
    expect(next.purityPlans[1].manualDisplayRatePer10g, 161875);
  });

  test('gold keeps its existing counter calculation', () {
    final previous = MetalRateProfile.defaultFor(MetalRateMetal.gold);
    final next = MetalRateMarketSync.apply(
      previous: previous,
      next: previous.copyWith(physicalMarketRatePer10g: 160000),
    );
    expect(next.purityPlans.map((plan) => plan.manualDisplayRatePer10g),
        [160000, 146560, 120000, 93600, 60000]);
  });
}
