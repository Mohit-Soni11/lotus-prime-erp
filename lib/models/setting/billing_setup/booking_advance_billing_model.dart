class BookingAdvanceBillingModel {
  static const String defaultDocumentPrefix = 'BK';
  static const String bookingTypeOpen = 'OPEN';
  static const String bookingTypeLocked = 'LOCKED';
  static const String defaultTermsAndConditions = _defaultTerms;
  static const String defaultFooterMessage = _defaultFooter;

  static const List<String> bookingTypes = [
    bookingTypeOpen,
    bookingTypeLocked,
  ];

  final String documentPrefix;
  final String defaultBookingType;
  final int defaultDeliveryDays;
  final double minimumAdvancePercent;
  final double minimumAdvanceAmount;
  final bool allowZeroAdvance;
  final String defaultPrintFormat;
  final int printCopies;
  final bool includeCustomerAddress;
  final bool includeRateColumn;
  final bool printTermsAndConditions;
  final bool printFooterMessage;
  final String termsAndConditions;
  final String footerMessage;

  const BookingAdvanceBillingModel({
    this.documentPrefix = defaultDocumentPrefix,
    this.defaultBookingType = bookingTypeOpen,
    this.defaultDeliveryDays = 15,
    this.minimumAdvancePercent = 0.0,
    this.minimumAdvanceAmount = 0.0,
    this.allowZeroAdvance = true,
    this.defaultPrintFormat = 'a4',
    this.printCopies = 1,
    this.includeCustomerAddress = true,
    this.includeRateColumn = true,
    this.printTermsAndConditions = true,
    this.printFooterMessage = true,
    this.termsAndConditions = defaultTermsAndConditions,
    this.footerMessage = defaultFooterMessage,
  });

  factory BookingAdvanceBillingModel.defaults() {
    return const BookingAdvanceBillingModel();
  }

  BookingAdvanceBillingModel copyWith({
    String? documentPrefix,
    String? defaultBookingType,
    int? defaultDeliveryDays,
    double? minimumAdvancePercent,
    double? minimumAdvanceAmount,
    bool? allowZeroAdvance,
    String? defaultPrintFormat,
    int? printCopies,
    bool? includeCustomerAddress,
    bool? includeRateColumn,
    bool? printTermsAndConditions,
    bool? printFooterMessage,
    String? termsAndConditions,
    String? footerMessage,
  }) {
    return BookingAdvanceBillingModel(
      documentPrefix: documentPrefix ?? this.documentPrefix,
      defaultBookingType: defaultBookingType ?? this.defaultBookingType,
      defaultDeliveryDays: defaultDeliveryDays ?? this.defaultDeliveryDays,
      minimumAdvancePercent:
          minimumAdvancePercent ?? this.minimumAdvancePercent,
      minimumAdvanceAmount: minimumAdvanceAmount ?? this.minimumAdvanceAmount,
      allowZeroAdvance: allowZeroAdvance ?? this.allowZeroAdvance,
      defaultPrintFormat: defaultPrintFormat ?? this.defaultPrintFormat,
      printCopies: printCopies ?? this.printCopies,
      includeCustomerAddress:
          includeCustomerAddress ?? this.includeCustomerAddress,
      includeRateColumn: includeRateColumn ?? this.includeRateColumn,
      printTermsAndConditions:
          printTermsAndConditions ?? this.printTermsAndConditions,
      printFooterMessage: printFooterMessage ?? this.printFooterMessage,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      footerMessage: footerMessage ?? this.footerMessage,
    );
  }
}

const _defaultTerms =
    'Booking advance confirms the customer request for the listed jewellery item and estimated specifications.\n'
    'Booking advance listed jewellery item और estimated specifications के लिए customer request confirm करता है.\n'
    'Final weight, purity, rate, making charges, stone value, GST and balance amount will be finalized at delivery.\n'
    'Final weight, purity, rate, making charges, stone value, GST और balance amount delivery पर final होगा.\n'
    'Locked-rate bookings will follow the agreed locked rate. Open-rate bookings will follow the applicable rate on delivery date.\n'
    'Locked-rate booking में agreed locked rate लागू होगा. Open-rate booking में delivery date का applicable rate लागू होगा.\n'
    'Delivery date is an estimated promise and may change for customization, hallmarking or supplier delay.\n'
    'Delivery date estimated promise है और customization, hallmarking या supplier delay होने पर बदल सकती है.';

const _defaultFooter =
    'Please keep this booking receipt safely and bring it at delivery and final billing.\n'
    'कृपया यह booking receipt सुरक्षित रखें और delivery तथा final billing के समय साथ लाएं.';
