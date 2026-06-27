import '../../../../../../models/setting/billing_setup/sales_billing_model.dart';

class SalesBillingPolicyInput {
  final String returnWindowDays;
  final String handlingChargePercent;
  final String buybackRatePercent;
  final String buybackPurityDeductPercent;
  final String termsAndConditions;
  final String returnPolicyText;
  final String buybackPolicyText;
  final String footerMessage;

  const SalesBillingPolicyInput({
    required this.returnWindowDays,
    required this.handlingChargePercent,
    required this.buybackRatePercent,
    required this.buybackPurityDeductPercent,
    required this.termsAndConditions,
    required this.returnPolicyText,
    required this.buybackPolicyText,
    required this.footerMessage,
  });

  factory SalesBillingPolicyInput.fromModel(SalesBillingModel model) {
    return SalesBillingPolicyInput(
      returnWindowDays: model.returnWindowDays.toString(),
      handlingChargePercent: _formatDecimal(model.handlingChargePercent),
      buybackRatePercent: _formatDecimal(model.buybackRatePercent),
      buybackPurityDeductPercent:
          _formatDecimal(model.buybackPurityDeductPercent),
      termsAndConditions: model.termsAndConditions,
      returnPolicyText: model.returnPolicyText,
      buybackPolicyText: model.buybackPolicyText,
      footerMessage: model.footerMessage,
    );
  }

  SalesBillingPolicyInput copyWith({
    String? returnWindowDays,
    String? handlingChargePercent,
    String? buybackRatePercent,
    String? buybackPurityDeductPercent,
    String? termsAndConditions,
    String? returnPolicyText,
    String? buybackPolicyText,
    String? footerMessage,
  }) {
    return SalesBillingPolicyInput(
      returnWindowDays: returnWindowDays ?? this.returnWindowDays,
      handlingChargePercent:
          handlingChargePercent ?? this.handlingChargePercent,
      buybackRatePercent: buybackRatePercent ?? this.buybackRatePercent,
      buybackPurityDeductPercent:
          buybackPurityDeductPercent ?? this.buybackPurityDeductPercent,
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
