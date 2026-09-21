import 'package:flutter/foundation.dart';

enum GirviReceiptMode {
  pledge,
  interest,
  release;

  String get title {
    switch (this) {
      case GirviReceiptMode.pledge:
        return 'Pledge Receipt';
      case GirviReceiptMode.interest:
        return 'Interest Receipt';
      case GirviReceiptMode.release:
        return 'Release Receipt';
    }
  }

  String get badgeLabel {
    switch (this) {
      case GirviReceiptMode.pledge:
        return 'Pledge';
      case GirviReceiptMode.interest:
        return 'Interest';
      case GirviReceiptMode.release:
        return 'Release';
    }
  }
}

@immutable
class GirviInvoicePayment {
  const GirviInvoicePayment({
    required this.label,
    required this.amount,
  });

  final String label;
  final double amount;
}

@immutable
class GirviInvoiceLedgerEntry {
  const GirviInvoiceLedgerEntry({
    required this.date,
    required this.typeLabel,
    required this.modeLabel,
    required this.amount,
    this.principalAmount = 0,
    this.interestAmount = 0,
    this.discountAmount = 0,
    this.balanceAfter = 0,
    this.monthsCovered,
    this.interestFromDate,
    this.interestToDate,
    this.notes,
  });

  final DateTime date;
  final String typeLabel;
  final String modeLabel;
  final double amount;
  final double principalAmount;
  final double interestAmount;
  final double discountAmount;
  final double balanceAfter;
  final int? monthsCovered;
  final DateTime? interestFromDate;
  final DateTime? interestToDate;
  final String? notes;
}

@immutable
class GirviInvoiceItemDraft {
  const GirviInvoiceItemDraft({
    required this.serialNo,
    required this.metal,
    required this.description,
    required this.purity,
    required this.pieces,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.valuationPurity,
    required this.fineWeight,
    required this.ratePerGram,
    required this.huid,
    required this.value,
    this.photoPaths = const [],
  });

  final int serialNo;
  final String metal;
  final String description;
  final String purity;
  final int pieces;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final String valuationPurity;
  final double fineWeight;
  final double ratePerGram;
  final String huid;
  final double value;
  final List<String> photoPaths;
}

@immutable
class GirviInvoiceDraft {
  const GirviInvoiceDraft({
    required this.ticketNo,
    required this.createdAt,
    required this.customerName,
    required this.customerMobile,
    required this.customerCity,
    this.customerAddress = '',
    required this.items,
    required this.totalValue,
    required this.loanAmount,
    required this.interestRate,
    required this.durationMonths,
    required this.startDate,
    required this.maturityDate,
    required this.monthlyInterest,
    required this.totalInterest,
    required this.totalDue,
    required this.payments,
    required this.disbursementSummary,
    this.ledgerEntries = const [],
    this.mode = GirviReceiptMode.pledge,
    this.accountStatus = 'Active',
    this.releaseDate,
    this.expectedDeliveryDate,
    this.deliveredAt,
    this.lastInterestPaidDate,
    this.releasePrincipal,
    this.releaseInterest,
    this.releasePenalty,
    this.releaseDiscount,
    this.releaseTotalAmount,
    this.releasePaymentMode,
    this.releaseNotes,
    this.releasedBy,
    this.principalOutstanding,
    this.interestOutstanding,
    this.idProofType,
    this.idProofNumber,
    this.idProofImagePath,
    this.notes,
  });

  final String ticketNo;
  final DateTime createdAt;
  final String customerName;
  final String customerMobile;
  final String customerCity;
  final String customerAddress;
  final List<GirviInvoiceItemDraft> items;
  final double totalValue;
  final double loanAmount;
  final double interestRate;
  final int durationMonths;
  final DateTime startDate;
  final DateTime maturityDate;
  final double monthlyInterest;
  final double totalInterest;
  final double totalDue;
  final List<GirviInvoicePayment> payments;
  final String disbursementSummary;
  final List<GirviInvoiceLedgerEntry> ledgerEntries;
  final GirviReceiptMode mode;
  final String accountStatus;
  final DateTime? releaseDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? deliveredAt;
  final DateTime? lastInterestPaidDate;
  final double? releasePrincipal;
  final double? releaseInterest;
  final double? releasePenalty;
  final double? releaseDiscount;
  final double? releaseTotalAmount;
  final String? releasePaymentMode;
  final String? releaseNotes;
  final String? releasedBy;
  final double? principalOutstanding;
  final double? interestOutstanding;
  final String? idProofType;
  final String? idProofNumber;
  final String? idProofImagePath;
  final String? notes;

  GirviInvoiceDraft copyWith({
    GirviReceiptMode? mode,
  }) {
    return GirviInvoiceDraft(
      ticketNo: ticketNo,
      createdAt: createdAt,
      customerName: customerName,
      customerMobile: customerMobile,
      customerCity: customerCity,
      customerAddress: customerAddress,
      items: items,
      totalValue: totalValue,
      loanAmount: loanAmount,
      interestRate: interestRate,
      durationMonths: durationMonths,
      startDate: startDate,
      maturityDate: maturityDate,
      monthlyInterest: monthlyInterest,
      totalInterest: totalInterest,
      totalDue: totalDue,
      payments: payments,
      disbursementSummary: disbursementSummary,
      ledgerEntries: ledgerEntries,
      mode: mode ?? this.mode,
      accountStatus: accountStatus,
      releaseDate: releaseDate,
      expectedDeliveryDate: expectedDeliveryDate,
      deliveredAt: deliveredAt,
      lastInterestPaidDate: lastInterestPaidDate,
      releasePrincipal: releasePrincipal,
      releaseInterest: releaseInterest,
      releasePenalty: releasePenalty,
      releaseDiscount: releaseDiscount,
      releaseTotalAmount: releaseTotalAmount,
      releasePaymentMode: releasePaymentMode,
      releaseNotes: releaseNotes,
      releasedBy: releasedBy,
      principalOutstanding: principalOutstanding,
      interestOutstanding: interestOutstanding,
      idProofType: idProofType,
      idProofNumber: idProofNumber,
      idProofImagePath: idProofImagePath,
      notes: notes,
    );
  }

  bool get isReleaseReceipt => mode == GirviReceiptMode.release;

  bool get isInterestReceipt => mode == GirviReceiptMode.interest;

  double get loanToValuePercent =>
      totalValue <= 0 ? 0 : (loanAmount / totalValue) * 100;

  double get totalOutstanding {
    final principal = principalOutstanding ?? loanAmount;
    final interest = interestOutstanding ?? totalInterest;
    final value = principal + interest;
    return value < 0 ? 0 : value;
  }

  String get displayCustomerAddress {
    final fullAddress = customerAddress.trim();
    return fullAddress.isEmpty ? '--' : fullAddress;
  }

  int get totalPieces => items.fold(0, (total, item) => total + item.pieces);

  double get totalGrossWeight =>
      items.fold(0, (total, item) => total + item.grossWeight);

  double get totalNetWeight =>
      items.fold(0, (total, item) => total + item.netWeight);

  int get photoCount =>
      items.fold(0, (total, item) => total + item.photoPaths.length);
}
