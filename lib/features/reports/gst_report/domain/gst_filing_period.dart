class GstFilingPeriod {
  const GstFilingPeriod({
    required this.month,
    required this.financialYearStart,
    required this.financialYearEnd,
    required this.quarter,
    required this.quarterStartMonth,
    required this.monthPositionInQuarter,
    required this.monthlyTaxPaymentDueDate,
    required this.iffDueDate,
    required this.gstr1QuarterDueDate,
    required this.gstr3bQuarterDueDate22,
    required this.gstr3bQuarterDueDate24,
  });

  factory GstFilingPeriod.fromMonth(DateTime value) {
    final month = DateTime(value.year, value.month);
    final financialYearStart = month.month >= 4 ? month.year : month.year - 1;
    final monthIndex = (month.month - 4) % 12;
    final quarter = (monthIndex ~/ 3) + 1;
    final quarterStartIndex = (quarter - 1) * 3;
    final quarterStartMonth = _calendarMonthFromFinancialIndex(
      financialYearStart,
      quarterStartIndex,
    );
    final quarterEndMonth = _calendarMonthFromFinancialIndex(
      financialYearStart,
      quarterStartIndex + 2,
    );
    final nextMonth = DateTime(month.year, month.month + 1);
    final quarterReturnMonth = DateTime(
      quarterEndMonth.year,
      quarterEndMonth.month + 1,
    );

    return GstFilingPeriod(
      month: month,
      financialYearStart: financialYearStart,
      financialYearEnd: financialYearStart + 1,
      quarter: quarter,
      quarterStartMonth: quarterStartMonth,
      monthPositionInQuarter: monthIndex - quarterStartIndex + 1,
      monthlyTaxPaymentDueDate: DateTime(nextMonth.year, nextMonth.month, 25),
      iffDueDate: monthIndex - quarterStartIndex < 2
          ? DateTime(nextMonth.year, nextMonth.month, 13)
          : null,
      gstr1QuarterDueDate: DateTime(
        quarterReturnMonth.year,
        quarterReturnMonth.month,
        13,
      ),
      gstr3bQuarterDueDate22: DateTime(
        quarterReturnMonth.year,
        quarterReturnMonth.month,
        22,
      ),
      gstr3bQuarterDueDate24: DateTime(
        quarterReturnMonth.year,
        quarterReturnMonth.month,
        24,
      ),
    );
  }

  final DateTime month;
  final int financialYearStart;
  final int financialYearEnd;
  final int quarter;
  final DateTime quarterStartMonth;
  final int monthPositionInQuarter;
  final DateTime monthlyTaxPaymentDueDate;
  final DateTime? iffDueDate;
  final DateTime gstr1QuarterDueDate;
  final DateTime gstr3bQuarterDueDate22;
  final DateTime gstr3bQuarterDueDate24;

  bool get isQuarterClosingMonth => monthPositionInQuarter == 3;

  bool get hasMonthlyTaxPayment => !isQuarterClosingMonth;

  String get financialYearLabel {
    return 'FY $financialYearStart-${financialYearEnd.toString().substring(2)}';
  }

  String get quarterLabel => 'Q$quarter';

  String get quarterKey => 'FY$financialYearStart-Q$quarter';

  String get quarterRangeLabel {
    final months = quarterMonths;
    return '${_shortMonth(months.first)}-${_shortMonth(months.last)}';
  }

  List<DateTime> get quarterMonths {
    return List.generate(
      3,
      (index) =>
          DateTime(quarterStartMonth.year, quarterStartMonth.month + index),
    );
  }

  List<DateTime> get financialYearMonths {
    return List.generate(
      12,
      (index) => _calendarMonthFromFinancialIndex(financialYearStart, index),
    );
  }

  List<GstQuarterCycle> get financialYearQuarters {
    return List.generate(4, (index) {
      final startIndex = index * 3;
      final startMonth = _calendarMonthFromFinancialIndex(
        financialYearStart,
        startIndex,
      );
      return GstQuarterCycle(
        quarter: index + 1,
        months: List.generate(
          3,
          (monthIndex) =>
              DateTime(startMonth.year, startMonth.month + monthIndex),
        ),
      );
    });
  }

  DateTime get quarterEndMonth {
    return DateTime(quarterStartMonth.year, quarterStartMonth.month + 2);
  }

  DateTime gstr3bDueDateForStateCode(String stateCode) {
    return _gstr3bDueDay24StateCodes.contains(stateCode.trim())
        ? gstr3bQuarterDueDate24
        : gstr3bQuarterDueDate22;
  }

  static DateTime _calendarMonthFromFinancialIndex(int fyStart, int index) {
    return DateTime(fyStart, 4 + index);
  }

  static String _shortMonth(DateTime value) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[value.month - 1];
  }
}

class GstQuarterCycle {
  const GstQuarterCycle({
    required this.quarter,
    required this.months,
  });

  final int quarter;
  final List<DateTime> months;

  String get label => 'Q$quarter';
}

const _gstr3bDueDay24StateCodes = {
  '01',
  '02',
  '03',
  '04',
  '05',
  '06',
  '07',
  '08',
  '09',
  '10',
  '11',
  '12',
  '13',
  '14',
  '15',
  '16',
  '17',
  '18',
  '19',
  '20',
  '21',
  '38',
};
