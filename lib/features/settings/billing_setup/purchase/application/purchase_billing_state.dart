import '../../../../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../domain/purchase_billing_policy_input.dart';

class PurchaseBillingState {
  final bool isLoading;
  final bool isSaving;
  final String selectedMetal;
  final Map<String, PurchaseBillingModel> settingsByMetal;
  final Map<String, PurchaseBillingPolicyInput> inputsByMetal;
  final Set<String> dirtyMetals;
  final List<String> validationMessages;

  const PurchaseBillingState({
    required this.isLoading,
    required this.isSaving,
    required this.selectedMetal,
    required this.settingsByMetal,
    required this.inputsByMetal,
    required this.dirtyMetals,
    required this.validationMessages,
  });

  factory PurchaseBillingState.initial() {
    return const PurchaseBillingState(
      isLoading: true,
      isSaving: false,
      selectedMetal: BillingMetal.gold,
      settingsByMetal: {},
      inputsByMetal: {},
      dirtyMetals: {},
      validationMessages: [],
    );
  }

  PurchaseBillingModel? get currentSettings => settingsByMetal[selectedMetal];

  PurchaseBillingPolicyInput? get currentInput => inputsByMetal[selectedMetal];

  bool get isCurrentDirty => dirtyMetals.contains(selectedMetal);

  PurchaseBillingState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? selectedMetal,
    Map<String, PurchaseBillingModel>? settingsByMetal,
    Map<String, PurchaseBillingPolicyInput>? inputsByMetal,
    Set<String>? dirtyMetals,
    List<String>? validationMessages,
  }) {
    return PurchaseBillingState(
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
