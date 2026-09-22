import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_interest_period_text.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';

void main() {
  test('compound interest rows describe covered calendar months', () {
    final lines = GirviLoanModel.calculateCompoundInterestBreakdown(
      principal: 35000,
      monthlyRatePercent: 5,
      months: 52,
    );

    expect(lines, hasLength(5));

    final first = GirviInterestPeriodText.forBreakdownLine(
      loanStartDate: DateTime(2022, 6, 14),
      line: lines[0],
    );
    final second = GirviInterestPeriodText.forBreakdownLine(
      loanStartDate: DateTime(2022, 6, 14),
      line: lines[1],
    );
    final finalCycle = GirviInterestPeriodText.forBreakdownLine(
      loanStartDate: DateTime(2022, 6, 14),
      line: lines[4],
    );

    expect(first.cycleLabel, 'First 12 months');
    expect(first.monthRangeLabel, 'Jun 2022 - May 2023');
    expect(second.cycleLabel, 'After 12 months - 12 months');
    expect(second.monthRangeLabel, 'Jun 2023 - May 2024');
    expect(finalCycle.cycleLabel, 'After 48 months - 4 months');
    expect(finalCycle.monthRangeLabel, 'Jun 2026 - Sep 2026');
  });

  test('started next calendar month is displayed as one covered month', () {
    final line = GirviLoanModel.calculateCompoundInterestBreakdown(
      principal: 1000,
      monthlyRatePercent: 5,
      months: 1,
    ).single;

    final period = GirviInterestPeriodText.forBreakdownLine(
      loanStartDate: DateTime(2026, 9, 28),
      line: line,
    );

    expect(period.cycleLabel, 'First 1 month');
    expect(period.monthRangeLabel, 'Sep 2026');
  });
}
