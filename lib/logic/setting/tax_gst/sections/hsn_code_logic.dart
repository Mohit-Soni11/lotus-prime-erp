// ============================================================
// FILE    : lib/logic/setting/tax_gst/sections/hsn_code_logic.dart
// MODULE  : Tax & GST Configuration — Section 3
// ============================================================
import 'package:flutter/material.dart';
import '../../../../database/tables/setting/tax_gst/tax_gst_config_dao.dart';
import '../../../../database/db/app_database.dart';
import '../../../../models/setting/tax_gst/hsn_code_model.dart';
import '../../../../theme/settings/tax_gst/tax_gst_strings.dart';

class HsnCodeLogic extends ChangeNotifier {
  HsnCodeLogic(AppDatabase db) : _dao = TaxGstConfigDao(db);
  final TaxGstConfigDao _dao;

  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  List<HsnCodeModel> codes = defaultHsnCodeModels();

  // ── Add HSN dialog controllers ────────────────────────────────
  final TextEditingController addCategoryCtrl = TextEditingController();
  final TextEditingController addHsnCtrl = TextEditingController();
  String addRateValue = '3%';

  void populateFrom(TaxGstConfigData? data) {
    codes = hsnListFromJson(data?.hsnCodesJson);
    notifyListeners();
  }

  void addCode() {
    if (addCategoryCtrl.text.trim().isEmpty || addHsnCtrl.text.trim().isEmpty) {
      return;
    }
    codes.add(HsnCodeModel(
      category: addCategoryCtrl.text.trim(),
      hsnCode: addHsnCtrl.text.trim(),
      gstRate: addRateValue,
    ));
    addCategoryCtrl.clear();
    addHsnCtrl.clear();
    addRateValue = '3%';
    _save();
    notifyListeners();
  }

  void removeCode(int index) {
    codes.removeAt(index);
    _save();
    notifyListeners();
  }

  void setAddRate(String rate) {
    addRateValue = rate;
    notifyListeners();
  }

  void resetAddForm() {
    addCategoryCtrl.clear();
    addHsnCtrl.clear();
    addRateValue = '3%';
    notifyListeners();
  }

  Future<void> _save() async {
    isSaving = true;
    notifyListeners();
    try {
      await _dao.saveHsnOnly(hsnListToJson(codes));
      successMessage = TaxGstStrings.feedbackSaved;
    } catch (_) {
      errorMessage = TaxGstStrings.feedbackSaveError;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    addCategoryCtrl.dispose();
    addHsnCtrl.dispose();
    super.dispose();
  }
}
