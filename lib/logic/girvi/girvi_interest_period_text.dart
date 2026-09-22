import 'package:intl/intl.dart';

import '../../models/girvi/girvi_loan_model.dart';

class GirviInterestPeriodText {
  static final DateFormat _monthFormat = DateFormat('MMM yyyy');

  final String cycleLabel;
  final String monthRangeLabel;
  final String monthsLabel;

  const GirviInterestPeriodText({
    required this.cycleLabel,
    required this.monthRangeLabel,
    required this.monthsLabel,
  });

  static GirviInterestPeriodText forBreakdownLine({
    required DateTime loanStartDate,
    required GirviInterestBreakdownLine line,
  }) {
    final startOffset =
        GirviLoanModel.compoundCycleMonths * (line.cycleNumber - 1);
    final startMonth = _monthAtOffset(loanStartDate, startOffset);
    final endMonth = _monthAtOffset(
      loanStartDate,
      startOffset + line.months - 1,
    );

    return GirviInterestPeriodText(
      cycleLabel: line.cycleNumber == 1
          ? 'First ${_monthsLabel(line.months)}'
          : 'After $startOffset months - ${_monthsLabel(line.months)}',
      monthRangeLabel: _monthRangeLabel(startMonth, endMonth),
      monthsLabel: _monthsLabel(line.months),
    );
  }

  static DateTime _monthAtOffset(DateTime startDate, int offset) {
    final monthIndex = startDate.month + offset - 1;
    final year = startDate.year + (monthIndex ~/ 12);
    final month = (monthIndex % 12) + 1;
    return DateTime(year, month);
  }

  static String _monthRangeLabel(DateTime startMonth, DateTime endMonth) {
    final startLabel = _monthFormat.format(startMonth);
    final endLabel = _monthFormat.format(endMonth);
    return startLabel == endLabel ? startLabel : '$startLabel - $endLabel';
  }

  static String _monthsLabel(int months) {
    return '$months month${months == 1 ? '' : 's'}';
  }
}
