import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_history_view.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';

void main() {
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
