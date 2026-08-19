// ==========================================
// FILE: pos_invoice_model.dart
// TYPE: Data Model
// DESCRIPTION: Complete snapshot of a finalized invoice.
// ==========================================

import 'package:flutter/material.dart';

import '../../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';

enum PrintFormat {
  a4,
  thermal3inch,
  thermal2inch,
}

extension PrintFormatExt on PrintFormat {
  String get label {
    switch (this) {
      case PrintFormat.a4:
        return "A4 Tax Invoice";
      case PrintFormat.thermal3inch:
        return "80 mm Thermal Receipt";
      case PrintFormat.thermal2inch:
        return "57 mm Compact Receipt";
    }
  }

  String get subtitle {
    switch (this) {
      case PrintFormat.a4:
        return "210 x 297 mm - Full-detail statutory invoice";
      case PrintFormat.thermal3inch:
        return "80 mm roll - Standard counter printer";
      case PrintFormat.thermal2inch:
        return "57 mm roll - Compact receipt printer";
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
  final GstPricingMode gstPricingMode;
  final SalesDocumentType documentType;
  final BillingMode billingMode;

  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String shopGstin;
  final String shopStateCode;
  final String shopLogoPath;
  final String shopLogoShape;
  final List<ShopPrintDocumentField> shopPrintFields;
  final bool shopPrintProfileApplied;
  final String shopSignaturePath;
  final String shopSignatureShape;

  final String customerName;
  final String customerMobile;
  final String customerCity;
  final String customerPan;
  final String customerGstin;
  final String customerStateCode;
  final String placeOfSupply;
  final TradeInAdjustMode tradeInMode;
  final CustomerMetalSettlementType customerMetalSettlementType;

  final List<SaleItemModel> saleItems;
  final List<TradeInItemModel> tradeInItems;

  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double totalGst;
  final double totalTradeInDeduction;
  final double crossMetalAdjustmentDeduction;
  final double grandTotal;
  final double roundOffAmount;

  final double cashPaid;
  final double upiPaid;
  final double cardPaid;
  final double advancePaid;
  final double balanceDue;
  final RefundMethod? changeSettlementMethod;
  final double changeSettlementAmount;
  final PaymentMode? changeSettlementPaymentMode;

  final DateTime? promiseDate;
  final double totalMakingCharge;
  final bool isMetalScopedCopy;

  double get totalPaid => cashPaid + upiPaid + cardPaid + advancePaid;
  double get igst {
    final amount = totalGst - cgst - sgst;
    if (amount.abs() <= 0.005) return 0;
    return (amount * 100).round() / 100;
  }

  bool get hasIgstBreakup => igst.abs() > 0.005;

  String get printShopName {
    final configured = shopPrintValue('shop_name');
    if (configured.isNotEmpty) return configured;
    return shopPrintProfileApplied ? '' : shopName;
  }

  String get printShopAddress {
    final businessAddress = shopPrintValue('business_address');
    if (businessAddress.isNotEmpty) return businessAddress;
    final address = [
      shopPrintValue('address_line'),
      shopPrintValue('city_state_pin'),
    ].where((value) => value.trim().isNotEmpty).join(', ');
    if (address.isNotEmpty) return address;
    return shopPrintProfileApplied ? '' : shopAddress;
  }

  String get printShopPhone {
    final mobile = shopPrintValue('mobile_number');
    if (mobile.isNotEmpty) return mobile;
    final whatsapp = shopPrintValue('whatsapp_number');
    if (whatsapp.isNotEmpty) return whatsapp;
    return shopPrintProfileApplied ? '' : shopPhone;
  }

  String get printShopGstin {
    final value = shopPrintValue('gstin');
    if (value.isNotEmpty) return value;
    return shopPrintProfileApplied ? '' : shopGstin;
  }

  List<String> get shopPrintHeaderLines {
    if (shopPrintProfileApplied) {
      return shopPrintFields
          .where((field) => field.id != 'shop_name')
          .map((field) => field.displayText)
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false);
    }

    if (shopPrintFields.isEmpty) {
      return [
        if (shopAddress.trim().isNotEmpty) shopAddress.trim(),
        if (shopPhone.trim().isNotEmpty) 'Mobile: ${shopPhone.trim()}',
        if (shopGstin.trim().isNotEmpty && shopGstin != 'Not Registered')
          'GSTIN: ${shopGstin.trim()}',
      ];
    }

    return shopPrintFields
        .where((field) => field.id != 'shop_name')
        .map((field) => field.displayText)
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  bool get shouldPrintBrandMark =>
      !shopPrintProfileApplied || shopLogoPath.trim().isNotEmpty;

  String shopPrintValue(String id) {
    for (final field in shopPrintFields) {
      if (field.id == id) return field.value;
    }
    return '';
  }

  double get netPayable => billingMode == BillingMode.wholesale
      ? grandTotal + roundOffAmount
      : grandTotal -
          totalTradeInDeduction -
          crossMetalAdjustmentDeduction +
          roundOffAmount;

  PaymentStatus get paymentStatus {
    if (netPayable < 0) return PaymentStatus.credit;
    if (balanceDue > 0.5) return PaymentStatus.due;
    return PaymentStatus.paid;
  }

  const PosInvoiceModel({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.billType,
    this.gstPricingMode = GstPricingMode.exclusive,
    this.documentType = SalesDocumentType.taxInvoice,
    required this.billingMode,
    required this.shopName,
    required this.shopAddress,
    required this.shopPhone,
    required this.shopGstin,
    this.shopStateCode = '',
    this.shopLogoPath = '',
    this.shopLogoShape = 'square',
    this.shopPrintFields = const <ShopPrintDocumentField>[],
    this.shopPrintProfileApplied = false,
    this.shopSignaturePath = '',
    this.shopSignatureShape = 'square',
    required this.customerName,
    required this.customerMobile,
    required this.customerCity,
    required this.customerPan,
    required this.customerGstin,
    this.customerStateCode = '',
    this.placeOfSupply = '',
    required this.tradeInMode,
    this.customerMetalSettlementType =
        CustomerMetalSettlementType.exchangeAdjustment,
    required this.saleItems,
    required this.tradeInItems,
    required this.grossAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.totalGst,
    required this.totalTradeInDeduction,
    this.crossMetalAdjustmentDeduction = 0.0,
    required this.grandTotal,
    this.roundOffAmount = 0.0,
    required this.cashPaid,
    required this.upiPaid,
    required this.cardPaid,
    required this.advancePaid,
    required this.balanceDue,
    required this.totalMakingCharge,
    this.changeSettlementMethod,
    this.changeSettlementAmount = 0.0,
    this.changeSettlementPaymentMode,
    this.promiseDate,
    this.isMetalScopedCopy = false,
  });
}
