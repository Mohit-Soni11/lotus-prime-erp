// lib/database/tables/setting/tax_gst/tax_gst_config_dao.dart

import '../../../db/app_database.dart';
import 'package:drift/drift.dart';

class TaxGstConfigDao {
  final AppDatabase db;
  TaxGstConfigDao(this.db);

  static const int _id = 1;

  // ── READ ──────────────────────────────────────────────────────
  Future<TaxGstConfigData?> fetchConfig() =>
      (db.select(db.taxGstConfigs)..where((t) => t.id.equals(_id)))
          .getSingleOrNull();

  Stream<TaxGstConfigData?> watchConfig() =>
      (db.select(db.taxGstConfigs)..where((t) => t.id.equals(_id)))
          .watchSingleOrNull();

  // ── UPSERT HELPER ─────────────────────────────────────────────
  Future<void> _upsert(TaxGstConfigsCompanion data) async {
    final exists = await fetchConfig();
    if (exists == null) {
      await db.into(db.taxGstConfigs).insert(data);
    } else {
      await (db.update(db.taxGstConfigs)..where((t) => t.id.equals(_id)))
          .write(data);
    }
  }

  // ── SECTION 1: GST REGISTRATION ──────────────────────────────
  Future<void> saveRegistration({
    String? gstin,
    String? legalName,
    String? panNumber,
    String? tanNumber,
    String? gstRegisteredOn,
    String taxpayerType = 'Regular',
    String? stateCode,
  }) async {
    await _upsert(TaxGstConfigsCompanion(
      id: const Value(1),
      gstin: Value(gstin),
      legalName: Value(legalName),
      panNumber: Value(panNumber),
      tanNumber: Value(tanNumber),
      gstRegisteredOn: Value(gstRegisteredOn),
      taxpayerType: Value(taxpayerType),
      stateCode: Value(stateCode),
      updatedAt: Value(DateTime.now()),
    ));
    await _syncShop(gstin: gstin, legalName: legalName);
  }

  // ── SECTION 2: GST SLABS ONLY ─────────────────────────────────
  // Called by GstSlabsLogic.save()
  Future<void> saveSlabsOnly(String gstSlabsJson) async {
    await _upsert(TaxGstConfigsCompanion(
      id: const Value(1),
      gstSlabsJson: Value(gstSlabsJson),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ── SECTION 3: HSN CODES ONLY ─────────────────────────────────
  // Called by HsnCodeLogic._save()
  Future<void> saveHsnOnly(String hsnCodesJson) async {
    await _upsert(TaxGstConfigsCompanion(
      id: const Value(1),
      hsnCodesJson: Value(hsnCodesJson),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ── SECTIONS 2+3 COMBINED (kept for backward compat) ──────────
  Future<void> saveSlabsAndHsn({
    required String gstSlabsJson,
    required String hsnCodesJson,
  }) async {
    await _upsert(TaxGstConfigsCompanion(
      id: const Value(1),
      gstSlabsJson: Value(gstSlabsJson),
      hsnCodesJson: Value(hsnCodesJson),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ── SECTION 4: TAX PREFERENCES ───────────────────────────────
  Future<void> savePreferences({
    required bool autoSplitIgst,
    required bool taxInclusive,
    required bool roundOff,
    required bool showBreakup,
    required bool compositeMode,
  }) async {
    await _upsert(TaxGstConfigsCompanion(
      id: const Value(1),
      autoSplitIgst: Value(autoSplitIgst),
      taxInclusivePricing: Value(taxInclusive),
      roundOffGstAmount: Value(roundOff),
      showGstBreakupOnBill: Value(showBreakup),
      compositeSupplyMode: Value(compositeMode),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ── SECTION 5: TCS / TDS ─────────────────────────────────────
  Future<void> saveTcsTds({
    required bool tcsEnabled,
    required double tcsThreshold,
    required double tcsRate,
    required bool tdsEnabled,
    required double tdsRate,
  }) async {
    await _upsert(TaxGstConfigsCompanion(
      id: const Value(1),
      tcsEnabled: Value(tcsEnabled),
      tcsThreshold: Value(tcsThreshold),
      tcsRatePct: Value(tcsRate),
      tdsEnabled: Value(tdsEnabled),
      tdsRatePct: Value(tdsRate),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ── SECTION 6: E-INVOICE ──────────────────────────────────────
  Future<void> saveEInvoice({
    required bool enabled,
    required String turnoverLimit,
    required String? irpUser,
    required String? irpPass,
    required bool gstr1Reminder,
    required bool gstr3bReminder,
  }) async {
    await _upsert(TaxGstConfigsCompanion(
      id: const Value(1),
      eInvoicingEnabled: Value(enabled),
      eInvoiceTurnoverLimit: Value(turnoverLimit),
      irpApiUsername: Value(irpUser),
      irpApiPassword: Value(irpPass),
      gstr1FilingReminder: Value(gstr1Reminder),
      gstr3bFilingReminder: Value(gstr3bReminder),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ── SECTION 7: BIS & HALLMARKING ─────────────────────────────
  Future<void> saveBisHallmark({
    String? bisLicense,
    String? bisValidFrom,
    String? bisValidUpto,
    String? huidNumber,
  }) async {
    await _upsert(TaxGstConfigsCompanion(
      id: const Value(1),
      bisLicenseNumber: Value(bisLicense),
      bisLicenseValidFrom: Value(bisValidFrom),
      bisLicenseValidUpto: Value(bisValidUpto),
      huidNumber: Value(huidNumber),
      updatedAt: Value(DateTime.now()),
    ));
    await _syncShop(bisLicense: bisLicense, huidNo: huidNumber);
  }

  // ── SHOP PROFILE SYNC ─────────────────────────────────────────
  Future<void> _syncShop({
    String? gstin,
    String? legalName,
    String? bisLicense,
    String? huidNo,
  }) async {
    try {
      final rowExists = await (db.select(db.shopProfiles)
                ..where((t) => t.id.equals(_id)))
              .getSingleOrNull() !=
          null;

      if (!rowExists) return;

      await (db.update(db.shopProfiles)..where((t) => t.id.equals(_id)))
          .write(ShopProfilesCompanion(
        gstin: gstin != null ? Value(gstin) : const Value.absent(),
        legalName: legalName != null ? Value(legalName) : const Value.absent(),
        bisLicense:
            bisLicense != null ? Value(bisLicense) : const Value.absent(),
        huidNo: huidNo != null ? Value(huidNo) : const Value.absent(),
      ));
    } catch (_) {}
  }
}
