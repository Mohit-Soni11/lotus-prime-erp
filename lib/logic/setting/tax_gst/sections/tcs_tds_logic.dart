// ============================================================
// FILE    : lib/logic/setting/tax_gst/sections/tcs_tds_logic.dart
// MODULE  : Tax & GST — Section 5
// ============================================================
import 'package:flutter/material.dart';
import '../../../../database/tables/setting/tax_gst/tax_gst_config_dao.dart';
import '../../../../database/db/app_database.dart';
import '../../../../theme/settings/tax_gst/tax_gst_strings.dart';

class TcsTdsLogic extends ChangeNotifier {
  TcsTdsLogic(AppDatabase db) : _dao = TaxGstConfigDao(db);
  final TaxGstConfigDao _dao;

  bool isEditing = false;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  bool tcsEnabled = true;
  bool tdsEnabled = false;

  final TextEditingController tcsThresholdCtrl =
      TextEditingController(text: '200000');
  final TextEditingController tcsRateCtrl = TextEditingController(text: '1.0');
  final TextEditingController tdsRateCtrl = TextEditingController(text: '1.0');

  void populateFrom(TaxGstConfigData? data) {
    if (data == null) return;
    tcsEnabled = data.tcsEnabled;
    tdsEnabled = data.tdsEnabled;
    tcsThresholdCtrl.text = data.tcsThreshold.toStringAsFixed(0);
    tcsRateCtrl.text = data.tcsRatePct.toString();
    tdsRateCtrl.text = data.tdsRatePct.toString();
    notifyListeners();
  }

  void setTcsEnabled(bool v) {
    tcsEnabled = v;
    notifyListeners();
  }

  void setTdsEnabled(bool v) {
    tdsEnabled = v;
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
      await _dao.saveTcsTds(
        tcsEnabled: tcsEnabled,
        tcsThreshold: double.tryParse(tcsThresholdCtrl.text) ?? 200000,
        tcsRate: double.tryParse(tcsRateCtrl.text) ?? 1.0,
        tdsEnabled: tdsEnabled,
        tdsRate: double.tryParse(tdsRateCtrl.text) ?? 1.0,
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

  void _clear() {
    errorMessage = null;
    successMessage = null;
  }

  @override
  void dispose() {
    tcsThresholdCtrl.dispose();
    tcsRateCtrl.dispose();
    tdsRateCtrl.dispose();
    super.dispose();
  }
}
