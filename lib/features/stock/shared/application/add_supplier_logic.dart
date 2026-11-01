import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/helpers/add_supplier/add_supplier_validator.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/add_supplier_form_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/repositories/supplier/supplier_repository.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

enum AddSupplierFormState {
  idle,
  validating,
  saving,
  success,
  duplicate,
  error,
}

class AddSupplierLogic extends ChangeNotifier {
  late final SupplierRepository _repo;

  AddSupplierLogic({SupplierModel? existing, SupplierRepository? repo}) {
    _repo = repo ?? SupplierRepository(AppDatabase());
    _isEdit = existing != null;
    _form = existing == null
        ? const AddSupplierFormModel()
        : AddSupplierFormModel.fromSupplier(existing);
  }

  bool _isEdit = false;
  AddSupplierFormModel _form = const AddSupplierFormModel();
  AddSupplierFormState _formState = AddSupplierFormState.idle;
  SupplierActiveField _activeField = SupplierActiveField.none;
  String? _errorMessage;
  String? _successMessage;
  Timer? _mobileDebounce;
  int _mobileCheckVersion = 0;
  bool _disposed = false;

  bool get isEditMode => _isEdit;
  AddSupplierFormModel get form => _form;
  AddSupplierFormState get formState => _formState;
  SupplierActiveField get activeField => _activeField;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isSaving => _formState == AddSupplierFormState.saving;
  bool get canSave => _form.isReadyToSave && !isSaving;

  void setActiveField(SupplierActiveField field) {
    _activeField = field;
    notifyListeners();
  }

  void onBusinessNameChanged(String value) {
    final err = AddSupplierValidator.validateBusinessNameLive(value);
    _form = _form.copyWith(
      businessName: value,
      businessNameError: err,
      clearBusinessNameError: err == null,
    );
    notifyListeners();
  }

  void onContactPersonChanged(String value) {
    _form = _form.copyWith(contactPersonName: value);
    notifyListeners();
  }

  void setSupplierType(SupplierType value) {
    _form = _form.copyWith(supplierType: value);
    notifyListeners();
  }

  void onMobileChanged(String value) {
    final version = ++_mobileCheckVersion;
    final err = AddSupplierValidator.validateMobileLive(value);
    _form = _form.copyWith(
      mobile: value,
      mobileError: err,
      clearMobileError: err == null,
      whatsapp: _form.sameAsWhatsApp ? value : _form.whatsapp,
    );
    notifyListeners();

    _mobileDebounce?.cancel();
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 && err == null) {
      _mobileDebounce = Timer(const Duration(milliseconds: 550), () async {
        try {
          final duplicate = await _repo.isMobileDuplicate(
            value.trim(),
            excludeSupplierId: _form.id,
          );
          if (!_disposed && version == _mobileCheckVersion && duplicate) {
            _form = _form.copyWith(
              mobileError: 'This mobile number already exists',
            );
            notifyListeners();
          }
        } catch (error) {
          AppLogger.debug('Supplier mobile lookup failed: $error');
        }
      });
    }
  }

  void setSameAsWhatsApp(bool value) {
    _form = _form.copyWith(
      sameAsWhatsApp: value,
      whatsapp: value ? _form.mobile : '',
      clearWhatsappError: true,
    );
    notifyListeners();
  }

  void onWhatsappChanged(String value) {
    final err = AddSupplierValidator.validateWhatsapp(value);
    _form = _form.copyWith(
      whatsapp: value,
      whatsappError: err,
      clearWhatsappError: err == null,
      sameAsWhatsApp: false,
    );
    notifyListeners();
  }

  void onEmailChanged(String value) {
    final err = AddSupplierValidator.validateEmail(value);
    _form = _form.copyWith(
      email: value,
      emailError: err,
      clearEmailError: err == null,
    );
    notifyListeners();
  }

  void onAlternateContactChanged(String value) {
    _form = _form.copyWith(alternateContact: value);
    notifyListeners();
  }

  void onPanChanged(String value) {
    final normalized = value.toUpperCase();
    final err = AddSupplierValidator.validatePan(normalized);
    _form = _form.copyWith(
      panNumber: normalized,
      panError: err,
      clearPanError: err == null,
    );
    notifyListeners();
  }

  void onGstChanged(String value) {
    final normalized = value.toUpperCase();
    final err = AddSupplierValidator.validateGst(normalized);
    _form = _form.copyWith(
      gstNumber: normalized,
      gstError: err,
      clearGstError: err == null,
    );
    notifyListeners();
  }

  void onAddressLine1Changed(String value) {
    _form = _form.copyWith(addressLine1: value);
    notifyListeners();
  }

  void onAddressLine2Changed(String value) {
    _form = _form.copyWith(addressLine2: value);
    notifyListeners();
  }

  void setCountry(String value) {
    _form = _form.copyWith(
        country: value, state: '', pincode: '', clearPincodeError: true);
    notifyListeners();
  }

  void setStateName(String value) {
    _form = _form.copyWith(state: value);
    notifyListeners();
  }

  void onPincodeChanged(String value) {
    final err =
        AddSupplierValidator.validatePostalCode(value, country: _form.country);
    _form = _form.copyWith(
      pincode: value,
      pincodeError: err,
      clearPincodeError: err == null,
    );
    notifyListeners();
  }

  Future<bool> save() async {
    _mobileDebounce?.cancel();
    _mobileCheckVersion++;
    _formState = AddSupplierFormState.validating;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final businessErr = AddSupplierValidator.validateBusinessName(
      _form.businessName,
    );
    final mobileErr = AddSupplierValidator.validateMobile(_form.mobile);
    final whatsappErr = AddSupplierValidator.validateWhatsapp(_form.whatsapp);
    final emailErr = AddSupplierValidator.validateEmail(_form.email);
    final panErr = AddSupplierValidator.validatePan(_form.panNumber);
    final gstErr = AddSupplierValidator.validateGst(_form.gstNumber);
    final pincodeErr = AddSupplierValidator.validatePostalCode(_form.pincode,
        country: _form.country);

    if (businessErr != null ||
        mobileErr != null ||
        whatsappErr != null ||
        emailErr != null ||
        panErr != null ||
        gstErr != null ||
        pincodeErr != null) {
      _form = _form.copyWith(
        businessNameError: businessErr,
        mobileError: mobileErr,
        whatsappError: whatsappErr,
        emailError: emailErr,
        panError: panErr,
        gstError: gstErr,
        pincodeError: pincodeErr,
      );
      _formState = AddSupplierFormState.idle;
      notifyListeners();
      return false;
    }

    bool duplicate;
    try {
      duplicate = await _repo.isMobileDuplicate(
        _form.mobile.trim(),
        excludeSupplierId: _form.id,
      );
    } catch (error) {
      AppLogger.debug('Supplier duplicate check failed: $error');
      _errorMessage = 'Could not verify the mobile number. Please retry.';
      _formState = AddSupplierFormState.error;
      notifyListeners();
      return false;
    }
    if (duplicate) {
      _form = _form.copyWith(mobileError: 'This mobile number already exists');
      _formState = AddSupplierFormState.duplicate;
      notifyListeners();
      return false;
    }

    _formState = AddSupplierFormState.saving;
    notifyListeners();

    try {
      final model = _form.toSupplierModel();
      if (_isEdit) {
        final ok = await _repo.updateSupplier(model);
        if (!ok) throw StateError('Supplier update failed');
        _successMessage = 'Supplier "${model.businessName}" updated';
      } else {
        await _repo.addSupplier(model);
        _successMessage = 'Supplier "${model.businessName}" added';
      }

      _formState = AddSupplierFormState.success;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.debug('AddSupplierLogic.save error: $e');
      _errorMessage = e.toString().contains('UNIQUE')
          ? 'A supplier with this mobile number already exists.'
          : 'Could not save supplier. Please try again.';
      _formState = AddSupplierFormState.error;
      notifyListeners();
      return false;
    }
  }

  void resetForm() {
    _mobileDebounce?.cancel();
    _mobileCheckVersion++;
    _form = const AddSupplierFormModel();
    _formState = AddSupplierFormState.idle;
    _activeField = SupplierActiveField.none;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    if (_formState != AddSupplierFormState.saving) {
      _formState = AddSupplierFormState.idle;
    }
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
