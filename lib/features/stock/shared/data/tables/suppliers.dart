// =============================================================================
// FILE        : suppliers.dart
// MODULE      : Supplier
// LAYER       : Database / Tables
// DESCRIPTION : Drift ORM table for Supplier / Manufacturer master records.
//               Pattern identical to customers.dart.
//               Added in schema v9.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:lotus_erp/database/tables/base_table.dart';

@DataClassName('Supplier')
@TableIndex(name: 'idx_supplier_mobile', columns: {#mobile})
@TableIndex(name: 'idx_supplier_business', columns: {#businessName})
@TableIndex(name: 'idx_supplier_type', columns: {#supplierType})
@TableIndex(name: 'idx_supplier_status', columns: {#status})
class Suppliers extends Table with BaseTable {
  // ── 1. BUSINESS IDENTIFICATION ─────────────────────────────────────────
  TextColumn get businessName => text().withLength(min: 1, max: 200)();
  TextColumn get contactPersonName => text().nullable()();
  TextColumn get supplierType =>
      text().withDefault(const Constant('Manufacturer'))();
  // Types: Manufacturer | Wholesaler | Retailer | Individual

  // ── 2. CONTACT DETAILS ─────────────────────────────────────────────────
  TextColumn get mobile => text().unique()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get alternateContact => text().nullable()();

  // ── 3. KYC & COMPLIANCE ────────────────────────────────────────────────
  TextColumn get panNumber => text().nullable()();
  TextColumn get gstNumber => text().nullable()();

  // ── 4. ADDRESS ─────────────────────────────────────────────────────────
  TextColumn get addressLine1 => text().nullable()();
  TextColumn get addressLine2 => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get pincode => text().nullable()();
  TextColumn get country => text().withDefault(const Constant('India'))();

  // ── 5. FINANCIAL ───────────────────────────────────────────────────────
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();

  // ── 6. META ────────────────────────────────────────────────────────────
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('Active'))();
  // Status: Active | Inactive
}
