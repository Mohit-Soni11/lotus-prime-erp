// ============================================================
// FILE    : lib/logic/setting/tax_gst/sections/gst_registration_logic.dart
// MODULE  : Tax & GST Configuration — Section 1
// AUTHOR  : Lotus Prime ERP
// VERSION : 1.0.0
// ============================================================

import 'package:flutter/material.dart';
import '../../../../database/tables/setting/tax_gst/tax_gst_config_dao.dart';
import '../../../../database/db/app_database.dart';
import '../../../../models/setting/tax_gst/gst_slab_model.dart';
import '../../../../theme/settings/tax_gst/tax_gst_strings.dart';

class GstRegistrationLogic extends ChangeNotifier {
  GstRegistrationLogic(AppDatabase db) : _dao = TaxGstConfigDao(db);

  final TaxGstConfigDao _dao;

  // ── Edit state ────────────────────────────────────────────────
  bool isEditing = false;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  // ── Controllers ──────────────────────────────────────────────
  final TextEditingController gstinCtrl = TextEditingController();
  final TextEditingController legalNameCtrl = TextEditingController();
  final TextEditingController panCtrl = TextEditingController();
  final TextEditingController tanCtrl = TextEditingController();
  final TextEditingController regDateCtrl = TextEditingController();
  final TextEditingController stateCtrl = TextEditingController();

  String taxpayerType = TaxpayerType.regular.label;

  // ── Validation errors ─────────────────────────────────────────
  String? gstinError;
  String? panError;

  // ── Populate from DB row ──────────────────────────────────────
  void populateFrom(TaxGstConfigData? data) {
    if (data == null) return;
    gstinCtrl.text = data.gstin ?? '';
    legalNameCtrl.text = data.legalName ?? '';
    panCtrl.text = data.panNumber ?? '';
    tanCtrl.text = data.tanNumber ?? '';
    regDateCtrl.text = data.gstRegisteredOn ?? '';
    stateCtrl.text = data.stateCode ?? '';
    taxpayerType = data.taxpayerType;
    notifyListeners();
  }

  // ── Mutators ─────────────────────────────────────────────────
  void setTaxpayerType(String value) {
    taxpayerType = value;
    notifyListeners();
  }

  void beginEdit() {
    isEditing = true;
    _clearMessages();
    notifyListeners();
  }

  void cancelEdit() {
    isEditing = false;
    _clearMessages();
    notifyListeners();
  }

  // ── Validation ───────────────────────────────────────────────
  bool _validate() {
    bool valid = true;
    final gstin = gstinCtrl.text.trim().toUpperCase();
    final pan = panCtrl.text.trim().toUpperCase();

    if (gstin.isNotEmpty &&
        !RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
            .hasMatch(gstin)) {
      gstinError = TaxGstStrings.validGstinFormat;
      valid = false;
    } else {
      gstinError = null;
    }

    if (pan.isNotEmpty &&
        !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan)) {
      panError = TaxGstStrings.validPanFormat;
      valid = false;
    } else {
      panError = null;
    }

    if (!valid) notifyListeners();
    return valid;
  }

  // ── Save ─────────────────────────────────────────────────────
  Future<bool> save() async {
    if (!_validate()) return false;

    isSaving = true;
    notifyListeners();

    try {
      await _dao.saveRegistration(
        gstin: _nullIfEmpty(gstinCtrl.text.trim().toUpperCase()),
        legalName: _nullIfEmpty(legalNameCtrl.text.trim()),
        panNumber: _nullIfEmpty(panCtrl.text.trim().toUpperCase()),
        tanNumber: _nullIfEmpty(tanCtrl.text.trim().toUpperCase()),
        gstRegisteredOn: _nullIfEmpty(regDateCtrl.text.trim()),
        taxpayerType: taxpayerType,
        stateCode: _nullIfEmpty(stateCtrl.text.trim()),
      );
      isEditing = false;
      successMessage = TaxGstStrings.snackSaved;
      return true;
    } catch (e) {
      errorMessage = TaxGstStrings.snackSaveError;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _clearMessages() {
    errorMessage = null;
    successMessage = null;
  }

  String? _nullIfEmpty(String value) => value.isEmpty ? null : value;

  @override
  void dispose() {
    gstinCtrl.dispose();
    legalNameCtrl.dispose();
    panCtrl.dispose();
    tanCtrl.dispose();
    regDateCtrl.dispose();
    stateCtrl.dispose();
    super.dispose();
  }
}
