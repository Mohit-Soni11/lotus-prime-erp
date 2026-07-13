// =============================================================================
// FILE        : karigar_receipts.dart
// MODULE      : Karigar
// LAYER       : Database / Tables
// DESCRIPTION : Drift ORM table for receiving finished goods back from karigar.
//               Tracks net weight received, wastage (gold loss during making),
//               making charges, and payment settlement.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:lotus_erp/database/tables/base_table.dart';
import 'karigar_masters.dart';
import 'karigar_issues.dart';

@DataClassName('KarigarReceipt')
@TableIndex(name: 'idx_receipt_karigar', columns: {#karigarId})
@TableIndex(name: 'idx_receipt_issue', columns: {#issueId})
@TableIndex(name: 'idx_receipt_number', columns: {#receiptNumber})
@TableIndex(name: 'idx_receipt_date', columns: {#receiptDate})
class KarigarReceipts extends Table with BaseTable {
  // ── 1. IDENTIFICATION ────────────────────────────────────────────────────
  /// Unique auto-generated number: KGR-YYYYMMDD-NNNN
  TextColumn get receiptNumber => text().unique()();

  /// FK → karigar_issues (which issue is being settled)
  IntColumn get issueId => integer().references(KarigarIssues, #id)();

  /// FK → karigar_masters (denormalized for fast queries)
  IntColumn get karigarId => integer().references(KarigarMasters, #id)();

  // ── 2. RECEIPT DETAILS ───────────────────────────────────────────────────
  DateTimeColumn get receiptDate => dateTime()();

  /// How many pieces were returned
  IntColumn get quantityReceived => integer().withDefault(const Constant(1))();

  // ── 3. WEIGHT DETAILS ────────────────────────────────────────────────────
  /// Total weight of finished goods returned (grams)
  RealColumn get grossWeightReceived =>
      real().withDefault(const Constant(0.0))();

  /// Stone/diamond tare weight embedded in finished goods (grams)
  RealColumn get stoneWeight => real().withDefault(const Constant(0.0))();

  /// Net metal weight received = gross - stone (grams)
  RealColumn get netWeightReceived => real().withDefault(const Constant(0.0))();

  /// Gold loss: issuedNet - receivedNet (grams) — stored for reporting
  RealColumn get wastageWeight => real().withDefault(const Constant(0.0))();

  /// Wastage as percentage of net issued weight
  RealColumn get wastagePercent => real().withDefault(const Constant(0.0))();

  // ── 4. MAKING CHARGES ────────────────────────────────────────────────────
  /// Per Gram (Rs/g) | Per Piece (Rs) | Percentage (%)
  TextColumn get makingChargesType =>
      text().withDefault(const Constant('Per Gram (Rs/g)'))();

  /// Rate amount (unit depends on makingChargesType)
  RealColumn get makingChargeRate => real().withDefault(const Constant(0.0))();

  /// Final computed making charges amount (Rs)
  RealColumn get makingChargesAmount =>
      real().withDefault(const Constant(0.0))();

  // ── 5. PAYMENT ───────────────────────────────────────────────────────────
  /// Unpaid | Partial | Paid
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('Unpaid'))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();

  // ── 6. NOTES ─────────────────────────────────────────────────────────────
  TextColumn get notes => text().nullable()();
}
