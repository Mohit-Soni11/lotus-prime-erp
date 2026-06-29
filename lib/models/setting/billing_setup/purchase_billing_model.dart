import 'sales_billing_model.dart';

class PurchaseBillingModel {
  final String metal;
  final bool showGrossWeight;
  final bool showLessWeight;
  final bool showNetWeight;
  final bool showPurity;
  final bool showRate;
  final bool showFineWeight;
  final bool showTotalValue;
  final bool showStoneDetails;
  final bool showStoneValue;
  final bool showHuid;
  final bool showSupplierDetails;
  final bool showPanNumber;
  final bool showDiamondCarats;
  final bool showDiamondClarity;
  final bool showCertificationNo;
  final bool showGstBreakup;
  final bool showHsnCode;
  final int returnWindowDays;
  final String returnMode;
  final double purityDeductPercent;
  final String termsAndConditions;
  final String returnPolicyText;
  final String buybackPolicyText;
  final String footerMessage;
  final String selectedTemplate;

  const PurchaseBillingModel({
    required this.metal,
    this.showGrossWeight = true,
    this.showLessWeight = true,
    this.showNetWeight = true,
    this.showPurity = true,
    this.showRate = true,
    this.showFineWeight = true,
    this.showTotalValue = true,
    this.showStoneDetails = false,
    this.showStoneValue = false,
    this.showHuid = false,
    this.showSupplierDetails = true,
    this.showPanNumber = true,
    this.showDiamondCarats = true,
    this.showDiamondClarity = true,
    this.showCertificationNo = false,
    this.showGstBreakup = false,
    this.showHsnCode = false,
    this.returnWindowDays = 1,
    this.returnMode = PurchaseReturnModeOptions.cashRefund,
    this.purityDeductPercent = 2.0,
    this.termsAndConditions = _defaultTerms,
    this.returnPolicyText = _defaultVerificationNote,
    this.buybackPolicyText = _defaultPayoutNote,
    this.footerMessage = _defaultFooter,
    this.selectedTemplate = 'default',
  });

  factory PurchaseBillingModel.defaultFor(String metal) {
    switch (metal) {
      case BillingMetal.gold:
        return PurchaseBillingModel(
          metal: metal,
          showGrossWeight: true,
          showLessWeight: true,
          showNetWeight: true,
          showPurity: true,
          showRate: true,
          showFineWeight: true,
          showTotalValue: true,
          showHuid: true,
          showSupplierDetails: true,
          showPanNumber: true,
          showGstBreakup: false,
          returnWindowDays: 1,
          returnMode: PurchaseReturnModeOptions.cashRefund,
          purityDeductPercent: 2.0,
          termsAndConditions: _goldTerms,
          returnPolicyText: _goldVerificationNote,
          buybackPolicyText: _goldPayoutNote,
          footerMessage: _defaultFooter,
        );

      case BillingMetal.silver:
        return PurchaseBillingModel(
          metal: metal,
          showGrossWeight: true,
          showLessWeight: true,
          showNetWeight: true,
          showPurity: true,
          showRate: true,
          showFineWeight: true,
          showTotalValue: true,
          showHuid: false,
          showSupplierDetails: true,
          showPanNumber: true,
          returnWindowDays: 1,
          returnMode: PurchaseReturnModeOptions.cashRefund,
          purityDeductPercent: 3.0,
          termsAndConditions: _silverTerms,
          returnPolicyText: _silverVerificationNote,
          buybackPolicyText: _silverPayoutNote,
          footerMessage: _defaultFooter,
        );

      case BillingMetal.diamond:
        return PurchaseBillingModel(
          metal: metal,
          showGrossWeight: false,
          showLessWeight: false,
          showNetWeight: false,
          showPurity: false,
          showRate: true,
          showFineWeight: false,
          showTotalValue: true,
          showStoneDetails: true,
          showStoneValue: true,
          showDiamondCarats: true,
          showDiamondClarity: true,
          showCertificationNo: true,
          showSupplierDetails: true,
          showPanNumber: true,
          returnWindowDays: 1,
          returnMode: PurchaseReturnModeOptions.cashRefund,
          purityDeductPercent: 5.0,
          termsAndConditions: _diamondTerms,
          returnPolicyText: _diamondVerificationNote,
          buybackPolicyText: _diamondPayoutNote,
          footerMessage: _defaultFooter,
        );

      case BillingMetal.platinum:
        return PurchaseBillingModel(
          metal: metal,
          showGrossWeight: true,
          showLessWeight: true,
          showNetWeight: true,
          showPurity: true,
          showRate: true,
          showFineWeight: true,
          showTotalValue: true,
          showHuid: false,
          showSupplierDetails: true,
          showPanNumber: true,
          returnWindowDays: 1,
          returnMode: PurchaseReturnModeOptions.cashRefund,
          purityDeductPercent: 2.0,
          termsAndConditions: _platinumTerms,
          returnPolicyText: _platinumVerificationNote,
          buybackPolicyText: _platinumPayoutNote,
          footerMessage: _defaultFooter,
        );

      default:
        return PurchaseBillingModel(metal: metal);
    }
  }

  PurchaseBillingModel copyWith({
    bool? showGrossWeight,
    bool? showLessWeight,
    bool? showNetWeight,
    bool? showPurity,
    bool? showRate,
    bool? showFineWeight,
    bool? showTotalValue,
    bool? showStoneDetails,
    bool? showStoneValue,
    bool? showHuid,
    bool? showSupplierDetails,
    bool? showPanNumber,
    bool? showDiamondCarats,
    bool? showDiamondClarity,
    bool? showCertificationNo,
    bool? showGstBreakup,
    bool? showHsnCode,
    int? returnWindowDays,
    String? returnMode,
    double? purityDeductPercent,
    String? termsAndConditions,
    String? returnPolicyText,
    String? buybackPolicyText,
    String? footerMessage,
    String? selectedTemplate,
  }) {
    return PurchaseBillingModel(
      metal: metal,
      showGrossWeight: showGrossWeight ?? this.showGrossWeight,
      showLessWeight: showLessWeight ?? this.showLessWeight,
      showNetWeight: showNetWeight ?? this.showNetWeight,
      showPurity: showPurity ?? this.showPurity,
      showRate: showRate ?? this.showRate,
      showFineWeight: showFineWeight ?? this.showFineWeight,
      showTotalValue: showTotalValue ?? this.showTotalValue,
      showStoneDetails: showStoneDetails ?? this.showStoneDetails,
      showStoneValue: showStoneValue ?? this.showStoneValue,
      showHuid: showHuid ?? this.showHuid,
      showSupplierDetails: showSupplierDetails ?? this.showSupplierDetails,
      showPanNumber: showPanNumber ?? this.showPanNumber,
      showDiamondCarats: showDiamondCarats ?? this.showDiamondCarats,
      showDiamondClarity: showDiamondClarity ?? this.showDiamondClarity,
      showCertificationNo: showCertificationNo ?? this.showCertificationNo,
      showGstBreakup: showGstBreakup ?? this.showGstBreakup,
      showHsnCode: showHsnCode ?? this.showHsnCode,
      returnWindowDays: returnWindowDays ?? this.returnWindowDays,
      returnMode: returnMode ?? this.returnMode,
      purityDeductPercent: purityDeductPercent ?? this.purityDeductPercent,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      returnPolicyText: returnPolicyText ?? this.returnPolicyText,
      buybackPolicyText: buybackPolicyText ?? this.buybackPolicyText,
      footerMessage: footerMessage ?? this.footerMessage,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
    );
  }
}

const _defaultTerms = 'Seller confirms legal ownership of the jewellery.\n'
    'विक्रेता पुष्टि करता है कि आभूषण उसका वैध स्वामित्व है.\n'
    'Valid identity proof is required before payout.\n'
    'भुगतान से पहले valid identity proof आवश्यक है.\n'
    'Once payment is completed, the purchase is treated as final.\n'
    'भुगतान पूरा होने के बाद purchase final माना जाएगा.';

const _defaultVerificationNote =
    'Final acceptance is subject to KYC, weight, purity and ownership verification.\n'
    'अंतिम स्वीकृति KYC, वजन, शुद्धता और स्वामित्व जांच के बाद होगी.';

const _defaultPayoutNote =
    'Purchase value is calculated on verified net weight, purity and live purchase rate.\n'
    'खरीद मूल्य verified net weight, शुद्धता और live purchase rate के आधार पर calculated होगा.\n'
    'Testing, melting, stone, dust or impurity deductions may apply before payout.\n'
    'Payout से पहले testing, melting, stone, dust या impurity deduction लागू हो सकती है.';

const _defaultFooter = 'Thank you for trusting us.\n'
    'हम पर भरोसा करने के लिए धन्यवाद.';

const _goldTerms =
    'Seller must provide valid ID and ownership confirmation for gold purchase.\n'
    'Gold purchase के लिए विक्रेता को valid ID और ownership confirmation देना आवश्यक है.\n'
    'Hallmark, HUID, weight and purity will be verified before payout.\n'
    'Payout से पहले hallmark, HUID, वजन और शुद्धता verify की जाएगी.\n'
    'Once payment is completed, the purchase is treated as final.\n'
    'भुगतान पूरा होने के बाद purchase final माना जाएगा.';

const _goldVerificationNote =
    'Gold ornaments are accepted only after weight, purity and ownership verification.\n'
    'Gold ornaments वजन, शुद्धता और ownership verification के बाद ही स्वीकार होंगे.\n'
    'Stones, beads, dust, wax, thread or non-gold parts will be deducted from payable weight.\n'
    'Stone, beads, dust, wax, thread या non-gold parts payable weight से deduct किए जाएंगे.';

const _goldPayoutNote =
    'Gold payout is based on verified fine weight, live purchase rate and approved deductions.\n'
    'Gold payout verified fine weight, live purchase rate और approved deductions पर based होगा.\n'
    'Testing, melting or refining deductions may apply before final settlement.\n'
    'Final settlement से पहले testing, melting या refining deduction लागू हो सकती है.';

const _silverTerms =
    'Seller must provide valid ID and ownership confirmation for silver purchase.\n'
    'Silver purchase के लिए विक्रेता को valid ID और ownership confirmation देना आवश्यक है.\n'
    'Weight and purity will be verified before payout.\n'
    'Payout से पहले वजन और शुद्धता verify की जाएगी.\n'
    'Once payment is completed, the purchase is treated as final.\n'
    'भुगतान पूरा होने के बाद purchase final माना जाएगा.';

const _silverVerificationNote =
    'Silver items are accepted only after weight, purity and condition verification.\n'
    'Silver items वजन, शुद्धता और condition verification के बाद ही स्वीकार होंगे.\n'
    'Stone, enamel, wax, dust or non-silver parts will be deducted from payable weight.\n'
    'Stone, enamel, wax, dust या non-silver parts payable weight से deduct किए जाएंगे.';

const _silverPayoutNote =
    'Silver payout is based on verified net weight, purity and live silver purchase rate.\n'
    'Silver payout verified net weight, शुद्धता और live silver purchase rate पर based होगा.\n'
    'Testing, melting or refining deductions may apply before final settlement.\n'
    'Final settlement से पहले testing, melting या refining deduction लागू हो सकती है.';

const _diamondTerms =
    'Seller must provide valid ID and ownership confirmation for diamond purchase.\n'
    'Diamond purchase के लिए विक्रेता को valid ID और ownership confirmation देना आवश्यक है.\n'
    'Certificate, carat, clarity, cut and condition will be verified before payout.\n'
    'Payout से पहले certificate, carat, clarity, cut और condition verify किए जाएंगे.\n'
    'Once payment is completed, the purchase is treated as final.\n'
    'भुगतान पूरा होने के बाद purchase final माना जाएगा.';

const _diamondVerificationNote =
    'Diamond purchase acceptance depends on certificate, carat, clarity and expert inspection.\n'
    'Diamond purchase acceptance certificate, carat, clarity और expert inspection पर निर्भर करेगी.\n'
    'Mismatch in certificate, damage or quality variation can change the final valuation.\n'
    'Certificate mismatch, damage या quality variation final valuation बदल सकता है.';

const _diamondPayoutNote =
    'Diamond payout is based on verified stone quality, condition and agreed purchase value.\n'
    'Diamond payout verified stone quality, condition और agreed purchase value पर based होगा.\n'
    'Final valuation is confirmed only after expert inspection.\n'
    'Final valuation expert inspection के बाद ही confirm होगी.';

const _platinumTerms =
    'Seller must provide valid ID and ownership confirmation for platinum purchase.\n'
    'Platinum purchase के लिए विक्रेता को valid ID और ownership confirmation देना आवश्यक है.\n'
    'Weight, purity and condition will be verified before payout.\n'
    'Payout से पहले वजन, शुद्धता और condition verify की जाएगी.\n'
    'Once payment is completed, the purchase is treated as final.\n'
    'भुगतान पूरा होने के बाद purchase final माना जाएगा.';

const _platinumVerificationNote =
    'Platinum items are accepted only after weight, purity and condition verification.\n'
    'Platinum items वजन, शुद्धता और condition verification के बाद ही स्वीकार होंगे.\n'
    'Non-platinum parts, stones or damage will be deducted from payable value.\n'
    'Non-platinum parts, stones या damage payable value से deduct किए जाएंगे.';

const _platinumPayoutNote =
    'Platinum payout is based on verified net weight, purity and live platinum purchase rate.\n'
    'Platinum payout verified net weight, शुद्धता और live platinum purchase rate पर based होगा.\n'
    'Testing, melting or condition-based deductions may apply before final settlement.\n'
    'Final settlement से पहले testing, melting या condition-based deduction लागू हो सकती है.';
