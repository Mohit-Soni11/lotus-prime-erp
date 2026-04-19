// =============================================================================
// FILE        : karigar_masters.dart
// MODULE      : Karigar
// LAYER       : Database / Tables
// DESCRIPTION : Drift ORM table for Karigar (artisan/craftsman) master records.
//               Stores identity, professional specialization, rates, and
//               financial opening balance for each artisan.
// =============================================================================

import 'package:drift/drift.dart';
import '../base_table.dart';

@DataClassName('KarigarMaster')
@TableIndex(name: 'idx_karigar_name',   columns: {#name})
@TableIndex(name: 'idx_karigar_phone',  columns: {#phone})
@TableIndex(name: 'idx_karigar_active', columns: {#isActive})
class KarigarMasters extends Table with BaseTable {

  // ── 1. IDENTIFICATION ────────────────────────────────────────────────────
  TextColumn get name           => text().withLength(min: 2, max: 150)();
  TextColumn get phone          => text().withLength(min: 10, max: 15)();
  TextColumn get alternatePhone => text().nullable()();

  // ── 2. PROFESSIONAL PROFILE ──────────────────────────────────────────────
  /// e.g. Gold Work, Silver Work, Diamond Setting, All Metals
  TextColumn get specialization => text().withDefault(const Constant('All Metals'))();
  /// Rate basis — Per Gram (Rs/g) | Per Piece (Rs) | Percentage (%)
  TextColumn get rateType       => text().withDefault(const Constant('Per Gram (Rs/g)'))();
  /// Making charge rate (unit depends on rateType)
  RealColumn get rateAmount     => real().withDefault(const Constant(0.0))();

  // ── 3. ADDRESS ───────────────────────────────────────────────────────────
  TextColumn get address        => text().nullable()();
  TextColumn get city           => text().nullable()();

  // ── 4. FINANCIAL ─────────────────────────────────────────────────────────
  /// Opening balance (positive = we owe karigar, negative = karigar owes us)
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();

  // ── 5. STATUS & META ─────────────────────────────────────────────────────
  BoolColumn get isActive       => boolean().withDefault(const Constant(true))();
  TextColumn get notes          => text().nullable()();
}
