// =============================================================================
// FILE        : lib/database/tables/billing/billing_settings_table.dart
// MODULE      : Billing Setup
// LAYER       : Database / Tables
// DESCRIPTION : Singleton settings table — one row per shop.
//               BaseTable mixin provides: id, createdAt, updatedAt (nullable).
//               4 logical groups: Sales, Purchase, Girvi, Return & Buyback.
// =============================================================================

import 'package:drift/drift.dart';
import '../../base_table.dart';

@DataClassName('BillingSetting')
class BillingSettings extends Table with BaseTable {
  // ═══════════════════════════════════════════════════════════════════════════
  // 1. SALES BILLING
  // ═══════════════════════════════════════════════════════════════════════════

  // Invoice Numbering
  TextColumn get salesInvoicePrefix =>
      text().withDefault(const Constant('INV-'))();
  IntColumn get salesStartingNumber =>
      integer().withDefault(const Constant(1))();
  BoolColumn get salesYearlyReset =>
      boolean().withDefault(const Constant(true))();

  // Estimate / Quotation
  TextColumn get estimatePrefix => text().withDefault(const Constant('EST-'))();
  IntColumn get estimateValidityDays =>
      integer().withDefault(const Constant(7))();

  // Payment
  TextColumn get salesDefaultPaymentMode =>
      text().withDefault(const Constant('Cash'))();
  TextColumn get salesUpiId => text().withDefault(const Constant(''))();
  IntColumn get salesDefaultCreditDays =>
      integer().withDefault(const Constant(30))();
  IntColumn get salesMinAdvancePercent =>
      integer().withDefault(const Constant(30))();

  // Discount & Rounding
  BoolColumn get salesAllowDiscount =>
      boolean().withDefault(const Constant(true))();
  RealColumn get salesMaxDiscountPercent =>
      real().withDefault(const Constant(5.0))();
  TextColumn get salesRoundingRule =>
      text().withDefault(const Constant('Nearest ₹1'))();

  // Invoice Display
  BoolColumn get salesShowMakingCharges =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get salesShowHuid => boolean().withDefault(const Constant(true))();
  BoolColumn get salesShowOldGoldLine =>
      boolean().withDefault(const Constant(true))();

  // Terms & Footer
  TextColumn get salesTerms => text().withDefault(
      const Constant('Items once sold will not be taken back or exchanged.\n'
          'Guarantee is provided as per BIS standards.\n'
          'Original bill is mandatory for any service claim.'))();
  TextColumn get salesFooterMsg => text().withDefault(
      const Constant('Thank you for shopping with us! Visit us again.'))();

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. PURCHASE BILLING
  // ═══════════════════════════════════════════════════════════════════════════

  TextColumn get purchaseInvoicePrefix =>
      text().withDefault(const Constant('PUR-'))();
  IntColumn get purchaseStartingNumber =>
      integer().withDefault(const Constant(1))();
  BoolColumn get purchaseYearlyReset =>
      boolean().withDefault(const Constant(true))();
  IntColumn get purchaseDefaultPaymentDays =>
      integer().withDefault(const Constant(30))();
  IntColumn get purchaseAdvancePercent =>
      integer().withDefault(const Constant(20))();
  TextColumn get purchaseDefaultPaymentMode =>
      text().withDefault(const Constant('Bank Transfer'))();
  RealColumn get purchaseWeightTolerancePercent =>
      real().withDefault(const Constant(0.5))();
  TextColumn get purchaseDefaultKarat =>
      text().withDefault(const Constant('22K'))();
  TextColumn get purchaseTerms => text().withDefault(const Constant(
      'Quality will be checked on delivery.\n'
      'Short delivery or defective goods must be reported within 24 hours.\n'
      'Payment as per agreed terms only.'))();
  BoolColumn get purchaseAutoPrint =>
      boolean().withDefault(const Constant(false))();

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. GIRVI BILLING
  // ═══════════════════════════════════════════════════════════════════════════

  TextColumn get girviPrefix => text().withDefault(const Constant('GRV-'))();
  IntColumn get girviStartingNumber =>
      integer().withDefault(const Constant(1))();
  RealColumn get girviDefaultInterestRate =>
      real().withDefault(const Constant(1.5))();
  TextColumn get girviInterestType =>
      text().withDefault(const Constant('Simple'))();
  IntColumn get girviGracePeriodDays =>
      integer().withDefault(const Constant(3))();
  TextColumn get girviDefaultDuration =>
      text().withDefault(const Constant('6 Months'))();
  IntColumn get girviReminderDays =>
      integer().withDefault(const Constant(15))();
  IntColumn get girviNoticeDays => integer().withDefault(const Constant(30))();
  TextColumn get girviTerms => text().withDefault(const Constant(
      'Interest will be charged per month on the loan amount.\n'
      'Unclaimed ornaments after notice period will be auctioned as per law.\n'
      'Customer is responsible for timely repayment.'))();
  BoolColumn get girviAutoPrint =>
      boolean().withDefault(const Constant(true))();

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. RETURN & BUYBACK
  // ═══════════════════════════════════════════════════════════════════════════

  IntColumn get returnWindowDays => integer().withDefault(const Constant(7))();
  RealColumn get returnHandlingChargePercent =>
      real().withDefault(const Constant(0.0))();
  TextColumn get returnMode =>
      text().withDefault(const Constant('Exchange Only'))();
  TextColumn get returnVoucherPrefix =>
      text().withDefault(const Constant('RET-'))();
  RealColumn get buybackRatePercent =>
      real().withDefault(const Constant(90.0))();
  RealColumn get buybackPurityDeductPercent =>
      real().withDefault(const Constant(2.0))();
  TextColumn get buybackDefaultKarat =>
      text().withDefault(const Constant('22K'))();
  TextColumn get returnTerms => text().withDefault(const Constant(
      'Returns accepted within the specified window with original bill only.\n'
      'Exchange is subject to stock availability.\n'
      'Buyback rate is calculated on the day\'s market rate.'))();
}
