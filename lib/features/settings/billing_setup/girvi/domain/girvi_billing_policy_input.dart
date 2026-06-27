import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';

class GirviBillingPolicyInput {
  final String girviPrefix;
  final String startingNumber;
  final String defaultInterestRate;
  final String gracePeriodDays;
  final String reminderDays;
  final String noticeDays;
  final String termsAndConditions;
  final String termsAndConditionsHindi;
  final String customerDeclaration;
  final String customerDeclarationHindi;
  final String footerMessage;

  const GirviBillingPolicyInput({
    required this.girviPrefix,
    required this.startingNumber,
    required this.defaultInterestRate,
    required this.gracePeriodDays,
    required this.reminderDays,
    required this.noticeDays,
    required this.termsAndConditions,
    required this.termsAndConditionsHindi,
    required this.customerDeclaration,
    required this.customerDeclarationHindi,
    required this.footerMessage,
  });

  factory GirviBillingPolicyInput.fromModel(GirviBillingModel model) {
    return GirviBillingPolicyInput(
      girviPrefix: model.girviPrefix,
      startingNumber: model.startingNumber.toString(),
      defaultInterestRate: _formatDecimal(model.defaultInterestRate),
      gracePeriodDays: model.gracePeriodDays.toString(),
      reminderDays: model.reminderDays.toString(),
      noticeDays: model.noticeDays.toString(),
      termsAndConditions: model.termsAndConditions,
      termsAndConditionsHindi: model.termsAndConditionsHindi,
      customerDeclaration: model.customerDeclaration,
      customerDeclarationHindi: model.customerDeclarationHindi,
      footerMessage: model.footerMessage,
    );
  }

  GirviBillingPolicyInput copyWith({
    String? girviPrefix,
    String? startingNumber,
    String? defaultInterestRate,
    String? gracePeriodDays,
    String? reminderDays,
    String? noticeDays,
    String? termsAndConditions,
    String? termsAndConditionsHindi,
    String? customerDeclaration,
    String? customerDeclarationHindi,
    String? footerMessage,
  }) {
    return GirviBillingPolicyInput(
      girviPrefix: girviPrefix ?? this.girviPrefix,
      startingNumber: startingNumber ?? this.startingNumber,
      defaultInterestRate: defaultInterestRate ?? this.defaultInterestRate,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      reminderDays: reminderDays ?? this.reminderDays,
      noticeDays: noticeDays ?? this.noticeDays,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      termsAndConditionsHindi:
          termsAndConditionsHindi ?? this.termsAndConditionsHindi,
      customerDeclaration: customerDeclaration ?? this.customerDeclaration,
      customerDeclarationHindi:
          customerDeclarationHindi ?? this.customerDeclarationHindi,
      footerMessage: footerMessage ?? this.footerMessage,
    );
  }

  static String _formatDecimal(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }
}
