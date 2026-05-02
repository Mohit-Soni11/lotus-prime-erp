// =============================================================================
// FILE        : lib/models/setting/billing/girvi_billing_model.dart
// MODULE      : Billing Setup → Girvi
// =============================================================================

class GirviBillingModel {
  // Section 1 — Voucher
  final String girviPrefix;
  final int startingNumber;

  // Section 2 — Interest
  final double defaultInterestRate;
  final String interestType;
  final int gracePeriodDays;
  final String defaultDuration;

  // Section 3 — Notice
  final int reminderDays;
  final int noticeDays;

  // Section 4 — Terms & Print
  final String termsAndConditions;
  final String footerMessage;
  final bool autoPrint;
  final String selectedTemplate;

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
  });

  static GirviBillingModel get defaults => const GirviBillingModel();

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
    );
  }
}
