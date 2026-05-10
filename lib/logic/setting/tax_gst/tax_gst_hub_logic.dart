// ============================================================
// FILE    : lib/logic/setting/tax_gst/tax_gst_hub_logic.dart
// MODULE  : Tax & GST Configuration — Master Hub
// AUTHOR  : Lotus Prime ERP
// VERSION : 1.0.0
// DESC    : Orchestrates all 7 section logics.
//           Loads data from DB once and distributes to each section.
//           Controls which card is expanded.
// ============================================================

import 'package:flutter/material.dart';
import '../../../../database/tables/setting/tax_gst/tax_gst_config_dao.dart';
import '../../../../database/db/app_database.dart';
import 'sections/gst_registration_logic.dart';
import 'sections/gst_slabs_logic.dart';
import 'sections/hsn_code_logic.dart';
import 'sections/tax_preferences_logic.dart';
import 'sections/tcs_tds_logic.dart';
import 'sections/e_invoice_logic.dart';
import 'sections/bis_hallmark_logic.dart';

class TaxGstHubLogic extends ChangeNotifier {
  TaxGstHubLogic(AppDatabase db)
      : _dao = TaxGstConfigDao(db),
        registrationLogic = GstRegistrationLogic(db),
        slabsLogic = GstSlabsLogic(db),
        hsnLogic = HsnCodeLogic(db),
        preferencesLogic = TaxPreferencesLogic(db),
        tcsTdsLogic = TcsTdsLogic(db),
        eInvoiceLogic = EInvoiceLogic(db),
        bisLogic = BisHallmarkLogic(db);

  final TaxGstConfigDao _dao;

  // ── Section Logics (publicly accessible by UI) ────────────────
  final GstRegistrationLogic registrationLogic;
  final GstSlabsLogic slabsLogic;
  final HsnCodeLogic hsnLogic;
  final TaxPreferencesLogic preferencesLogic;
  final TcsTdsLogic tcsTdsLogic;
  final EInvoiceLogic eInvoiceLogic;
  final BisHallmarkLogic bisLogic;

  // ── Screen state ─────────────────────────────────────────────
  bool isLoading = false;
  String? loadError;

  /// Index of currently expanded card (-1 = all collapsed)
  int expandedIndex = -1;

  // ── Init ─────────────────────────────────────────────────────
  Future<void> initialise() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final data = await _dao.fetchConfig();
      // Distribute loaded data to all section logics
      registrationLogic.populateFrom(data);
      slabsLogic.populateFrom(data);
      hsnLogic.populateFrom(data);
      preferencesLogic.populateFrom(data);
      tcsTdsLogic.populateFrom(data);
      eInvoiceLogic.populateFrom(data);
      bisLogic.populateFrom(data);
    } catch (e) {
      loadError = 'Failed to load Tax & GST configuration: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Card expand / collapse ────────────────────────────────────
  void toggleCard(int index) {
    expandedIndex = expandedIndex == index ? -1 : index;
    notifyListeners();
  }

  void collapseAll() {
    expandedIndex = -1;
    notifyListeners();
  }

  bool isExpanded(int index) => expandedIndex == index;

  // ── Dispose all children ─────────────────────────────────────
  @override
  void dispose() {
    registrationLogic.dispose();
    slabsLogic.dispose();
    hsnLogic.dispose();
    preferencesLogic.dispose();
    tcsTdsLogic.dispose();
    eInvoiceLogic.dispose();
    bisLogic.dispose();
    super.dispose();
  }
}
