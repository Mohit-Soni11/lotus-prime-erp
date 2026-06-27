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
      label: 'Return window',
      min: 0,
      max: 365,
      messages: messages,
    );
    final purityDeductPercent = _parsePercent(
      input.purityDeductPercent,
      label: 'Purity deduction',
      messages: messages,
    );
    final termsAndConditions = input.termsAndConditions.trim();
    final returnPolicyText = input.returnPolicyText.trim();
    final buybackPolicyText = input.buybackPolicyText.trim();
    final footerMessage = input.footerMessage.trim();

    _requireText(
      termsAndConditions,
      label: 'Terms and conditions',
      messages: messages,
    );
    _requireText(
      returnPolicyText,
      label: 'Return policy',
      messages: messages,
    );
    _requireText(
      buybackPolicyText,
      label: 'Settlement policy',
      messages: messages,
    );

    if (messages.isNotEmpty) {
      return PurchaseBillingValidationResult(model: null, messages: messages);
    }

    return PurchaseBillingValidationResult(
      model: baseModel.copyWith(
        returnWindowDays: returnWindowDays,
        purityDeductPercent: purityDeductPercent,
        termsAndConditions: termsAndConditions,
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
