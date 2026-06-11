import 'dart:convert';

class GirviBillingMetal {
  GirviBillingMetal._();

  static const gold = 'gold';
  static const silver = 'silver';
  static const diamond = 'diamond';
  static const platinum = 'platinum';
  static const other = 'other';

  static const supported = [gold, silver, diamond, platinum];

  static String normalize(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('gold')) return gold;
    if (normalized.contains('silver')) return silver;
    if (normalized.contains('diamond')) return diamond;
    if (normalized.contains('platinum')) return platinum;
    return other;
  }

  static String displayName(String metal) {
    switch (normalize(metal)) {
      case gold:
        return 'Gold';
      case silver:
        return 'Silver';
      case diamond:
        return 'Diamond';
      case platinum:
        return 'Platinum';
      default:
        return 'Other';
    }
  }
}

class GirviInvoiceFieldSettings {
  final bool showSerialNumber;
  final bool showMetal;
  final bool showItemName;
  final bool showPieces;
  final bool showHuid;
  final bool showPurity;
  final bool showGrossWeight;
  final bool showLessWeight;
  final bool showNetWeight;
  final bool showValuationPurity;
  final bool showFineWeight;
  final bool showRatePerGram;
  final bool showValuationAmount;
  final bool showItemPhotos;

  const GirviInvoiceFieldSettings({
    this.showSerialNumber = true,
    this.showMetal = true,
    this.showItemName = true,
    this.showPieces = true,
    this.showHuid = true,
    this.showPurity = true,
    this.showGrossWeight = true,
    this.showLessWeight = true,
    this.showNetWeight = true,
    this.showValuationPurity = false,
    this.showFineWeight = false,
    this.showRatePerGram = false,
    this.showValuationAmount = false,
    this.showItemPhotos = true,
  });

  factory GirviInvoiceFieldSettings.defaultFor(String metal) {
    final normalized = GirviBillingMetal.normalize(metal);
    return GirviInvoiceFieldSettings(
      showHuid: normalized == GirviBillingMetal.gold,
    );
  }

  int get activeFieldCount => [
        showSerialNumber,
        showMetal,
        showItemName,
        showPieces,
        showHuid,
        showPurity,
        showGrossWeight,
        showLessWeight,
        showNetWeight,
        showValuationPurity,
        showFineWeight,
        showRatePerGram,
        showValuationAmount,
        showItemPhotos,
      ].where((value) => value).length;

  GirviInvoiceFieldSettings copyWith({
    bool? showSerialNumber,
    bool? showMetal,
    bool? showItemName,
    bool? showPieces,
    bool? showHuid,
    bool? showPurity,
    bool? showGrossWeight,
    bool? showLessWeight,
    bool? showNetWeight,
    bool? showValuationPurity,
    bool? showFineWeight,
    bool? showRatePerGram,
    bool? showValuationAmount,
    bool? showItemPhotos,
  }) {
    return GirviInvoiceFieldSettings(
      showSerialNumber: showSerialNumber ?? this.showSerialNumber,
      showMetal: showMetal ?? this.showMetal,
      showItemName: showItemName ?? this.showItemName,
      showPieces: showPieces ?? this.showPieces,
      showHuid: showHuid ?? this.showHuid,
      showPurity: showPurity ?? this.showPurity,
      showGrossWeight: showGrossWeight ?? this.showGrossWeight,
      showLessWeight: showLessWeight ?? this.showLessWeight,
      showNetWeight: showNetWeight ?? this.showNetWeight,
      showValuationPurity: showValuationPurity ?? this.showValuationPurity,
      showFineWeight: showFineWeight ?? this.showFineWeight,
      showRatePerGram: showRatePerGram ?? this.showRatePerGram,
      showValuationAmount: showValuationAmount ?? this.showValuationAmount,
      showItemPhotos: showItemPhotos ?? this.showItemPhotos,
    );
  }

  Map<String, bool> toJson() => {
        'serialNumber': showSerialNumber,
        'metal': showMetal,
        'itemName': showItemName,
        'pieces': showPieces,
        'huid': showHuid,
        'purity': showPurity,
        'grossWeight': showGrossWeight,
        'lessWeight': showLessWeight,
        'netWeight': showNetWeight,
        'valuationPurity': showValuationPurity,
        'fineWeight': showFineWeight,
        'ratePerGram': showRatePerGram,
        'valuationAmount': showValuationAmount,
        'itemPhotos': showItemPhotos,
      };

  factory GirviInvoiceFieldSettings.fromJson(
    Object? value, {
    required GirviInvoiceFieldSettings fallback,
  }) {
    if (value is! Map) return fallback;

    bool read(String key, bool defaultValue) {
      final resolved = value[key];
      return resolved is bool ? resolved : defaultValue;
    }

    return fallback.copyWith(
      showSerialNumber: read('serialNumber', fallback.showSerialNumber),
      showMetal: read('metal', fallback.showMetal),
      showItemName: read('itemName', fallback.showItemName),
      showPieces: read('pieces', fallback.showPieces),
      showHuid: read('huid', fallback.showHuid),
      showPurity: read('purity', fallback.showPurity),
      showGrossWeight: read('grossWeight', fallback.showGrossWeight),
      showLessWeight: read('lessWeight', fallback.showLessWeight),
      showNetWeight: read('netWeight', fallback.showNetWeight),
      showValuationPurity:
          read('valuationPurity', fallback.showValuationPurity),
      showFineWeight: read('fineWeight', fallback.showFineWeight),
      showRatePerGram: read('ratePerGram', fallback.showRatePerGram),
      showValuationAmount:
          read('valuationAmount', fallback.showValuationAmount),
      showItemPhotos: read('itemPhotos', fallback.showItemPhotos),
    );
  }
}

class GirviBillingModel {
  static const defaultFooterMessage = 'Please keep this Girvi receipt safely.';

  final String girviPrefix;
  final int startingNumber;
  final double defaultInterestRate;
  final String interestType;
  final int gracePeriodDays;
  final String defaultDuration;
  final int reminderDays;
  final int noticeDays;
  final String termsAndConditions;
  final String termsAndConditionsHindi;
  final String customerDeclaration;
  final String customerDeclarationHindi;
  final String footerMessage;
  final bool autoPrint;
  final String selectedTemplate;
  final Map<String, GirviInvoiceFieldSettings> metalInvoiceSettings;

  // Legacy fields are retained for older saved setup payloads and callers.
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
  final bool showKycPhoto;
  final bool showCustomerMobile;
  final bool showCustomerCity;
  final bool showLoanAmount;
  final bool showInterestRate;
  final bool showDuration;
  final bool showStartDate;
  final bool showMaturityDate;
  final bool showMonthlyInterest;
  final bool showTotalInterest;
  final bool showTotalDue;
  final bool showDisbursementDetails;
  final bool showNotes;
  final bool printTermsAndConditions;
  final bool printCustomerDeclaration;
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
    this.termsAndConditionsHindi = 'ऋण राशि पर ब्याज प्रति माह लिया जाएगा।\n'
        'नोटिस अवधि के बाद न छुड़ाए गए आभूषणों की नीलामी लागू कानून के अनुसार की जा सकती है।\n'
        'ग्राहक समय पर भुगतान और ऋण छुड़ाने के लिए जिम्मेदार है।',
    this.customerDeclaration =
        'I declare that the pledged articles belong to me, are free from dispute, and the information provided by me is true. '
            'I have verified the item details, loan amount and interest terms, and have received the stated disbursement.',
    this.customerDeclarationHindi =
        'मैं घोषणा करता/करती हूं कि गिरवी रखी गई वस्तुएं मेरी हैं, किसी विवाद से मुक्त हैं और मेरे द्वारा दी गई जानकारी सत्य है। '
            'मैंने वस्तुओं का विवरण, ऋण राशि और ब्याज की शर्तें जांच ली हैं तथा बताई गई भुगतान राशि प्राप्त कर ली है।',
    this.footerMessage = defaultFooterMessage,
    this.autoPrint = true,
    this.selectedTemplate = 'default',
    this.metalInvoiceSettings = const {},
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
    this.showKycPhoto = false,
    this.showCustomerMobile = true,
    this.showCustomerCity = true,
    this.showLoanAmount = true,
    this.showInterestRate = true,
    this.showDuration = false,
    this.showStartDate = false,
    this.showMaturityDate = false,
    this.showMonthlyInterest = false,
    this.showTotalInterest = false,
    this.showTotalDue = false,
    this.showDisbursementDetails = false,
    this.showNotes = false,
    this.printTermsAndConditions = false,
    this.printCustomerDeclaration = true,
    this.printFooterMessage = true,
  });

  static GirviBillingModel get defaults => const GirviBillingModel();

  GirviInvoiceFieldSettings settingsForMetal(String metal) {
    final key = GirviBillingMetal.normalize(metal);
    return metalInvoiceSettings[key] ??
        GirviInvoiceFieldSettings.defaultFor(key);
  }

  int get visibleInvoiceFieldCount =>
      settingsForMetal(GirviBillingMetal.gold).activeFieldCount;

  int get visibleDocumentFieldCount => [
        showCustomerMobile,
        showCustomerCity,
        showLoanAmount,
        showInterestRate,
        showDuration,
        showStartDate,
        showMaturityDate,
        showMonthlyInterest,
        showTotalInterest,
        showTotalDue,
        showTotalValue,
        showDisbursementDetails,
        showKycDetails,
        showKycPhoto,
        showNotes,
        printTermsAndConditions,
        printCustomerDeclaration,
        printFooterMessage,
      ].where((value) => value).length;

  GirviBillingModel withMetalSettings(
    String metal,
    GirviInvoiceFieldSettings settings,
  ) {
    final updated = Map<String, GirviInvoiceFieldSettings>.from(
      metalInvoiceSettings,
    );
    updated[GirviBillingMetal.normalize(metal)] = settings;
    return copyWith(metalInvoiceSettings: updated);
  }

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
    String? termsAndConditionsHindi,
    String? customerDeclaration,
    String? customerDeclarationHindi,
    String? footerMessage,
    bool? autoPrint,
    String? selectedTemplate,
    Map<String, GirviInvoiceFieldSettings>? metalInvoiceSettings,
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
    bool? showKycPhoto,
    bool? showCustomerMobile,
    bool? showCustomerCity,
    bool? showLoanAmount,
    bool? showInterestRate,
    bool? showDuration,
    bool? showStartDate,
    bool? showMaturityDate,
    bool? showMonthlyInterest,
    bool? showTotalInterest,
    bool? showTotalDue,
    bool? showDisbursementDetails,
    bool? showNotes,
    bool? printTermsAndConditions,
    bool? printCustomerDeclaration,
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
      termsAndConditionsHindi:
          termsAndConditionsHindi ?? this.termsAndConditionsHindi,
      customerDeclaration: customerDeclaration ?? this.customerDeclaration,
      customerDeclarationHindi:
          customerDeclarationHindi ?? this.customerDeclarationHindi,
      footerMessage: footerMessage ?? this.footerMessage,
      autoPrint: autoPrint ?? this.autoPrint,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      metalInvoiceSettings: metalInvoiceSettings ?? this.metalInvoiceSettings,
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
      showKycPhoto: showKycPhoto ?? this.showKycPhoto,
      showCustomerMobile: showCustomerMobile ?? this.showCustomerMobile,
      showCustomerCity: showCustomerCity ?? this.showCustomerCity,
      showLoanAmount: showLoanAmount ?? this.showLoanAmount,
      showInterestRate: showInterestRate ?? this.showInterestRate,
      showDuration: showDuration ?? this.showDuration,
      showStartDate: showStartDate ?? this.showStartDate,
      showMaturityDate: showMaturityDate ?? this.showMaturityDate,
      showMonthlyInterest: showMonthlyInterest ?? this.showMonthlyInterest,
      showTotalInterest: showTotalInterest ?? this.showTotalInterest,
      showTotalDue: showTotalDue ?? this.showTotalDue,
      showDisbursementDetails:
          showDisbursementDetails ?? this.showDisbursementDetails,
      showNotes: showNotes ?? this.showNotes,
      printTermsAndConditions:
          printTermsAndConditions ?? this.printTermsAndConditions,
      printCustomerDeclaration:
          printCustomerDeclaration ?? this.printCustomerDeclaration,
      printFooterMessage: printFooterMessage ?? this.printFooterMessage,
    );
  }
}

class GirviBillingTemplateOptions {
  GirviBillingTemplateOptions._();

  static String encode(GirviBillingModel model) {
    final metals = <String, Object>{
      for (final metal in GirviBillingMetal.supported)
        metal: model.settingsForMetal(metal).toJson(),
    };
    if (model.metalInvoiceSettings.containsKey(GirviBillingMetal.other)) {
      metals[GirviBillingMetal.other] =
          model.settingsForMetal(GirviBillingMetal.other).toJson();
    }

    return jsonEncode({
      'version': 4,
      'template': model.selectedTemplate,
      'metals': metals,
      'document': {
        'customerMobile': model.showCustomerMobile,
        'customerCity': model.showCustomerCity,
        'loanAmount': model.showLoanAmount,
        'interestRate': model.showInterestRate,
        'duration': model.showDuration,
        'startDate': model.showStartDate,
        'maturityDate': model.showMaturityDate,
        'monthlyInterest': model.showMonthlyInterest,
        'totalInterest': model.showTotalInterest,
        'totalDue': model.showTotalDue,
        'totalValuation': model.showTotalValue,
        'disbursementDetails': model.showDisbursementDetails,
        'kycDetails': model.showKycDetails,
        'kycPhoto': model.showKycPhoto,
        'notes': model.showNotes,
        'printTerms': model.printTermsAndConditions,
        'printDeclaration': model.printCustomerDeclaration,
        'printFooter': model.printFooterMessage,
      },
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
        'printDeclaration': model.printCustomerDeclaration,
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
      final document = decoded['document'];

      bool readLegacy(String key, bool fallback) {
        if (invoice is! Map<String, dynamic>) return fallback;
        final value = invoice[key];
        return value is bool ? value : fallback;
      }

      bool readDocument(String key, bool fallback) {
        if (document is! Map<String, dynamic>) return fallback;
        final value = document[key];
        return value is bool ? value : fallback;
      }

      final legacyApplied = base.copyWith(
        selectedTemplate:
            decoded['template']?.toString() ?? base.selectedTemplate,
        showMetal: readLegacy('metal', base.showMetal),
        showPieces: readLegacy('pieces', base.showPieces),
        showGrossWeight: readLegacy('grossWeight', base.showGrossWeight),
        showLessWeight: readLegacy('lessWeight', base.showLessWeight),
        showNetWeight: readLegacy('netWeight', base.showNetWeight),
        showPurity: readLegacy('purity', base.showPurity),
        showValuationPurity:
            readLegacy('valuationPurity', base.showValuationPurity),
        showFineWeight: readLegacy('fineWeight', base.showFineWeight),
        showRate: readLegacy('rate', base.showRate),
        showHuid: readLegacy('huid', base.showHuid),
        showItemPhotos: readLegacy('itemPhotos', base.showItemPhotos),
        showKycDetails: readDocument(
          'kycDetails',
          readLegacy('kycDetails', base.showKycDetails),
        ),
        showKycPhoto: readDocument('kycPhoto', base.showKycPhoto),
        showCustomerMobile:
            readDocument('customerMobile', base.showCustomerMobile),
        showCustomerCity: readDocument('customerCity', base.showCustomerCity),
        showLoanAmount: readDocument('loanAmount', base.showLoanAmount),
        showInterestRate: readDocument('interestRate', base.showInterestRate),
        showDuration: readDocument('duration', base.showDuration),
        showStartDate: readDocument('startDate', base.showStartDate),
        showMaturityDate: readDocument('maturityDate', base.showMaturityDate),
        showMonthlyInterest:
            readDocument('monthlyInterest', base.showMonthlyInterest),
        showTotalInterest:
            readDocument('totalInterest', base.showTotalInterest),
        showTotalDue: readDocument('totalDue', base.showTotalDue),
        showTotalValue: readDocument(
          'totalValuation',
          readLegacy('totalValue', base.showTotalValue),
        ),
        showDisbursementDetails: readDocument(
          'disbursementDetails',
          readLegacy(
            'disbursementDetails',
            base.showDisbursementDetails,
          ),
        ),
        showNotes: readDocument('notes', base.showNotes),
        printTermsAndConditions: readDocument(
          'printTerms',
          readLegacy('printTerms', base.printTermsAndConditions),
        ),
        printCustomerDeclaration: readDocument(
          'printDeclaration',
          readLegacy(
            'printDeclaration',
            base.printCustomerDeclaration,
          ),
        ),
        printFooterMessage: readDocument(
          'printFooter',
          readLegacy('printFooter', base.printFooterMessage),
        ),
      );

      final storedMetals = decoded['metals'];
      if (storedMetals is! Map) {
        final migrated = <String, GirviInvoiceFieldSettings>{
          for (final metal in GirviBillingMetal.supported)
            metal: GirviInvoiceFieldSettings.defaultFor(metal).copyWith(
              showMetal: legacyApplied.showMetal,
              showPieces: legacyApplied.showPieces,
              showHuid: legacyApplied.showHuid,
              showPurity: legacyApplied.showPurity,
              showGrossWeight: legacyApplied.showGrossWeight,
              showLessWeight: legacyApplied.showLessWeight,
              showNetWeight: legacyApplied.showNetWeight,
              showValuationPurity: legacyApplied.showValuationPurity,
              showFineWeight: legacyApplied.showFineWeight,
              showRatePerGram: legacyApplied.showRate,
              showValuationAmount: legacyApplied.showTotalValue,
              showItemPhotos: legacyApplied.showItemPhotos,
            ),
        };
        return legacyApplied.copyWith(metalInvoiceSettings: migrated);
      }

      final metalSettings = <String, GirviInvoiceFieldSettings>{};
      for (final entry in storedMetals.entries) {
        final metal = GirviBillingMetal.normalize(entry.key.toString());
        metalSettings[metal] = GirviInvoiceFieldSettings.fromJson(
          entry.value,
          fallback: GirviInvoiceFieldSettings.defaultFor(metal),
        );
      }
      return legacyApplied.copyWith(
        metalInvoiceSettings: metalSettings,
      );
    } catch (_) {
      return base;
    }
  }
}
