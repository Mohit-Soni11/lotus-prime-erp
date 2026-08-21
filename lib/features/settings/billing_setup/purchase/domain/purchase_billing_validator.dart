import '../../../../../../models/setting/billing_setup/purchase_billing_model.dart';
import 'purchase_billing_policy_input.dart';

class PurchaseBillingValidationResult {
  final PurchaseBillingModel? model;
  final List<String> messages;

  const PurchaseBillingValidationResult({
    required this.model,
    required this.messages,
  });

  bool get isValid => messages.isEmpty && model != null;
}

class PurchaseBillingValidator {
  PurchaseBillingValidator._();

  static PurchaseBillingValidationResult validate({
    required PurchaseBillingModel baseModel,
    required PurchaseBillingPolicyInput input,
  }) {
    final messages = <String>[];
    final returnWindowDays = _parseInt(
      input.returnWindowDays,
      label: 'Seller reclaim window',
      min: 0,
      max: 30,
      messages: messages,
    );
    final purityDeductPercent = _parsePercent(
      input.purityDeductPercent,
      label: 'Purity or melting deduction',
      messages: messages,
    );
    final lateReclaimPenaltyAmount = _parseAmount(
      input.lateReclaimPenaltyAmount,
      label: 'Late reclaim penalty amount',
      messages: messages,
    );
    final highValueReclaimThreshold = _parseAmount(
      input.highValueReclaimThreshold,
      label: 'High-value reclaim threshold',
      messages: messages,
    );
    final highValueReclaimPenaltyPercent = _parsePercent(
      input.highValueReclaimPenaltyPercent,
      label: 'High-value reclaim penalty',
      messages: messages,
    );
    final termsAndConditions = input.termsAndConditions;
    final sellerDeclarationText = input.sellerDeclarationText;
    final returnPolicyText = input.returnPolicyText;
    final buybackPolicyText = input.buybackPolicyText;
    final footerMessage = input.footerMessage;

    _requireText(
      termsAndConditions,
      label: 'Terms and conditions',
      messages: messages,
    );
    _requireText(
      sellerDeclarationText,
      label: 'Seller ownership declaration',
      messages: messages,
    );
    _requireText(
      returnPolicyText,
      label: 'Seller reclaim policy',
      messages: messages,
    );
    _requireText(
      buybackPolicyText,
      label: 'Valuation and payout note',
      messages: messages,
    );

    if (messages.isNotEmpty) {
      return PurchaseBillingValidationResult(model: null, messages: messages);
    }

    return PurchaseBillingValidationResult(
      model: baseModel.copyWith(
        returnWindowDays: returnWindowDays,
        purityDeductPercent: purityDeductPercent,
        lateReclaimPenaltyAmount: lateReclaimPenaltyAmount,
        highValueReclaimThreshold: highValueReclaimThreshold,
        highValueReclaimPenaltyPercent: highValueReclaimPenaltyPercent,
        termsAndConditions: termsAndConditions,
        sellerDeclarationText: sellerDeclarationText,
        returnPolicyText: returnPolicyText,
        buybackPolicyText: buybackPolicyText,
        footerMessage: footerMessage,
      ),
      messages: const [],
    );
  }

  static int? _parseInt(
    String raw, {
    required String label,
    required int min,
    required int max,
    required List<String> messages,
  }) {
    final value = int.tryParse(raw.trim());
    if (value == null) {
      messages.add('$label must be a whole number.');
      return null;
    }
    if (value < min || value > max) {
      messages.add('$label must be between $min and $max days.');
      return null;
    }
    return value;
  }

  static double? _parsePercent(
    String raw, {
    required String label,
    required List<String> messages,
  }) {
    final normalized = raw.trim().replaceAll(',', '');
    final value = double.tryParse(normalized);
    if (value == null) {
      messages.add('$label must be a valid percentage.');
      return null;
    }
    if (value < 0 || value > 100) {
      messages.add('$label must be between 0 and 100%.');
      return null;
    }
    return value;
  }

  static double? _parseAmount(
    String raw, {
    required String label,
    required List<String> messages,
  }) {
    final normalized = raw.trim().replaceAll(',', '');
    final value = double.tryParse(normalized);
    if (value == null) {
      messages.add('$label must be a valid amount.');
      return null;
    }
    if (value < 0 || value > 1000000) {
      messages.add('$label must be between 0 and 1000000.');
      return null;
    }
    return value;
  }

  static void _requireText(
    String value, {
    required String label,
    required List<String> messages,
  }) {
    if (value.isEmpty) {
      messages.add('$label cannot be empty.');
    }
  }
}
