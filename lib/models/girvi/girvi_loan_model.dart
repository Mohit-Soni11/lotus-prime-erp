import 'package:flutter/material.dart';
import 'girvi_enums.dart';
import 'girvi_interest_calculator.dart';

export 'girvi_interest_calculator.dart';

/// Joined Girvi loan projection with customer and payment aggregates.
class GirviLoanWithCustomer {
  final GirviLoanModel loan;
  final String customerName;
  final String customerMobile;
  final String? customerCity;
  final String customerAddress;
  final String interestType;
  final double interestPaidTotal;
  final double principalPaidTotal;
  final double interestDiscountTotal;
  final double principalDiscountTotal;
  final double legacyPrincipalRepaidTotal;
  final List<GirviInterestAdjustment> interestAdjustments;

  const GirviLoanWithCustomer({
    required this.loan,
    required this.customerName,
    required this.customerMobile,
    this.customerCity,
    this.customerAddress = '',
    this.interestType = GirviInterestCalculationType.compound,
    this.interestPaidTotal = 0,
    this.principalPaidTotal = 0,
    this.interestDiscountTotal = 0,
    this.principalDiscountTotal = 0,
    this.legacyPrincipalRepaidTotal = 0,
    this.interestAdjustments = const [],
  });

  double get originalPrincipal => loan.loanAmount + legacyPrincipalRepaidTotal;

  GirviInterestQuote interestQuoteAt([DateTime? asOf]) {
    final end = loan.releaseDate ?? asOf ?? DateTime.now();
    return GirviInterestCalculator.quoteAt(
      principal: originalPrincipal,
      monthlyRatePercent: loan.interestRate,
      startDate: loan.startDate,
      asOf: end,
      adjustments: interestAdjustments,
      principalDue: principalDue,
    );
  }

  double get grossInterestAccrued => interestQuoteAt().grossInterest;

  double get netInterestDue => interestQuoteAt().interestOutstanding;

  double get advanceInterestCredit => interestQuoteAt().advanceInterestCredit;

  double get principalDue {
    final due = loan.loanAmount - principalPaidTotal - principalDiscountTotal;
    return due <= 0 ? 0 : due;
  }

  double get totalPayable => interestQuoteAt().totalPayable;
}

/// Human-readable elapsed period between two dates.
class GirviElapsedPeriod {
  final int years;
  final int months;
  final int days;

  const GirviElapsedPeriod({
    required this.years,
    required this.months,
    required this.days,
  });

  bool get isZero => years == 0 && months == 0 && days == 0;

  String get displayLabel {
    final parts = <String>[
      if (years > 0) '$years year${years == 1 ? '' : 's'}',
      if (months > 0) '$months month${months == 1 ? '' : 's'}',
      if (days > 0 || isZero) '$days day${days == 1 ? '' : 's'}',
    ];
    return parts.join(' ');
  }
}

/// Domain model for a Girvi loan with computed settlement values.
class GirviLoanModel {
  static const int compoundCycleMonths =
      GirviInterestCalculator.compoundCycleMonths;

  final int id;
  final String ticketNo;
  final int customerId;
  final String itemDescription;
  final int itemCount;
  final String? huidNumber;
  final String? itemPhotoPath;
  final String metalType;
  final String metalPurity;
  final double grossWeight;
  final double stoneWeight;
  final double netWeight;
  final double loanAmount;
  final double interestRate;
  final int durationMonths;
  final String disbursementMode;
  final String? interestCalculationType;
  final bool invoiceGenerated;
  final DateTime startDate;
  final DateTime? maturityDate;
  final DateTime? releaseDate;
  final DateTime? lastInterestPaidDate;
  final String? idProofType;
  final String? idProofNumber;
  final String? idProofImagePath;
  final String status;
  final String? notes;
  // Release settlement fields
  final double? releasePrincipal;
  final double? releaseInterest;
  final double? releasePenalty;
  final double? releaseDiscount;
  final double? releaseTotalAmount;
  final String? releasePaymentMode;
  final String? releaseNotes;
  final String? releasedBy;
  final DateTime? expectedDeliveryDate;
  final DateTime? deliveredAt;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const GirviLoanModel({
    required this.id,
    required this.ticketNo,
    required this.customerId,
    required this.itemDescription,
    required this.itemCount,
    this.huidNumber,
    this.itemPhotoPath,
    required this.metalType,
    required this.metalPurity,
    required this.grossWeight,
    required this.stoneWeight,
    required this.netWeight,
    required this.loanAmount,
    required this.interestRate,
    required this.durationMonths,
    required this.disbursementMode,
    this.interestCalculationType,
    this.invoiceGenerated = false,
    required this.startDate,
    required this.createdAt,
    this.maturityDate,
    this.releaseDate,
    this.lastInterestPaidDate,
    this.idProofType,
    this.idProofNumber,
    this.idProofImagePath,
    this.status = 'ACTIVE',
    this.notes,
    this.releasePrincipal,
    this.releaseInterest,
    this.releasePenalty,
    this.releaseDiscount,
    this.releaseTotalAmount,
    this.releasePaymentMode,
    this.releaseNotes,
    this.releasedBy,
    this.expectedDeliveryDate,
    this.deliveredAt,
    this.updatedAt,
  });

  /// Days since loan started
  int get daysElapsed {
    final ref = releaseDate ?? DateTime.now();
    return ref.difference(startDate).inDays;
  }

  /// Chargeable months elapsed. Any started month is billed as a full month.
  double get monthsElapsed {
    final ref = releaseDate ?? DateTime.now();
    return chargeableMonthsBetween(startDate, ref).toDouble();
  }

  /// Chargeable months since last interest was paid.
  double get unpaidMonths {
    if (lastInterestPaidDate == null) return monthsElapsed;
    final ref = releaseDate ?? DateTime.now();
    return chargeableMonthsBetween(lastInterestPaidDate!, ref).toDouble();
  }

  DateTime get unpaidInterestStartDate => lastInterestPaidDate ?? startDate;

  DateTime get unpaidInterestEndDate => releaseDate ?? DateTime.now();

  GirviElapsedPeriod get unpaidInterestElapsedPeriod =>
      elapsedPeriodBetween(unpaidInterestStartDate, unpaidInterestEndDate);

  /// Full future months already covered by advance interest payments.
  int get advanceInterestMonths {
    final paidTill = lastInterestPaidDate;
    if (paidTill == null) return 0;
    final ref = releaseDate ?? DateTime.now();
    if (!paidTill.isAfter(ref)) return 0;
    return chargeableMonthsBetween(ref, paidTill);
  }

  bool get hasAdvanceInterest => advanceInterestMonths > 0;

  /// Estimate for legacy loan views that only store a paid-through date.
  /// Financial actions use the complete dated payment ledger instead.
  double get accruedInterest {
    final paidThrough = lastInterestPaidDate;
    final end = unpaidInterestEndDate;
    if (paidThrough != null && !paidThrough.isBefore(end)) return 0;
    final paidThroughAmount = paidThrough == null
        ? 0.0
        : GirviInterestCalculator.quoteAt(
            principal: loanAmount,
            monthlyRatePercent: interestRate,
            startDate: startDate,
            asOf: paidThrough,
            adjustments: const [],
          ).grossInterest;
    return GirviInterestCalculator.quoteAt(
      principal: loanAmount,
      monthlyRatePercent: interestRate,
      startDate: startDate,
      asOf: end,
      adjustments: paidThrough == null
          ? const []
          : [
              GirviInterestAdjustment(
                  date: paidThrough, paid: paidThroughAmount)
            ],
    ).interestOutstanding;
  }

  static int chargeableMonthsBetween(DateTime from, DateTime to) =>
      GirviInterestCalculator.chargeableMonthsBetween(from, to);

  static GirviElapsedPeriod elapsedPeriodBetween(DateTime from, DateTime to) {
    final fromDate = DateUtils.dateOnly(from);
    final toDate = DateUtils.dateOnly(to);
    if (!toDate.isAfter(fromDate)) {
      return const GirviElapsedPeriod(years: 0, months: 0, days: 0);
    }

    var years = toDate.year - fromDate.year;
    var yearAnchor = _addCalendarYears(fromDate, years);
    if (yearAnchor.isAfter(toDate)) {
      years--;
      yearAnchor = _addCalendarYears(fromDate, years);
    }

    var months = ((toDate.year - yearAnchor.year) * 12) +
        toDate.month -
        yearAnchor.month;
    var monthAnchor =
        DateUtils.dateOnly(addChargeableMonths(yearAnchor, months));
    if (monthAnchor.isAfter(toDate)) {
      months--;
      monthAnchor = DateUtils.dateOnly(addChargeableMonths(yearAnchor, months));
    }

    final days = toDate.difference(monthAnchor).inDays;
    return GirviElapsedPeriod(
      years: years,
      months: months,
      days: days,
    );
  }

  static DateTime addChargeableMonths(DateTime from, int months) {
    if (months <= 0) return from;
    final targetMonthIndex = from.month + months - 1;
    final year = from.year + (targetMonthIndex ~/ 12);
    final month = (targetMonthIndex % 12) + 1;
    final day = from.day.clamp(1, DateUtils.getDaysInMonth(year, month));
    return DateTime(
      year,
      month,
      day,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }

  static DateTime _addCalendarYears(DateTime from, int years) {
    if (years <= 0) return from;
    final year = from.year + years;
    final day = from.day.clamp(1, DateUtils.getDaysInMonth(year, from.month));
    return DateTime(year, from.month, day);
  }

  /// Total amount due to release = principal + total interest
  double get totalDue => loanAmount + accruedInterest;

  /// Is the maturity date past?
  bool get isPastMaturity {
    if (maturityDate == null) return false;
    final today = DateTime.now();
    final maturity = maturityDate!;
    return DateTime(today.year, today.month, today.day).isAfter(
      DateTime(maturity.year, maturity.month, maturity.day),
    );
  }

  /// Days remaining to maturity (negative = overdue)
  int get daysToMaturity {
    if (maturityDate == null) return 0;
    return maturityDate!.difference(DateTime.now()).inDays;
  }

  /// How many months overdue (0 if not overdue)
  double get overdueMonths {
    if (!isPastMaturity) return 0;
    return (-daysToMaturity) / 30.0;
  }

  GirviStatus get girviStatus => GirviStatus.fromDb(status);
  MetalType get metalTypeEnum => MetalType.fromDb(metalType);
  MetalPurity get metalPurityEnum => MetalPurity.fromDb(metalPurity);

  bool get isActive => girviStatus.isActive;
  bool get isClosed => girviStatus.isClosed;
  bool get isOverdue =>
      girviStatus == GirviStatus.overdue ||
      (isPastMaturity &&
          (girviStatus == GirviStatus.active ||
              girviStatus == GirviStatus.partialRelease));

  /// Color for status badge
  Color get statusColor {
    switch (girviStatus) {
      case GirviStatus.active:
        return isOverdue ? const Color(0xFFEF4444) : const Color(0xFF10B981);
      case GirviStatus.overdue:
        return const Color(0xFFEF4444);
      case GirviStatus.released:
        return const Color(0xFF3B82F6);
      case GirviStatus.partialRelease:
        return const Color(0xFFF59E0B);
      case GirviStatus.readyForDelivery:
        return const Color(0xFF10B981);
      case GirviStatus.auctioned:
        return const Color(0xFF6B7280);
    }
  }

  Color get statusBgColor => statusColor.withValues(alpha: 0.12);

  String get statusLabel {
    if (girviStatus.isActive && isOverdue) return 'Overdue';
    return girviStatus.displayName;
  }

  /// Short description for list card subtitle
  String get itemSummary =>
      '$itemCount item${itemCount > 1 ? 's' : ''} - ${metalTypeEnum.displayName} $metalPurity - ${netWeight.toStringAsFixed(2)}g';
}

// GIRVI PAYMENT MODEL

/// Domain model for a Girvi payment ledger row.
class GirviPaymentModel {
  final int id;
  final int girviId;
  final DateTime paymentDate;
  final double amount;
  final String paymentType;
  final String paymentMode;
  final int? monthsCovered;
  final DateTime? interestFromDate;
  final DateTime? interestToDate;
  final double balanceAfter;
  final double principalComponent;
  final double interestComponent;
  final double principalDiscountComponent;
  final double interestDiscountComponent;
  final String? receiptNo;
  final String? notes;
  final DateTime createdAt;

  const GirviPaymentModel({
    required this.id,
    required this.girviId,
    required this.paymentDate,
    required this.amount,
    required this.paymentType,
    required this.paymentMode,
    required this.balanceAfter,
    required this.createdAt,
    this.principalComponent = 0,
    this.interestComponent = 0,
    this.principalDiscountComponent = 0,
    this.interestDiscountComponent = 0,
    this.monthsCovered,
    this.interestFromDate,
    this.interestToDate,
    this.receiptNo,
    this.notes,
  });

  GirviPaymentType get type => GirviPaymentType.fromDb(paymentType);
  GirviPaymentMode get mode => GirviPaymentMode.fromDb(paymentMode);
  double get discountAmount =>
      principalDiscountComponent + interestDiscountComponent;
}

/// Result returned after recording a release settlement.
class GirviSettlementResult {
  final bool fullySettled;
  final double principalRemaining;
  final double interestRemaining;
  final double principalDiscount;
  final double interestDiscount;

  const GirviSettlementResult({
    required this.fullySettled,
    required this.principalRemaining,
    required this.interestRemaining,
    this.principalDiscount = 0,
    this.interestDiscount = 0,
  });

  double get totalRemaining => principalRemaining + interestRemaining;
  double get discountApplied => principalDiscount + interestDiscount;
}

/// Aggregated Girvi dashboard summary.
class GirviSummaryModel {
  final int totalActive;
  final int totalOverdue;
  final int totalReadyForDelivery;
  final int totalReleased;
  final double totalPrincipalActive;
  final double totalInterestDue;
  final double totalOverdueReceivable;
  final double totalCollectedThisMonth;

  const GirviSummaryModel({
    required this.totalActive,
    required this.totalOverdue,
    this.totalReadyForDelivery = 0,
    required this.totalReleased,
    required this.totalPrincipalActive,
    required this.totalInterestDue,
    this.totalOverdueReceivable = 0,
    required this.totalCollectedThisMonth,
  });

  factory GirviSummaryModel.empty() => const GirviSummaryModel(
        totalActive: 0,
        totalOverdue: 0,
        totalReadyForDelivery: 0,
        totalReleased: 0,
        totalPrincipalActive: 0,
        totalInterestDue: 0,
        totalOverdueReceivable: 0,
        totalCollectedThisMonth: 0,
      );

  int get totalLoans =>
      totalActive + totalOverdue + totalReadyForDelivery + totalReleased;
}
