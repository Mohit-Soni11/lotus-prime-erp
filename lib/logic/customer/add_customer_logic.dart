// =============================================================================
// FILE        : add_customer_logic.dart
// MODULE      : Customer → Add New Customer
// LAYER       : Logic / Controller
// VERSION     : 2.0 — Full expansion
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/customer/customer_enums/add_customer_enums.dart';
import '../../models/customer/add_customer/add_customer_form_model.dart';
import '../../helpers/add_customer_/add_customer_validator.dart';
import '../../helpers/add_customer_/add_customer_form_validation.dart';
import '../../repositories/customer/add_customer_repository.dart';

class AddCustomerLogic extends ChangeNotifier {
  final AddCustomerRepository _repo;
  final int? customerId;

  AddCustomerLogic({
    AddCustomerRepository? repo,
    this.customerId,
  }) : _repo = repo ?? AddCustomerRepository();

  // ── STATE ─────────────────────────────────────────────────────────────────
  AddCustomerFormModel _form = const AddCustomerFormModel();
  AddCustomerFormModel? _initialEditForm;
  SaveState _saveState = SaveState.idle;
  ActiveField _activeField = ActiveField.none;
  Timer? _mobileDebounce;
  int _mobileCheckVersion = 0;
  bool _disposed = false;

  // ── GETTERS ──────────────────────────────────────────────────────────────
  AddCustomerFormModel get form => _form;
  SaveState get saveState => _saveState;
  ActiveField get activeField => _activeField;
  bool get isSaving => _saveState == SaveState.saving;
  bool get canSave => !isSaving;
  bool get isEditMode => customerId != null;

  Future<AddCustomerFormModel?> loadCustomerForEdit() async {
    final id = customerId;
    if (id == null) return null;

    final loadedForm = await _repo.fetchCustomerForEdit(id);
    if (_disposed) return null;
    if (loadedForm != null) {
      _form = loadedForm;
      _initialEditForm = loadedForm;
      _saveState = SaveState.idle;
      notifyListeners();
    }
    return loadedForm;
  }

  // ── FOCUS ────────────────────────────────────────────────────────────────
  void setActiveField(ActiveField f) {
    _activeField = f;
    notifyListeners();
  }

  // ── ENTITY TYPE ──────────────────────────────────────────────────────────
  void setEntityType(CustomerEntityType t) {
    _form = _form.copyWith(
      entityType: t,
      clearFirstNameError: true,
      clearCompanyNameError: true,
    );
    notifyListeners();
  }

  // ── PERSONAL ─────────────────────────────────────────────────────────────
  void onFirstNameChanged(String v) {
    final error =
        v.trim().isEmpty ? null : AddCustomerValidator.validateName(v);
    _form = _form.copyWith(
      firstName: v,
      firstNameError: error,
      clearFirstNameError: error == null,
    );
    notifyListeners();
  }

  void onLastNameChanged(String v) {
    _form = _form.copyWith(lastName: v);
    notifyListeners();
  }

  void onCompanyNameChanged(String v) {
    _form = _form.copyWith(companyName: v, clearCompanyNameError: true);
    notifyListeners();
  }

  void onContactPersonChanged(String v) {
    _form = _form.copyWith(contactPersonName: v);
    notifyListeners();
  }

  void setGender(Gender? g) {
    _form = g == null
        ? _form.copyWith(clearGender: true)
        : _form.copyWith(gender: g);
    notifyListeners();
  }

  // ── CONTACT ───────────────────────────────────────────────────────────────
  void onMobileChanged(String v) {
    final liveErr = AddCustomerValidator.validateMobileLive(v);
    _mobileDebounce?.cancel();
    final version = ++_mobileCheckVersion;
    _form = _form.copyWith(
      mobile: v,
      mobileError: liveErr,
      clearMobileError: liveErr == null,
      whatsapp: _form.sameAsWhatsApp ? v : _form.whatsapp,
      clearWhatsappError: _form.sameAsWhatsApp,
    );
    notifyListeners();

    if (AddCustomerValidator.validateMobile(v) == null && v.trim().isNotEmpty) {
      _mobileDebounce = Timer(const Duration(milliseconds: 600), () async {
        try {
          final isDup = await _repo.isMobileDuplicate(v.trim(),
              excludeCustomerId: customerId);
          if (!_disposed && version == _mobileCheckVersion && isDup) {
            _form = _form.copyWith(mobileError: 'Mobile already registered');
            notifyListeners();
          }
        } catch (_) {
          // Save performs the authoritative duplicate check.
        }
      });
    }
  }

  void setSameAsWhatsApp(bool val) {
    _form = _form.copyWith(
      sameAsWhatsApp: val,
      whatsapp: val ? _form.mobile : '',
      clearWhatsappError: true,
    );
    notifyListeners();
  }

  void onWhatsappChanged(String v) {
    _form = _form.copyWith(whatsapp: v, clearWhatsappError: true);
    notifyListeners();
  }

  void onEmailChanged(String v) {
    final err = AddCustomerValidator.validateEmailLive(v);
    _form =
        _form.copyWith(email: v, emailError: err, clearEmailError: err == null);
    notifyListeners();
  }

  void onAlternateContactChanged(String v) {
    _form =
        _form.copyWith(alternateContact: v, clearAlternateContactError: true);
    notifyListeners();
  }

  // ── KYC ──────────────────────────────────────────────────────────────────
  void onPanChanged(String v) {
    final err = AddCustomerValidator.validatePanLive(v);
    _form = _form.copyWith(
        panNumber: v.toUpperCase(), panError: err, clearPanError: err == null);
    notifyListeners();
  }

  void setIdProofType(IdProofType? t) {
    _form = t == null
        ? _form.copyWith(clearIdProofType: true, clearIdProofError: true)
        : _form.copyWith(idProofType: t, clearIdProofError: true);
    notifyListeners();
  }

  void onIdProofNumberChanged(String v) {
    _form = _form.copyWith(idProofNumber: v, clearIdProofError: true);
    notifyListeners();
  }

  void setIdProofDocPath(String? path) {
    _form = path == null
        ? _form.copyWith(clearIdProofDocPath: true)
        : _form.copyWith(idProofDocPath: path);
    notifyListeners();
  }

  void onGstChanged(String v) {
    _form = _form.copyWith(gstNumber: v.toUpperCase(), clearGstError: true);
    notifyListeners();
  }

  // ── ADDRESS ───────────────────────────────────────────────────────────────
  void onAddressLine1Changed(String v) {
    _form = _form.copyWith(addressLine1: v);
    notifyListeners();
  }

  void onAddressLine2Changed(String v) {
    _form = _form.copyWith(addressLine2: v);
    notifyListeners();
  }

  void setCountry(String v) {
    _form = _form.copyWith(country: v, state: '');
    notifyListeners();
  }

  // ignore: use_setters_to_change_properties (matches setState_ naming)
  void setState_(String v) {
    _form = _form.copyWith(state: v);
    notifyListeners();
  }

  void onCityChanged(String v) {
    _form = _form.copyWith(city: v);
    notifyListeners();
  }

  void onPincodeChanged(String v) {
    _form = _form.copyWith(pincode: v, clearPincodeError: true);
    notifyListeners();
  }

  void setProfileImagePath(String? path) {
    _form = path == null
        ? _form.copyWith(clearProfileImage: true)
        : _form.copyWith(profileImagePath: path);
    notifyListeners();
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────
  Future<bool> saveCustomer() async {
    _mobileDebounce?.cancel();
    _mobileCheckVersion++;
    _saveState = SaveState.validating;
    notifyListeners();
    _form = AddCustomerFormValidation.apply(_form);
    if (_form.hasErrors) {
      _saveState = SaveState.validationError;
      notifyListeners();
      return false;
    }

    _saveState = SaveState.saving;
    notifyListeners();

    final result = await _repo.saveCustomer(
      _form,
      customerId: customerId,
    );
    if (_disposed) return result == SaveResult.success;
    switch (result) {
      case SaveResult.success:
        _saveState = SaveState.success;
        notifyListeners();
        return true;
      case SaveResult.duplicate:
        _form = _form.copyWith(mobileError: 'Mobile already registered');
        _saveState = SaveState.duplicate;
        notifyListeners();
        return false;
      case SaveResult.error:
        _saveState = SaveState.error;
        notifyListeners();
        return false;
    }
  }

  // ── RESET ─────────────────────────────────────────────────────────────────
  void resetForm() {
    _mobileDebounce?.cancel();
    _mobileCheckVersion++;
    _form = _initialEditForm ?? const AddCustomerFormModel();
    _saveState = SaveState.idle;
    _activeField = ActiveField.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _mobileCheckVersion++;
    _mobileDebounce?.cancel();
    super.dispose();
  }
}
