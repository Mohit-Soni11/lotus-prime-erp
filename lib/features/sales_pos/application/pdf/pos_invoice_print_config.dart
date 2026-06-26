import '../../../../models/setting/billing_setup/sales_billing_model.dart';

class BillSettings {
  bool showHuid;
  bool showPcs;
  bool showGrossWt;
  bool showLessWt;
  bool showNetWt;
  bool showPurity;
  bool showRate;
  bool showMaking;
  bool showMakingType;
  bool showAmount;
  bool showExchangeBreakdown;
  String footerMessage;
  String termsAndConditions;
  String returnPolicyText;
  String buybackPolicyText;
  bool printTermsAndConditions;
  bool printReturnPolicy;
  bool printBuybackPolicy;
  bool printFooterMessage;
  String selectedTemplate;

  BillSettings({
    this.showHuid = true,
    this.showPcs = true,
    this.showGrossWt = true,
    this.showLessWt = true,
    this.showNetWt = true,
    this.showPurity = true,
    this.showRate = true,
    this.showMaking = true,
    this.showMakingType = true,
    this.showAmount = true,
    this.showExchangeBreakdown = true,
    this.footerMessage = 'Thank you for shopping with us! Visit us again.',
    this.termsAndConditions = '',
    this.returnPolicyText = '',
    this.buybackPolicyText = '',
    this.printTermsAndConditions = false,
    this.printReturnPolicy = false,
    this.printBuybackPolicy = false,
    this.printFooterMessage = true,
    this.selectedTemplate = TemplateOptions.defaultTemplate,
  });

  factory BillSettings.fromSalesBilling(SalesBillingModel model) {
    return BillSettings(
      showHuid: model.showHuid,
      showPcs: model.showPieces,
      showGrossWt: model.showGrossWeight,
      showLessWt: model.showLessWeight,
      showNetWt: model.showNetWeight,
      showPurity: model.showPurity,
      showRate: model.showRate,
      showMaking: model.showMakingCharges,
      showMakingType: model.showMakingChargeType,
      showAmount: model.showTotalValue,
      showExchangeBreakdown: model.showOldGoldLine,
      footerMessage: model.footerMessage,
      termsAndConditions: model.termsAndConditions,
      returnPolicyText: model.returnPolicyText,
      buybackPolicyText: model.buybackPolicyText,
      printTermsAndConditions: false,
      printReturnPolicy: false,
      printBuybackPolicy: false,
      printFooterMessage: false,
      selectedTemplate: model.selectedTemplate,
    );
  }
}

class InvoicePrintConfig {
  BillSettings retailNormal = BillSettings();
  BillSettings retailGst = BillSettings();
  BillSettings wholesaleNormal = BillSettings();
  BillSettings wholesaleGst = BillSettings();
}
