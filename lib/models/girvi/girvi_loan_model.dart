// =============================================================================
// FILE        : girvi_loan_model.dart
// MODULE      : Girvi / Pawn
// LAYER       : Models / Domain
// DESCRIPTION : Rich domain model wrapping the raw GirviLoan DB row.
//               Adds computed properties: daysElapsed, monthsElapsed,
//               accruedInterest, totalDue, isOverdue, statusColor, etc.
//               Used in list screens, detail screens, and release flow.
// =============================================================================

import 'package:flutter/material.dart';
import 'girvi_enums.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// GIRVI LOAN WITH CUSTOMER â€” JOIN MODEL
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class GirviLoanWithCustomer {
  final GirviLoanModel loan;
  final String customerName;
  final String customerMobile;
  final String? customerCity;

  const GirviLoanWithCustomer({
    required this.loan,
    required this.customerName,
    required this.customerMobile,
    this.customerCity,
  });
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// GIRVI LOAN MODEL â€” MAIN DOMAIN OBJECT
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class GirviLoanModel {
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
  final double ratePerGram;
  final double totalValue;
  final double ltvPercent;
  final double loanAmount;
  final double interestRate;
  final int durationMonths;
  final String disbursementMode;
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

  // Release data
  final double? releasePrincipal;
  final double? releaseInterest;
  final double? releasePenalty;
  final double? releaseTotalAmount;
  final String? releasePaymentMode;
  final String? releaseNotes;
  final String? releasedBy;

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
    required this.ratePerGram,
    required this.totalValue,
    required this.ltvPercent,
    required this.loanAmount,
    required this.interestRate,
    required this.durationMonths,
    required this.disbursementMode,
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
    this.releaseTotalAmount,
    this.releasePaymentMode,
    this.releaseNotes,
    this.releasedBy,
    this.updatedAt,
  });

  // â”€â”€ COMPUTED PROPERTIES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Days since loan started
  int get daysElapsed {
    final ref = releaseDate ?? DateTime.now();
    return ref.difference(startDate).inDays;
  }

  /// Full months elapsed (for interest calculation)
  double get monthsElapsed {
    final ref = releaseDate ?? DateTime.now();
    final days = ref.difference(startDate).inDays;
    return days / 30.0;
  }

  /// Months since last interest was paid (for partial interest scenarios)
  double get unpaidMonths {
    if (lastInterestPaidDate == null) return monthsElapsed;
    final ref = releaseDate ?? DateTime.now();
    final days = ref.difference(lastInterestPaidDate!).inDays;
    return days / 30.0;
  }

  /// Accrued interest = loanAmount Ã— (interestRate/100) Ã— monthsElapsed
  double get accruedInterest =>
      loanAmount * (interestRate / 100) * monthsElapsed;

  /// Simple interest for a given number of months
  double interestForMonths(double months) =>
      loanAmount * (interestRate / 100) * months;

  /// Total amount due to release = principal + total interest
  double get totalDue => loanAmount + accruedInterest;

  /// Is the maturity date past?
  bool get isPastMaturity {
    if (maturityDate == null) return false;
    return DateTime.now().isAfter(maturityDate!);
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
  bool get isOverdue => isPastMaturity && isActive;

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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// GIRVI PAYMENT MODEL
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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
    this.monthsCovered,
    this.interestFromDate,
    this.interestToDate,
    this.receiptNo,
    this.notes,
  });

  GirviPaymentType get type => GirviPaymentType.fromDb(paymentType);
  GirviPaymentMode get mode => GirviPaymentMode.fromDb(paymentMode);
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// GIRVI SUMMARY MODEL â€” for dashboard/overview
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class GirviSummaryModel {
  final int totalActive;
  final int totalOverdue;
  final int totalReleased;
  final int totalAuctioned;
  final double totalPrincipalActive;
  final double totalInterestDue;
  final double totalPortfolioValue;
  final double totalCollectedThisMonth;

  const GirviSummaryModel({
    required this.totalActive,
    required this.totalOverdue,
    required this.totalReleased,
    required this.totalAuctioned,
    required this.totalPrincipalActive,
    required this.totalInterestDue,
    required this.totalPortfolioValue,
    required this.totalCollectedThisMonth,
  });

  factory GirviSummaryModel.empty() => const GirviSummaryModel(
        totalActive: 0,
        totalOverdue: 0,
        totalReleased: 0,
        totalAuctioned: 0,
        totalPrincipalActive: 0,
        totalInterestDue: 0,
        totalPortfolioValue: 0,
        totalCollectedThisMonth: 0,
      );

  int get totalLoans => totalActive + totalReleased + totalAuctioned;
}
