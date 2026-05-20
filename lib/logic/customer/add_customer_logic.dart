// =============================================================================
// FILE        : add_customer_logic.dart
// MODULE      : Customer → Add New Customer
// LAYER       : Logic / Controller
// VERSION     : 2.0 — Full expansion
// =============================================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../models/customer/customer_enums/add_customer_enums.dart';
import '../../models/customer/add_customer/add_customer_form_model.dart';
import '../../helpers/add_customer_/add_customer_validator.dart';
import '../../repositories/customer/add_customer_repository.dart';

class AddCustomerLogic extends ChangeNotifier {
  final AddCustomerRepository _repo;

  AddCustomerLogic({AddCustomerRepository? repo})
      : _repo = repo ?? AddCustomerRepository();

  // ── STATE ─────────────────────────────────────────────────────────────────
  AddCustomerFormModel _form = const AddCustomerFormModel();
  SaveState _saveState = SaveState.idle;
  ActiveField _activeField = ActiveField.none;
  Timer? _mobileDebounce;
  int _membershipSeq = 1;

  // ── GETTERS ──────────────────────────────────────────────────────────────
  AddCustomerFormModel get form => _form;
  SaveState get saveState => _saveState;
  ActiveField get activeField => _activeField;
  bool get isSaving => _saveState == SaveState.saving;
  bool get canSave => _form.isReadyToSave && !isSaving;

  // ── FOCUS ────────────────────────────────────────────────────────────────
  void setActiveField(ActiveField f) {
    _activeField = f;
    notifyListeners();
  }

  // ── ENTITY TYPE ──────────────────────────────────────────────────────────
  void setEntityType(CustomerEntityType t) {
    _form = _form.copyWith(entityType: t);
    notifyListeners();
  }

  // ── PERSONAL ─────────────────────────────────────────────────────────────
  void onFirstNameChanged(String v) {
    _form = _form.copyWith(
      firstName: v,
      clearFirstNameError: v.trim().length >= 2,
      firstNameError:
          v.trim().isNotEmpty && v.trim().length < 2 ? 'Name too short' : null,
    );
    notifyListeners();
  }

  void onLastNameChanged(String v) {
    _form = _form.copyWith(lastName: v);
    notifyListeners();
  }

  void onCompanyNameChanged(String v) {
    _form = _form.copyWith(companyName: v);
    notifyListeners();
  }

  void onContactPersonChanged(String v) {
    _form = _form.copyWith(contactPersonName: v);
    notifyListeners();
  }

  void setDateOfBirth(DateTime? date) {
    _form = date == null
        ? _form.copyWith(clearDob: true)
        : _form.copyWith(dateOfBirth: date);
    notifyListeners();
  }

  void setGender(Gender? g) {
    _form = g == null
        ? _form.copyWith(clearGender: true)
        : _form.copyWith(gender: g);
    notifyListeners();
  }

  void setAnniversaryDate(DateTime? date) {
    _form = date == null
        ? _form.copyWith(clearAnniversary: true)
        : _form.copyWith(anniversaryDate: date);
    notifyListeners();
  }

  // ── CONTACT ───────────────────────────────────────────────────────────────
  void onMobileChanged(String v) {
    final liveErr = AddCustomerValidator.validateMobileLive(v);
    _form = _form.copyWith(
      mobile: v,
      mobileError: liveErr,
      whatsapp: _form.sameAsWhatsApp ? v : _form.whatsapp,
    );
    notifyListeners();

    _mobileDebounce?.cancel();
    if (v.trim().length == 10 && liveErr == null) {
      _mobileDebounce = Timer(const Duration(milliseconds: 600), () async {
        final isDup = await _repo.isMobileDuplicate(v.trim());
        if (isDup) {
          _form = _form.copyWith(mobileError: 'Mobile already registered');
          notifyListeners();
        }
      });
    }
  }

  void setSameAsWhatsApp(bool val) {
    _form = _form.copyWith(
      sameAsWhatsApp: val,
      whatsapp: val ? _form.mobile : '',
    );
    notifyListeners();
  }

  void onWhatsappChanged(String v) {
    _form = _form.copyWith(whatsapp: v);
    notifyListeners();
  }

  void onEmailChanged(String v) {
    final err = AddCustomerValidator.validateEmailLive(v);
    _form =
        _form.copyWith(email: v, emailError: err, clearEmailError: err == null);
    notifyListeners();
  }

  void onAlternateContactChanged(String v) {
    _form = _form.copyWith(alternateContact: v);
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
        ? _form.copyWith(clearIdProofType: true)
        : _form.copyWith(idProofType: t);
    notifyListeners();
  }

  void onIdProofNumberChanged(String v) {
    _form = _form.copyWith(idProofNumber: v);
    notifyListeners();
  }

  void setIdProofDocPath(String? path) {
    _form = path == null
        ? _form.copyWith(clearIdProofDocPath: true)
        : _form.copyWith(idProofDocPath: path);
    notifyListeners();
  }

  void onGstChanged(String v) {
    _form = _form.copyWith(gstNumber: v.toUpperCase());
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
    _form = _form.copyWith(pincode: v);
    notifyListeners();
  }

  // ── BILLING ───────────────────────────────────────────────────────────────
  void onOpeningBalanceChanged(String v) {
    _form = _form.copyWith(openingBalance: double.tryParse(v) ?? 0.0);
    notifyListeners();
  }

  void onCreditLimitChanged(String v) {
    _form = _form.copyWith(creditLimit: double.tryParse(v) ?? 0.0);
    notifyListeners();
  }

  void setCustomerTier(CustomerTier t) {
    _form = _form.copyWith(customerTier: t);
    notifyListeners();
  }

  String generateMembershipId() {
    final now = DateTime.now();
    final ym = DateFormat('yyyyMM').format(now);
    final seq = _membershipSeq.toString().padLeft(4, '0');
    _membershipSeq++;
    final id = 'LTMP-$ym-$seq';
    _form = _form.copyWith(membershipId: id);
    notifyListeners();
    return id;
  }

  // ── PREFERENCES ───────────────────────────────────────────────────────────
  void setRingSize(RingSize? r) {
    _form = r == null
        ? _form.copyWith(clearRingSize: true)
        : _form.copyWith(ringSize: r);
    notifyListeners();
  }

  void setBangleSize(BangleSize? b) {
    _form = b == null
        ? _form.copyWith(clearBangleSize: true)
        : _form.copyWith(bangleSize: b);
    notifyListeners();
  }

  void addFamilyMember() {
    final newId = 'fm_${Random().nextInt(99999)}';
    final updated = [..._form.familyMembers, FamilyMember(id: newId)];
    _form = _form.copyWith(familyMembers: updated);
    notifyListeners();
  }

  void removeFamilyMember(String id) {
    final updated = _form.familyMembers.where((m) => m.id != id).toList();
    _form = _form.copyWith(familyMembers: updated);
    notifyListeners();
  }

  void updateFamilyMember(String id, FamilyMember updated) {
    final list =
        _form.familyMembers.map((m) => m.id == id ? updated : m).toList();
    _form = _form.copyWith(familyMembers: list);
    notifyListeners();
  }

  // ── ADDITIONAL ────────────────────────────────────────────────────────────
  void setReferralSource(ReferralSource? r) {
    _form = r == null
        ? _form.copyWith(clearReferralSource: true)
        : _form.copyWith(referralSource: r);
    notifyListeners();
  }

  void onNotesChanged(String v) {
    _form = _form.copyWith(notes: v);
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
    _saveState = SaveState.validating;
    notifyListeners();

    final nameErr = _form.isCorporate
        ? AddCustomerValidator.validateCompanyName(_form.companyName)
        : AddCustomerValidator.validateName(_form.firstName);
    final mobileErr = AddCustomerValidator.validateMobile(_form.mobile);
    final panErr = AddCustomerValidator.validatePan(_form.panNumber);
    final emailErr = AddCustomerValidator.validateEmail(_form.email);

    if (nameErr != null ||
        mobileErr != null ||
        panErr != null ||
        emailErr != null) {
      _form = _form.copyWith(
        firstNameError: nameErr,
        mobileError: mobileErr,
        panError: panErr,
        emailError: emailErr,
      );
      _saveState = SaveState.idle;
      notifyListeners();
      return false;
    }

    _saveState = SaveState.saving;
    notifyListeners();

    final result = await _repo.saveCustomer(_form);
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
    _form = const AddCustomerFormModel();
    _saveState = SaveState.idle;
    _activeField = ActiveField.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _mobileDebounce?.cancel();
    super.dispose();
  }
}
