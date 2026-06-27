import 'package:flutter/foundation.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';

import '../data/girvi_billing_settings_repository.dart';
import '../domain/girvi_billing_options.dart';
import '../domain/girvi_billing_policy_input.dart';
import '../domain/girvi_billing_validator.dart';
import 'girvi_billing_state.dart';

class GirviBillingController extends ChangeNotifier {
  final GirviBillingSettingsRepository _repository;
  var _state = GirviBillingState.initial();
  var _savedModel = GirviBillingModel.defaults;
  bool _disposed = false;

  GirviBillingController({
    GirviBillingSettingsRepository? repository,
  }) : _repository = repository ?? GirviBillingSettingsRepository();

  GirviBillingState get state => _state;

  Future<void> load() async {
    _emit(_state.copyWith(isLoading: true, validationMessages: const []));
    try {
      final model = await _repository.fetch();
      _savedModel = model;
      _emit(
        _state.copyWith(
          isLoading: false,
          isDirty: false,
          model: model,
          input: GirviBillingPolicyInput.fromModel(model),
          validationMessages: const [],
        ),
      );
    } catch (_) {
      _emit(
        _state.copyWith(
          isLoading: false,
          validationMessages: const [
            'Girvi billing settings could not be loaded.',
          ],
        ),
      );
    }
  }

  void selectInvoiceMetal(String metal) {
    final normalized = GirviBillingMetal.normalize(metal);
    if (!GirviBillingMetal.supported.contains(normalized)) return;
    _emit(
      _state.copyWith(
        selectedInvoiceMetal: normalized,
        validationMessages: const [],
      ),
    );
  }

  void updateInput(GirviBillingPolicyInput input) {
    _markDirty(input: input);
  }

  void updateModel(GirviBillingModel model) {
    _markDirty(model: model);
  }

  void updateInterestType(String value) {
    if (!GirviBillingOptions.interestTypes.contains(value)) return;
    _markDirty(model: _state.model.copyWith(interestType: value));
  }

  void updateDefaultDuration(String value) {
    if (!GirviBillingOptions.durations.contains(value)) return;
    _markDirty(model: _state.model.copyWith(defaultDuration: value));
  }

  void updateSelectedTemplate(String templateId) {
    if (!PrintTemplateRegistry.templateIds.contains(templateId)) return;
    _markDirty(model: _state.model.copyWith(selectedTemplate: templateId));
  }

  void updateAutoPrint(bool value) {
    _markDirty(model: _state.model.copyWith(autoPrint: value));
  }

  void resetToDefaults() {
    final model = GirviBillingModel.defaults;
    _emit(
      _state.copyWith(
        isDirty: true,
        model: model,
        input: GirviBillingPolicyInput.fromModel(model),
        selectedInvoiceMetal: GirviBillingMetal.gold,
        validationMessages: const [],
      ),
    );
  }

  void discardChanges() {
    _emit(
      _state.copyWith(
        isDirty: false,
        model: _savedModel,
        input: GirviBillingPolicyInput.fromModel(_savedModel),
        validationMessages: const [],
      ),
    );
  }

  Future<bool> save() async {
    final validation = GirviBillingValidator.validate(
      baseModel: _state.model,
      input: _state.input,
    );
    if (!validation.isValid) {
      _emit(_state.copyWith(validationMessages: validation.messages));
      return false;
    }

    final model = validation.model!;
    _emit(_state.copyWith(isSaving: true, validationMessages: const []));
    final saved = await _repository.save(model);
    if (!saved) {
      _emit(
        _state.copyWith(
          isSaving: false,
          validationMessages: const [
            'Girvi billing settings could not be saved.',
          ],
        ),
      );
      return false;
    }

    _savedModel = model;
    _emit(
      _state.copyWith(
        isSaving: false,
        isDirty: false,
        model: model,
        input: GirviBillingPolicyInput.fromModel(model),
        validationMessages: const [],
      ),
    );
    return true;
  }

  void _markDirty({
    GirviBillingModel? model,
    GirviBillingPolicyInput? input,
  }) {
    _emit(
      _state.copyWith(
        isDirty: true,
        model: model,
        input: input,
        validationMessages: const [],
      ),
    );
  }

  void _emit(GirviBillingState state) {
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
