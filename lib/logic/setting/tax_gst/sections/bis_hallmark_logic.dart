// ============================================================
// FILE    : lib/logic/setting/tax_gst/sections/bis_hallmark_logic.dart
// MODULE  : Tax & GST — Section 7
// ============================================================
import 'package:flutter/material.dart';
import '../../../../database/tables/setting/tax_gst/tax_gst_config_dao.dart'; // ✅ fixed: trailing space removed
import '../../../../database/db/app_database.dart';
import '../../../../theme/settings/tax_gst/tax_gst_strings.dart';

class BisHallmarkLogic extends ChangeNotifier {
  BisHallmarkLogic(AppDatabase db) : _dao = TaxGstConfigDao(db);
  final TaxGstConfigDao _dao;

  bool isEditing = false;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  final TextEditingController bisLicenseCtrl = TextEditingController();
  final TextEditingController bisValidFromCtrl = TextEditingController();
  final TextEditingController bisValidUptoCtrl = TextEditingController();
  final TextEditingController huidCtrl = TextEditingController();

  void populateFrom(TaxGstConfigData? data) {
    if (data == null) return;
    bisLicenseCtrl.text = data.bisLicenseNumber ?? '';
    bisValidFromCtrl.text = data.bisLicenseValidFrom ?? '';
    bisValidUptoCtrl.text = data.bisLicenseValidUpto ?? '';
    huidCtrl.text = data.huidNumber ?? '';
    notifyListeners();
  }

  void beginEdit() {
    isEditing = true;
    _clear();
    notifyListeners();
  }

  void cancelEdit() {
    isEditing = false;
    _clear();
    notifyListeners();
  }

  Future<bool> save() async {
    isSaving = true;
    notifyListeners();
    try {
      await _dao.saveBisHallmark(
        bisLicense: _ne(bisLicenseCtrl.text),
        bisValidFrom: _ne(bisValidFromCtrl.text),
        bisValidUpto: _ne(bisValidUptoCtrl.text),
        huidNumber: _ne(huidCtrl.text),
      );
      isEditing = false;
      successMessage = TaxGstStrings.snackSaved;
      return true;
    } catch (_) {
      errorMessage = TaxGstStrings.snackSaveError;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  String? _ne(String v) => v.trim().isEmpty ? null : v.trim();
  void _clear() {
    errorMessage = null;
    successMessage = null;
  }

  @override
  void dispose() {
    bisLicenseCtrl.dispose();
    bisValidFromCtrl.dispose();
    bisValidUptoCtrl.dispose();
    huidCtrl.dispose();
    super.dispose();
  }
}
