// =============================================================================
// FILE        : purchase_enums.dart
// MODULE      : Purchase
// LAYER       : Models / Enums
// DESCRIPTION : Shared purchase enums for customer metal and stock flows.
// =============================================================================

/// Purchase counterparty source.
enum PurchaseSource {
  fromCustomer('From Customer'),
  fromSupplier('From Supplier');

  final String label;
  const PurchaseSource(this.label);
}

/// Tax treatment for a purchase voucher.
enum PurchaseTaxType {
  normal,
  gst,
}

/// Metal type for purchased items
enum PurchaseMetalType {
  gold,
  silver,
  platinum,
  diamond,
}

extension PurchaseMetalTypeExtension on PurchaseMetalType {
  String get displayName {
    switch (this) {
      case PurchaseMetalType.gold:
        return 'GOLD';
      case PurchaseMetalType.silver:
        return 'SILVER';
      case PurchaseMetalType.platinum:
        return 'PLATINUM';
      case PurchaseMetalType.diamond:
        return 'DIAMOND';
    }
  }

  String get apiValue => name.toUpperCase();
}

/// Payment mode used when paying the seller.
enum PurchasePaymentMode {
  cash,
  upi,
  card,
}

extension PurchasePaymentModeExtension on PurchasePaymentMode {
  String get displayName {
    switch (this) {
      case PurchasePaymentMode.cash:
        return 'CASH';
      case PurchasePaymentMode.upi:
        return 'UPI / BANK';
      case PurchasePaymentMode.card:
        return 'CARD';
    }
  }
}

/// Purchase voucher lifecycle
enum PurchaseStatus {
  draft,
  saved,
  cancelled,
}

/// Discount type on purchase (supplier discount)
enum PurchaseDiscountType {
  flatAmount,
  percentage,
}

extension PurchaseDiscountTypeExtension on PurchaseDiscountType {
  String get symbol {
    switch (this) {
      case PurchaseDiscountType.flatAmount:
        return '₹';
      case PurchaseDiscountType.percentage:
        return '%';
    }
  }
}
