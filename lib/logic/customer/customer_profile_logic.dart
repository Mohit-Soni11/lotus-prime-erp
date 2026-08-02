// -----------------------------------------------------------------------------
// FILE: customer_profile_logic.dart
// MODULE: Customer -> Customer Profile
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import '../../models/customer/customer_profile/customer_profile_model.dart';
import '../../models/girvi/girvi_invoice_draft.dart';
import '../../repositories/customer/customer_profile_repository.dart';

enum ProfileState { loading, loaded, error, deleting, deleted, saving }

class CustomerProfileLogic extends ChangeNotifier {
  final CustomerProfileRepository _repo;
  final int customerId;

  // Optional callback used when an advance order is converted to a sale.
  final Function(int advanceOrderId, int customerId)? onConvertAdvanceToSale;

  CustomerProfileLogic({
    required this.customerId,
    CustomerProfileRepository? repo,
    this.onConvertAdvanceToSale,
  }) : _repo = repo ?? CustomerProfileRepository() {
    _load();
  }

  // State
  ProfileState _state = ProfileState.loading;
  CustomerProfileModel? _profile;
  String? _error;

  // Due limit edit state. The repository still uses the legacy field name.
  bool _editingCreditLimit = false;
  bool _savingCreditLimit = false;

  // Edit mode
  bool _editMode = false;
  bool _savingEdit = false;
  String? _editError;

  // Active tab for stats
  int _activeTab = 0;

  // Getters
  ProfileState get state => _state;
  CustomerProfileModel? get profile => _profile;
  String? get error => _error;
  bool get isLoading => _state == ProfileState.loading;
  bool get editingCreditLimit => _editingCreditLimit;
  bool get savingCreditLimit => _savingCreditLimit;
  bool get editingDueLimit => _editingCreditLimit;
  bool get savingDueLimit => _savingCreditLimit;
  bool get editMode => _editMode;
  bool get savingEdit => _savingEdit;
  String? get editError => _editError;
  int get activeTab => _activeTab;

  // Load
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

  Future<GirviInvoiceDraft?> fetchGirviInvoiceDraft(int loanId) {
    return _repo.fetchGirviInvoiceDraft(
      customerId: customerId,
      loanId: loanId,
    );
  }

  // Tab navigation
  void setTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  // Edit mode
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

  /// Saves all editable fields from the profile edit dialog.
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

    if (name.trim().isEmpty) {
      _editError = "Name cannot be empty";
      notifyListeners();
      return false;
    }
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanMobile.isNotEmpty && cleanMobile.length != 10) {
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
      mobile: cleanMobile,
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
        mobile: cleanMobile,
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

  // Due limit
  void startEditDueLimit() => startEditCreditLimit();

  void cancelEditDueLimit() => cancelEditCreditLimit();

  Future<bool> saveDueLimit(double newLimit) => saveCreditLimit(newLimit);

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

  // Convert advance to new sale
  void triggerConvertAdvanceToSale(int advanceOrderId) {
    onConvertAdvanceToSale?.call(advanceOrderId, customerId);
  }

  // Delete
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
