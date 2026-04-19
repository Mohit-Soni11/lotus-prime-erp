// =============================================================================
// FILE        : customers.dart
// MODULE      : Customer
// LAYER       : Database / Tables
// DESCRIPTION : Expanded Customers table with full ERP-grade fields.
// VERSION     : 2.0 — Full expansion (schema migration v3)
// =============================================================================

import 'package:drift/drift.dart';
import '../tables/base_table.dart';

@DataClassName('Customer')
@TableIndex(name: 'idx_customers_name',     columns: {#name})
@TableIndex(name: 'idx_customers_mobile',   columns: {#mobile})
@TableIndex(name: 'idx_customers_tier',     columns: {#customerTier})
@TableIndex(name: 'idx_customers_entity',   columns: {#entityType})
class Customers extends Table with BaseTable {

  // ── LEGACY (kept for backward compatibility) ────────────────────────────
  TextColumn get name       => text().withLength(min: 1, max: 200)();
  TextColumn get mobile     => text().unique()();
  TextColumn get city       => text().nullable()();
  TextColumn get type       => text().withDefault(const Constant('Regular'))();

  // ── 1. ENTITY TYPE ───────────────────────────────────────────────────────
  TextColumn get entityType         => text().withDefault(const Constant('Individual'))();

  // ── 2. PERSONAL DETAILS ──────────────────────────────────────────────────
  TextColumn get firstName          => text().nullable()();
  TextColumn get lastName           => text().nullable()();
  TextColumn get companyName        => text().nullable()();
  TextColumn get contactPersonName  => text().nullable()();
  TextColumn get dateOfBirth        => text().nullable()(); // ISO-8601
  TextColumn get gender             => text().nullable()();
  TextColumn get anniversaryDate    => text().nullable()(); // ISO-8601

  // ── 3. CONTACT DETAILS ───────────────────────────────────────────────────
  TextColumn get whatsapp           => text().nullable()();
  TextColumn get email              => text().nullable()();
  TextColumn get alternateContact   => text().nullable()();

  // ── 4. KYC & COMPLIANCE ──────────────────────────────────────────────────
  TextColumn get panNumber          => text().nullable()();
  TextColumn get idProofType        => text().nullable()();
  TextColumn get idProofNumber      => text().nullable()();
  TextColumn get idProofDocPath     => text().nullable()();
  TextColumn get gstNumber          => text().nullable()();

  // ── 5. ADDRESS ───────────────────────────────────────────────────────────
  TextColumn get addressLine1       => text().nullable()();
  TextColumn get addressLine2       => text().nullable()();
  TextColumn get country            => text().withDefault(const Constant('India'))();
  TextColumn get state              => text().nullable()();
  TextColumn get pincode            => text().nullable()();

  // ── 6. ACCOUNT & BILLING ─────────────────────────────────────────────────
  RealColumn get openingBalance     => real().withDefault(const Constant(0.0))();
  RealColumn get creditLimit        => real().withDefault(const Constant(0.0))();
  TextColumn get customerTier       => text().withDefault(const Constant('Regular'))();
  TextColumn get membershipId       => text().nullable()();

  // ── 7. PREFERENCES ───────────────────────────────────────────────────────
  TextColumn get ringSize           => text().nullable()();
  TextColumn get bangleSize         => text().nullable()();
  TextColumn get familyDetailsJson  => text().nullable()(); // JSON array string

  // ── 8. ADDITIONAL ────────────────────────────────────────────────────────
  TextColumn get referralSource     => text().nullable()();
  TextColumn get notes              => text().nullable()();
  TextColumn get profileImagePath   => text().nullable()();
}