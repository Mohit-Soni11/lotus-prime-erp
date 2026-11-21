import '../../../models/setting/metal_rate/metal_rate_model.dart';

/// Advances market-following counter rates while retaining custom selling rates.
abstract final class MetalRateMarketSync {
  static MetalRateProfile apply({
    required MetalRateProfile previous,
    required MetalRateProfile next,
  }) {
    if (next.marketBaseRatePer10g <= 0 || next.purityPlans.isEmpty) return next;
    final previousPlans = {
      for (final plan in previous.purityPlans) plan.label: plan,
    };
    final silver = next.metal == MetalRateMetal.silver;
    final plans = <MetalRatePurityPlan>[];
    for (var index = 0; index < next.purityPlans.length; index++) {
      final plan = next.purityPlans[index];
      final oldPlan = previousPlans[plan.label] ?? plan;
      // Local silver jewellery has an independently entered counter rate.
      if (silver && plan.label == '700') {
        plans.add(plan);
        continue;
      }
      final oldRate = silver
          ? previous.marketParityRateFor(oldPlan)
          : _goldFollowerRate(previous.marketBaseRatePer10g, oldPlan, index);
      final newRate = silver
          ? next.marketParityRateFor(plan)
          : _goldFollowerRate(next.marketBaseRatePer10g, plan, index);
      final enteredRate = oldPlan.manualDisplayRatePer10g;
      final followsMarket = silver
          ? enteredRate <= 0 || (enteredRate - oldRate).abs() < 0.005
          : _followsGoldMarket(enteredRate, oldRate);
      plans.add(followsMarket
          ? plan.copyWith(manualDisplayRatePer10g: newRate)
          : plan);
    }
    return next.copyWith(purityPlans: plans);
  }

  static double _goldFollowerRate(
      double base, MetalRatePurityPlan plan, int index) {
    if (base <= 0) return 0;
    final key = plan.label.trim().toUpperCase().replaceAll('KT', 'K');
    if (index == 0 || key == '24K' || key == '999') return base;
    return ((base * plan.purityFactor / 10).round() * 10).toDouble();
  }

  static bool _followsGoldMarket(double rate, double previousMarket) {
    if (rate <= 0) return true;
    if (previousMarket <= 0) return false;
    final tolerance = previousMarket * 0.03;
    return (rate - previousMarket).abs() <= (tolerance < 100 ? 100 : tolerance);
  }
}
