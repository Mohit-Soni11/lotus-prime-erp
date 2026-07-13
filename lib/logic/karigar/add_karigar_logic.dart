// =============================================================================
// FILE        : add_karigar_logic.dart
// MODULE      : Karigar → Add Karigar
// LAYER       : Logic / Controller
// DESCRIPTION : Full-screen Add Karigar form controller.
//               Handles validation, saving, and state management.
//               ChangeNotifier — zero setState in UI.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/karigar/add_karigar/add_karigar_form_model.dart';
import '../../models/karigar/karigar_enums/karigar_enums.dart';
import '../../repositories/karigar/karigar_directory_repository.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

enum AddKarigarSaveState { idle, saving, success, error }

class AddKarigarLogic extends ChangeNotifier {
  final KarigarDirectoryRepository _repo;

  AddKarigarLogic({AppDatabase? db})
      : _repo = KarigarDirectoryRepository(db ?? AppDatabase());

  // ── STATE ──────────────────────────────────────────────────────────────────
  AddKarigarFormModel _form = AddKarigarFormModel.empty();
  AddKarigarSaveState _saveState = AddKarigarSaveState.idle;
  String? _errorMessage;

  // ── GETTERS ────────────────────────────────────────────────────────────────
  AddKarigarFormModel get form => _form;
  AddKarigarSaveState get saveState => _saveState;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _saveState == AddKarigarSaveState.saving;
  bool get canSave => _form.isValid && !isSaving;

  // ── FIELD HANDLERS ─────────────────────────────────────────────────────────

  void onFirstNameChanged(String v) {
    String? err;
    if (v.trim().isEmpty) {
      err = 'Name is required';
    } else if (v.trim().length < 2) {
      err = 'Name is too short';
    }
    _form = _form.copyWith(
      firstName: v,
      firstNameError: err,
      clearFirstNameError: err == null,
    );
    notifyListeners();
  }

  void onLastNameChanged(String v) {
    _form = _form.copyWith(lastName: v);
    notifyListeners();
  }

  void onPhoneChanged(String v) {
    String? err;
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      err = 'Phone is required';
    } else if (digits.length < 10) {
      err = 'Enter a valid 10-digit number';
    }
    _form = _form.copyWith(
      phone: v,
      phoneError: err,
      clearPhoneError: err == null,
    );
    notifyListeners();
  }

  void onAlternatePhoneChanged(String v) {
    _form = _form.copyWith(alternatePhone: v);
    notifyListeners();
  }

  void setSpecialization(KarigarSpecialization v) {
    _form = _form.copyWith(specialization: v);
    notifyListeners();
  }

  void setRateType(KarigarRateType v) {
    _form = _form.copyWith(rateType: v);
    notifyListeners();
  }

  void onRateAmountChanged(String v) {
    _form = _form.copyWith(rateAmount: double.tryParse(v) ?? 0.0);
    notifyListeners();
  }

  void onAddressChanged(String v) {
    _form = _form.copyWith(address: v);
    notifyListeners();
  }

  void onCityChanged(String v) {
    _form = _form.copyWith(city: v);
    notifyListeners();
  }

  void onOpeningBalanceChanged(String v) {
    _form = _form.copyWith(openingBalance: double.tryParse(v) ?? 0.0);
    notifyListeners();
  }

  void onNotesChanged(String v) {
    _form = _form.copyWith(notes: v);
    notifyListeners();
  }

  void setIsActive(bool v) {
    _form = _form.copyWith(isActive: v);
    notifyListeners();
  }

  void setProfileImagePath(String? path) {
    if (path == null) {
      _form = _form.copyWith(clearProfileImage: true);
    } else {
      _form = _form.copyWith(profileImagePath: path);
    }
    notifyListeners();
  }

  // ── SAVE ───────────────────────────────────────────────────────────────────

  Future<bool> saveKarigar() async {
    // Trigger validation on all required fields
    onFirstNameChanged(_form.firstName);
    onPhoneChanged(_form.phone);
    if (!_form.isValid) return false;

    _saveState = AddKarigarSaveState.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final companion = KarigarMastersCompanion.insert(
        name: _form.fullName,
        phone: _form.phone.trim(),
        alternatePhone: drift.Value(
          _form.alternatePhone.trim().isEmpty
              ? null
              : _form.alternatePhone.trim(),
        ),
        specialization: drift.Value(_form.specialization.label),
        rateType: drift.Value(_form.rateType.label),
        rateAmount: drift.Value(_form.rateAmount),
        address: drift.Value(
          _form.address.trim().isEmpty ? null : _form.address.trim(),
        ),
        city: drift.Value(
          _form.city.trim().isEmpty ? null : _form.city.trim(),
        ),
        openingBalance: drift.Value(_form.openingBalance),
        isActive: drift.Value(_form.isActive),
        notes: drift.Value(
          _form.notes.trim().isEmpty ? null : _form.notes.trim(),
        ),
      );

      await _repo.addKarigar(companion);
      _saveState = AddKarigarSaveState.success;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.debug('AddKarigarLogic.saveKarigar error: $e');
      _saveState = AddKarigarSaveState.error;
      _errorMessage = 'Failed to save karigar. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ── RESET ──────────────────────────────────────────────────────────────────

  void resetForm() {
    _form = AddKarigarFormModel.empty();
    _saveState = AddKarigarSaveState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
