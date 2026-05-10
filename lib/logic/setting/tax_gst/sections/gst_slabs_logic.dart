// ============================================================
// FILE    : lib/logic/setting/tax_gst/sections/gst_slabs_logic.dart
// MODULE  : Tax & GST Configuration — Section 2
// ============================================================
import 'package:flutter/material.dart';
import '../../../../database/tables/setting/tax_gst/tax_gst_config_dao.dart';
import '../../../../database/db/app_database.dart';
import '../../../../models/setting/tax_gst/gst_slab_model.dart';
import '../../../../theme/settings/tax_gst/tax_gst_strings.dart';

class GstSlabsLogic extends ChangeNotifier {
  GstSlabsLogic(AppDatabase db) : _dao = TaxGstConfigDao(db);
  final TaxGstConfigDao _dao;

  bool isEditing = false;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  List<GstSlabModel> slabs = defaultGstSlabModels();

  void populateFrom(TaxGstConfigData? data) {
    slabs = gstSlabListFromJson(data?.gstSlabsJson);
    notifyListeners();
  }

  void updateRate(int index, String rate) {
    slabs[index] = slabs[index].copyWith(rate: rate);
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
      await _dao.saveSlabsOnly(gstSlabListToJson(slabs));
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
}
