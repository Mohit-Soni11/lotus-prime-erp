import 'package:flutter/foundation.dart';

import '../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../data/sales_billing_settings_repository.dart';
import '../domain/sales_billing_metal_profile.dart';
import '../domain/sales_billing_policy_input.dart';
import '../domain/sales_billing_validator.dart';
import 'sales_billing_state.dart';

class SalesBillingController extends ChangeNotifier {
  final SalesBillingSettingsRepository _repository;
  var _state = SalesBillingState.initial();
  var _savedSettingsByMetal = <String, SalesBillingModel>{};
  bool _disposed = false;

  SalesBillingController({
    SalesBillingSettingsRepository? repository,
  }) : _repository = repository ?? SalesBillingSettingsRepository();

  SalesBillingState get state => _state;

  Future<void> load() async {
    _emit(_state.copyWith(isLoading: true, validationMessages: const []));
    try {
      final settings = await _repository.fetchAll();
      final inputs = {
        for (final entry in settings.entries)
          entry.key: SalesBillingPolicyInput.fromModel(entry.value),
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
            'Sales billing settings could not be loaded.',
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

  void updateCurrentInput(SalesBillingPolicyInput input) {
    final inputs = Map<String, SalesBillingPolicyInput>.of(
      _state.inputsByMetal,
    );
    inputs[_state.selectedMetal] = input;
    _markDirty(inputsByMetal: inputs);
  }

  void toggleField(SalesBillingFieldKey key, bool value) {
    _updateCurrentSettings(
      (model) => SalesBillingMetalProfiles.setValue(model, key, value),
    );
  }

  void updateReturnMode(String mode) {
    _updateCurrentSettings((model) => model.copyWith(returnMode: mode));
  }

  void updateSelectedTemplate(String templateId) {
    if (!TemplateOptions.all.contains(templateId)) return;
    _updateCurrentSettings(
      (model) => model.copyWith(selectedTemplate: templateId),
    );
  }

  void updatePrintTerms(bool value) {
    _updateCurrentSettings(
      (model) => model.copyWith(printTermsAndConditions: value),
    );
  }

  void updatePrintReturnPolicy(bool value) {
    _updateCurrentSettings(
      (model) => model.copyWith(printReturnPolicy: value),
    );
  }

  void updatePrintBuybackPolicy(bool value) {
    _updateCurrentSettings(
      (model) => model.copyWith(printBuybackPolicy: value),
    );
  }

  void updatePrintFooter(bool value) {
    _updateCurrentSettings(
      (model) => model.copyWith(printFooterMessage: value),
    );
  }

  void resetCurrentToDefaults() {
    final metal = _state.selectedMetal;
    final model = SalesBillingModel.defaultFor(metal);
    final settings = Map<String, SalesBillingModel>.of(_state.settingsByMetal);
    final inputs = Map<String, SalesBillingPolicyInput>.of(
      _state.inputsByMetal,
    );
    settings[metal] = model;
    inputs[metal] = SalesBillingPolicyInput.fromModel(model);
    _markDirty(settingsByMetal: settings, inputsByMetal: inputs);
  }

  void discardCurrentChanges() {
    final metal = _state.selectedMetal;
    final saved = _savedSettingsByMetal[metal];
    if (saved == null) return;

    final settings = Map<String, SalesBillingModel>.of(_state.settingsByMetal);
    final inputs = Map<String, SalesBillingPolicyInput>.of(
      _state.inputsByMetal,
    );
    final dirtyMetals = Set<String>.of(_state.dirtyMetals)..remove(metal);
    settings[metal] = saved;
    inputs[metal] = SalesBillingPolicyInput.fromModel(saved);

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

    final validation = SalesBillingValidator.validate(
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
            'Sales billing settings could not be saved.',
          ],
        ),
      );
      return false;
    }

    final settings = Map<String, SalesBillingModel>.of(_state.settingsByMetal);
    final inputs = Map<String, SalesBillingPolicyInput>.of(
      _state.inputsByMetal,
    );
    final dirtyMetals = Set<String>.of(_state.dirtyMetals)..remove(metal);
    settings[metal] = parsedModel;
    inputs[metal] = SalesBillingPolicyInput.fromModel(parsedModel);
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
    SalesBillingModel Function(SalesBillingModel model) update,
  ) {
    final current = _state.currentSettings;
    if (current == null) return;
    final settings = Map<String, SalesBillingModel>.of(_state.settingsByMetal);
    settings[_state.selectedMetal] = update(current);
    _markDirty(settingsByMetal: settings);
  }

  void _markDirty({
    Map<String, SalesBillingModel>? settingsByMetal,
    Map<String, SalesBillingPolicyInput>? inputsByMetal,
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

  void _emit(SalesBillingState state) {
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
