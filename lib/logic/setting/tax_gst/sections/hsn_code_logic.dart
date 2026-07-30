import 'package:flutter/material.dart';

import '../../../../database/db/app_database.dart';
import '../../../../database/tables/setting/tax_gst/tax_gst_config_dao.dart';
import '../../../../models/setting/tax_gst/hsn_code_model.dart';
import '../../../../theme/settings/tax_gst/tax_gst_strings.dart';

class HsnCodeLogic extends ChangeNotifier {
  HsnCodeLogic(AppDatabase db) : _dao = TaxGstConfigDao(db);

  final TaxGstConfigDao _dao;

  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  List<HsnCodeModel> codes = defaultHsnCodeModels();

  final TextEditingController addCategoryCtrl = TextEditingController();
  final TextEditingController addHsnCtrl = TextEditingController();
  final TextEditingController addDisplayCodeCtrl = TextEditingController();
  final TextEditingController addEffectiveFromCtrl = TextEditingController();
  String addRateValue = '3%';
  String addAppliesToValue = TaxGstStrings.hsnAppliesProductSale;
  int? editingIndex;

  bool get isEditing => editingIndex != null;

  void populateFrom(TaxGstConfigData? data) {
    codes = hsnListFromJson(data?.hsnCodesJson);
    notifyListeners();
  }

  void saveDraft() {
    final category = addCategoryCtrl.text.trim();
    final hsn = addHsnCtrl.text.trim();
    if (category.isEmpty || hsn.isEmpty) {
      return;
    }

    final entry = HsnCodeModel(
      category: category,
      hsnCode: hsn,
      gstRate: addRateValue,
      displayCode: addDisplayCodeCtrl.text.trim(),
      appliesTo: addAppliesToValue,
      effectiveFrom: addEffectiveFromCtrl.text.trim(),
    );

    final target = editingIndex;
    if (target == null) {
      codes.add(entry);
    } else if (target >= 0 && target < codes.length) {
      codes[target] = entry;
    }

    resetAddForm(notify: false);
    _save();
    notifyListeners();
  }

  void addCode() => saveDraft();

  void startEdit(int index) {
    if (index < 0 || index >= codes.length) {
      return;
    }
    final entry = codes[index];
    editingIndex = index;
    addCategoryCtrl.text = entry.category;
    addHsnCtrl.text = entry.hsnCode;
    addDisplayCodeCtrl.text = entry.displayCode;
    addEffectiveFromCtrl.text = entry.effectiveFrom;
    addRateValue = entry.gstRate;
    addAppliesToValue =
        TaxGstStrings.hsnAppliesToOptions.contains(entry.appliesTo)
            ? entry.appliesTo
            : TaxGstStrings.hsnAppliesProductSale;
    notifyListeners();
  }

  void removeCode(int index) {
    if (index < 0 || index >= codes.length) {
      return;
    }
    codes.removeAt(index);
    if (editingIndex == index) {
      resetAddForm(notify: false);
    } else if (editingIndex != null && editingIndex! > index) {
      editingIndex = editingIndex! - 1;
    }
    _save();
    notifyListeners();
  }

  void setAddRate(String rate) {
    addRateValue = rate;
    notifyListeners();
  }

  void setAddAppliesTo(String appliesTo) {
    addAppliesToValue = appliesTo;
    notifyListeners();
  }

  void resetAddForm({bool notify = true}) {
    addCategoryCtrl.clear();
    addHsnCtrl.clear();
    addDisplayCodeCtrl.clear();
    addEffectiveFromCtrl.clear();
    addRateValue = '3%';
    addAppliesToValue = TaxGstStrings.hsnAppliesProductSale;
    editingIndex = null;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _save() async {
    isSaving = true;
    notifyListeners();
    try {
      await _dao.saveHsnOnly(hsnListToJson(codes));
      successMessage = TaxGstStrings.feedbackSaved;
      errorMessage = null;
    } catch (_) {
      successMessage = null;
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
    addDisplayCodeCtrl.dispose();
    addEffectiveFromCtrl.dispose();
    super.dispose();
  }
}
