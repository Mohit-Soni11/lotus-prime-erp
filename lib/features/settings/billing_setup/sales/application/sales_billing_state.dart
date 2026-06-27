import '../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../domain/sales_billing_policy_input.dart';

class SalesBillingState {
  final bool isLoading;
  final bool isSaving;
  final String selectedMetal;
  final Map<String, SalesBillingModel> settingsByMetal;
  final Map<String, SalesBillingPolicyInput> inputsByMetal;
  final Set<String> dirtyMetals;
  final List<String> validationMessages;

  const SalesBillingState({
    required this.isLoading,
    required this.isSaving,
    required this.selectedMetal,
    required this.settingsByMetal,
    required this.inputsByMetal,
    required this.dirtyMetals,
    required this.validationMessages,
  });

  factory SalesBillingState.initial() {
    return const SalesBillingState(
      isLoading: true,
      isSaving: false,
      selectedMetal: BillingMetal.gold,
      settingsByMetal: {},
      inputsByMetal: {},
      dirtyMetals: {},
      validationMessages: [],
    );
  }

  SalesBillingModel? get currentSettings => settingsByMetal[selectedMetal];

  SalesBillingPolicyInput? get currentInput => inputsByMetal[selectedMetal];

  bool get isCurrentDirty => dirtyMetals.contains(selectedMetal);

  SalesBillingState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? selectedMetal,
    Map<String, SalesBillingModel>? settingsByMetal,
    Map<String, SalesBillingPolicyInput>? inputsByMetal,
    Set<String>? dirtyMetals,
    List<String>? validationMessages,
  }) {
    return SalesBillingState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      selectedMetal: selectedMetal ?? this.selectedMetal,
      settingsByMetal: settingsByMetal ?? this.settingsByMetal,
      inputsByMetal: inputsByMetal ?? this.inputsByMetal,
      dirtyMetals: dirtyMetals ?? this.dirtyMetals,
      validationMessages: validationMessages ?? this.validationMessages,
    );
  }
}
