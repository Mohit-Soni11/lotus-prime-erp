import '../../../../../../models/setting/billing_setup/booking_advance_billing_model.dart';

class BookingAdvanceBillingInput {
  final String documentPrefix;
  final String defaultDeliveryDays;
  final String minimumAdvancePercent;
  final String minimumAdvanceAmount;
  final String termsAndConditions;
  final String footerMessage;

  const BookingAdvanceBillingInput({
    required this.documentPrefix,
    required this.defaultDeliveryDays,
    required this.minimumAdvancePercent,
    required this.minimumAdvanceAmount,
    required this.termsAndConditions,
    required this.footerMessage,
  });

  factory BookingAdvanceBillingInput.fromModel(
    BookingAdvanceBillingModel model,
  ) {
    return BookingAdvanceBillingInput(
      documentPrefix: model.documentPrefix,
      defaultDeliveryDays: model.defaultDeliveryDays.toString(),
      minimumAdvancePercent: _formatDecimal(model.minimumAdvancePercent),
      minimumAdvanceAmount: _formatDecimal(model.minimumAdvanceAmount),
      termsAndConditions: model.termsAndConditions,
      footerMessage: model.footerMessage,
    );
  }

  BookingAdvanceBillingInput copyWith({
    String? documentPrefix,
    String? defaultDeliveryDays,
    String? minimumAdvancePercent,
    String? minimumAdvanceAmount,
    String? termsAndConditions,
    String? footerMessage,
  }) {
    return BookingAdvanceBillingInput(
      documentPrefix: documentPrefix ?? this.documentPrefix,
      defaultDeliveryDays: defaultDeliveryDays ?? this.defaultDeliveryDays,
      minimumAdvancePercent:
          minimumAdvancePercent ?? this.minimumAdvancePercent,
      minimumAdvanceAmount: minimumAdvanceAmount ?? this.minimumAdvanceAmount,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      footerMessage: footerMessage ?? this.footerMessage,
    );
  }

  static String _formatDecimal(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }
}
