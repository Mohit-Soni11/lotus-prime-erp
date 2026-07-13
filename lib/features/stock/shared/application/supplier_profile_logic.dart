import 'package:flutter/foundation.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier_profile/supplier_profile_model.dart';
import 'package:lotus_erp/repositories/supplier/supplier_profile_repository.dart';

enum SupplierProfileState { loading, loaded, error, saving, deleting, deleted }

class SupplierProfileLogic extends ChangeNotifier {
  final SupplierProfileRepository _repo;
  final int supplierId;

  SupplierProfileLogic({
    required this.supplierId,
    SupplierProfileRepository? repo,
  }) : _repo = repo ?? SupplierProfileRepository() {
    _load();
  }

  SupplierProfileState _state = SupplierProfileState.loading;
  SupplierProfileModel? _profile;
  String? _error;
  bool _editMode = false;
  bool _savingEdit = false;
  String? _editError;
  int _activeTab = 0;

  SupplierProfileState get state => _state;
  SupplierProfileModel? get profile => _profile;
  String? get error => _error;
  bool get isLoading => _state == SupplierProfileState.loading;
  bool get isSaving => _state == SupplierProfileState.saving;
  bool get editMode => _editMode;
  bool get savingEdit => _savingEdit;
  String? get editError => _editError;
  int get activeTab => _activeTab;

  Future<void> _load() async {
    _state = SupplierProfileState.loading;
    _error = null;
    notifyListeners();

    final result = await _repo.fetchProfile(supplierId);
    if (result == null) {
      _error = 'Supplier profile not found';
      _state = SupplierProfileState.error;
    } else {
      _profile = result;
      _state = SupplierProfileState.loaded;
    }
    notifyListeners();
  }

  Future<void> refresh() => _load();

  void setTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  void enterEditMode() {
    _editMode = true;
    _editError = null;
    notifyListeners();
  }

  void cancelEditMode() {
    _editMode = false;
    _editError = null;
    notifyListeners();
  }

  Future<bool> saveEdit({
    required String businessName,
    required String mobile,
    required String supplierType,
    String contactPersonName = '',
    String whatsapp = '',
    String email = '',
    String alternateContact = '',
    String panNumber = '',
    String gstNumber = '',
    String addressLine1 = '',
    String addressLine2 = '',
    String state = '',
    String pincode = '',
    String country = 'India',
    String notes = '',
    double openingBalance = 0.0,
  }) async {
    final current = _profile;
    if (current == null) return false;

    if (businessName.trim().isEmpty) {
      _editError = 'Business name cannot be empty';
      notifyListeners();
      return false;
    }

    final mobileDigits = mobile.replaceAll(RegExp(r'\D'), '');
    if (mobileDigits.length < 10) {
      _editError = 'Mobile number must contain at least 10 digits';
      notifyListeners();
      return false;
    }

    _savingEdit = true;
    _state = SupplierProfileState.saving;
    _editError = null;
    notifyListeners();

    final updatedOutstanding =
        (openingBalance + current.voucherDueTotal - current.oldDueAdjustedTotal)
            .clamp(0.0, double.infinity)
            .toDouble();

    final updated = SupplierProfileModel(
      id: current.id,
      businessName: businessName.trim(),
      contactPersonName: _nullable(contactPersonName),
      supplierType: SupplierType.fromLabel(supplierType),
      mobile: mobile.trim(),
      whatsapp: _nullable(whatsapp),
      email: _nullable(email),
      alternateContact: _nullable(alternateContact),
      panNumber: _nullable(panNumber)?.toUpperCase(),
      gstNumber: _nullable(gstNumber)?.toUpperCase(),
      addressLine1: _nullable(addressLine1),
      addressLine2: _nullable(addressLine2),
      state: _nullable(state),
      pincode: _nullable(pincode),
      country: country.trim().isEmpty ? 'India' : country.trim(),
      openingBalance: openingBalance,
      notes: _nullable(notes),
      status: current.status,
      createdAt: current.createdAt,
      voucherDueTotal: current.voucherDueTotal,
      oldDueAdjustedTotal: current.oldDueAdjustedTotal,
      outstandingDue: updatedOutstanding,
      purchases: current.purchases,
    );

    final ok = await _repo.updateSupplier(updated);
    if (ok) {
      _profile = updated;
      _editMode = false;
      _state = SupplierProfileState.loaded;
    } else {
      _editError = 'Failed to save supplier profile. Please try again.';
      _state = SupplierProfileState.loaded;
    }

    _savingEdit = false;
    notifyListeners();
    return ok;
  }

  Future<bool> deactivateSupplier() async {
    final current = _profile;
    if (current == null) return false;

    _state = SupplierProfileState.deleting;
    notifyListeners();

    final ok = await _repo.deactivateSupplier(current.id);
    _state = ok ? SupplierProfileState.deleted : SupplierProfileState.loaded;
    notifyListeners();
    return ok;
  }
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
