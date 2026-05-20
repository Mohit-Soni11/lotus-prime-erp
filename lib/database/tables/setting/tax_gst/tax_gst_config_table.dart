// ============================================================
// FILE    : lib/database/tables/tax_gst_config_table.dart
// MODULE  : Tax & GST Configuration
// AUTHOR  : Lotus Prime ERP
// VERSION : 1.0.0
// DESC    : Drift table definition.
//           🔗 Linked fields sync to ShopProfiles on save.
//           Run: flutter pub run build_runner build --delete-conflicting-outputs
// ============================================================

import 'package:drift/drift.dart';

/// Drift table storing the complete Tax & GST configuration.
/// One row per shop (id = 1). Uses insertOnConflictUpdate for upsert.
@DataClassName('TaxGstConfigData')
class TaxGstConfigs extends Table {
  // ── Primary Key ──────────────────────────────────────────────
  IntColumn get id => integer().autoIncrement()();

  // ── 1. GST REGISTRATION ──────────────────────────────────────
  TextColumn get gstin => text().nullable()();
  TextColumn get legalName => text().nullable()();
  TextColumn get panNumber => text().nullable()();
  TextColumn get tanNumber => text().nullable()();
  TextColumn get gstRegisteredOn => text().nullable()();
  TextColumn get taxpayerType =>
      text().withDefault(const Constant('Regular'))();
  TextColumn get stateCode => text().nullable()();
  TextColumn get gstCertificatePath => text().nullable()();

  // ── 2. GST SLABS (JSON Array) ─────────────────────────────────
  /// JSON-encoded List<GstSlabModel>
  TextColumn get gstSlabsJson => text().nullable()();

  // ── 3. HSN CODES (JSON Array) ─────────────────────────────────
  /// JSON-encoded List<HsnCodeModel>
  TextColumn get hsnCodesJson => text().nullable()();

  // ── 4. TAX PREFERENCES ───────────────────────────────────────
  BoolColumn get autoSplitIgst => boolean().withDefault(const Constant(true))();
  BoolColumn get taxInclusivePricing =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get roundOffGstAmount =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showGstBreakupOnBill =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get compositeSupplyMode =>
      boolean().withDefault(const Constant(false))();

  // ── 5. TCS / TDS ─────────────────────────────────────────────
  BoolColumn get tcsEnabled => boolean().withDefault(const Constant(true))();
  RealColumn get tcsThreshold => real().withDefault(const Constant(200000.0))();
  RealColumn get tcsRatePct => real().withDefault(const Constant(1.0))();
  BoolColumn get tdsEnabled => boolean().withDefault(const Constant(false))();
  RealColumn get tdsRatePct => real().withDefault(const Constant(1.0))();

  // ── 6. E-INVOICE & COMPLIANCE ────────────────────────────────
  BoolColumn get eInvoicingEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get eInvoiceTurnoverLimit =>
      text().withDefault(const Constant('₹5 Crore'))();
  TextColumn get irpApiUsername => text().nullable()();
  TextColumn get irpApiPassword => text().nullable()();
  BoolColumn get gstr1FilingReminder =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get gstr3bFilingReminder =>
      boolean().withDefault(const Constant(true))();

  // ── 7. BIS & HALLMARKING ──────────────────────────────────────
  TextColumn get bisLicenseNumber => text().nullable()();
  TextColumn get bisLicenseValidFrom => text().nullable()();
  TextColumn get bisLicenseValidUpto => text().nullable()();
  TextColumn get huidNumber => text().nullable()();
  TextColumn get bisLicenseDocPath => text().nullable()();

  // ── Audit ─────────────────────────────────────────────────────
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
