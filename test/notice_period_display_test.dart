import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/notice_pdf/notice_period_display.dart';

void main() {
  test('annual cycle shows its month range and exact account dates', () {
    final label = NoticePeriodDisplay.fromRecord(
      period: '09 May 2023 to 08 May 2024',
      months: 12,
      priorMonths: 0,
      cycleNumber: 1,
      compound: true,
      asOf: DateTime(2026, 10, 17),
    );
    expect(label.monthLabel, 'Year 1 · Months 1-12');
    expect(label.dateRange, '09 May 2023 - 08 May 2024');
    expect(label.chargeableLabel, isNull);
  });

  test('open cycle stops at notice date and states chargeable months', () {
    final label = NoticePeriodDisplay.fromRecord(
      period: '09 May 2026 to 09 November 2026',
      months: 6,
      priorMonths: 36,
      cycleNumber: 4,
      compound: true,
      asOf: DateTime(2026, 10, 17),
    );
    expect(label.monthLabel, 'Year 4 · Months 37-42');
    expect(label.dateRange, '09 May 2026 - 17 Oct 2026');
    expect(label.chargeableLabel, '6 chargeable months');
  });

  test('calendar dates keep leap-day and month-end boundaries', () {
    final label = NoticePeriodDisplay.fromRecord(
      period: '29 February 2024 to 27 February 2025',
      months: 12,
      priorMonths: 0,
      cycleNumber: 1,
      compound: true,
    );
    expect(label.dateRange, '29 Feb 2024 - 27 Feb 2025');
  });
}
