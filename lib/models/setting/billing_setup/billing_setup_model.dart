// =============================================================================
// FILE        : lib/models/setting/billing_setup/billing_setup_model.dart
// MODULE      : Billing Setup
// LAYER       : Models
// DESCRIPTION : Pure Dart models — 4 billing cards. No Flutter dependency.
// =============================================================================

// ══ 1. SALES BILLING MODEL ════════════════════════════════════════════════════
class SalesBillingModel {
  final String invoicePrefix;
  final int startingNumber;
  final bool yearlyReset;
  final String estimatePrefix;
  final int estimateValidityDays;
  final String defaultPaymentMode;
  final String upiId;
  final int defaultCreditDays;
  final int minAdvancePercent;
  final bool allowDiscount;
  final double maxDiscountPercent;
  final String roundingRule;
  final bool showMakingCharges;
  final bool showHuid;
  final bool showOldGoldLine;
  final String terms;
  final String footerMsg;

  const SalesBillingModel({
    this.invoicePrefix = 'INV-',
    this.startingNumber = 1,
    this.yearlyReset = true,
    this.estimatePrefix = 'EST-',
    this.estimateValidityDays = 7,
    this.defaultPaymentMode = 'Cash',
    this.upiId = '',
    this.defaultCreditDays = 30,
    this.minAdvancePercent = 30,
    this.allowDiscount = true,
    this.maxDiscountPercent = 5.0,
    this.roundingRule = 'Nearest ₹1',
    this.showMakingCharges = true,
    this.showHuid = true,
    this.showOldGoldLine = true,
    this.terms =
        'Items once sold will not be taken back or exchanged.\nGuarantee is provided as per BIS standards.\nOriginal bill is mandatory for any service claim.',
    this.footerMsg = 'Thank you for shopping with us! Visit us again.',
  });

  SalesBillingModel copyWith({
    String? invoicePrefix,
    int? startingNumber,
    bool? yearlyReset,
    String? estimatePrefix,
    int? estimateValidityDays,
    String? defaultPaymentMode,
    String? upiId,
    int? defaultCreditDays,
    int? minAdvancePercent,
    bool? allowDiscount,
    double? maxDiscountPercent,
    String? roundingRule,
    bool? showMakingCharges,
    bool? showHuid,
    bool? showOldGoldLine,
    String? terms,
    String? footerMsg,
  }) =>
      SalesBillingModel(
        invoicePrefix: invoicePrefix ?? this.invoicePrefix,
        startingNumber: startingNumber ?? this.startingNumber,
        yearlyReset: yearlyReset ?? this.yearlyReset,
        estimatePrefix: estimatePrefix ?? this.estimatePrefix,
        estimateValidityDays: estimateValidityDays ?? this.estimateValidityDays,
        defaultPaymentMode: defaultPaymentMode ?? this.defaultPaymentMode,
        upiId: upiId ?? this.upiId,
        defaultCreditDays: defaultCreditDays ?? this.defaultCreditDays,
        minAdvancePercent: minAdvancePercent ?? this.minAdvancePercent,
        allowDiscount: allowDiscount ?? this.allowDiscount,
        maxDiscountPercent: maxDiscountPercent ?? this.maxDiscountPercent,
        roundingRule: roundingRule ?? this.roundingRule,
        showMakingCharges: showMakingCharges ?? this.showMakingCharges,
        showHuid: showHuid ?? this.showHuid,
        showOldGoldLine: showOldGoldLine ?? this.showOldGoldLine,
        terms: terms ?? this.terms,
        footerMsg: footerMsg ?? this.footerMsg,
      );
}

// ══ 2. PURCHASE BILLING MODEL ═════════════════════════════════════════════════
class PurchaseBillingModel {
  final String invoicePrefix;
  final int startingNumber;
  final bool yearlyReset;
  final int defaultPaymentDays;
  final int advancePercent;
  final String defaultPaymentMode;
  final double weightTolerancePercent;
  final String defaultKarat;
  final String terms;
  final bool autoPrint;

  const PurchaseBillingModel({
    this.invoicePrefix = 'PUR-',
    this.startingNumber = 1,
    this.yearlyReset = true,
    this.defaultPaymentDays = 30,
    this.advancePercent = 20,
    this.defaultPaymentMode = 'Bank Transfer',
    this.weightTolerancePercent = 0.5,
    this.defaultKarat = '22K',
    this.terms =
        'Quality will be checked on delivery.\nShort delivery or defective goods must be reported within 24 hours.\nPayment as per agreed terms only.',
    this.autoPrint = false,
  });

  PurchaseBillingModel copyWith({
    String? invoicePrefix,
    int? startingNumber,
    bool? yearlyReset,
    int? defaultPaymentDays,
    int? advancePercent,
    String? defaultPaymentMode,
    double? weightTolerancePercent,
    String? defaultKarat,
    String? terms,
    bool? autoPrint,
  }) =>
      PurchaseBillingModel(
        invoicePrefix: invoicePrefix ?? this.invoicePrefix,
        startingNumber: startingNumber ?? this.startingNumber,
        yearlyReset: yearlyReset ?? this.yearlyReset,
        defaultPaymentDays: defaultPaymentDays ?? this.defaultPaymentDays,
        advancePercent: advancePercent ?? this.advancePercent,
        defaultPaymentMode: defaultPaymentMode ?? this.defaultPaymentMode,
        weightTolerancePercent:
            weightTolerancePercent ?? this.weightTolerancePercent,
        defaultKarat: defaultKarat ?? this.defaultKarat,
        terms: terms ?? this.terms,
        autoPrint: autoPrint ?? this.autoPrint,
      );
}

// ══ 3. GIRVI BILLING MODEL ════════════════════════════════════════════════════
class GirviBillingModel {
  final String girviPrefix;
  final int startingNumber;
  final double defaultInterestRate;
  final String interestType;
  final int gracePeriodDays;
  final String defaultDuration;
  final int reminderDays;
  final int noticeDays;
  final String terms;
  final bool autoPrint;

  const GirviBillingModel({
    this.girviPrefix = 'GRV-',
    this.startingNumber = 1,
    this.defaultInterestRate = 1.5,
    this.interestType = 'Simple',
    this.gracePeriodDays = 3,
    this.defaultDuration = '6 Months',
    this.reminderDays = 15,
    this.noticeDays = 30,
    this.terms =
        'Interest will be charged per month on the loan amount.\nUnclaimed ornaments after notice period will be auctioned as per law.\nCustomer is responsible for timely repayment.',
    this.autoPrint = true,
  });

  GirviBillingModel copyWith({
    String? girviPrefix,
    int? startingNumber,
    double? defaultInterestRate,
    String? interestType,
    int? gracePeriodDays,
    String? defaultDuration,
    int? reminderDays,
    int? noticeDays,
    String? terms,
    bool? autoPrint,
  }) =>
      GirviBillingModel(
        girviPrefix: girviPrefix ?? this.girviPrefix,
        startingNumber: startingNumber ?? this.startingNumber,
        defaultInterestRate: defaultInterestRate ?? this.defaultInterestRate,
        interestType: interestType ?? this.interestType,
        gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
        defaultDuration: defaultDuration ?? this.defaultDuration,
        reminderDays: reminderDays ?? this.reminderDays,
        noticeDays: noticeDays ?? this.noticeDays,
        terms: terms ?? this.terms,
        autoPrint: autoPrint ?? this.autoPrint,
      );
}

// ══ 4. RETURN & BUYBACK MODEL ═════════════════════════════════════════════════
class ReturnBillingModel {
  final int returnWindowDays;
  final double handlingChargePercent;
  final String returnMode;
  final String returnVoucherPrefix;
  final double buybackRatePercent;
  final double buybackPurityDeductPercent;
  final String buybackDefaultKarat;
  final String terms;

  const ReturnBillingModel({
    this.returnWindowDays = 7,
    this.handlingChargePercent = 0.0,
    this.returnMode = 'Exchange Only',
    this.returnVoucherPrefix = 'RET-',
    this.buybackRatePercent = 90.0,
    this.buybackPurityDeductPercent = 2.0,
    this.buybackDefaultKarat = '22K',
    this.terms =
        'Returns accepted within the specified window with original bill only.\nExchange is subject to stock availability.\nBuyback rate is calculated on the day\'s market rate.',
  });

  ReturnBillingModel copyWith({
    int? returnWindowDays,
    double? handlingChargePercent,
    String? returnMode,
    String? returnVoucherPrefix,
    double? buybackRatePercent,
    double? buybackPurityDeductPercent,
    String? buybackDefaultKarat,
    String? terms,
  }) =>
      ReturnBillingModel(
        returnWindowDays: returnWindowDays ?? this.returnWindowDays,
        handlingChargePercent:
            handlingChargePercent ?? this.handlingChargePercent,
        returnMode: returnMode ?? this.returnMode,
        returnVoucherPrefix: returnVoucherPrefix ?? this.returnVoucherPrefix,
        buybackRatePercent: buybackRatePercent ?? this.buybackRatePercent,
        buybackPurityDeductPercent:
            buybackPurityDeductPercent ?? this.buybackPurityDeductPercent,
        buybackDefaultKarat: buybackDefaultKarat ?? this.buybackDefaultKarat,
        terms: terms ?? this.terms,
      );
}
