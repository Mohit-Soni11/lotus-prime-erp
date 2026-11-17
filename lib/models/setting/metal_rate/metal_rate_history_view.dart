import 'metal_rate_model.dart';
import 'metal_rate_revision_change.dart';

enum MetalRateHistoryPeriod { current, month, year }

class MetalRateHistoryPoint {
  final DateTime time;
  final double rate;

  const MetalRateHistoryPoint(this.time, this.rate);
}

/// A calendar period with the last earlier revision carried into its opening.
class MetalRateHistoryView {
  final MetalRateHistoryPeriod period;
  final DateTime start;
  final DateTime end;
  final List<MetalRateHistoryEntry> revisions;
  final List<MetalRateRevision> changeEntries;
  final List<MetalRateHistoryPoint> points;

  const MetalRateHistoryView._({
    required this.period,
    required this.start,
    required this.end,
    required this.revisions,
    required this.changeEntries,
    required this.points,
  });

  factory MetalRateHistoryView.build(
    List<MetalRateHistoryEntry> history,
    MetalRateHistoryPeriod period, {
    DateTime? now,
    String? purityLabel,
  }) {
    final end = now ?? DateTime.now();
    final start = switch (period) {
      MetalRateHistoryPeriod.current => DateTime(end.year, end.month, end.day),
      MetalRateHistoryPeriod.month => DateTime(end.year, end.month),
      MetalRateHistoryPeriod.year => DateTime(end.year),
    };
    final sorted = [...history]
      ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
    final earlier = sorted.where((entry) => entry.changedAt.isBefore(start));
    final baseline = earlier.isEmpty ? null : earlier.last;
    final revisions = sorted
        .where((entry) =>
            !entry.changedAt.isBefore(start) && !entry.changedAt.isAfter(end))
        .toList();
    MetalRateProfile? previous;
    final changes = <MetalRateRevision>[];
    for (final entry in sorted) {
      if (entry.changedAt.isAfter(end)) break;
      if (entry.changedAt.isBefore(start)) {
        previous = entry.profile;
        continue;
      }
      changes.add(MetalRateRevision.compare(entry, previous));
      previous = entry.profile;
    }
    final points = <MetalRateHistoryPoint>[
      if (baseline != null && _rateFor(baseline.profile, purityLabel) > 0)
        MetalRateHistoryPoint(start, _rateFor(baseline.profile, purityLabel)),
      for (final entry in revisions)
        if (_rateFor(entry.profile, purityLabel) > 0)
          MetalRateHistoryPoint(
              entry.changedAt, _rateFor(entry.profile, purityLabel)),
    ];
    if (points.isNotEmpty && points.last.time.isBefore(end)) {
      points.add(MetalRateHistoryPoint(end, points.last.rate));
    }
    return MetalRateHistoryView._(
      period: period,
      start: start,
      end: end,
      revisions: revisions.reversed.toList(growable: false),
      changeEntries: changes.reversed.toList(growable: false),
      points: points,
    );
  }

  double get change =>
      points.isEmpty ? 0 : points.last.rate - points.first.rate;
  double get changePercent => points.isEmpty || points.first.rate == 0
      ? 0
      : change / points.first.rate * 100;

  static double _rateFor(MetalRateProfile profile, String? purityLabel) {
    if (purityLabel == null) return profile.primaryShopRatePer10g;
    for (final plan in profile.purityPlans) {
      if (plan.label == purityLabel) {
        return profile.effectiveSellingRateFor(plan);
      }
    }
    return 0;
  }
}
