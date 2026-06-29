// ============================================================
// FILE    : lib/logic/setting/tax_gst/sections/tax_preferences_logic.dart
// MODULE  : Tax & GST — Section 4
// ============================================================
import 'package:flutter/material.dart';
import '../../../../database/tables/setting/tax_gst/tax_gst_config_dao.dart';
import '../../../../database/db/app_database.dart';
import '../../../../theme/settings/tax_gst/tax_gst_strings.dart';

class TaxPreferencesLogic extends ChangeNotifier {
  TaxPreferencesLogic(AppDatabase db) : _dao = TaxGstConfigDao(db);
  final TaxGstConfigDao _dao;

  bool isEditing = false;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  bool autoSplitIgst = true;
  bool taxInclusivePricing = false;
  bool roundOffGstAmount = true;
  bool showGstBreakup = true;
  bool compositeSupply = false;

  void populateFrom(TaxGstConfigData? data) {
    if (data == null) return;
    autoSplitIgst = data.autoSplitIgst;
    taxInclusivePricing = data.taxInclusivePricing;
    roundOffGstAmount = data.roundOffGstAmount;
    showGstBreakup = data.showGstBreakupOnBill;
    compositeSupply = data.compositeSupplyMode;
    notifyListeners();
  }

  void toggle(String field, bool value) {
    switch (field) {
      case 'autoSplit':
        autoSplitIgst = value;
        break;
      case 'inclusive':
        taxInclusivePricing = value;
        break;
      case 'roundOff':
        roundOffGstAmount = value;
        break;
      case 'showBreakup':
        showGstBreakup = value;
        break;
      case 'composite':
        compositeSupply = value;
        break;
    }
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
      await _dao.savePreferences(
        autoSplitIgst: autoSplitIgst,
        taxInclusive: taxInclusivePricing,
        roundOff: roundOffGstAmount,
        showBreakup: showGstBreakup,
        compositeMode: compositeSupply,
      );
      isEditing = false;
      successMessage = TaxGstStrings.feedbackSaved;
      return true;
    } catch (_) {
      errorMessage = TaxGstStrings.feedbackSaveError;
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
