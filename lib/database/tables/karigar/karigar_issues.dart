// =============================================================================
// FILE        : karigar_issues.dart
// MODULE      : Karigar
// LAYER       : Database / Tables
// DESCRIPTION : Drift ORM table for gold/silver issue transactions to karigar.
//               Every time metal is given out for making, a row is created here.
//               Status lifecycle: Pending → In Progress → Completed | Cancelled.
// =============================================================================

import 'package:drift/drift.dart';
import '../base_table.dart';
import 'karigar_masters.dart';

@DataClassName('KarigarIssue')
@TableIndex(name: 'idx_issue_karigar', columns: {#karigarId})
@TableIndex(name: 'idx_issue_status', columns: {#status})
@TableIndex(name: 'idx_issue_number', columns: {#issueNumber})
@TableIndex(name: 'idx_issue_date', columns: {#issueDate})
class KarigarIssues extends Table with BaseTable {
  // ── 1. IDENTIFICATION ────────────────────────────────────────────────────
  /// Unique auto-generated number: KGI-YYYYMMDD-NNNN
  TextColumn get issueNumber => text().unique()();

  /// FK → karigar_masters
  IntColumn get karigarId => integer().references(KarigarMasters, #id)();

  // ── 2. ISSUE DETAILS ─────────────────────────────────────────────────────
  DateTimeColumn get issueDate => dateTime()();

  /// Jewellery item description: "22K Gold Ring for wedding order"
  TextColumn get itemDescription => text().withLength(min: 2, max: 300)();

  /// Broad category: Ring, Necklace, Bangle, etc.
  TextColumn get itemCategory => text().withDefault(const Constant('Ring'))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  // ── 3. METAL DETAILS ─────────────────────────────────────────────────────
  /// Gold | Silver | Platinum
  TextColumn get metalType => text().withDefault(const Constant('Gold'))();

  /// 22K (916), 925 (Sterling), etc.
  TextColumn get purity => text().nullable()();

  /// Total gross weight issued (grams)
  RealColumn get grossWeightIssued => real().withDefault(const Constant(0.0))();

  /// Net weight after deducting any stone tare (grams)
  RealColumn get netWeightIssued => real().withDefault(const Constant(0.0))();

  // ── 4. DELIVERY TIMELINE ─────────────────────────────────────────────────
  DateTimeColumn get expectedDelivery => dateTime().nullable()();

  // ── 5. STATUS & META ─────────────────────────────────────────────────────
  /// Pending | In Progress | Completed | Cancelled
  TextColumn get status => text().withDefault(const Constant('Pending'))();
  TextColumn get notes => text().nullable()();
}
