// ==========================================
// FILE: sales_pos_enums.dart
// TYPE: Core System Enumerations (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Strictly typed enumerations for the Sales POS module.
//              Includes extensions for UI display and Backend API mapping.
//              Zero hardcoded strings policy applied.
// ==========================================

/// Represents the type of metal selected in the item row.
enum MetalType {
  gold,
  silver,
  platinum,
  diamond,
}

extension MetalTypeExtension on MetalType {
  String get displayName {
    switch (this) {
      case MetalType.gold:
        return 'GOLD';
      case MetalType.silver:
        return 'SILVER';
      case MetalType.platinum:
        return 'PLATINUM';
      case MetalType.diamond:
        return 'DIAMOND';
    }
  }

  // Future-proof: For sending data to Node.js/Python/Go backend
  String get apiValue => name.toUpperCase();
}

/// Represents how the making charge is calculated.
enum MakingChargeType {
  percentage,
  perGram,
  perKg,
  perPiece,
}

extension MakingChargeTypeExtension on MakingChargeType {
  String get symbol {
    switch (this) {
      case MakingChargeType.percentage:
        return '%';
      case MakingChargeType.perGram:
        return '/g';
      case MakingChargeType.perKg:
        return '/kg';
      case MakingChargeType.perPiece:
        return '/pc';
    }
  }
}

/// Represents the overall billing mode.
enum BillingMode {
  retail,
  wholesale,
}

/// Represents the tax application type.
enum BillType {
  normal,
  gst,
}

extension BillTypeExtension on BillType {
  String get displayName => this == BillType.gst ? 'GST' : 'NORMAL';
}

/// Represents how trade-in metal value is adjusted against the final bill.
enum TradeInAdjustMode {
  cashAdjust,
  metalAdjust,
}

/// Represents why customer metal was received in the POS bill.
enum CustomerMetalSettlementType {
  exchangeAdjustment,
  purchaseFromCustomer,
}

extension CustomerMetalSettlementTypeExtension on CustomerMetalSettlementType {
  String get storageValue {
    switch (this) {
      case CustomerMetalSettlementType.exchangeAdjustment:
        return 'EXCHANGE_ADJUSTMENT';
      case CustomerMetalSettlementType.purchaseFromCustomer:
        return 'PURCHASE_FROM_CUSTOMER';
    }
  }

  String get ledgerSource {
    switch (this) {
      case CustomerMetalSettlementType.exchangeAdjustment:
        return 'Exchange Adjustment';
      case CustomerMetalSettlementType.purchaseFromCustomer:
        return 'Purchase From Customer';
    }
  }
}

/// Represents the type of discount applied to the total gross amount.
enum DiscountType {
  flatAmount,
  percentage,
}

extension DiscountTypeExtension on DiscountType {
  String get symbol {
    switch (this) {
      case DiscountType.flatAmount:
        return '';
      case DiscountType.percentage:
        return '%';
    }
  }
}

/// Represents the authorization level of the user handling the POS.
enum UserRole {
  owner,
  manager,
  cashier,
  staff,
}

extension UserRoleExtension on UserRole {
  String get displayName => name.toUpperCase();
}

// ==========================================
//  NEW ADDITIONS (Extracted from UI Hardcoded Strings)
// ==========================================

/// Tracks the lifecycle state of the current POS invoice.
enum InvoiceStatus {
  draft,
  onHold,
  completed,
  cancelled,
}

/// Represents the method used when refunding change to a customer.
enum RefundMethod {
  cash,
  upi,
  accountCredit,
}

extension RefundMethodExtension on RefundMethod {
  String get displayName {
    switch (this) {
      case RefundMethod.cash:
        return 'CASH';
      case RefundMethod.upi:
        return 'UPI';
      case RefundMethod.accountCredit:
        return 'CUSTOMER ACCOUNT';
    }
  }
}

/// Represents the different payment collection modes.
enum PaymentMode {
  cash,
  upi,
  card,
  advance,
}

extension PaymentModeExtension on PaymentMode {
  String get displayName {
    switch (this) {
      case PaymentMode.cash:
        return 'CASH';
      case PaymentMode.upi:
        return 'UPI / BANK';
      case PaymentMode.card:
        return 'CARD';
      case PaymentMode.advance:
        return 'ADVANCE';
    }
  }
}
