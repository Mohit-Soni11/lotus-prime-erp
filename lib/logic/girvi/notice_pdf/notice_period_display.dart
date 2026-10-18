import 'package:intl/intl.dart';

import '../../../models/girvi/girvi_loan_model.dart';

/// Customer-facing labels derived from the verified notice period record.
class NoticePeriodDisplay {
  const NoticePeriodDisplay({
    required this.monthLabel,
    this.dateRange,
    this.chargeableLabel,
  });

  final String monthLabel;
  final String? dateRange;
  final String? chargeableLabel;

  static final DateFormat _sourceDate = DateFormat('dd MMMM yyyy', 'en_US');
  static final DateFormat _shortDate = DateFormat('dd MMM yyyy', 'en_US');

  static DateTime? parseNoticeDate(String? value) {
    if (value == null) return null;
    try {
      return _sourceDate.parseStrict(value.trim());
    } on FormatException {
      return null;
    }
  }

  factory NoticePeriodDisplay.fromRecord({
    required String? period,
    required int? months,
    required int priorMonths,
    required int cycleNumber,
    required bool compound,
    DateTime? asOf,
  }) {
    final validMonths = months != null && months > 0;
    final monthLabel = validMonths
        ? compound
            ? 'Year $cycleNumber · Months ${priorMonths + 1}-${priorMonths + months}'
            : 'Months ${priorMonths + 1}-${priorMonths + months}'
        : period ?? 'Period not recorded';
    final dates = _parseRange(period);
    DateTime? displayEnd = dates?.$2;
    if (dates != null &&
        asOf != null &&
        displayEnd!.isAfter(asOf) &&
        !asOf.isBefore(dates.$1)) {
      displayEnd = asOf;
    }
    return NoticePeriodDisplay(
      monthLabel: monthLabel,
      dateRange: dates == null
          ? null
          : '${_shortDate.format(dates.$1)} - ${_shortDate.format(displayEnd!)}',
      chargeableLabel:
          compound && validMonths && months < GirviLoanModel.compoundCycleMonths
              ? '$months chargeable month${months == 1 ? '' : 's'}'
              : null,
    );
  }

  static (DateTime, DateTime)? _parseRange(String? value) {
    if (value == null) return null;
    final parts = value.split(RegExp(r'\s+to\s+', caseSensitive: false));
    if (parts.length != 2) return null;
    try {
      final from = _sourceDate.parseStrict(parts[0].trim());
      final to = _sourceDate.parseStrict(parts[1].trim());
      return to.isBefore(from) ? null : (from, to);
    } on FormatException {
      return null;
    }
  }
}
