// ==========================================
// FILE: pos_invoice_model.dart
// TYPE: Data Model
// DESCRIPTION: Complete snapshot of a finalized invoice.
// ==========================================

import 'package:flutter/material.dart';

import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales & orders/sales_pos_models/sales_pos_models.dart';

enum PrintFormat {
  a4,
  thermal3inch,
  thermal2inch,
}

extension PrintFormatExt on PrintFormat {
  String get label {
    switch (this) {
      case PrintFormat.a4:
        return "A4 Size";
      case PrintFormat.thermal3inch:
        return "3-Inch Thermal";
      case PrintFormat.thermal2inch:
        return "2-Inch Thermal";
    }
  }

  String get subtitle {
    switch (this) {
      case PrintFormat.a4:
        return "210 x 297 mm - Full detail invoice";
      case PrintFormat.thermal3inch:
        return "80 mm roll - Standard POS printer";
      case PrintFormat.thermal2inch:
        return "57 mm roll - Compact receipt";
    }
  }

  IconData get icon {
    switch (this) {
      case PrintFormat.a4:
        return Icons.description_outlined;
      case PrintFormat.thermal3inch:
        return Icons.receipt_long_outlined;
      case PrintFormat.thermal2inch:
        return Icons.receipt_outlined;
    }
  }

  double get previewWidth {
    switch (this) {
      case PrintFormat.a4:
        return 420;
      case PrintFormat.thermal3inch:
        return 240;
      case PrintFormat.thermal2inch:
        return 180;
    }
  }
}

enum PaymentStatus { paid, due, credit }

extension PaymentStatusExt on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.paid:
        return "PAID";
      case PaymentStatus.due:
        return "DUE";
      case PaymentStatus.credit:
        return "CREDIT";
    }
  }
}

class PosInvoiceModel {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final BillType billType;
  final BillingMode billingMode;

  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String shopGstin;

  final String customerName;
  final String customerMobile;
  final String customerCity;
  final String customerPan;
  final String customerGstin;

  final List<SaleItemModel> saleItems;
  final List<OldGoldItemModel> oldGoldItems;

  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double totalGst;
  final double totalOldGoldDeduction;
  final double grandTotal;

  final double cashPaid;
  final double upiPaid;
  final double cardPaid;
  final double advancePaid;
  final double balanceDue;

  final DateTime? promiseDate;
  final double totalMakingCharge;

  double get totalPaid => cashPaid + upiPaid + cardPaid + advancePaid;

  double get netPayable => billingMode == BillingMode.wholesale
      ? grandTotal
      : grandTotal - totalOldGoldDeduction;

  PaymentStatus get paymentStatus {
    if (netPayable < 0) return PaymentStatus.credit;
    if (balanceDue > 0.5) return PaymentStatus.due;
    return PaymentStatus.paid;
  }

  const PosInvoiceModel({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.billType,
    required this.billingMode,
    required this.shopName,
    required this.shopAddress,
    required this.shopPhone,
    required this.shopGstin,
    required this.customerName,
    required this.customerMobile,
    required this.customerCity,
    required this.customerPan,
    required this.customerGstin,
    required this.saleItems,
    required this.oldGoldItems,
    required this.grossAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.totalGst,
    required this.totalOldGoldDeduction,
    required this.grandTotal,
    required this.cashPaid,
    required this.upiPaid,
    required this.cardPaid,
    required this.advancePaid,
    required this.balanceDue,
    required this.totalMakingCharge,
    this.promiseDate,
  });
}
