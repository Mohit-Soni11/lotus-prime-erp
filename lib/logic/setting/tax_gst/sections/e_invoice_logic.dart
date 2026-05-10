// ============================================================
// FILE    : lib/logic/setting/tax_gst/sections/e_invoice_logic.dart
// MODULE  : Tax & GST — Section 6
// ============================================================
import 'package:flutter/material.dart';
import '../../../../database/tables/setting/tax_gst/tax_gst_config_dao.dart';
import '../../../../database/db/app_database.dart';
import '../../../../theme/settings/tax_gst/tax_gst_strings.dart';

class EInvoiceLogic extends ChangeNotifier {
  EInvoiceLogic(AppDatabase db) : _dao = TaxGstConfigDao(db);
  final TaxGstConfigDao _dao;

  bool isEditing = false;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  bool eInvoicingEnabled = false;
  String turnoverLimit = '₹5 Crore';
  bool gstr1Reminder = true;
  bool gstr3bReminder = true;
  bool irpPassVisible = false;

  final TextEditingController irpUserCtrl = TextEditingController();
  final TextEditingController irpPassCtrl = TextEditingController();

  void populateFrom(TaxGstConfigData? data) {
    if (data == null) return;
    eInvoicingEnabled = data.eInvoicingEnabled;
    turnoverLimit = data.eInvoiceTurnoverLimit;
    gstr1Reminder = data.gstr1FilingReminder;
    gstr3bReminder = data.gstr3bFilingReminder;
    irpUserCtrl.text = data.irpApiUsername ?? '';
    irpPassCtrl.text = data.irpApiPassword ?? '';
    notifyListeners();
  }

  void setEnabled(bool v) {
    eInvoicingEnabled = v;
    notifyListeners();
  }

  void setTurnoverLimit(String v) {
    turnoverLimit = v;
    notifyListeners();
  }

  void setGstr1Reminder(bool v) {
    gstr1Reminder = v;
    notifyListeners();
  }

  void setGstr3bReminder(bool v) {
    gstr3bReminder = v;
    notifyListeners();
  }

  void togglePassVisibility() {
    irpPassVisible = !irpPassVisible;
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
      await _dao.saveEInvoice(
        enabled: eInvoicingEnabled,
        turnoverLimit: turnoverLimit,
        irpUser:
            irpUserCtrl.text.trim().isEmpty ? null : irpUserCtrl.text.trim(),
        irpPass:
            irpPassCtrl.text.trim().isEmpty ? null : irpPassCtrl.text.trim(),
        gstr1Reminder: gstr1Reminder,
        gstr3bReminder: gstr3bReminder,
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
    irpUserCtrl.dispose();
    irpPassCtrl.dispose();
    super.dispose();
  }
}
