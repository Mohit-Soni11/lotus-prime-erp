import 'package:flutter/foundation.dart';

@immutable
class CustomerBillModel {
  static const double _kPaymentTolerance = 0.01;

  final int id;
  final String billNo;
  final double totalAmount;
  final double paidAmount;
  final double? recordedDueAmount;
  final String status;
  final String paymentStatus;
  final DateTime billDate;
  final int? sourceAdvanceOrderId;
  final String? sourceAdvanceOrderNo;
  final int lineCount;
  final int returnedLineCount;
  final double returnedAmount;
  final String returnVoucherNo;
  final bool isModified;
  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double gstAmount;
  final double makingTotal;
  final double roundOffAmount;
  final double tradeInDeduction;
  final double cashPaid;
  final double upiPaid;
  final double cardPaid;
  final double advancePaid;
  final String billingMode;
  final String documentType;
  final String gstPricingMode;
  final String taxTreatment;
  final String placeOfSupply;
  final List<CustomerLinkedDocumentModel> linkedDocuments;

  const CustomerBillModel({
    required this.id,
    required this.billNo,
    required this.totalAmount,
    required this.status,
    required this.billDate,
    this.paymentStatus = '',
    this.sourceAdvanceOrderId,
    this.sourceAdvanceOrderNo,
    this.paidAmount = 0.0,
    this.recordedDueAmount,
    this.lineCount = 0,
    this.returnedLineCount = 0,
    this.returnedAmount = 0.0,
    this.returnVoucherNo = '',
    this.isModified = false,
    this.grossAmount = 0.0,
    this.discountAmount = 0.0,
    this.taxableAmount = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.gstAmount = 0.0,
    this.makingTotal = 0.0,
    this.roundOffAmount = 0.0,
    this.tradeInDeduction = 0.0,
    this.cashPaid = 0.0,
    this.upiPaid = 0.0,
    this.cardPaid = 0.0,
    this.advancePaid = 0.0,
    this.billingMode = '',
    this.documentType = '',
    this.gstPricingMode = '',
    this.taxTreatment = '',
    this.placeOfSupply = '',
    this.linkedDocuments = const [],
  });

  String get normalizedStatus => status.trim().toUpperCase();
  String get normalizedPaymentStatus => paymentStatus.trim().toUpperCase();

  bool get isPaid {
    if (normalizedPaymentStatus == 'PAID' ||
        normalizedPaymentStatus == 'SETTLED' ||
        normalizedPaymentStatus == 'COMPLETE' ||
        normalizedPaymentStatus == 'COMPLETED') {
      return true;
    }
    if (normalizedPaymentStatus == 'DUE' ||
        normalizedPaymentStatus == 'UNPAID' ||
        normalizedPaymentStatus == 'PARTIAL') {
      return false;
    }
    final normalized = normalizedStatus;
    if (normalized == 'PAID' ||
        normalized == 'COMPLETE' ||
        normalized == 'COMPLETED') {
      return true;
    }
    return dueAmount <= _kPaymentTolerance;
  }

  bool get isPartial => !isPaid && paidAmount > _kPaymentTolerance;
  bool get isUnpaid => !isPaid && !isPartial;
  bool get isActive => normalizedStatus == 'ACTIVE';
  bool get isCancelled =>
      normalizedStatus == 'CANCELLED' ||
      normalizedStatus == 'CANCELED' ||
      normalizedStatus == 'VOID';
  bool get isFullyReturned =>
      normalizedStatus == 'RETURNED' ||
      (lineCount > 0 && returnedLineCount >= lineCount);
  bool get isPartiallyReturned =>
      normalizedStatus == 'PARTIALLY_RETURNED' ||
      (returnedLineCount > 0 && !isFullyReturned);
  bool get hasReturnActivity => isFullyReturned || isPartiallyReturned;
  bool get hasLinkedDocuments => linkedDocuments.isNotEmpty;
  bool get isFromAdvanceOrder =>
      sourceAdvanceOrderId != null ||
      (sourceAdvanceOrderNo != null && sourceAdvanceOrderNo!.trim().isNotEmpty);

  String get advanceSourceLabel {
    final orderNo = sourceAdvanceOrderNo?.trim();
    return orderNo == null || orderNo.isEmpty
        ? 'Advance Order'
        : 'Advance Order $orderNo';
  }

  double get dueAmount {
    final recorded = recordedDueAmount;
    if (recorded != null) {
      return recorded.clamp(0.0, double.infinity).toDouble();
    }
    return (totalAmount - paidAmount).clamp(0.0, double.infinity).toDouble();
  }

  String get paymentLabel => isPaid
      ? "SETTLED"
      : isPartial
          ? "PARTIAL"
          : "UNPAID";

  String get lifecycleLabel {
    if (isCancelled) return 'CANCELLED';
    if (isFullyReturned) return 'RETURNED';
    if (isPartiallyReturned) return 'PARTIAL RETURN';
    if (isModified) return 'MODIFIED';
    return '';
  }

  String get returnProgressLabel {
    if (!hasReturnActivity) return '';
    final total = lineCount <= 0 ? returnedLineCount : lineCount;
    return '$returnedLineCount/$total ITEMS';
  }

  String get linkedDocumentSummary {
    if (linkedDocuments.isEmpty) return '';
    final first = linkedDocuments.first.documentNo;
    final remaining = linkedDocuments.length - 1;
    return remaining <= 0 ? 'Linked $first' : 'Linked $first +$remaining';
  }

  String get formattedAmount => "\u20B9 ${totalAmount.toStringAsFixed(2)}";
  String get formattedPaidAmount => "\u20B9 ${paidAmount.toStringAsFixed(2)}";
  String get formattedDueAmount => "\u20B9 ${dueAmount.toStringAsFixed(2)}";
  String get formattedReturnedAmount =>
      "\u20B9 ${returnedAmount.toStringAsFixed(2)}";

  double get linkedReturnValue =>
      linkedDocuments.fold(0.0, (total, doc) => total + doc.returnValue);
  double get currentInvoiceValue =>
      (totalAmount - linkedReturnValue).clamp(0.0, double.infinity).toDouble();

  String get formattedDate {
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
    return "${billDate.day.toString().padLeft(2, '0')} "
        "${months[billDate.month]} ${billDate.year}";
  }
}

@immutable
class CustomerLinkedDocumentModel {
  final int id;
  final String documentNo;
  final String operationType;
  final String sourceType;
  final String sourceNumber;
  final String status;
  final DateTime createdAt;
  final int lineCount;
  final double netWeight;
  final double returnValue;
  final double makingReturnedAmount;
  final double dueAdjustedAmount;
  final double customerCreditAmount;

  const CustomerLinkedDocumentModel({
    required this.id,
    required this.documentNo,
    required this.operationType,
    required this.sourceType,
    this.sourceNumber = '',
    required this.status,
    required this.createdAt,
    this.lineCount = 0,
    this.netWeight = 0,
    this.returnValue = 0,
    this.makingReturnedAmount = 0,
    this.dueAdjustedAmount = 0,
    this.customerCreditAmount = 0,
  });

  String get normalizedOperation => operationType.trim().toUpperCase();
  String get normalizedStatus => status.trim().toUpperCase();

  String get documentTitle {
    return switch (normalizedOperation) {
      'SALES_RETURN' => 'Sales Return Voucher',
      'RETURN' => 'Sales Return Voucher',
      'BOOKING_CANCELLATION' => 'Booking Cancellation Note',
      _ => 'Linked Return Document',
    };
  }

  String get statusLabel {
    if (normalizedStatus == 'POSTED') return 'POSTED';
    if (normalizedStatus == 'VOIDED') return 'VOIDED';
    return normalizedStatus.isEmpty ? 'SAVED' : normalizedStatus;
  }

  String get lineCountLabel {
    final suffix = lineCount == 1 ? 'item' : 'items';
    return '$lineCount $suffix';
  }

  String get formattedReturnValue => "\u20B9 ${returnValue.toStringAsFixed(2)}";
  String get formattedMakingReturned =>
      "\u20B9 ${makingReturnedAmount.toStringAsFixed(2)}";
  String get formattedDueAdjusted =>
      "\u20B9 ${dueAdjustedAmount.toStringAsFixed(2)}";
  String get formattedCustomerCredit =>
      "\u20B9 ${customerCreditAmount.toStringAsFixed(2)}";

  String get formattedDate {
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
    return "${createdAt.day.toString().padLeft(2, '0')} "
        "${months[createdAt.month]} ${createdAt.year}";
  }
}

@immutable
class CustomerBillLineItemModel {
  final int lineNo;
  final String metalType;
  final String itemName;
  final String hsnCode;
  final String? huid;
  final String? purity;
  final int quantity;
  final String quantityUnitCode;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double rate;
  final String makingChargeType;
  final double makingChargeInput;
  final double makingCharge;
  final double itemTotal;
  final double taxableAmount;
  final double gstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double gstAmount;
  final double invoiceValue;
  final bool isReturned;
  final String returnVoucherNo;
  final double returnedValue;

  const CustomerBillLineItemModel({
    this.lineNo = 1,
    this.metalType = 'GOLD',
    required this.itemName,
    this.hsnCode = '',
    required this.grossWeight,
    this.lessWeight = 0,
    required this.netWeight,
    required this.rate,
    this.quantity = 1,
    this.quantityUnitCode = 'PCS',
    this.makingChargeType = '',
    this.makingChargeInput = 0,
    required this.makingCharge,
    required this.itemTotal,
    this.taxableAmount = 0,
    this.gstRate = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.gstAmount = 0,
    this.invoiceValue = 0,
    this.isReturned = false,
    this.returnVoucherNo = '',
    this.returnedValue = 0,
    this.huid,
    this.purity,
  });

  String get unitLabel {
    final unit = quantityUnitCode.trim().toUpperCase();
    if (unit.isEmpty) return quantity.toString();
    return '$quantity $unit';
  }

  double get displayInvoiceValue => invoiceValue > 0 ? invoiceValue : itemTotal;
}

@immutable
class CustomerBillDetailModel {
  final CustomerBillModel bill;
  final String customerName;
  final String customerMobile;
  final List<CustomerBillLineItemModel> items;

  const CustomerBillDetailModel({
    required this.bill,
    required this.customerName,
    required this.customerMobile,
    required this.items,
  });
}
