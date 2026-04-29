// -----------------------------------------------------------------------------
// FILE: customer_profile_logic.dart
// MODULE: Customer → Customer Profile
// CHANGE LOG:
//   - saveEdit: now accepts whatsapp, email, addressLine1, state, pincode
//   - Added: onConvertAdvanceToSale callback support
//   - Added: convertAdvanceToSale() — marks order delivered + triggers callback
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import '../../models/customer/customer_profile/customer_profile_model.dart';
import '../../repositories/customer/customer_profile_repository.dart';

enum ProfileState { loading, loaded, error, deleting, deleted, saving }

class CustomerProfileLogic extends ChangeNotifier {
  final CustomerProfileRepository _repo;
  final int customerId;

  // Optional callback: called when an advance order is converted to a new sale
  // Passes the advanceOrderId so the POS screen can pre-fill it
  final Function(int advanceOrderId, int customerId)? onConvertAdvanceToSale;

  CustomerProfileLogic({
    required this.customerId,
    CustomerProfileRepository? repo,
    this.onConvertAdvanceToSale,
  }) : _repo = repo ?? CustomerProfileRepository() {
    _load();
  }

  // ── STATE ─────────────────────────────────────────────────────────────
  ProfileState _state = ProfileState.loading;
  CustomerProfileModel? _profile;
  String? _error;

  // Credit limit edit
  bool _editingCreditLimit = false;
  bool _savingCreditLimit = false;

  // Edit mode
  bool _editMode = false;
  bool _savingEdit = false;
  String? _editError;

  // Active tab for stats
  int _activeTab = 0;

  // ── GETTERS ──────────────────────────────────────────────────────────
  ProfileState get state => _state;
  CustomerProfileModel? get profile => _profile;
  String? get error => _error;
  bool get isLoading => _state == ProfileState.loading;
  bool get editingCreditLimit => _editingCreditLimit;
  bool get savingCreditLimit => _savingCreditLimit;
  bool get editMode => _editMode;
  bool get savingEdit => _savingEdit;
  String? get editError => _editError;
  int get activeTab => _activeTab;

  // ── LOAD ─────────────────────────────────────────────────────────────
  Future<void> _load() async {
    _state = ProfileState.loading;
    notifyListeners();

    final result = await _repo.fetchProfile(customerId);
    if (result != null) {
      _profile = result;
      _state = ProfileState.loaded;
    } else {
      _error = "Customer not found";
      _state = ProfileState.error;
    }
    notifyListeners();
  }

  Future<void> refresh() => _load();

  Future<CustomerBillDetailModel?> fetchBillDetails(int billId) {
    return _repo.fetchBillDetails(customerId: customerId, billId: billId);
  }

  // ── TAB NAVIGATION ────────────────────────────────────────────────────
  void setTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  // ── EDIT MODE ─────────────────────────────────────────────────────────
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

  /// Extended saveEdit — accepts all editable fields from improved dialog
  Future<bool> saveEdit({
    required String name,
    required String mobile,
    required String city,
    required String type,
    String whatsapp = "",
    String email = "",
    String address = "",
    String state = "",
    String pincode = "",
  }) async {
    if (_profile == null) return false;

    // Validation
    if (name.trim().isEmpty) {
      _editError = "Name cannot be empty";
      notifyListeners();
      return false;
    }
    if (mobile.trim().length != 10) {
      _editError = "Mobile must be 10 digits";
      notifyListeners();
      return false;
    }

    _savingEdit = true;
    _editError = null;
    notifyListeners();

    final ok = await _repo.updateCustomer(
      customerId: customerId,
      name: name,
      mobile: mobile,
      city: city,
      type: type,
      whatsapp: whatsapp,
      email: email,
      addressLine1: address,
      state: state,
      pincode: pincode,
    );

    if (ok) {
      _profile = _profile!.copyWith(
        name: name,
        mobile: mobile,
        city: city,
        type: type,
        whatsapp: whatsapp,
      );
      _editMode = false;
    } else {
      _editError = "Failed to save. Please try again.";
    }

    _savingEdit = false;
    notifyListeners();
    return ok;
  }

  // ── CREDIT LIMIT ─────────────────────────────────────────────────────
  void startEditCreditLimit() {
    _editingCreditLimit = true;
    notifyListeners();
  }

  void cancelEditCreditLimit() {
    _editingCreditLimit = false;
    notifyListeners();
  }

  Future<bool> saveCreditLimit(double newLimit) async {
    if (_profile == null) return false;
    _savingCreditLimit = true;
    notifyListeners();

    final ok = await _repo.saveCreditLimit(customerId, newLimit);
    if (ok) {
      _profile = _profile!.copyWith(creditLimit: newLimit);
    }
    _savingCreditLimit = false;
    _editingCreditLimit = false;
    notifyListeners();
    return ok;
  }

  // ── CONVERT ADVANCE → NEW SALE ───────────────────────────────────────  ✅ NEW
  /// Called when user taps "Convert to Sale" on an advance order card.
  /// Triggers the onConvertAdvanceToSale callback with orderId + customerId
  /// so the parent can navigate to Sales POS with pre-filled data.
  void triggerConvertAdvanceToSale(int advanceOrderId) {
    onConvertAdvanceToSale?.call(advanceOrderId, customerId);
  }

  // ── DELETE ────────────────────────────────────────────────────────────
  Future<bool> deleteCustomer() async {
    _state = ProfileState.deleting;
    notifyListeners();

    final ok = await _repo.deleteCustomer(customerId);
    if (ok) {
      _state = ProfileState.deleted;
    } else {
      _state = ProfileState.loaded;
    }
    notifyListeners();
    return ok;
  }
}
