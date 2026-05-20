import 'package:flutter/foundation.dart';

import '../supplier_model/supplier_enums.dart';
import '../supplier_model/supplier_model.dart';

enum SupplierLedgerHealth {
  clear,
  due,
  watch;

  String get label {
    switch (this) {
      case SupplierLedgerHealth.clear:
        return 'CLEAR';
      case SupplierLedgerHealth.due:
        return 'DUE';
      case SupplierLedgerHealth.watch:
        return 'WATCH';
    }
  }

  static SupplierLedgerHealth calculate(double outstandingDue) {
    if (outstandingDue <= 0.005) return SupplierLedgerHealth.clear;
    if (outstandingDue <= 25000) return SupplierLedgerHealth.due;
    return SupplierLedgerHealth.watch;
  }
}

@immutable
class SupplierProfilePurchaseModel {
  final int voucherId;
  final String voucherNo;
  final String? supplierInvoiceNo;
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
  bool get hasDue => balanceDue > 0.005;
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
  });

  String get displayName => businessName.trim().isEmpty ? mobile : businessName;
  String get avatarInitials => buildInitials(displayName);
  String get typeLabel => supplierType.label;
  String get statusLabel => status.label;
  bool get isActive => status == SupplierStatus.active;
  bool get hasOutstandingDue => outstandingDue > 0.005;
  SupplierLedgerHealth get ledgerHealth =>
      SupplierLedgerHealth.calculate(outstandingDue);

  int get purchaseCount => purchases.length;
  int get totalStockEntries =>
      purchases.fold(0, (sum, item) => sum + item.stockEntryCount);
  int get dueVoucherCount =>
      purchases.where((item) => item.balanceDue > 0.005).length;
  int get billPhotoCount => purchases.where((item) => item.hasBillPhoto).length;
  int get metalSettlementCount =>
      purchases.where((item) => item.hasMetalSettlement).length;

  double get totalPurchaseValue =>
      purchases.fold(0.0, (sum, item) => sum + item.grandTotal);
  double get totalPaidValue =>
      purchases.fold(0.0, (sum, item) => sum + item.totalPaid);
  double get totalMetalFine =>
      purchases.fold(0.0, (sum, item) => sum + item.metalPaidFine);
  double get totalMetalValue =>
      purchases.fold(0.0, (sum, item) => sum + item.metalPaidValue);

  List<SupplierProfilePurchaseModel> get duePurchases =>
      purchases.where((item) => item.hasDue).toList(growable: false);
  List<SupplierProfilePurchaseModel> get metalSettlements => purchases
      .where((item) => item.hasMetalSettlement)
      .toList(growable: false);
  List<SupplierProfilePurchaseModel> get billDocuments =>
      purchases.where((item) => item.hasBillPhoto).toList(growable: false);

  String get formattedSince {
    final date = createdAt;
    if (date == null) return 'Not recorded';
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
    return '${months[date.month]} ${date.year}';
  }

  String get addressLine {
    final parts = [
      addressLine1,
      addressLine2,
      state,
      pincode,
      country,
    ].where((value) => value != null && value.trim().isNotEmpty);
    return parts.isEmpty ? 'Not added' : parts.join(', ');
  }

  String get primaryContactName {
    final name = contactPersonName?.trim();
    return name == null || name.isEmpty ? 'Owner / Manager' : name;
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
