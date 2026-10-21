part of 'contact_recovery_model.dart';

class ContactRecoveryState {
  final List<ContactRecoveryCase> allCases;
  final bool isLoading;
  final String? errorMessage;
  final String? inlineMessage;

  const ContactRecoveryState({
    required this.allCases,
    required this.isLoading,
    this.errorMessage,
    this.inlineMessage,
  });

  factory ContactRecoveryState.initial() {
    return const ContactRecoveryState(
      allCases: [],
      isLoading: true,
    );
  }

  ContactRecoveryState copyWith({
    List<ContactRecoveryCase>? allCases,
    bool? isLoading,
    String? errorMessage,
    String? inlineMessage,
    bool clearError = false,
    bool clearInlineMessage = false,
  }) {
    return ContactRecoveryState(
      allCases: allCases ?? this.allCases,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      inlineMessage:
          clearInlineMessage ? null : inlineMessage ?? this.inlineMessage,
    );
  }
}
