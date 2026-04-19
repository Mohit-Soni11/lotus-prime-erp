// =============================================================================
// FILE        : bank_accounts.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : Database / Tables
// DESCRIPTION : Master table for all bank accounts registered in the shop.
//               A jewellery business typically maintains 1–4 bank accounts
//               (current + savings + OD) plus UPI handles.
//               Each BankTransaction references a BankAccount via accountId.
//
// SCHEMA      : v7
// INDEXES     : accountNumber (unique), isActive (filter)
// =============================================================================

import 'package:drift/drift.dart';
import '../base_table.dart';

@DataClassName('BankAccount')
@TableIndex(name: 'idx_bank_acc_number', columns: {#accountNumber})
@TableIndex(name: 'idx_bank_acc_active',  columns: {#isActive})
class BankAccounts extends Table with BaseTable {

  // ── Identity ───────────────────────────────────────────────────────────────
  /// Display name: "SBI Current", "HDFC Savings"
  TextColumn get accountName   => text().withLength(min: 1, max: 100)();

  /// Full legal account holder name (for cheque printing)
  TextColumn get holderName    => text().nullable()();

  // ── Bank Details ───────────────────────────────────────────────────────────
  TextColumn get bankName      => text()();
  TextColumn get accountNumber => text().unique()();
  TextColumn get ifscCode      => text().nullable()();
  TextColumn get branchName    => text().nullable()();

  /// SAVINGS | CURRENT | OD | CC (Overdraft / Credit Card)
  TextColumn get accountType   => text().withDefault(const Constant('CURRENT'))();

  // ── UPI ───────────────────────────────────────────────────────────────────
  TextColumn get upiId         => text().nullable()();

  // ── Opening Balance ────────────────────────────────────────────────────────
  /// Set once when account is registered — used for closing balance calculation
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();

  /// Date from which this account became active in ERP
  DateTimeColumn get activeSince => dateTime().withDefault(currentDateAndTime)();

  // ── Flags ──────────────────────────────────────────────────────────────────
  BoolColumn get isActive      => boolean().withDefault(const Constant(true))();
  BoolColumn get isPrimary     => boolean().withDefault(const Constant(false))();

  // ── Display ────────────────────────────────────────────────────────────────
  /// Color hex for UI card accent: "#D4AF37"
  TextColumn get colorHex      => text().nullable()();
}