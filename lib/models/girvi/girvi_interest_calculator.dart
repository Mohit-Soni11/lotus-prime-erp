/// The single interest policy used by pledge accounts, collections and notices.
/// Replays recorded payments and approved discounts before each annual
/// capitalization so settled interest never becomes part of the next base.
class GirviInterestCalculator {
  const GirviInterestCalculator._();

  static const int compoundCycleMonths = 12;
  static const int maximumCoveredMonths = 1200;

  static int chargeableMonthsBetween(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (!end.isAfter(start)) return 0;
    final wholeMonths = (end.year - start.year) * 12 + end.month - start.month;
    final target = DateTime(start.year, start.month + wholeMonths, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    final anchor = DateTime(
        target.year, target.month, start.day < lastDay ? start.day : lastDay);
    return end.isAfter(anchor)
        ? wholeMonths + 1
        : wholeMonths == 0
            ? 1
            : wholeMonths;
  }

  /// Replays dated interest credits against each chargeable month. Interest
  /// paid before an anniversary cannot be added to the next cycle's base.
  static GirviInterestQuote quoteAt({
    required double principal,
    required double monthlyRatePercent,
    required DateTime startDate,
    required DateTime asOf,
    required Iterable<GirviInterestAdjustment> adjustments,
    double principalDue = 0,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(asOf.year, asOf.month, asOf.day);
    final months = chargeableMonthsBetween(start, end);
    final ordered = adjustments
        .map((entry) => GirviInterestAdjustment(
              date: DateTime(entry.date.year, entry.date.month, entry.date.day),
              paid: entry.paid,
              discount: entry.discount,
            ))
        .where((entry) => !entry.date.isAfter(end))
        .toList(growable: false)
      ..sort((a, b) {
        final dateOrder = a.date.compareTo(b.date);
        if (dateOrder != 0) return dateOrder;
        return b.paid.compareTo(a.paid);
      });
    var eventIndex = 0;
    var capitalized = 0.0;
    var currentCycleDue = 0.0;
    var advanceCredit = 0.0;
    var grossInterest = 0.0;
    var interestPaid = 0.0;
    var interestDiscount = 0.0;
    var cycleInterest = 0.0;
    var cycleOpening = principal;
    final cycles = <GirviInterestBreakdownLine>[];

    void applyCredit(double amount, {required bool isDiscount}) {
      if (amount <= 0) return;
      final appliedToCapitalized = amount < capitalized ? amount : capitalized;
      capitalized -= appliedToCapitalized;
      var remaining = amount - appliedToCapitalized;
      final appliedToCurrent =
          remaining < currentCycleDue ? remaining : currentCycleDue;
      currentCycleDue -= appliedToCurrent;
      remaining -= appliedToCurrent;
      if (!isDiscount) advanceCredit += remaining;
    }

    void applyThrough(DateTime date) {
      while (eventIndex < ordered.length &&
          !ordered[eventIndex].date.isAfter(date)) {
        final entry = ordered[eventIndex++];
        final paid = entry.paid > 0 ? entry.paid : 0.0;
        final discount = entry.discount > 0 ? entry.discount : 0.0;
        interestPaid += paid;
        interestDiscount += discount;
        applyCredit(paid, isDiscount: false);
        applyCredit(discount, isDiscount: true);
      }
    }

    applyThrough(start);
    for (var month = 1; month <= months; month++) {
      if ((month - 1) % compoundCycleMonths == 0) {
        cycleOpening = principal + capitalized;
        cycleInterest = 0;
      }
      final monthlyCharge = (principal + capitalized) *
          monthlyRatePercent.clamp(0, double.infinity) /
          100;
      grossInterest += monthlyCharge;
      cycleInterest += monthlyCharge;
      final creditApplied =
          advanceCredit < monthlyCharge ? advanceCredit : monthlyCharge;
      advanceCredit -= creditApplied;
      currentCycleDue += monthlyCharge - creditApplied;

      final anniversary = _addCalendarMonths(start, month);
      applyThrough(end.isBefore(anniversary) ? end : anniversary);
      final completedCycle =
          month % compoundCycleMonths == 0 && !end.isBefore(anniversary);
      if (completedCycle) {
        capitalized += currentCycleDue;
        currentCycleDue = 0;
      }
      if (completedCycle || month == months) {
        final cycleMonths = month % compoundCycleMonths == 0
            ? compoundCycleMonths
            : month % compoundCycleMonths;
        cycles.add(GirviInterestBreakdownLine(
          cycleNumber: cycles.length + 1,
          months: cycleMonths,
          principalBase: cycleOpening,
          monthlyRatePercent: monthlyRatePercent,
          interestAmount: cycleInterest,
          capitalizedAfterLine: completedCycle,
          closingBalance: principal + capitalized + currentCycleDue,
        ));
      }
    }
    applyThrough(end);
    return GirviInterestQuote(
      chargeableMonths: months,
      interestType: GirviInterestCalculationType.forChargeableMonths(months),
      grossInterest: grossInterest,
      interestPaid: interestPaid,
      interestDiscount: interestDiscount,
      interestOutstanding: capitalized + currentCycleDue,
      advanceInterestCredit: advanceCredit,
      currentMonthlyInterest: (principal + capitalized) *
          monthlyRatePercent.clamp(0, double.infinity) /
          100,
      principalDue: principalDue > 0 ? principalDue : 0,
      cycles: List.unmodifiable(cycles),
    );
  }

  static int coveredMonthsForTimeline({
    required double principal,
    required double monthlyRatePercent,
    required DateTime startDate,
    required DateTime asOf,
    required Iterable<GirviInterestAdjustment> adjustments,
  }) {
    final entries = adjustments
        .where((entry) =>
            !DateTime(entry.date.year, entry.date.month, entry.date.day)
                .isAfter(DateTime(asOf.year, asOf.month, asOf.day)))
        .toList();
    final credit = entries.fold<double>(
        0,
        (sum, entry) =>
            sum +
            entry.paid.clamp(0, double.infinity) +
            entry.discount.clamp(0, double.infinity));
    if (credit <= 0 || principal <= 0 || monthlyRatePercent <= 0) return 0;
    var lower = 0;
    var upper = maximumCoveredMonths;
    while (lower < upper) {
      final middle = lower + ((upper - lower + 1) ~/ 2);
      final gross = quoteAt(
        principal: principal,
        monthlyRatePercent: monthlyRatePercent,
        startDate: startDate,
        asOf: _addCalendarMonths(startDate, middle),
        adjustments: entries,
      ).grossInterest;
      if (gross <= credit + 0.01) {
        lower = middle;
      } else {
        upper = middle - 1;
      }
    }
    return lower;
  }

  static DateTime _addCalendarMonths(DateTime from, int months) {
    final first = DateTime(from.year, from.month + months, 1);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(
        first.year, first.month, from.day < lastDay ? from.day : lastDay);
  }

  static double interestForMonths({
    required double principal,
    required double monthlyRatePercent,
    required int months,
  }) {
    if (months <= 0 || principal <= 0 || monthlyRatePercent <= 0) return 0;
    final monthlyRate = monthlyRatePercent / 100;
    var balance = principal;
    var accrued = 0.0;
    var remaining = months;
    while (remaining >= compoundCycleMonths) {
      final interest = balance * monthlyRate * compoundCycleMonths;
      accrued += interest;
      balance += interest;
      remaining -= compoundCycleMonths;
    }
    if (remaining > 0) accrued += balance * monthlyRate * remaining;
    return accrued;
  }

  static double interestBetweenMonths({
    required double principal,
    required double monthlyRatePercent,
    required int fromMonth,
    required int toMonth,
  }) {
    if (toMonth <= fromMonth) return 0;
    final start = fromMonth < 0 ? 0 : fromMonth;
    return interestForMonths(
          principal: principal,
          monthlyRatePercent: monthlyRatePercent,
          months: toMonth,
        ) -
        interestForMonths(
          principal: principal,
          monthlyRatePercent: monthlyRatePercent,
          months: start,
        );
  }
}

class GirviInterestCalculationType {
  const GirviInterestCalculationType._();

  static const simple = 'Simple';
  static const compound = 'Compound';

  static String normalize(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == simple.toLowerCase()) return simple;
    if (normalized == compound.toLowerCase()) return compound;
    return compound;
  }

  static bool isSimple(String? value) => normalize(value) == simple;

  static String forChargeableMonths(int months) =>
      months > GirviInterestCalculator.compoundCycleMonths ? compound : simple;

  static String forPeriod(DateTime start, DateTime end) => forChargeableMonths(
      GirviInterestCalculator.chargeableMonthsBetween(start, end));
}

class GirviInterestBreakdownLine {
  final int cycleNumber;
  final int months;
  final double principalBase;
  final double monthlyRatePercent;
  final double interestAmount;
  final bool capitalizedAfterLine;
  final double? closingBalance;

  const GirviInterestBreakdownLine({
    required this.cycleNumber,
    required this.months,
    required this.principalBase,
    required this.monthlyRatePercent,
    required this.interestAmount,
    required this.capitalizedAfterLine,
    this.closingBalance,
  });

  double get monthlyInterest => principalBase * monthlyRatePercent / 100;
  double get closingAmount => closingBalance ?? principalBase + interestAmount;
}

class GirviInterestAdjustment {
  final DateTime date;
  final double paid;
  final double discount;

  const GirviInterestAdjustment({
    required this.date,
    this.paid = 0,
    this.discount = 0,
  });
}

class GirviInterestQuote {
  final int chargeableMonths;
  final String interestType;
  final double grossInterest;
  final double interestPaid;
  final double interestDiscount;
  final double interestOutstanding;
  final double advanceInterestCredit;
  final double currentMonthlyInterest;
  final double principalDue;
  final List<GirviInterestBreakdownLine> cycles;

  const GirviInterestQuote({
    required this.chargeableMonths,
    required this.interestType,
    required this.grossInterest,
    required this.interestPaid,
    required this.interestDiscount,
    required this.interestOutstanding,
    required this.advanceInterestCredit,
    required this.currentMonthlyInterest,
    required this.principalDue,
    required this.cycles,
  });

  double get totalPayable => principalDue + interestOutstanding;
}
