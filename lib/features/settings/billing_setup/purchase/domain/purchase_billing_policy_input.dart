import '../../../../../../models/setting/billing_setup/purchase_billing_model.dart';

class PurchaseBillingPolicyInput {
  final String returnWindowDays;
  final String purityDeductPercent;
  final String lateReclaimPenaltyAmount;
  final String highValueReclaimThreshold;
  final String highValueReclaimPenaltyPercent;
  final String termsAndConditions;
  final String sellerDeclarationText;
  final String returnPolicyText;
  final String buybackPolicyText;
  final String footerMessage;

  const PurchaseBillingPolicyInput({
    required this.returnWindowDays,
    required this.purityDeductPercent,
    required this.lateReclaimPenaltyAmount,
    required this.highValueReclaimThreshold,
    required this.highValueReclaimPenaltyPercent,
    required this.termsAndConditions,
    required this.sellerDeclarationText,
    required this.returnPolicyText,
    required this.buybackPolicyText,
    required this.footerMessage,
  });

  factory PurchaseBillingPolicyInput.fromModel(PurchaseBillingModel model) {
    return PurchaseBillingPolicyInput(
      returnWindowDays: model.returnWindowDays.toString(),
      purityDeductPercent: _formatDecimal(model.purityDeductPercent),
      lateReclaimPenaltyAmount: _formatDecimal(model.lateReclaimPenaltyAmount),
      highValueReclaimThreshold:
          _formatDecimal(model.highValueReclaimThreshold),
      highValueReclaimPenaltyPercent:
          _formatDecimal(model.highValueReclaimPenaltyPercent),
      termsAndConditions: model.termsAndConditions,
      sellerDeclarationText: model.sellerDeclarationText,
      returnPolicyText: model.returnPolicyText,
      buybackPolicyText: model.buybackPolicyText,
      footerMessage: model.footerMessage,
    );
  }

  PurchaseBillingPolicyInput copyWith({
    String? returnWindowDays,
    String? purityDeductPercent,
    String? lateReclaimPenaltyAmount,
    String? highValueReclaimThreshold,
    String? highValueReclaimPenaltyPercent,
    String? termsAndConditions,
    String? sellerDeclarationText,
    String? returnPolicyText,
    String? buybackPolicyText,
    String? footerMessage,
  }) {
    return PurchaseBillingPolicyInput(
      returnWindowDays: returnWindowDays ?? this.returnWindowDays,
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
    );
  }

  static String _formatDecimal(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }
}
