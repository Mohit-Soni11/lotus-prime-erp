import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';

import '../domain/girvi_billing_policy_input.dart';

class GirviBillingState {
  final bool isLoading;
  final bool isSaving;
  final bool isDirty;
  final String selectedInvoiceMetal;
  final GirviBillingModel model;
  final GirviBillingPolicyInput input;
  final List<String> validationMessages;

  const GirviBillingState({
    required this.isLoading,
    required this.isSaving,
    required this.isDirty,
    required this.selectedInvoiceMetal,
    required this.model,
    required this.input,
    required this.validationMessages,
  });

  factory GirviBillingState.initial() {
    final model = GirviBillingModel.defaults;
    return GirviBillingState(
      isLoading: true,
      isSaving: false,
      isDirty: false,
      selectedInvoiceMetal: GirviBillingMetal.gold,
      model: model,
      input: GirviBillingPolicyInput.fromModel(model),
      validationMessages: const [],
    );
  }

  GirviBillingState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isDirty,
    String? selectedInvoiceMetal,
    GirviBillingModel? model,
    GirviBillingPolicyInput? input,
    List<String>? validationMessages,
  }) {
    return GirviBillingState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDirty: isDirty ?? this.isDirty,
      selectedInvoiceMetal: selectedInvoiceMetal ?? this.selectedInvoiceMetal,
      model: model ?? this.model,
      input: input ?? this.input,
      validationMessages: validationMessages ?? this.validationMessages,
    );
  }
}
