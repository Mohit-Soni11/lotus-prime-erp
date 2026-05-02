// =============================================================================
// FILE        : lib/database/tables/setting/billing/girvi_billing_settings.dart
// MODULE      : Billing Setup → Girvi
// DESCRIPTION : Single-row Girvi billing settings table.
//               Girvi ek hi type hoti hai — metal-wise split nahi hoti.
// =============================================================================

import 'package:drift/drift.dart';
import '../../base_table.dart';

@DataClassName('GirviBillingSetting')
class GirviBillingSettings extends Table with BaseTable {
  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1 — VOUCHER / TICKET NUMBERING
  // ═══════════════════════════════════════════════════════════════════════════

  TextColumn get girviPrefix => text().withDefault(const Constant('GRV-'))();
  IntColumn get startingNumber => integer().withDefault(const Constant(1))();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2 — INTEREST RULES
  // ═══════════════════════════════════════════════════════════════════════════

  // % per month charged on loan amount
  RealColumn get defaultInterestRate =>
      real().withDefault(const Constant(1.5))();
  // 'Simple' | 'Compound'
  TextColumn get interestType => text().withDefault(const Constant('Simple'))();
  // Days allowed after due date before penalty starts
  IntColumn get gracePeriodDays => integer().withDefault(const Constant(3))();
  // Default loan duration: '1 Month' | '3 Months' | '6 Months' etc.
  TextColumn get defaultDuration =>
      text().withDefault(const Constant('6 Months'))();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3 — REMINDER & NOTICE PERIOD
  // ═══════════════════════════════════════════════════════════════════════════

  // Days before expiry to send reminder
  IntColumn get reminderDays => integer().withDefault(const Constant(15))();
  // Days after expiry before legal notice is issued
  IntColumn get noticeDays => integer().withDefault(const Constant(30))();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4 — TERMS & PRINT
  // ═══════════════════════════════════════════════════════════════════════════

  TextColumn get termsAndConditions => text().withDefault(const Constant(
      'Interest will be charged per month on the loan amount.\n'
      'Unclaimed ornaments after notice period will be auctioned as per law.\n'
      'Customer is responsible for timely repayment.'))();
  TextColumn get footerMessage => text().withDefault(const Constant(''))();
  BoolColumn get autoPrint => boolean().withDefault(const Constant(true))();

  // Template for future use
  TextColumn get selectedTemplate =>
      text().withDefault(const Constant('default'))();
}
