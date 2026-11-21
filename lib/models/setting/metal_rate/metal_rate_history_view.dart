import 'metal_rate_model.dart';
import 'metal_rate_revision_change.dart';

enum MetalRateHistoryPeriod { current, month, year }

class MetalRateHistoryPoint {
  final DateTime time;
  final double rate;

  const MetalRateHistoryPoint(this.time, this.rate);

  bool get isAvailable => rate.isFinite && rate > 0;
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
    final sorted = [...history]..sort((a, b) {
        final timeOrder = a.changedAt.compareTo(b.changedAt);
        if (timeOrder != 0) return timeOrder;
        final revisionOrder = (a.revision ?? 0).compareTo(b.revision ?? 0);
        return revisionOrder != 0
            ? revisionOrder
            : a.profile.updatedAt.compareTo(b.profile.updatedAt);
      });
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
    // The latest saved revision wins when the database timestamp is shared.
    final timeline = <DateTime, double>{
      if (baseline != null) start: _rateFor(baseline.profile, purityLabel),
      for (final entry in revisions)
        entry.changedAt: _rateFor(entry.profile, purityLabel),
    };
    final points = <MetalRateHistoryPoint>[];
    for (final event in timeline.entries) {
      final point = MetalRateHistoryPoint(event.key, event.value);
      if (!point.isAvailable && points.isNotEmpty && points.last.isAvailable) {
        // Keep the last valid rate up to its reset, then leave a chart gap.
        points.add(MetalRateHistoryPoint(event.key, points.last.rate));
      }
      points.add(point);
    }
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

  double get change => !hasCurrentRate
      ? 0
      : currentRate - points.firstWhere((p) => p.isAvailable).rate;
  double get changePercent => !hasCurrentRate
      ? 0
      : change / points.firstWhere((p) => p.isAvailable).rate * 100;

  bool get hasSavedRate => points.any((point) => point.isAvailable);
  bool get hasCurrentRate => points.isNotEmpty && points.last.isAvailable;
  double get currentRate => hasCurrentRate ? points.last.rate : 0;

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
