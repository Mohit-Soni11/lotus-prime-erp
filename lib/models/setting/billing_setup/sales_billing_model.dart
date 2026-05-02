// =============================================================================
// FILE        : lib/models/setting/billing/sales_billing_model.dart
// MODULE      : Billing Setup → Sales
// DESCRIPTION : Pure Dart models for sales billing settings.
//               One model per metal. No DB dependency.
// =============================================================================

// Metal identifier constants — matches MetalType enum values
class BillingMetal {
  static const String gold = 'gold';
  static const String silver = 'silver';
  static const String diamond = 'diamond';
  static const String platinum = 'platinum';

  static const List<String> all = [gold, silver, diamond, platinum];

  static String displayName(String metal) {
    switch (metal) {
      case gold:
        return 'Gold';
      case silver:
        return 'Silver';
      case diamond:
        return 'Diamond';
      case platinum:
        return 'Platinum';
      default:
        return metal;
    }
  }

  static String emoji(String metal) {
    switch (metal) {
      case gold:
        return '🥇';
      case silver:
        return '🥈';
      case diamond:
        return '💎';
      case platinum:
        return '⬜';
      default:
        return '🔘';
    }
  }
}

// Return mode options
class ReturnModeOptions {
  static const String exchangeOnly = 'Exchange Only';
  static const String refund = 'Refund';
  static const String both = 'Both';
  static const List<String> all = [exchangeOnly, refund, both];
}

// Purchase return mode options
class PurchaseReturnModeOptions {
  static const String exchange = 'Exchange';
  static const String creditNote = 'Credit Note';
  static const String cashRefund = 'Cash Refund';
  static const List<String> all = [exchange, creditNote, cashRefund];
}

// Template options (expandable in future)
class TemplateOptions {
  static const String defaultTemplate = 'default';
  static const List<String> all = [defaultTemplate];
  // Future: 'thermal_58mm', 'thermal_80mm', 'a4_gst', 'a5_minimal'
}

// =============================================================================
// SALES BILLING MODEL
// =============================================================================
class SalesBillingModel {
  final String metal;

  // Section 1 — Invoice Item Display
  final bool showPieces;
  final bool showGrossWeight;
  final bool showLessWeight;
  final bool showNetWeight;
  final bool showPurity;
  final bool showRate;
  final bool showMakingCharges;
  final bool showMakingChargeType;
  final bool showStoneDetails;
  final bool showStoneValue;
  final bool showTotalValue;
  // Gold/Platinum specific
  final bool showHuid;
  final bool showWastage;
  final bool showOldGoldLine;
  // Diamond specific
  final bool showDiamondClarity;
  final bool showCertificationNo;
  final bool showDiamondCarats;
  final bool showDiamondPieces;
  final bool showMetalWeight;
  // Calculated
  final bool showFineWeight;
  // GST
  final bool showGstBreakup;
  final bool showHsnCode;

  // Section 2 — Return & Buyback
  final int returnWindowDays;
  final String returnMode;
  final double handlingChargePercent;
  final double buybackRatePercent;
  final double buybackPurityDeductPercent;

  // Section 3 — Terms
  final String termsAndConditions;
  final String footerMessage;

  // Section 4 — Template
  final String selectedTemplate;

  const SalesBillingModel({
    required this.metal,
    // Display
    this.showPieces = true,
    this.showGrossWeight = true,
    this.showLessWeight = true,
    this.showNetWeight = true,
    this.showPurity = true,
    this.showRate = true,
    this.showMakingCharges = true,
    this.showMakingChargeType = true,
    this.showStoneDetails = false,
    this.showStoneValue = false,
    this.showTotalValue = true,
    this.showHuid = false,
    this.showWastage = false,
    this.showOldGoldLine = true,
    this.showDiamondClarity = true,
    this.showCertificationNo = false,
    this.showDiamondCarats = true,
    this.showDiamondPieces = true,
    this.showMetalWeight = true,
    this.showFineWeight = false,
    this.showGstBreakup = false,
    this.showHsnCode = false,
    // Return
    this.returnWindowDays = 7,
    this.returnMode = 'Exchange Only',
    this.handlingChargePercent = 0.0,
    this.buybackRatePercent = 90.0,
    this.buybackPurityDeductPercent = 2.0,
    // Terms
    this.termsAndConditions =
        'Items once sold will not be taken back or exchanged.\n'
            'Guarantee is provided as per BIS standards.\n'
            'Original bill is mandatory for any service claim.',
    this.footerMessage = 'Thank you for shopping with us! Visit us again.',
    // Template
    this.selectedTemplate = 'default',
  });

  // Default settings per metal (smart defaults based on industry practice)
  factory SalesBillingModel.defaultFor(String metal) {
    switch (metal) {
      case BillingMetal.gold:
        return SalesBillingModel(
          metal: metal,
          showPieces: true,
          showGrossWeight: true,
          showLessWeight: true,
          showNetWeight: true,
          showPurity: true,
          showRate: true,
          showMakingCharges: true,
          showMakingChargeType: true,
          showStoneDetails: false,
          showStoneValue: false,
          showTotalValue: true,
          showHuid: true, // Gold: HUID is mandatory (BIS)
          showWastage: false,
          showOldGoldLine: true,
          showFineWeight: false,
          showGstBreakup: false,
          showHsnCode: false,
          returnWindowDays: 7,
          returnMode: 'Exchange Only',
          handlingChargePercent: 0.0,
          buybackRatePercent: 90.0,
          buybackPurityDeductPercent: 2.0,
          termsAndConditions:
              'Gold items once sold will not be taken back or exchanged.\n'
              'Guarantee is provided as per BIS Hallmark standards.\n'
              'HUID is mandatory for all gold items as per Govt. norms.\n'
              'Original bill is mandatory for any service claim.',
          footerMessage: 'Thank you for shopping with us! Visit us again.',
        );

      case BillingMetal.silver:
        return SalesBillingModel(
          metal: metal,
          showPieces: true,
          showGrossWeight: true,
          showLessWeight: false, // Silver: less/stone weight rarely shown
          showNetWeight: true,
          showPurity: true,
          showRate: true,
          showMakingCharges: true,
          showMakingChargeType: false, // Silver: usually flat per gram
          showStoneDetails: false,
          showStoneValue: false,
          showTotalValue: true,
          showHuid: false, // Silver: no HUID
          showWastage: false,
          showOldGoldLine: false, // Silver: no old gold exchange typically
          showFineWeight: false,
          showGstBreakup: false,
          showHsnCode: false,
          returnWindowDays: 7,
          returnMode: 'Exchange Only',
          handlingChargePercent: 0.0,
          buybackRatePercent: 85.0,
          buybackPurityDeductPercent: 3.0,
          termsAndConditions:
              'Silver items once sold will not be taken back or exchanged.\n'
              'Exchange subject to purity verification.\n'
              'Original bill is mandatory for any service claim.',
          footerMessage: 'Thank you for shopping with us! Visit us again.',
        );

      case BillingMetal.diamond:
        return SalesBillingModel(
          metal: metal,
          showPieces: true,
          showGrossWeight: false, // Diamond: gross weight not primary
          showLessWeight: false,
          showNetWeight: false,
          showPurity: false, // Diamond: clarity instead of purity
          showRate: true,
          showMakingCharges: true,
          showMakingChargeType: false,
          showStoneDetails: true, // Diamond: stone details are primary
          showStoneValue: true,
          showTotalValue: true,
          showHuid: false,
          showWastage: false,
          showOldGoldLine: false,
          showDiamondClarity: true, // VVS1, VS1 etc.
          showCertificationNo: false,
          showDiamondCarats: true,
          showDiamondPieces: true,
          showMetalWeight: true, // Show the gold/silver frame weight
          showFineWeight: false,
          showGstBreakup: false,
          showHsnCode: false,
          returnWindowDays: 0, // Diamond: typically no return
          returnMode: 'Exchange Only',
          handlingChargePercent: 0.0,
          buybackRatePercent: 80.0,
          buybackPurityDeductPercent: 5.0,
          termsAndConditions:
              'Diamond jewellery once sold cannot be returned or exchanged.\n'
              'Certificate is mandatory for resale or valuation.\n'
              'Diamond quality is as per certificate provided.\n'
              'Original bill is mandatory for any service claim.',
          footerMessage: 'Thank you for shopping with us! Visit us again.',
        );

      case BillingMetal.platinum:
        return SalesBillingModel(
          metal: metal,
          showPieces: true,
          showGrossWeight: true,
          showLessWeight: true,
          showNetWeight: true,
          showPurity: true, // 950PT, 900PT, 850PT
          showRate: true,
          showMakingCharges: true,
          showMakingChargeType: true,
          showStoneDetails: false,
          showStoneValue: false,
          showTotalValue: true,
          showHuid: false,
          showWastage: false,
          showOldGoldLine: false,
          showFineWeight: false,
          showGstBreakup: false,
          showHsnCode: false,
          returnWindowDays: 7,
          returnMode: 'Exchange Only',
          handlingChargePercent: 0.0,
          buybackRatePercent: 88.0,
          buybackPurityDeductPercent: 2.0,
          termsAndConditions:
              'Platinum items once sold will not be taken back or exchanged.\n'
              'Purity as per Pt marking on item.\n'
              'Original bill is mandatory for any service claim.',
          footerMessage: 'Thank you for shopping with us! Visit us again.',
        );

      default:
        return SalesBillingModel(metal: metal);
    }
  }

  SalesBillingModel copyWith({
    bool? showPieces,
    bool? showGrossWeight,
    bool? showLessWeight,
    bool? showNetWeight,
    bool? showPurity,
    bool? showRate,
    bool? showMakingCharges,
    bool? showMakingChargeType,
    bool? showStoneDetails,
    bool? showStoneValue,
    bool? showTotalValue,
    bool? showHuid,
    bool? showWastage,
    bool? showOldGoldLine,
    bool? showDiamondClarity,
    bool? showCertificationNo,
    bool? showDiamondCarats,
    bool? showDiamondPieces,
    bool? showMetalWeight,
    bool? showFineWeight,
    bool? showGstBreakup,
    bool? showHsnCode,
    int? returnWindowDays,
    String? returnMode,
    double? handlingChargePercent,
    double? buybackRatePercent,
    double? buybackPurityDeductPercent,
    String? termsAndConditions,
    String? footerMessage,
    String? selectedTemplate,
  }) {
    return SalesBillingModel(
      metal: metal,
      showPieces: showPieces ?? this.showPieces,
      showGrossWeight: showGrossWeight ?? this.showGrossWeight,
      showLessWeight: showLessWeight ?? this.showLessWeight,
      showNetWeight: showNetWeight ?? this.showNetWeight,
      showPurity: showPurity ?? this.showPurity,
      showRate: showRate ?? this.showRate,
      showMakingCharges: showMakingCharges ?? this.showMakingCharges,
      showMakingChargeType: showMakingChargeType ?? this.showMakingChargeType,
      showStoneDetails: showStoneDetails ?? this.showStoneDetails,
      showStoneValue: showStoneValue ?? this.showStoneValue,
      showTotalValue: showTotalValue ?? this.showTotalValue,
      showHuid: showHuid ?? this.showHuid,
      showWastage: showWastage ?? this.showWastage,
      showOldGoldLine: showOldGoldLine ?? this.showOldGoldLine,
      showDiamondClarity: showDiamondClarity ?? this.showDiamondClarity,
      showCertificationNo: showCertificationNo ?? this.showCertificationNo,
      showDiamondCarats: showDiamondCarats ?? this.showDiamondCarats,
      showDiamondPieces: showDiamondPieces ?? this.showDiamondPieces,
      showMetalWeight: showMetalWeight ?? this.showMetalWeight,
      showFineWeight: showFineWeight ?? this.showFineWeight,
      showGstBreakup: showGstBreakup ?? this.showGstBreakup,
      showHsnCode: showHsnCode ?? this.showHsnCode,
      returnWindowDays: returnWindowDays ?? this.returnWindowDays,
      returnMode: returnMode ?? this.returnMode,
      handlingChargePercent:
          handlingChargePercent ?? this.handlingChargePercent,
      buybackRatePercent: buybackRatePercent ?? this.buybackRatePercent,
      buybackPurityDeductPercent:
          buybackPurityDeductPercent ?? this.buybackPurityDeductPercent,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      footerMessage: footerMessage ?? this.footerMessage,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
    );
  }
}
