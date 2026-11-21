import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_history_view.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_revision_change.dart';

void main() {
  for (final metal in [MetalRateMetal.gold, MetalRateMetal.silver]) {
    test('${metal.name} summary contains only base selling and old purchase',
        () {
      final base = MetalRateProfile.defaultFor(metal);
      final current = base.copyWith(
        mcxRatePer10g: 200000,
        physicalMarketRatePer10g: 180000,
        oldMetalPurchaseRatePer10g: 120000,
        purityPlans: [
          for (final plan in base.purityPlans)
            plan.copyWith(manualDisplayRatePer10g: 150000),
        ],
      );
      final revision = MetalRateRevision.compare(
        MetalRateHistoryEntry(
            profile: current,
            changedAt: DateTime(2026, 11, 21),
            source: 'Manual'),
        base,
      );
      expect(revision.summaryChanges.map((change) => change.label),
          ['${base.purityPlans.first.label} selling', 'Old metal purchase']);
      expect(revision.changes.length, greaterThan(2));
    });
  }

  test('shared timestamps use revision order and plot the latest saved value',
      () {
    final base = MetalRateProfile.defaultFor(MetalRateMetal.silver);
    final at = DateTime(2026, 11, 21, 10);
    MetalRateHistoryEntry saved(int revision, double rate) =>
        MetalRateHistoryEntry(
          profile: base.copyWith(physicalMarketRatePer10g: rate),
          changedAt: at,
          source: 'Manual',
          revision: revision,
        );
    final view = MetalRateHistoryView.build(
      [saved(5, 180000), saved(4, 170000)],
      MetalRateHistoryPeriod.current,
      now: DateTime(2026, 11, 21, 12),
      purityLabel: '999',
    );
    expect(view.currentRate, 180000);
    expect(view.points.map((point) => point.rate), [180000, 180000]);
    expect(view.changeEntries.first.entry.revision, 5);
    final change = view.changeEntries.first.summaryChanges.single;
    expect(change.previousRate, 170000);
    expect(change.currentRate, 180000);
  });

  test('reset leaves a graph gap instead of carrying a stale selling rate', () {
    final base = MetalRateProfile.defaultFor(MetalRateMetal.silver);
    final view = MetalRateHistoryView.build([
      MetalRateHistoryEntry(
          profile: base.copyWith(physicalMarketRatePer10g: 175000),
          changedAt: DateTime(2026, 11, 21, 9),
          source: 'Manual',
          revision: 1),
      MetalRateHistoryEntry(
          profile: base,
          changedAt: DateTime(2026, 11, 21, 10),
          source: 'Manual',
          revision: 2),
    ], MetalRateHistoryPeriod.current, now: DateTime(2026, 11, 21, 12));
    expect(view.hasSavedRate, isTrue);
    expect(view.hasCurrentRate, isFalse);
    expect(view.currentRate, 0);
    expect(view.points.last.isAvailable, isFalse);
    expect(view.points.where((point) => point.isAvailable).last.time,
        DateTime(2026, 11, 21, 10));
  });

  test('revision details identify a changed silver jewellery rate', () {
    final base = MetalRateProfile.defaultFor(MetalRateMetal.silver);
    final before = base.copyWith(purityPlans: [
      for (final plan in base.purityPlans)
        plan.label == '700'
            ? plan.copyWith(manualDisplayRatePer10g: 110000)
            : plan,
    ]);
    final after = before.copyWith(purityPlans: [
      for (final plan in before.purityPlans)
        plan.label == '700'
            ? plan.copyWith(manualDisplayRatePer10g: 130000)
            : plan,
    ]);
    final entry = MetalRateHistoryEntry(
      profile: after,
      changedAt: DateTime(2026, 11, 17),
      source: 'Metal Rate Master',
    );
    final revision = MetalRateRevision.compare(entry, before);

    expect(revision.changes, hasLength(1));
    expect(revision.changes.single.label, '700 selling');
    expect(revision.changes.single.previousRate, 110000);
    expect(revision.changes.single.currentRate, 130000);

    final view = MetalRateHistoryView.build(
      [
        MetalRateHistoryEntry(
          profile: before,
          changedAt: DateTime(2026, 11, 16),
          source: 'Metal Rate Master',
        ),
        entry,
      ],
      MetalRateHistoryPeriod.month,
      now: DateTime(2026, 11, 17, 12),
      purityLabel: '700',
    );
    expect(view.change, 20000);
    expect(view.changeEntries.first.changes.single.label, '700 selling');
  });

  MetalRateHistoryEntry revision(DateTime at, double rate) {
    final base = MetalRateProfile.defaultFor(MetalRateMetal.gold);
    return MetalRateHistoryEntry(
      profile: base.copyWith(purityPlans: [
        base.purityPlans.first.copyWith(manualDisplayRatePer10g: rate),
      ]),
      changedAt: at,
      source: 'Metal Rate Master',
    );
  }

  test('calendar periods include the preceding rate as a chart baseline', () {
    final now = DateTime(2026, 11, 17, 12);
    final history = [
      revision(DateTime(2025, 12, 30), 100000),
      revision(DateTime(2026, 10, 20), 110000),
      revision(DateTime(2026, 11, 16), 120000),
      revision(DateTime(2026, 11, 17, 9), 130000),
    ];

    final current = MetalRateHistoryView.build(
        history, MetalRateHistoryPeriod.current,
        now: now);
    expect(current.start, DateTime(2026, 11, 17));
    expect(current.revisions, hasLength(1));
    expect(current.points.first.rate, 120000);
    expect(current.points.last.rate, 130000);
    expect(current.change, 10000);
    expect(current.changePercent, closeTo(8.33, 0.01));

    final month = MetalRateHistoryView.build(
        history, MetalRateHistoryPeriod.month,
        now: now);
    expect(month.revisions, hasLength(2));
    expect(month.points.first.rate, 110000);

    final year = MetalRateHistoryView.build(
        history, MetalRateHistoryPeriod.year,
        now: now);
    expect(year.revisions, hasLength(3));
    expect(year.points.first.rate, 100000);
    expect(year.points.last.time, now);
  });

  test('period without revisions remains flat at the last saved rate', () {
    final view = MetalRateHistoryView.build(
      [revision(DateTime(2026, 10, 20), 110000)],
      MetalRateHistoryPeriod.current,
      now: DateTime(2026, 11, 17, 12),
    );
    expect(view.revisions, isEmpty);
    expect(view.points, hasLength(2));
    expect(view.change, 0);
  });
}
