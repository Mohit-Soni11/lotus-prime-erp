// =============================================================================
// FILE        : lib/models/setting/billing/sales_billing_model.dart
// MODULE      : Billing Setup → Sales
// DESCRIPTION : Pure Dart models for sales billing settings.
//               One model per metal. No DB dependency.
// =============================================================================

import '../../../features/print_templates/domain/print_template_registry.dart';

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
  static const String defaultTemplate = PrintTemplateRegistry.defaultTemplateId;
  static List<String> get all => PrintTemplateRegistry.templateIds;

  static String labelFor(String templateId) {
    return PrintTemplateRegistry.labelFor(templateId);
  }
}

class SalesBillingTemplateOptions {
  static const String _marker = '|print:';

  static bool hasLegacyPrintOptions(String storedTemplate) {
    return storedTemplate.contains(_marker);
  }

  static String baseTemplate(String storedTemplate) {
    final markerIndex = storedTemplate.indexOf(_marker);
    if (markerIndex == -1) return storedTemplate;
    return storedTemplate.substring(0, markerIndex);
  }

  static bool readFlag(
    String storedTemplate,
    String key, {
    required bool defaultValue,
  }) {
    final markerIndex = storedTemplate.indexOf(_marker);
    if (markerIndex == -1) return defaultValue;

    final payload = storedTemplate.substring(markerIndex + _marker.length);
    for (final part in payload.split(',')) {
      final pieces = part.split('=');
      if (pieces.length != 2) continue;
      if (pieces.first.trim() == key) {
        return pieces.last.trim() == '1';
      }
    }
    return defaultValue;
  }
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
  final String returnPolicyText; // ✅ NEW: Return policy printed on bill
  final String buybackPolicyText; // ✅ NEW: Buyback policy printed on bill
  final String footerMessage;

  // Section 4 — Template
  final String selectedTemplate;
  final bool printTermsAndConditions;
  final bool printReturnPolicy;
  final bool printBuybackPolicy;
  final bool printFooterMessage;

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
            'बिक्री के बाद वस्तु वापस या एक्सचेंज नहीं की जाएगी.\n'
            'Guarantee is provided as per BIS standards.\n'
            'गारंटी BIS मानकों के अनुसार दी जाएगी.\n'
            'Original bill is mandatory for any service claim.\n'
            'किसी भी सेवा दावे के लिए मूल बिल आवश्यक है.',
    this.returnPolicyText =
        'Returns accepted within 7 days with original bill only.\n'
            'रिटर्न केवल मूल बिल के साथ 7 दिनों के अंदर स्वीकार होगा.\n'
            'Exchange is subject to stock availability.\n'
            'एक्सचेंज स्टॉक उपलब्धता पर निर्भर करेगा.',
    this.buybackPolicyText =
        'Buyback is calculated at market rate after purity deduction.\n'
            'बायबैक शुद्धता कटौती के बाद बाजार दर पर calculated होगा.\n'
            'Original bill is mandatory for buyback.\n'
            'बायबैक के लिए मूल बिल आवश्यक है.',
    this.footerMessage = 'Thank you for shopping with us! Visit us again.\n'
        'खरीदारी के लिए धन्यवाद! फिर पधारें.',
    // Template
    this.selectedTemplate = 'default',
    this.printTermsAndConditions = true,
    this.printReturnPolicy = true,
    this.printBuybackPolicy = true,
    this.printFooterMessage = true,
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
              'सोने की वस्तु बिक्री के बाद वापस या एक्सचेंज नहीं की जाएगी.\n'
              'Guarantee is provided as per BIS Hallmark standards.\n'
              'गारंटी BIS Hallmark मानकों के अनुसार दी जाएगी.\n'
              'HUID is mandatory for all gold items as per Govt. norms.\n'
              'सरकारी नियमों के अनुसार सोने की वस्तु में HUID आवश्यक है.\n'
              'Original bill is mandatory for any service claim.\n'
              'किसी भी सेवा दावे के लिए मूल बिल आवश्यक है.',
          returnPolicyText:
              'Gold jewellery is eligible for exchange within 7 days with the original invoice.\n'
              'सोने की ज्वेलरी मूल बिल के साथ 7 दिनों के अंदर एक्सचेंज के लिए मान्य है.\n'
              'Used, damaged, altered or custom-made items are not eligible for return.\n'
              'उपयोग की गई, टूटी, बदली हुई या कस्टम वस्तु रिटर्न के लिए मान्य नहीं होगी.',
          buybackPolicyText:
              'Gold buyback is calculated on the current market rate after purity verification.\n'
              'सोने का बायबैक शुद्धता जांच के बाद मौजूदा बाजार दर पर calculated होगा.\n'
              'HUID/original invoice may be required for compliance and valuation.\n'
              'नियमों और मूल्यांकन के लिए HUID या मूल बिल मांगा जा सकता है.',
          footerMessage: 'Thank you for shopping with us! Visit us again.\n'
              'खरीदारी के लिए धन्यवाद! फिर पधारें.',
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
              'चांदी की वस्तु बिक्री के बाद वापस या एक्सचेंज नहीं की जाएगी.\n'
              'Exchange subject to purity verification.\n'
              'एक्सचेंज शुद्धता जांच पर निर्भर करेगा.\n'
              'Original bill is mandatory for any service claim.\n'
              'किसी भी सेवा दावे के लिए मूल बिल आवश्यक है.',
          returnPolicyText:
              'Silver items can be exchanged within 7 days with the original invoice.\n'
              'चांदी की वस्तु मूल बिल के साथ 7 दिनों के अंदर एक्सचेंज की जा सकती है.\n'
              'Tarnish, usage marks, damage or customised orders are not covered under return.\n'
              'दाग, उपयोग के निशान, टूट-फूट या कस्टम ऑर्डर रिटर्न में शामिल नहीं होंगे.',
          buybackPolicyText:
              'Silver buyback is based on current silver rate, purity test and applicable deductions.\n'
              'चांदी का बायबैक मौजूदा दर, शुद्धता जांच और लागू कटौती पर आधारित होगा.\n'
              'Original invoice is recommended for faster valuation.\n'
              'तेज मूल्यांकन के लिए मूल बिल साथ लाना बेहतर है.',
          footerMessage: 'Thank you for shopping with us! Visit us again.\n'
              'खरीदारी के लिए धन्यवाद! फिर पधारें.',
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
              'डायमंड ज्वेलरी बिक्री के बाद वापस या एक्सचेंज नहीं होगी.\n'
              'Certificate is mandatory for resale or valuation.\n'
              'रीसेल या मूल्यांकन के लिए certificate आवश्यक है.\n'
              'Diamond quality is as per certificate provided.\n'
              'डायमंड quality दिए गए certificate के अनुसार होगी.\n'
              'Original bill is mandatory for any service claim.\n'
              'किसी भी सेवा दावे के लिए मूल बिल आवश्यक है.',
          returnPolicyText:
              'Diamond jewellery is generally non-returnable after billing.\n'
              'डायमंड ज्वेलरी बिलिंग के बाद सामान्यतः non-returnable होगी.\n'
              'Exchange or upgrade requests require original invoice and certificate verification.\n'
              'एक्सचेंज या upgrade के लिए मूल बिल और certificate verification आवश्यक है.',
          buybackPolicyText:
              'Diamond buyback depends on certificate, cut, clarity, carat, condition and market demand.\n'
              'डायमंड बायबैक certificate, cut, clarity, carat, condition और market demand पर निर्भर करेगा.\n'
              'Final value is confirmed only after expert inspection.\n'
              'अंतिम मूल्य expert inspection के बाद ही तय होगा.',
          footerMessage: 'Thank you for shopping with us! Visit us again.\n'
              'खरीदारी के लिए धन्यवाद! फिर पधारें.',
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
              'प्लैटिनम वस्तु बिक्री के बाद वापस या एक्सचेंज नहीं की जाएगी.\n'
              'Purity as per Pt marking on item.\n'
              'शुद्धता वस्तु पर दिए गए Pt marking के अनुसार होगी.\n'
              'Original bill is mandatory for any service claim.\n'
              'किसी भी सेवा दावे के लिए मूल बिल आवश्यक है.',
          returnPolicyText:
              'Platinum jewellery is eligible for exchange within 7 days with the original invoice.\n'
              'प्लैटिनम ज्वेलरी मूल बिल के साथ 7 दिनों के अंदर एक्सचेंज के लिए मान्य है.\n'
              'Customised, damaged or altered items are not eligible for return.\n'
              'कस्टम, टूटी या बदली हुई वस्तु रिटर्न के लिए मान्य नहीं होगी.',
          buybackPolicyText:
              'Platinum buyback is calculated on current platinum rate after purity and weight verification.\n'
              'प्लैटिनम बायबैक शुद्धता और वजन जांच के बाद मौजूदा दर पर calculated होगा.\n'
              'Deductions may apply for testing, refining or item condition.\n'
              'Testing, refining या item condition के अनुसार कटौती लागू हो सकती है.',
          footerMessage: 'Thank you for shopping with us! Visit us again.\n'
              'खरीदारी के लिए धन्यवाद! फिर पधारें.',
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
    String? returnPolicyText,
    String? buybackPolicyText,
    String? footerMessage,
    String? selectedTemplate,
    bool? printTermsAndConditions,
    bool? printReturnPolicy,
    bool? printBuybackPolicy,
    bool? printFooterMessage,
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
      returnPolicyText: returnPolicyText ?? this.returnPolicyText,
      buybackPolicyText: buybackPolicyText ?? this.buybackPolicyText,
      footerMessage: footerMessage ?? this.footerMessage,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      printTermsAndConditions:
          printTermsAndConditions ?? this.printTermsAndConditions,
      printReturnPolicy: printReturnPolicy ?? this.printReturnPolicy,
      printBuybackPolicy: printBuybackPolicy ?? this.printBuybackPolicy,
      printFooterMessage: printFooterMessage ?? this.printFooterMessage,
    );
  }
}
