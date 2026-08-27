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
  final double lateReclaimPenaltyAmount;
  final double highValueReclaimThreshold;
  final double highValueReclaimPenaltyPercent;
  final String termsAndConditions;
  final String sellerDeclarationText;
  final String returnPolicyText;
  final String buybackPolicyText;
  final String footerMessage;
  final String selectedTemplate;
  final bool printTermsAndConditions;
  final bool printSellerDeclaration;
  final bool printReturnPolicy;
  final bool printBuybackPolicy;
  final bool printFooterMessage;

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
    this.lateReclaimPenaltyAmount = 2000.0,
    this.highValueReclaimThreshold = 50000.0,
    this.highValueReclaimPenaltyPercent = 12.0,
    this.termsAndConditions = _defaultTerms,
    this.sellerDeclarationText = _defaultSellerDeclaration,
    this.returnPolicyText = _defaultReclaimPolicy,
    this.buybackPolicyText = _defaultPayoutNote,
    this.footerMessage = _defaultFooter,
    this.selectedTemplate = 'default',
    this.printTermsAndConditions = true,
    this.printSellerDeclaration = true,
    this.printReturnPolicy = true,
    this.printBuybackPolicy = true,
    this.printFooterMessage = true,
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
          lateReclaimPenaltyAmount: 2000.0,
          highValueReclaimThreshold: 50000.0,
          highValueReclaimPenaltyPercent: 12.0,
          termsAndConditions: _goldTerms,
          sellerDeclarationText: _goldSellerDeclaration,
          returnPolicyText: _goldReclaimPolicy,
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
          lateReclaimPenaltyAmount: 2000.0,
          highValueReclaimThreshold: 50000.0,
          highValueReclaimPenaltyPercent: 12.0,
          termsAndConditions: _silverTerms,
          sellerDeclarationText: _silverSellerDeclaration,
          returnPolicyText: _silverReclaimPolicy,
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
          lateReclaimPenaltyAmount: 2000.0,
          highValueReclaimThreshold: 50000.0,
          highValueReclaimPenaltyPercent: 12.0,
          termsAndConditions: _diamondTerms,
          sellerDeclarationText: _diamondSellerDeclaration,
          returnPolicyText: _diamondReclaimPolicy,
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
          lateReclaimPenaltyAmount: 2000.0,
          highValueReclaimThreshold: 50000.0,
          highValueReclaimPenaltyPercent: 12.0,
          termsAndConditions: _platinumTerms,
          sellerDeclarationText: _platinumSellerDeclaration,
          returnPolicyText: _platinumReclaimPolicy,
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
    double? lateReclaimPenaltyAmount,
    double? highValueReclaimThreshold,
    double? highValueReclaimPenaltyPercent,
    String? termsAndConditions,
    String? sellerDeclarationText,
    String? returnPolicyText,
    String? buybackPolicyText,
    String? footerMessage,
    String? selectedTemplate,
    bool? printTermsAndConditions,
    bool? printSellerDeclaration,
    bool? printReturnPolicy,
    bool? printBuybackPolicy,
    bool? printFooterMessage,
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
      lateReclaimPenaltyAmount:
          lateReclaimPenaltyAmount ?? this.lateReclaimPenaltyAmount,
      highValueReclaimThreshold:
          highValueReclaimThreshold ?? this.highValueReclaimThreshold,
      highValueReclaimPenaltyPercent:
          highValueReclaimPenaltyPercent ?? this.highValueReclaimPenaltyPercent,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      sellerDeclarationText:
          sellerDeclarationText ?? this.sellerDeclarationText,
      returnPolicyText: returnPolicyText ?? this.returnPolicyText,
      buybackPolicyText: buybackPolicyText ?? this.buybackPolicyText,
      footerMessage: footerMessage ?? this.footerMessage,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      printTermsAndConditions:
          printTermsAndConditions ?? this.printTermsAndConditions,
      printSellerDeclaration:
          printSellerDeclaration ?? this.printSellerDeclaration,
      printReturnPolicy: printReturnPolicy ?? this.printReturnPolicy,
      printBuybackPolicy: printBuybackPolicy ?? this.printBuybackPolicy,
      printFooterMessage: printFooterMessage ?? this.printFooterMessage,
    );
  }
}

const _defaultTerms =
    'Seller must submit Aadhaar or valid government ID before payout.\n'
    'Payout से पहले विक्रेता को Aadhaar या valid government ID देना आवश्यक है.\n'
    'Purchase value is calculated on verified fine weight, item condition and applicable item-wise deductions.\n'
    'खरीद मूल्य verified fine weight, item condition और applicable item-wise deductions पर calculated होगा.\n'
    'After payout, ownership of the item is transferred to the shop.\n'
    'Payout के बाद item का ownership shop को transfer माना जाएगा.';

const _defaultSellerDeclaration =
    'The seller confirms lawful ownership of the listed metal item(s), voluntary sale to the business, and acceptance of the verified weight, purity, value, payout mode and commitment date, if any.\n'
    'विक्रेता listed metal item(s) के lawful ownership, business को voluntary sale, verified weight, purity, value, payout mode और commitment date, यदि कोई हो, को स्वीकार करता/करती है.\n'
    'The seller declares that the item(s) are free from theft, dispute, pledge, loan, lien, police case or third-party claim, and accepts full responsibility for any false declaration or future claim.\n'
    'विक्रेता घोषणा करता/करती है कि item(s) theft, dispute, pledge, loan, lien, police case या third-party claim से मुक्त हैं और false declaration या future claim की पूरी जिम्मेदारी स्वीकार करता/करती है.\n'
    'After the agreed payout is released or recorded, ownership and possession rights of the item(s) stand transferred to the business.\n'
    'Agreed payout release या record होने के बाद item(s) का ownership और possession rights business को transfer माना जाएगा.';

const _defaultReclaimPolicy =
    'Seller may request return of the sold item only within 1 day from the purchase voucher date, subject to item availability.\n'
    'विक्रेता purchase voucher date से सिर्फ 1 दिन के अंदर sold item return request कर सकता/सकती है, item availability के अनुसार.\n'
    'After 1 day, the item will not be returned. If management approves an exceptional late reclaim, the configured penalty amount will be charged.\n'
    '1 दिन के बाद item return नहीं होगा. Management exceptional late reclaim approve करे तो configured penalty amount charge किया जाएगा.';

const _defaultPayoutNote =
    'Final payout is based on verified fine weight, purchase rate, item condition and applicable deductions.\n'
    'Final payout verified fine weight, purchase rate, item condition और applicable deductions पर based होगा.\n'
    'Stone, dust, wax, thread, non-metal parts, testing loss or melting loss may be deducted before payout.\n'
    'Payout से पहले stone, dust, wax, thread, non-metal parts, testing loss या melting loss deduct हो सकता है.';

const _defaultFooter =
    'Seller and business acknowledge that this purchase invoice records the verified metal valuation, payout settlement and ownership transfer.\n'
    'विक्रेता और business स्वीकार करते हैं कि यह purchase invoice verified metal valuation, payout settlement और ownership transfer का record है.';

const _goldTerms =
    'Seller must submit Aadhaar or valid government ID before gold payout.\n'
    'Gold payout से पहले विक्रेता को Aadhaar या valid government ID देना आवश्यक है.\n'
    'Gold payout is calculated on verified fine weight, condition and applicable item-wise deductions.\n'
    'Gold payout verified fine weight, condition और applicable item-wise deductions पर calculated होगा.\n'
    'After payout, ownership of the gold item is transferred to the shop.\n'
    'Payout के बाद gold item का ownership shop को transfer माना जाएगा.';

const _goldSellerDeclaration = _defaultSellerDeclaration;

const _goldReclaimPolicy = _defaultReclaimPolicy;

const _goldPayoutNote =
    'Gold payout is based on verified fine weight, purchase rate and item-wise testing or melting result.\n'
    'Gold payout verified fine weight, purchase rate और item-wise testing/melting result पर based होगा.\n'
    'Stone, beads, dust, wax, thread, testing loss or melting loss will be deducted from payable value.\n'
    'Stone, beads, dust, wax, thread, testing loss या melting loss payable value से deduct होगा.';

const _silverTerms =
    'Seller must submit Aadhaar or valid government ID before silver payout.\n'
    'Silver payout से पहले विक्रेता को Aadhaar या valid government ID देना आवश्यक है.\n'
    'Silver payout is calculated on verified fine weight, condition and applicable item-wise deductions.\n'
    'Silver payout verified fine weight, condition और applicable item-wise deductions पर calculated होगा.\n'
    'After payout, ownership of the silver item is transferred to the shop.\n'
    'Payout के बाद silver item का ownership shop को transfer माना जाएगा.';

const _silverSellerDeclaration = _defaultSellerDeclaration;

const _silverReclaimPolicy = _defaultReclaimPolicy;

const _silverPayoutNote =
    'Silver payout is based on verified fine weight, purchase rate and item-wise testing or melting result.\n'
    'Silver payout verified fine weight, purchase rate और item-wise testing/melting result पर based होगा.\n'
    'Stone, enamel, wax, dust, non-silver parts, testing loss or melting loss will be deducted from payable value.\n'
    'Stone, enamel, wax, dust, non-silver parts, testing loss या melting loss payable value से deduct होगा.';

const _diamondTerms =
    'Seller must submit Aadhaar or valid government ID before diamond payout.\n'
    'Diamond payout से पहले विक्रेता को Aadhaar या valid government ID देना आवश्यक है.\n'
    'Diamond payout is calculated after certificate, carat, clarity, cut and condition verification.\n'
    'Diamond payout certificate, carat, clarity, cut और condition verification के बाद calculated होगा.\n'
    'After payout, ownership of the diamond item is transferred to the shop.\n'
    'Payout के बाद diamond item का ownership shop को transfer माना जाएगा.';

const _diamondSellerDeclaration = _defaultSellerDeclaration;

const _diamondReclaimPolicy = _defaultReclaimPolicy;

const _diamondPayoutNote =
    'Diamond payout is based on verified stone quality, condition and agreed purchase value.\n'
    'Diamond payout verified stone quality, condition और agreed purchase value पर based होगा.\n'
    'Certificate mismatch, damage or quality variation can change the final valuation.\n'
    'Certificate mismatch, damage या quality variation final valuation बदल सकता है.';

const _platinumTerms =
    'Seller must submit Aadhaar or valid government ID before platinum payout.\n'
    'Platinum payout से पहले विक्रेता को Aadhaar या valid government ID देना आवश्यक है.\n'
    'Platinum payout is calculated on verified fine weight, condition and applicable item-wise deductions.\n'
    'Platinum payout verified fine weight, condition और applicable item-wise deductions पर calculated होगा.\n'
    'After payout, ownership of the platinum item is transferred to the shop.\n'
    'Payout के बाद platinum item का ownership shop को transfer माना जाएगा.';

const _platinumSellerDeclaration = _defaultSellerDeclaration;

const _platinumReclaimPolicy = _defaultReclaimPolicy;

const _platinumPayoutNote =
    'Platinum payout is based on verified fine weight, purchase rate and item-wise testing or melting result.\n'
    'Platinum payout verified fine weight, purchase rate और item-wise testing/melting result पर based होगा.\n'
    'Non-platinum parts, stones, testing loss, melting loss or condition-based deduction will be deducted from payable value.\n'
    'Non-platinum parts, stones, testing loss, melting loss या condition-based deduction payable value से deduct होगा.';
