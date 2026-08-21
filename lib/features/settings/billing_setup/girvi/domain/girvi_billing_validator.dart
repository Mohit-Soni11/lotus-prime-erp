import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';

import 'girvi_billing_options.dart';
import 'girvi_billing_policy_input.dart';

class GirviBillingValidationResult {
  final GirviBillingModel? model;
  final List<String> messages;

  const GirviBillingValidationResult({
    required this.model,
    required this.messages,
  });

  bool get isValid => model != null && messages.isEmpty;
}

class GirviBillingValidator {
  GirviBillingValidator._();

  static final _prefixPattern = RegExp(r'^[A-Za-z0-9\-\/]+$');

  static GirviBillingValidationResult validate({
    required GirviBillingModel baseModel,
    required GirviBillingPolicyInput input,
  }) {
    final messages = <String>[];
    final prefix = input.girviPrefix.trim();
    final startingNumber = _parseInt(
      input.startingNumber,
      label: 'Starting ticket number',
      min: 1,
      max: 999999,
      unitLabel: 'number',
      messages: messages,
    );
    final defaultInterestRate = _parsePercent(
      input.defaultInterestRate,
      label: 'Monthly interest rate',
      min: 0,
      max: 100,
      messages: messages,
    );
    final gracePeriodDays = _parseInt(
      input.gracePeriodDays,
      label: 'Grace period',
      min: 0,
      max: 365,
      unitLabel: 'days',
      messages: messages,
    );
    final reminderDays = _parseInt(
      input.reminderDays,
      label: 'Reminder window',
      min: 0,
      max: 365,
      unitLabel: 'days',
      messages: messages,
    );
    final noticeDays = _parseInt(
      input.noticeDays,
      label: 'Auction notice window',
      min: 0,
      max: 365,
      unitLabel: 'days',
      messages: messages,
    );
    final termsAndConditions = input.termsAndConditions;
    final termsAndConditionsHindi = input.termsAndConditionsHindi;
    final customerDeclaration = input.customerDeclaration;
    final customerDeclarationHindi = input.customerDeclarationHindi;
    final footerMessage = input.footerMessage;

    if (prefix.isEmpty) {
      messages.add('Ticket prefix cannot be empty.');
    } else if (prefix.length > 16) {
      messages.add('Ticket prefix must be 16 characters or less.');
    } else if (!_prefixPattern.hasMatch(prefix)) {
      messages.add(
          'Ticket prefix can use only letters, numbers, hyphen, and slash.');
    }

    _requireText(
      termsAndConditions,
      label: 'English terms and conditions',
      messages: messages,
    );
    _requireText(
      customerDeclaration,
      label: 'English customer declaration',
      messages: messages,
    );

    if (baseModel.printTermsAndConditions && termsAndConditionsHindi.isEmpty) {
      messages.add('Hindi terms are required when receipt terms are enabled.');
    }
    if (baseModel.printCustomerDeclaration &&
        customerDeclarationHindi.isEmpty) {
      messages.add(
        'Hindi declaration is required when customer declaration is enabled.',
      );
    }
    if (baseModel.printFooterMessage && footerMessage.isEmpty) {
      messages.add(
          'Footer message cannot be empty when footer printing is enabled.');
    }
    if (!GirviBillingOptions.interestTypes.contains(baseModel.interestType)) {
      messages.add('Select a valid interest type.');
    }
    if (!GirviBillingOptions.durations.contains(baseModel.defaultDuration)) {
      messages.add('Select a valid default duration.');
    }

    if (messages.isNotEmpty) {
      return GirviBillingValidationResult(model: null, messages: messages);
    }

    return GirviBillingValidationResult(
      model: baseModel.copyWith(
        girviPrefix: prefix,
        startingNumber: startingNumber,
        defaultInterestRate: defaultInterestRate,
        gracePeriodDays: gracePeriodDays,
        reminderDays: reminderDays,
        noticeDays: noticeDays,
        termsAndConditions: termsAndConditions,
        termsAndConditionsHindi: termsAndConditionsHindi,
        customerDeclaration: customerDeclaration,
        customerDeclarationHindi: customerDeclarationHindi,
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
    required String unitLabel,
    required List<String> messages,
  }) {
    final value = int.tryParse(raw.trim());
    if (value == null) {
      messages.add('$label must be a whole number.');
      return null;
    }
    if (value < min || value > max) {
      messages.add('$label must be between $min and $max $unitLabel.');
      return null;
    }
    return value;
  }

  static double? _parsePercent(
    String raw, {
    required String label,
    required double min,
    required double max,
    required List<String> messages,
  }) {
    final value = double.tryParse(raw.trim().replaceAll(',', ''));
    if (value == null) {
      messages.add('$label must be a valid percentage.');
      return null;
    }
    if (value < min || value > max) {
      messages.add(
          '$label must be between ${min.toStringAsFixed(0)} and ${max.toStringAsFixed(0)}%.');
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
