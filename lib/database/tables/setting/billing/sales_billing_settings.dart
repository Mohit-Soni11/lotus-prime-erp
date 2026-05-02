// =============================================================================
// FILE        : lib/database/tables/setting/billing/sales_billing_settings.dart
// MODULE      : Billing Setup → Sales
// DESCRIPTION : Per-metal sales billing settings table.
//               4 rows: gold / silver / diamond / platinum
//               Controls what appears on each metal's sales invoice.
// =============================================================================

import 'package:drift/drift.dart';
import '../../base_table.dart';

@DataClassName('SalesBillingSetting')
@TableIndex(name: 'idx_sales_billing_metal', columns: {#metal}, unique: true)
class SalesBillingSettings extends Table with BaseTable {
  // ── METAL IDENTIFIER ─────────────────────────────────────────────────────
  // Values: 'gold' | 'silver' | 'diamond' | 'platinum'
  TextColumn get metal => text()();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1 — INVOICE ITEM DISPLAY
  // Controls which columns/lines appear on the printed bill for this metal.
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Common to all metals ─────────────────────────────────────────────────
  BoolColumn get showPieces => boolean().withDefault(const Constant(true))();
  BoolColumn get showGrossWeight =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showLessWeight =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showNetWeight => boolean().withDefault(const Constant(true))();
  BoolColumn get showPurity => boolean().withDefault(const Constant(true))();
  BoolColumn get showRate => boolean().withDefault(const Constant(true))();
  BoolColumn get showMakingCharges =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showMakingChargeType =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showStoneDetails =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get showStoneValue =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get showTotalValue =>
      boolean().withDefault(const Constant(true))();

  // ── Gold / Platinum specific ──────────────────────────────────────────────
  // HUID: BIS Hallmark number — mandatory for gold as per govt rules
  BoolColumn get showHuid => boolean().withDefault(const Constant(false))();
  // Wastage: % deducted in wholesale billing — shown as a line item
  BoolColumn get showWastage => boolean().withDefault(const Constant(false))();
  // Old Gold exchange line: shows deduction when customer gives old gold
  BoolColumn get showOldGoldLine =>
      boolean().withDefault(const Constant(true))();

  // ── Diamond specific ──────────────────────────────────────────────────────
  // For diamond, purityCtrl holds clarity grade (VVS1, VS1 etc.)
  BoolColumn get showDiamondClarity =>
      boolean().withDefault(const Constant(true))();
  // Diamond certification number (GIA / IGI / HRD)
  BoolColumn get showCertificationNo =>
      boolean().withDefault(const Constant(false))();
  // Total diamond weight in carats
  BoolColumn get showDiamondCarats =>
      boolean().withDefault(const Constant(true))();
  // Number of diamond pieces
  BoolColumn get showDiamondPieces =>
      boolean().withDefault(const Constant(true))();
  // For diamond jewellery: show the metal frame weight separately
  BoolColumn get showMetalWeight =>
      boolean().withDefault(const Constant(true))();

  // ── Fine weight (calculated: netWt × purity%) ─────────────────────────────
  BoolColumn get showFineWeight =>
      boolean().withDefault(const Constant(false))();

  // ── GST breakup ───────────────────────────────────────────────────────────
  // Show CGST + SGST lines separately vs inclusive price
  BoolColumn get showGstBreakup =>
      boolean().withDefault(const Constant(false))();
  // HSN code line on invoice
  BoolColumn get showHsnCode => boolean().withDefault(const Constant(false))();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2 — RETURN & BUYBACK POLICY
  // Per-metal return rules that get printed on invoice / applied at POS.
  // ═══════════════════════════════════════════════════════════════════════════

  // Days within which customer can return this metal's item
  IntColumn get returnWindowDays => integer().withDefault(const Constant(7))();
  // 'Exchange Only' | 'Refund' | 'Both'
  TextColumn get returnMode =>
      text().withDefault(const Constant('Exchange Only'))();
  // % charge deducted at the time of return (handling/restocking)
  RealColumn get handlingChargePercent =>
      real().withDefault(const Constant(0.0))();
  // % of day's market rate paid during buyback
  RealColumn get buybackRatePercent =>
      real().withDefault(const Constant(90.0))();
  // Purity % deducted during buyback (testing/refining loss)
  RealColumn get buybackPurityDeductPercent =>
      real().withDefault(const Constant(2.0))();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3 — TERMS & FOOTER
  // Printed at the bottom of the invoice for this metal type.
  // ═══════════════════════════════════════════════════════════════════════════

  TextColumn get termsAndConditions => text().withDefault(
      const Constant('Items once sold will not be taken back or exchanged.\n'
          'Guarantee is provided as per BIS standards.\n'
          'Original bill is mandatory for any service claim.'))();
  TextColumn get footerMessage => text().withDefault(
      const Constant('Thank you for shopping with us! Visit us again.'))();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4 — PRINT TEMPLATE
  // Which invoice template to use when printing this metal's bill.
  // Currently only 'default'. Future: 'thermal_58mm', 'a4_gst', 'a5_minimal'
  // ═══════════════════════════════════════════════════════════════════════════

  TextColumn get selectedTemplate =>
      text().withDefault(const Constant('default'))();
}
