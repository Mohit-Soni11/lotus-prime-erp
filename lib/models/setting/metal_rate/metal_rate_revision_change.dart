import 'metal_rate_model.dart';

class MetalRateRevisionChange {
  final String label;
  final double previousRate;
  final double currentRate;

  const MetalRateRevisionChange({
    required this.label,
    required this.previousRate,
    required this.currentRate,
  });
}

class MetalRateRevision {
  final MetalRateHistoryEntry entry;
  final List<MetalRateRevisionChange> changes;

  const MetalRateRevision({required this.entry, required this.changes});

  /// The counter summary stays focused; the full revision remains available.
  List<MetalRateRevisionChange> get summaryChanges {
    final profile = entry.profile;
    if (profile.metal != MetalRateMetal.gold &&
        profile.metal != MetalRateMetal.silver) {
      return changes;
    }
    final basePlans = profile.purityPlans.where(profile.isMarketBasePlan);
    final labels = [
      if (basePlans.isNotEmpty) '${basePlans.first.label} selling',
      'Old metal purchase',
    ];
    return [
      for (final label in labels)
        ...changes.where((change) => change.label == label),
    ];
  }

  factory MetalRateRevision.compare(
    MetalRateHistoryEntry entry,
    MetalRateProfile? previous,
  ) {
    final current = entry.profile;
    final changes = <MetalRateRevisionChange>[];

    void add(String label, double before, double after) {
      if ((before - after).abs() < 0.005) return;
      changes.add(MetalRateRevisionChange(
        label: label,
        previousRate: before,
        currentRate: after,
      ));
    }

    add('Market reference', previous?.mcxRatePer10g ?? 0,
        current.mcxRatePer10g);
    add('Local market', previous?.marketBaseRatePer10g ?? 0,
        current.marketBaseRatePer10g);
    add('Old metal purchase', previous?.primaryBuyRatePer10g ?? 0,
        current.primaryBuyRatePer10g);

    final previousPlans = {
      for (final plan in previous?.purityPlans ?? <MetalRatePurityPlan>[])
        plan.label: plan,
    };
    final currentPlans = {
      for (final plan in current.purityPlans) plan.label: plan,
    };
    for (final label in {...previousPlans.keys, ...currentPlans.keys}) {
      final oldPlan = previousPlans[label];
      final newPlan = currentPlans[label];
      add(
        '$label selling',
        oldPlan == null ? 0 : previous!.effectiveSellingRateFor(oldPlan),
        newPlan == null ? 0 : current.effectiveSellingRateFor(newPlan),
      );
    }

    return MetalRateRevision(entry: entry, changes: changes);
  }
}
