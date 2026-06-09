import 'package:flutter/foundation.dart';

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
  final String? idProofType;
  final String? idProofNumber;
  final String? idProofImagePath;
  final String? notes;

  int get totalPieces => items.fold(0, (total, item) => total + item.pieces);

  double get totalGrossWeight =>
      items.fold(0, (total, item) => total + item.grossWeight);

  double get totalNetWeight =>
      items.fold(0, (total, item) => total + item.netWeight);

  int get photoCount =>
      items.fold(0, (total, item) => total + item.photoPaths.length);
}
