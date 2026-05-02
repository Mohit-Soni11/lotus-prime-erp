// =============================================================================
// FILE        : lib/database/tables/setting/billing/purchase_billing_settings.dart
// MODULE      : Billing Setup → Purchase
// DESCRIPTION : Per-metal purchase billing settings table.
//               4 rows: gold / silver / diamond / platinum
//               Controls what appears on each metal's purchase voucher.
// =============================================================================

import 'package:drift/drift.dart';
import '../../base_table.dart';

@DataClassName('PurchaseBillingSetting')
@TableIndex(name: 'idx_purchase_billing_metal', columns: {#metal}, unique: true)
class PurchaseBillingSettings extends Table with BaseTable {
  // ── METAL IDENTIFIER ─────────────────────────────────────────────────────
  TextColumn get metal => text()();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1 — PURCHASE VOUCHER ITEM DISPLAY
  // Controls what appears on the printed purchase voucher for this metal.
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Common to all metals ─────────────────────────────────────────────────
  BoolColumn get showGrossWeight =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showLessWeight =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showNetWeight => boolean().withDefault(const Constant(true))();
  BoolColumn get showPurity => boolean().withDefault(const Constant(true))();
  BoolColumn get showRate => boolean().withDefault(const Constant(true))();
  BoolColumn get showFineWeight =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showTotalValue =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showStoneDetails =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get showStoneValue =>
      boolean().withDefault(const Constant(false))();

  // ── Gold / Platinum specific ──────────────────────────────────────────────
  BoolColumn get showHuid => boolean().withDefault(const Constant(false))();

  // ── Supplier / Customer details on voucher ────────────────────────────────
  BoolColumn get showSupplierDetails =>
      boolean().withDefault(const Constant(true))();
  // PAN number of seller (required if transaction > ₹2 lakh)
  BoolColumn get showPanNumber => boolean().withDefault(const Constant(true))();

  // ── Diamond specific ──────────────────────────────────────────────────────
  BoolColumn get showDiamondCarats =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showDiamondClarity =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showCertificationNo =>
      boolean().withDefault(const Constant(false))();

  // ── GST ───────────────────────────────────────────────────────────────────
  BoolColumn get showGstBreakup =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get showHsnCode => boolean().withDefault(const Constant(false))();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2 — PURCHASE RETURN POLICY
  // Rules for returning purchased items back to supplier/customer.
  // ═══════════════════════════════════════════════════════════════════════════

  IntColumn get returnWindowDays => integer().withDefault(const Constant(3))();
  // 'Exchange' | 'Credit Note' | 'Cash Refund'
  TextColumn get returnMode =>
      text().withDefault(const Constant('Credit Note'))();
  // % deducted for quality/purity issues found during testing
  RealColumn get purityDeductPercent =>
      real().withDefault(const Constant(2.0))();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3 — TERMS & FOOTER
  // Printed on purchase voucher for this metal type.
  // ═══════════════════════════════════════════════════════════════════════════

  TextColumn get termsAndConditions => text().withDefault(const Constant(
      'Quality will be checked on delivery.\n'
      'Short delivery or defective goods must be reported within 24 hours.\n'
      'Payment as per agreed terms only.'))();
  TextColumn get footerMessage => text().withDefault(const Constant(''))();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4 — PRINT TEMPLATE
  // ═══════════════════════════════════════════════════════════════════════════

  TextColumn get selectedTemplate =>
      text().withDefault(const Constant('default'))();
}
