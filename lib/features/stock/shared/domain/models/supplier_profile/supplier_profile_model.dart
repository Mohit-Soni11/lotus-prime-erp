import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:flutter/foundation.dart';
import 'supplier_stock_batch.dart';

@immutable
class SupplierProfilePurchaseModel {
  final int voucherId;
  final String voucherNo;
  final String? supplierInvoiceNo;
  final String taxType;
  final String purchaseCategory;
  final String inputCreditStatus;
  final String partyName;
  final double grossAmount;
  final double grandTotal;
  final double totalPaid;
  final double balanceDue;
  final double ratePerKg;
  final double metalPaidGrossWeight;
  final double metalPaidPurity;
  final double metalPaidFine;
  final double metalPaidValue;
  final double metalFineDue;
  final double metalFineDueValue;
  final double metalFineCredit;
  final double metalFineCreditValue;
  final String? dueMode;
  final String? excessMode;
  final DateTime? promiseDate;
  final String paymentStatus;
  final int stockEntryCount;
  final DateTime createdAt;
  final String? billPhotoPath;
  final double oldDueBefore;
  final double oldDueAdjustedAmount;
  final int metalLineCount;

  const SupplierProfilePurchaseModel({
    required this.voucherId,
    required this.voucherNo,
    this.supplierInvoiceNo,
    this.taxType = 'NORMAL',
    this.purchaseCategory = 'NON_GST_PURCHASE',
    this.inputCreditStatus = 'NO_ITC',
    required this.partyName,
    required this.grossAmount,
    required this.grandTotal,
    required this.totalPaid,
    required this.balanceDue,
    required this.ratePerKg,
    required this.metalPaidGrossWeight,
    required this.metalPaidPurity,
    required this.metalPaidFine,
    required this.metalPaidValue,
    this.metalFineDue = 0.0,
    this.metalFineDueValue = 0.0,
    this.metalFineCredit = 0.0,
    this.metalFineCreditValue = 0.0,
    this.dueMode,
    this.excessMode,
    this.promiseDate,
    required this.paymentStatus,
    required this.stockEntryCount,
    required this.createdAt,
    this.billPhotoPath,
    this.oldDueBefore = 0.0,
    this.oldDueAdjustedAmount = 0.0,
    this.metalLineCount = 0,
  });

  bool get hasBillPhoto => billPhotoPath != null && billPhotoPath!.isNotEmpty;
  bool get isGstPurchase =>
      purchaseCategory.trim().toUpperCase() == 'GST_PURCHASE' ||
      taxType.trim().toUpperCase() == 'GST';
  bool get isInputCreditEligible =>
      inputCreditStatus.trim().toUpperCase() == 'ITC_ELIGIBLE';
  bool get hasDue => balanceDue > 0.005 || hasMetalFineDue;
  bool get hasMetalFineDue => metalFineDue > 0.005;
  bool get hasMetalFineCredit => metalFineCredit > 0.005;
  bool get hasOldDueAdjustment => oldDueAdjustedAmount > 0.005;
  bool get hasMetalSettlement =>
      metalPaidFine > 0.005 || metalPaidValue > 0.005 || metalLineCount > 0;

  bool get isPaid {
    final normalized = paymentStatus.trim().toUpperCase();
    return normalized == 'PAID' ||
        normalized == 'COMPLETE' ||
        normalized == 'COMPLETED' ||
        !hasDue;
  }

  String get statusLabel => isPaid
      ? 'COMPLETE'
      : totalPaid > 0.005
          ? 'PARTIAL'
          : 'UNPAID';

  String get formattedDate => _formatDate(createdAt);

  String get formattedPromiseDate {
    final date = promiseDate;
    if (date == null) return 'Not set';
    return _formatDate(date);
  }
}

@immutable
class SupplierProfileModel {
  final int id;
  final String businessName;
  final String? contactPersonName;
  final SupplierType supplierType;
  final String mobile;
  final String? whatsapp;
  final String? email;
  final String? alternateContact;
  final String? panNumber;
  final String? gstNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? state;
  final String? pincode;
  final String country;
  final double openingBalance;
  final String? notes;
  final SupplierStatus status;
  final DateTime? createdAt;
  final double voucherDueTotal;
  final double oldDueAdjustedTotal;
  final double outstandingDue;
  final List<SupplierProfilePurchaseModel> purchases;
  final List<SupplierStockBatch> batches;

  const SupplierProfileModel({
    required this.id,
    required this.businessName,
    this.contactPersonName,
    this.supplierType = SupplierType.manufacturer,
    required this.mobile,
    this.whatsapp,
    this.email,
    this.alternateContact,
    this.panNumber,
    this.gstNumber,
    this.addressLine1,
    this.addressLine2,
    this.state,
    this.pincode,
    this.country = 'India',
    this.openingBalance = 0.0,
    this.notes,
    this.status = SupplierStatus.active,
    this.createdAt,
    this.voucherDueTotal = 0.0,
    this.oldDueAdjustedTotal = 0.0,
    this.outstandingDue = 0.0,
    this.purchases = const [],
    this.batches = const [],
  });

  String get displayName => businessName.trim().isEmpty ? mobile : businessName;
  String get avatarInitials => buildInitials(displayName);
  String get typeLabel => supplierType.label;
  String get statusLabel => status.label;
  bool get isActive => status == SupplierStatus.active;
  int get totalBatchCount => batches.length;
  int get activeBatchCount => batches.where((batch) => batch.isActive).length;

  List<SupplierProfilePurchaseModel> get billDocuments =>
      purchases.where((item) => item.hasBillPhoto).toList(growable: false);

  String get addressLine {
    final parts = [
      addressLine1,
      addressLine2,
      state,
      pincode,
    ].where((value) => value != null && value.trim().isNotEmpty);
    if (parts.isEmpty) return 'Not added';
    return [...parts, country].join(', ');
  }

  SupplierProfileModel copyWith({
    String? businessName,
    String? contactPersonName,
    SupplierType? supplierType,
    String? mobile,
    String? whatsapp,
    String? email,
    String? alternateContact,
    String? panNumber,
    String? gstNumber,
    String? addressLine1,
    String? addressLine2,
    String? state,
    String? pincode,
    String? country,
    double? openingBalance,
    String? notes,
    SupplierStatus? status,
    double? voucherDueTotal,
    double? oldDueAdjustedTotal,
    double? outstandingDue,
    List<SupplierProfilePurchaseModel>? purchases,
    List<SupplierStockBatch>? batches,
  }) {
    return SupplierProfileModel(
      id: id,
      businessName: businessName ?? this.businessName,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      supplierType: supplierType ?? this.supplierType,
      mobile: mobile ?? this.mobile,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      alternateContact: alternateContact ?? this.alternateContact,
      panNumber: panNumber ?? this.panNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      openingBalance: openingBalance ?? this.openingBalance,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      voucherDueTotal: voucherDueTotal ?? this.voucherDueTotal,
      oldDueAdjustedTotal: oldDueAdjustedTotal ?? this.oldDueAdjustedTotal,
      outstandingDue: outstandingDue ?? this.outstandingDue,
      purchases: purchases ?? this.purchases,
      batches: batches ?? this.batches,
    );
  }

  SupplierModel toSupplierModel() {
    return SupplierModel(
      id: id,
      businessName: businessName,
      contactPersonName: contactPersonName,
      supplierType: supplierType,
      mobile: mobile,
      whatsapp: whatsapp,
      email: email,
      alternateContact: alternateContact,
      panNumber: panNumber,
      gstNumber: gstNumber,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      state: state,
      pincode: pincode,
      country: country,
      openingBalance: openingBalance,
      notes: notes,
      status: status,
      createdAt: createdAt,
    );
  }

  static String buildInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'SP';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }
}

String _formatDate(DateTime date) {
  const months = [
    '',
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
    'Dec'
  ];
  return '${date.day.toString().padLeft(2, '0')} '
      '${months[date.month]} ${date.year}';
}
