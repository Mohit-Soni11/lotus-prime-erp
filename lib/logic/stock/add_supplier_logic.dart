// =============================================================================
// FILE        : add_supplier_logic.dart
// MODULE      : Supplier
// LAYER       : Logic / Controller
// DESCRIPTION : ChangeNotifier for Add / Edit Supplier form.
//               Pattern identical to AddCustomerLogic.
// =============================================================================

import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/stock/supplier_model/supplier_model.dart';
import '../../models/stock/supplier_model/supplier_enums.dart';
import '../../repositories/supplier/supplier_repository.dart';

enum AddSupplierFormState { idle, saving, success, error }

class AddSupplierLogic extends ChangeNotifier {
  late final SupplierRepository _repo;

  /// Pass existing model for Edit mode, null for Add mode.
  AddSupplierLogic({SupplierModel? existing}) {
    _repo = SupplierRepository(AppDatabase());
    _isEdit = existing != null;
    _existingId = existing?.id;
    if (existing != null) _populateFromExisting(existing);
  }

  // ── STATE ──────────────────────────────────────────────────────────────

  bool _isEdit = false;
  int? _existingId;
  AddSupplierFormState _formState = AddSupplierFormState.idle;
  String? _errorMessage;
  String? _successMessage;

  // ── FORM VALUES (kept as plain fields for direct binding) ─────────────

  String businessName = '';
  String contactPerson = '';
  SupplierType supplierType = SupplierType.manufacturer;
  String mobile = '';
  String whatsapp = '';
  String email = '';
  String alternateContact = '';
  String panNumber = '';
  String gstNumber = '';
  String addressLine1 = '';
  String addressLine2 = '';
  String state = '';
  String pincode = '';
  double openingBalance = 0.0;
  String notes = '';

  // ── GETTERS ────────────────────────────────────────────────────────────

  bool get isEditMode => _isEdit;
  AddSupplierFormState get formState => _formState;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isSaving => _formState == AddSupplierFormState.saving;

  // ── POPULATE FOR EDIT ──────────────────────────────────────────────────

  void _populateFromExisting(SupplierModel m) {
    businessName = m.businessName;
    contactPerson = m.contactPersonName ?? '';
    supplierType = m.supplierType;
    mobile = m.mobile;
    whatsapp = m.whatsapp ?? '';
    email = m.email ?? '';
    alternateContact = m.alternateContact ?? '';
    panNumber = m.panNumber ?? '';
    gstNumber = m.gstNumber ?? '';
    addressLine1 = m.addressLine1 ?? '';
    addressLine2 = m.addressLine2 ?? '';
    state = m.state ?? '';
    pincode = m.pincode ?? '';
    openingBalance = m.openingBalance;
    notes = m.notes ?? '';
  }

  // ── SETTERS ────────────────────────────────────────────────────────────

  void setSupplierType(SupplierType val) {
    supplierType = val;
    notifyListeners();
  }

  void setOpeningBalance(String val) {
    openingBalance = double.tryParse(val) ?? 0.0;
  }

  // ── VALIDATORS ─────────────────────────────────────────────────────────

  String? validateBusinessName(String? val) {
    if (val == null || val.trim().isEmpty) return 'Business name is required';
    if (val.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? validateMobile(String? val) {
    if (val == null || val.trim().isEmpty) return 'Mobile number is required';
    final digits = val.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  String? validateGstNumber(String? val) {
    if (val == null || val.trim().isEmpty) return null; // optional
    if (val.trim().length != 15) return 'GST number must be 15 characters';
    return null;
  }

  String? validatePanNumber(String? val) {
    if (val == null || val.trim().isEmpty) return null; // optional
    if (val.trim().length != 10) return 'PAN must be 10 characters';
    return null;
  }

  // ── SAVE ───────────────────────────────────────────────────────────────

  Future<bool> save() async {
    _formState = AddSupplierFormState.saving;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final model = SupplierModel(
        id: _existingId,
        businessName: businessName.trim(),
        contactPersonName:
            contactPerson.trim().isEmpty ? null : contactPerson.trim(),
        supplierType: supplierType,
        mobile: mobile.trim(),
        whatsapp: whatsapp.trim().isEmpty ? null : whatsapp.trim(),
        email: email.trim().isEmpty ? null : email.trim(),
        alternateContact:
            alternateContact.trim().isEmpty ? null : alternateContact.trim(),
        panNumber:
            panNumber.trim().isEmpty ? null : panNumber.trim().toUpperCase(),
        gstNumber:
            gstNumber.trim().isEmpty ? null : gstNumber.trim().toUpperCase(),
        addressLine1: addressLine1.trim().isEmpty ? null : addressLine1.trim(),
        addressLine2: addressLine2.trim().isEmpty ? null : addressLine2.trim(),
        state: state.trim().isEmpty ? null : state.trim(),
        pincode: pincode.trim().isEmpty ? null : pincode.trim(),
        openingBalance: openingBalance,
        notes: notes.trim().isEmpty ? null : notes.trim(),
      );

      if (_isEdit) {
        await _repo.updateSupplier(model);
        _successMessage = 'Supplier "${model.businessName}" updated!';
      } else {
        await _repo.addSupplier(model);
        _successMessage =
            'Supplier "${model.businessName}" added successfully!';
      }

      _formState = AddSupplierFormState.success;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AddSupplierLogic.save error: $e');
      if (e.toString().contains('UNIQUE')) {
        _errorMessage = 'A supplier with this mobile number already exists.';
      } else {
        _errorMessage = 'Could not save supplier. Please try again.';
      }
      _formState = AddSupplierFormState.error;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _formState = AddSupplierFormState.idle;
    notifyListeners();
  }
}
