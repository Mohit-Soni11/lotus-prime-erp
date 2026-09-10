import 'package:flutter/foundation.dart';

import '../../../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../../../../models/setting/billing_setup/booking_advance_billing_model.dart';
import '../data/booking_advance_billing_settings_repository.dart';
import '../domain/booking_advance_billing_input.dart';
import '../domain/booking_advance_billing_validator.dart';
import 'booking_advance_billing_state.dart';

class BookingAdvanceBillingController extends ChangeNotifier {
  final BookingAdvanceBillingSettingsRepository _repository;
  var _state = BookingAdvanceBillingState.initial();
  BookingAdvanceBillingModel? _savedSettings;
  bool _disposed = false;

  BookingAdvanceBillingController({
    BookingAdvanceBillingSettingsRepository? repository,
  }) : _repository = repository ?? BookingAdvanceBillingSettingsRepository();

  BookingAdvanceBillingState get state => _state;

  Future<void> load() async {
    _emit(_state.copyWith(isLoading: true, validationMessages: const []));
    try {
      final settings = await _repository.fetch();
      _savedSettings = settings;
      _emit(
        _state.copyWith(
          isLoading: false,
          settings: settings,
          input: BookingAdvanceBillingInput.fromModel(settings),
          isDirty: false,
          validationMessages: const [],
        ),
      );
    } catch (_) {
      _emit(
        _state.copyWith(
          isLoading: false,
          validationMessages: const [
            'Booking and advance billing settings could not be loaded.',
          ],
        ),
      );
    }
  }

  void updateInput(BookingAdvanceBillingInput input) {
    _emit(
      _state.copyWith(
        input: input,
        isDirty: true,
        validationMessages: const [],
      ),
    );
  }

  void updateDefaultBookingType(String value) {
    _updateSettings((model) => model.copyWith(defaultBookingType: value));
  }

  void updateDefaultPrintFormat(String value) {
    if (!PrintFormat.values.any((format) => format.name == value)) return;
    _updateSettings((model) => model.copyWith(defaultPrintFormat: value));
  }

  void updatePrintCopies(int copies) {
    _updateSettings((model) => model.copyWith(printCopies: copies));
  }

  void updateAllowZeroAdvance(bool value) {
    _updateSettings((model) => model.copyWith(allowZeroAdvance: value));
  }

  void updateIncludeCustomerAddress(bool value) {
    _updateSettings((model) => model.copyWith(includeCustomerAddress: value));
  }

  void updateIncludeRateColumn(bool value) {
    _updateSettings((model) => model.copyWith(includeRateColumn: value));
  }

  void updatePrintTerms(bool value) {
    _updateSettings((model) => model.copyWith(printTermsAndConditions: value));
  }

  void updatePrintFooter(bool value) {
    _updateSettings((model) => model.copyWith(printFooterMessage: value));
  }

  void resetToDefaults() {
    final defaults = BookingAdvanceBillingModel.defaults();
    _emit(
      _state.copyWith(
        settings: defaults,
        input: BookingAdvanceBillingInput.fromModel(defaults),
        isDirty: true,
        validationMessages: const [],
      ),
    );
  }

  void discardChanges() {
    final saved = _savedSettings;
    if (saved == null) return;
    _emit(
      _state.copyWith(
        settings: saved,
        input: BookingAdvanceBillingInput.fromModel(saved),
        isDirty: false,
        validationMessages: const [],
      ),
    );
  }

  Future<bool> save() async {
    final settings = _state.settings;
    final input = _state.input;
    if (settings == null || input == null) return false;

    final validation = BookingAdvanceBillingValidator.validate(
      baseModel: settings,
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
            'Booking and advance billing settings could not be saved.',
          ],
        ),
      );
      return false;
    }

    _savedSettings = parsedModel;
    _emit(
      _state.copyWith(
        isSaving: false,
        settings: parsedModel,
        input: BookingAdvanceBillingInput.fromModel(parsedModel),
        isDirty: false,
        validationMessages: const [],
      ),
    );
    return true;
  }

  void _updateSettings(
    BookingAdvanceBillingModel Function(BookingAdvanceBillingModel model)
        update,
  ) {
    final current = _state.settings;
    if (current == null) return;
    _emit(
      _state.copyWith(
        settings: update(current),
        isDirty: true,
        validationMessages: const [],
      ),
    );
  }

  void _emit(BookingAdvanceBillingState state) {
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
