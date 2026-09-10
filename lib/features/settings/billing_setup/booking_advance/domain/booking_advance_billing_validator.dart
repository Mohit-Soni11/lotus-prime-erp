import '../../../../../../models/setting/billing_setup/booking_advance_billing_model.dart';
import 'booking_advance_billing_input.dart';

class BookingAdvanceBillingValidationResult {
  final BookingAdvanceBillingModel? model;
  final List<String> messages;

  const BookingAdvanceBillingValidationResult({
    required this.model,
    required this.messages,
  });

  bool get isValid => messages.isEmpty && model != null;
}

class BookingAdvanceBillingValidator {
  BookingAdvanceBillingValidator._();

  static BookingAdvanceBillingValidationResult validate({
    required BookingAdvanceBillingModel baseModel,
    required BookingAdvanceBillingInput input,
  }) {
    final messages = <String>[];
    final documentPrefix = _parseDocumentPrefix(
      input.documentPrefix,
      messages: messages,
    );
    final defaultDeliveryDays = _parseInt(
      input.defaultDeliveryDays,
      label: 'Default delivery promise',
      min: 0,
      max: 365,
      messages: messages,
    );
    final minimumAdvancePercent = _parsePercent(
      input.minimumAdvancePercent,
      label: 'Minimum advance percentage',
      messages: messages,
    );
    final minimumAdvanceAmount = _parseAmount(
      input.minimumAdvanceAmount,
      label: 'Minimum advance amount',
      messages: messages,
    );

    _requireText(
      input.termsAndConditions,
      label: 'Booking terms and conditions',
      messages: messages,
    );
    _requireText(
      input.footerMessage,
      label: 'Booking footer message',
      messages: messages,
    );

    if (messages.isNotEmpty) {
      return BookingAdvanceBillingValidationResult(
        model: null,
        messages: messages,
      );
    }

    return BookingAdvanceBillingValidationResult(
      model: baseModel.copyWith(
        documentPrefix: documentPrefix,
        defaultDeliveryDays: defaultDeliveryDays,
        minimumAdvancePercent: minimumAdvancePercent,
        minimumAdvanceAmount: minimumAdvanceAmount,
        termsAndConditions: input.termsAndConditions,
        footerMessage: input.footerMessage,
      ),
      messages: const [],
    );
  }

  static String? _parseDocumentPrefix(
    String raw, {
    required List<String> messages,
  }) {
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) {
      messages.add('Document prefix cannot be empty.');
      return null;
    }
    if (!RegExp(r'^[A-Z0-9]{2,8}$').hasMatch(normalized)) {
      messages.add('Document prefix must be 2 to 8 letters or numbers.');
      return null;
    }
    return normalized;
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
    final value = double.tryParse(raw.trim().replaceAll(',', ''));
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
    final value = double.tryParse(raw.trim().replaceAll(',', ''));
    if (value == null) {
      messages.add('$label must be a valid amount.');
      return null;
    }
    if (value < 0 || value > 10000000) {
      messages.add('$label must be between 0 and 10000000.');
      return null;
    }
    return value;
  }

  static void _requireText(
    String value, {
    required String label,
    required List<String> messages,
  }) {
    if (value.trim().isEmpty) messages.add('$label cannot be empty.');
  }
}
