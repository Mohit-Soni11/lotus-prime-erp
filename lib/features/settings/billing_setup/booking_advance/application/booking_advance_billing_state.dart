import '../../../../../../models/setting/billing_setup/booking_advance_billing_model.dart';
import '../domain/booking_advance_billing_input.dart';

class BookingAdvanceBillingState {
  final bool isLoading;
  final bool isSaving;
  final BookingAdvanceBillingModel? settings;
  final BookingAdvanceBillingInput? input;
  final bool isDirty;
  final List<String> validationMessages;

  const BookingAdvanceBillingState({
    required this.isLoading,
    required this.isSaving,
    required this.settings,
    required this.input,
    required this.isDirty,
    required this.validationMessages,
  });

  factory BookingAdvanceBillingState.initial() {
    return const BookingAdvanceBillingState(
      isLoading: true,
      isSaving: false,
      settings: null,
      input: null,
      isDirty: false,
      validationMessages: [],
    );
  }

  BookingAdvanceBillingState copyWith({
    bool? isLoading,
    bool? isSaving,
    BookingAdvanceBillingModel? settings,
    BookingAdvanceBillingInput? input,
    bool? isDirty,
    List<String>? validationMessages,
  }) {
    return BookingAdvanceBillingState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      settings: settings ?? this.settings,
      input: input ?? this.input,
      isDirty: isDirty ?? this.isDirty,
      validationMessages: validationMessages ?? this.validationMessages,
    );
  }
}
