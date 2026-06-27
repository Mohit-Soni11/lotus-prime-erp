import 'package:flutter/foundation.dart';

import '../../../../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../data/purchase_billing_settings_repository.dart';
import '../domain/purchase_billing_metal_profile.dart';
import '../domain/purchase_billing_policy_input.dart';
import '../domain/purchase_billing_validator.dart';
import 'purchase_billing_state.dart';

class PurchaseBillingController extends ChangeNotifier {
  final PurchaseBillingSettingsRepository _repository;
  var _state = PurchaseBillingState.initial();
  var _savedSettingsByMetal = <String, PurchaseBillingModel>{};
  bool _disposed = false;

  PurchaseBillingController({
    PurchaseBillingSettingsRepository? repository,
  }) : _repository = repository ?? PurchaseBillingSettingsRepository();

  PurchaseBillingState get state => _state;

  Future<void> load() async {
    _emit(_state.copyWith(isLoading: true, validationMessages: const []));
    try {
      final settings = await _repository.fetchAll();
      final inputs = {
        for (final entry in settings.entries)
          entry.key: PurchaseBillingPolicyInput.fromModel(entry.value),
      };
      _savedSettingsByMetal = Map.of(settings);
      _emit(
        _state.copyWith(
          isLoading: false,
          settingsByMetal: settings,
          inputsByMetal: inputs,
          dirtyMetals: const {},
          validationMessages: const [],
        ),
      );
    } catch (_) {
      _emit(
        _state.copyWith(
          isLoading: false,
          validationMessages: const [
            'Purchase billing settings could not be loaded.',
          ],
        ),
      );
    }
  }

  void selectMetal(String metal) {
    if (!BillingMetal.all.contains(metal)) return;
    _emit(
      _state.copyWith(
        selectedMetal: metal,
        validationMessages: const [],
      ),
    );
  }

  void updateCurrentInput(PurchaseBillingPolicyInput input) {
    final inputs = Map<String, PurchaseBillingPolicyInput>.of(
      _state.inputsByMetal,
    );
    inputs[_state.selectedMetal] = input;
    _markDirty(inputsByMetal: inputs);
  }

  void toggleField(PurchaseBillingFieldKey key, bool value) {
    _updateCurrentSettings(
      (model) => PurchaseBillingMetalProfiles.setValue(model, key, value),
    );
  }

  void updateReturnMode(String mode) {
    _updateCurrentSettings((model) => model.copyWith(returnMode: mode));
  }

  void updateSelectedTemplate(String templateId) {
    _updateCurrentSettings(
      (model) => model.copyWith(selectedTemplate: templateId),
    );
  }

  void resetCurrentToDefaults() {
    final metal = _state.selectedMetal;
    final model = PurchaseBillingModel.defaultFor(metal);
    final settings = Map<String, PurchaseBillingModel>.of(
      _state.settingsByMetal,
    );
    final inputs = Map<String, PurchaseBillingPolicyInput>.of(
      _state.inputsByMetal,
    );
    settings[metal] = model;
    inputs[metal] = PurchaseBillingPolicyInput.fromModel(model);
    _markDirty(settingsByMetal: settings, inputsByMetal: inputs);
  }

  void discardCurrentChanges() {
    final metal = _state.selectedMetal;
    final saved = _savedSettingsByMetal[metal];
    if (saved == null) return;

    final settings = Map<String, PurchaseBillingModel>.of(
      _state.settingsByMetal,
    );
    final inputs = Map<String, PurchaseBillingPolicyInput>.of(
      _state.inputsByMetal,
    );
    final dirtyMetals = Set<String>.of(_state.dirtyMetals)..remove(metal);
    settings[metal] = saved;
    inputs[metal] = PurchaseBillingPolicyInput.fromModel(saved);

    _emit(
      _state.copyWith(
        settingsByMetal: Map.unmodifiable(settings),
        inputsByMetal: Map.unmodifiable(inputs),
        dirtyMetals: Set.unmodifiable(dirtyMetals),
        validationMessages: const [],
      ),
    );
  }

  Future<bool> saveCurrent() async {
    final metal = _state.selectedMetal;
    final model = _state.settingsByMetal[metal];
    final input = _state.inputsByMetal[metal];
    if (model == null || input == null) return false;

    final validation = PurchaseBillingValidator.validate(
      baseModel: model,
      input: input,
    );
    if (!validation.isValid) {
      _emit(_state.copyWith(validationMessages: validation.messages));
      return false;
    }

    final parsedModel = validation.model!;
    _emit(_state.copyWith(isSaving: true, validationMessages: const []));
    final saved = await _repository.save(parsedModel);
    if (!saved) {
      _emit(
        _state.copyWith(
          isSaving: false,
          validationMessages: const [
            'Purchase billing settings could not be saved.',
          ],
        ),
      );
      return false;
    }

    final settings = Map<String, PurchaseBillingModel>.of(
      _state.settingsByMetal,
    );
    final inputs = Map<String, PurchaseBillingPolicyInput>.of(
      _state.inputsByMetal,
    );
    final dirtyMetals = Set<String>.of(_state.dirtyMetals)..remove(metal);
    settings[metal] = parsedModel;
    inputs[metal] = PurchaseBillingPolicyInput.fromModel(parsedModel);
    _savedSettingsByMetal[metal] = parsedModel;

    _emit(
      _state.copyWith(
        isSaving: false,
        settingsByMetal: Map.unmodifiable(settings),
        inputsByMetal: Map.unmodifiable(inputs),
        dirtyMetals: Set.unmodifiable(dirtyMetals),
        validationMessages: const [],
      ),
    );
    return true;
  }

  void _updateCurrentSettings(
    PurchaseBillingModel Function(PurchaseBillingModel model) update,
  ) {
    final current = _state.currentSettings;
    if (current == null) return;
    final settings = Map<String, PurchaseBillingModel>.of(
      _state.settingsByMetal,
    );
    settings[_state.selectedMetal] = update(current);
    _markDirty(settingsByMetal: settings);
  }

  void _markDirty({
    Map<String, PurchaseBillingModel>? settingsByMetal,
    Map<String, PurchaseBillingPolicyInput>? inputsByMetal,
  }) {
    final dirtyMetals = Set<String>.of(_state.dirtyMetals)
      ..add(_state.selectedMetal);
    _emit(
      _state.copyWith(
        settingsByMetal:
            settingsByMetal == null ? null : Map.unmodifiable(settingsByMetal),
        inputsByMetal:
            inputsByMetal == null ? null : Map.unmodifiable(inputsByMetal),
        dirtyMetals: Set.unmodifiable(dirtyMetals),
        validationMessages: const [],
      ),
    );
  }

  void _emit(PurchaseBillingState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
