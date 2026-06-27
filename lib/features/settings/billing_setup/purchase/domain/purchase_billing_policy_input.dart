import '../../../../../../models/setting/billing_setup/purchase_billing_model.dart';

class PurchaseBillingPolicyInput {
  final String returnWindowDays;
  final String purityDeductPercent;
  final String termsAndConditions;
  final String returnPolicyText;
  final String buybackPolicyText;
  final String footerMessage;

  const PurchaseBillingPolicyInput({
    required this.returnWindowDays,
    required this.purityDeductPercent,
    required this.termsAndConditions,
    required this.returnPolicyText,
    required this.buybackPolicyText,
    required this.footerMessage,
  });

  factory PurchaseBillingPolicyInput.fromModel(PurchaseBillingModel model) {
    return PurchaseBillingPolicyInput(
      returnWindowDays: model.returnWindowDays.toString(),
      purityDeductPercent: _formatDecimal(model.purityDeductPercent),
      termsAndConditions: model.termsAndConditions,
      returnPolicyText: model.returnPolicyText,
      buybackPolicyText: model.buybackPolicyText,
      footerMessage: model.footerMessage,
    );
  }

  PurchaseBillingPolicyInput copyWith({
    String? returnWindowDays,
    String? purityDeductPercent,
    String? termsAndConditions,
    String? returnPolicyText,
    String? buybackPolicyText,
    String? footerMessage,
  }) {
    return PurchaseBillingPolicyInput(
      returnWindowDays: returnWindowDays ?? this.returnWindowDays,
      purityDeductPercent: purityDeductPercent ?? this.purityDeductPercent,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      returnPolicyText: returnPolicyText ?? this.returnPolicyText,
      buybackPolicyText: buybackPolicyText ?? this.buybackPolicyText,
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
