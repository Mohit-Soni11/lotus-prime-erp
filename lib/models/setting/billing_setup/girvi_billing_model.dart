import 'dart:convert';

class GirviBillingModel {
  final String girviPrefix;
  final int startingNumber;
  final double defaultInterestRate;
  final String interestType;
  final int gracePeriodDays;
  final String defaultDuration;
  final int reminderDays;
  final int noticeDays;
  final String termsAndConditions;
  final String footerMessage;
  final bool autoPrint;
  final String selectedTemplate;

  final bool showMetal;
  final bool showPieces;
  final bool showGrossWeight;
  final bool showLessWeight;
  final bool showNetWeight;
  final bool showPurity;
  final bool showValuationPurity;
  final bool showFineWeight;
  final bool showRate;
  final bool showHuid;
  final bool showTotalValue;
  final bool showItemPhotos;
  final bool showKycDetails;
  final bool showDisbursementDetails;
  final bool printTermsAndConditions;
  final bool printFooterMessage;

  const GirviBillingModel({
    this.girviPrefix = 'GRV-',
    this.startingNumber = 1,
    this.defaultInterestRate = 1.5,
    this.interestType = 'Simple',
    this.gracePeriodDays = 3,
    this.defaultDuration = '6 Months',
    this.reminderDays = 15,
    this.noticeDays = 30,
    this.termsAndConditions =
        'Interest will be charged per month on the loan amount.\n'
            'Unclaimed ornaments after notice period will be auctioned as per law.\n'
            'Customer is responsible for timely repayment.',
    this.footerMessage = '',
    this.autoPrint = true,
    this.selectedTemplate = 'default',
    this.showMetal = true,
    this.showPieces = true,
    this.showGrossWeight = true,
    this.showLessWeight = true,
    this.showNetWeight = true,
    this.showPurity = true,
    this.showValuationPurity = false,
    this.showFineWeight = false,
    this.showRate = false,
    this.showHuid = true,
    this.showTotalValue = false,
    this.showItemPhotos = true,
    this.showKycDetails = false,
    this.showDisbursementDetails = false,
    this.printTermsAndConditions = false,
    this.printFooterMessage = false,
  });

  static GirviBillingModel get defaults => const GirviBillingModel();

  int get visibleInvoiceFieldCount => 9;

  GirviBillingModel copyWith({
    String? girviPrefix,
    int? startingNumber,
    double? defaultInterestRate,
    String? interestType,
    int? gracePeriodDays,
    String? defaultDuration,
    int? reminderDays,
    int? noticeDays,
    String? termsAndConditions,
    String? footerMessage,
    bool? autoPrint,
    String? selectedTemplate,
    bool? showMetal,
    bool? showPieces,
    bool? showGrossWeight,
    bool? showLessWeight,
    bool? showNetWeight,
    bool? showPurity,
    bool? showValuationPurity,
    bool? showFineWeight,
    bool? showRate,
    bool? showHuid,
    bool? showTotalValue,
    bool? showItemPhotos,
    bool? showKycDetails,
    bool? showDisbursementDetails,
    bool? printTermsAndConditions,
    bool? printFooterMessage,
  }) {
    return GirviBillingModel(
      girviPrefix: girviPrefix ?? this.girviPrefix,
      startingNumber: startingNumber ?? this.startingNumber,
      defaultInterestRate: defaultInterestRate ?? this.defaultInterestRate,
      interestType: interestType ?? this.interestType,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      reminderDays: reminderDays ?? this.reminderDays,
      noticeDays: noticeDays ?? this.noticeDays,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      footerMessage: footerMessage ?? this.footerMessage,
      autoPrint: autoPrint ?? this.autoPrint,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      showMetal: showMetal ?? this.showMetal,
      showPieces: showPieces ?? this.showPieces,
      showGrossWeight: showGrossWeight ?? this.showGrossWeight,
      showLessWeight: showLessWeight ?? this.showLessWeight,
      showNetWeight: showNetWeight ?? this.showNetWeight,
      showPurity: showPurity ?? this.showPurity,
      showValuationPurity: showValuationPurity ?? this.showValuationPurity,
      showFineWeight: showFineWeight ?? this.showFineWeight,
      showRate: showRate ?? this.showRate,
      showHuid: showHuid ?? this.showHuid,
      showTotalValue: showTotalValue ?? this.showTotalValue,
      showItemPhotos: showItemPhotos ?? this.showItemPhotos,
      showKycDetails: showKycDetails ?? this.showKycDetails,
      showDisbursementDetails:
          showDisbursementDetails ?? this.showDisbursementDetails,
      printTermsAndConditions:
          printTermsAndConditions ?? this.printTermsAndConditions,
      printFooterMessage: printFooterMessage ?? this.printFooterMessage,
    );
  }
}

class GirviBillingTemplateOptions {
  GirviBillingTemplateOptions._();

  static String encode(GirviBillingModel model) {
    return jsonEncode({
      'version': 1,
      'template': model.selectedTemplate,
      'invoice': {
        'metal': model.showMetal,
        'pieces': model.showPieces,
        'grossWeight': model.showGrossWeight,
        'lessWeight': model.showLessWeight,
        'netWeight': model.showNetWeight,
        'purity': model.showPurity,
        'valuationPurity': model.showValuationPurity,
        'fineWeight': model.showFineWeight,
        'rate': model.showRate,
        'huid': model.showHuid,
        'totalValue': model.showTotalValue,
        'itemPhotos': model.showItemPhotos,
        'kycDetails': model.showKycDetails,
        'disbursementDetails': model.showDisbursementDetails,
        'printTerms': model.printTermsAndConditions,
        'printFooter': model.printFooterMessage,
      },
    });
  }

  static GirviBillingModel apply(
    GirviBillingModel base,
    String storedValue,
  ) {
    if (!storedValue.trimLeft().startsWith('{')) {
      return base.copyWith(selectedTemplate: storedValue);
    }

    try {
      final decoded = jsonDecode(storedValue);
      if (decoded is! Map<String, dynamic>) return base;
      final invoice = decoded['invoice'];
      if (invoice is! Map<String, dynamic>) return base;

      bool read(String key, bool fallback) {
        final value = invoice[key];
        return value is bool ? value : fallback;
      }

      return base.copyWith(
        selectedTemplate:
            decoded['template']?.toString() ?? base.selectedTemplate,
        showMetal: read('metal', base.showMetal),
        showPieces: read('pieces', base.showPieces),
        showGrossWeight: read('grossWeight', base.showGrossWeight),
        showLessWeight: read('lessWeight', base.showLessWeight),
        showNetWeight: read('netWeight', base.showNetWeight),
        showPurity: read('purity', base.showPurity),
        showValuationPurity: read('valuationPurity', base.showValuationPurity),
        showFineWeight: read('fineWeight', base.showFineWeight),
        showRate: read('rate', base.showRate),
        showHuid: read('huid', base.showHuid),
        showTotalValue: read('totalValue', base.showTotalValue),
        showItemPhotos: read('itemPhotos', base.showItemPhotos),
        showKycDetails: read('kycDetails', base.showKycDetails),
        showDisbursementDetails:
            read('disbursementDetails', base.showDisbursementDetails),
        printTermsAndConditions:
            read('printTerms', base.printTermsAndConditions),
        printFooterMessage: read('printFooter', base.printFooterMessage),
      );
    } catch (_) {
      return base;
    }
  }
}
