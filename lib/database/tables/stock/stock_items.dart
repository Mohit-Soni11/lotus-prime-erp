// =============================================================================
// FILE        : stock_items.dart
// MODULE      : Stock & Inventory
// LAYER       : Database / Tables
// DESCRIPTION : Drift ORM table for jewellery stock items.
//
// CHANGELOG:
//   v1 — Initial stock table
//   v2 — Added stoneValue (₹), purchaseRate (₹/g), supplierId (FK)
//        to support stepped wizard + supplier linking.
//
// WEIGHT LOGIC (important):
//   netWeight  = grossWeight − stoneWeight  → used for METAL billing
//   stoneValue = separate ₹ charge          → NOT subtracted, added as
//                                             its own line item on invoice
//   purchaseRate = rate/gram at purchase    → owner-only, guards cost price
// =============================================================================

import 'package:drift/drift.dart';
import '../base_table.dart';
import 'suppliers.dart';

@DataClassName('StockItem')
@TableIndex(name: 'idx_stock_sku',       columns: {#sku})
@TableIndex(name: 'idx_stock_category',  columns: {#category})
@TableIndex(name: 'idx_stock_metal',     columns: {#metalType})
@TableIndex(name: 'idx_stock_status',    columns: {#status})
@TableIndex(name: 'idx_stock_supplier',  columns: {#supplierId})
class StockItems extends Table with BaseTable {

  // ── 1. IDENTIFICATION ──────────────────────────────────────────────────
  TextColumn get sku          => text().unique()();
  TextColumn get itemName     => text().withLength(min: 1, max: 200)();
  TextColumn get description  => text().nullable()();

  // ── 2. CLASSIFICATION ──────────────────────────────────────────────────
  TextColumn get category     => text()();
  TextColumn get subCategory  => text()();

  // ── 3. METAL DETAILS ───────────────────────────────────────────────────
  TextColumn get metalType    => text().withDefault(const Constant('Gold'))();
  TextColumn get purity       => text().nullable()();
  RealColumn get grossWeight  => real().withDefault(const Constant(0.0))();
  RealColumn get stoneWeight  => real().withDefault(const Constant(0.0))();
  RealColumn get netWeight    => real().withDefault(const Constant(0.0))();

  // ── 4. STONE / DIAMOND DETAILS ─────────────────────────────────────────
  TextColumn get stoneType    => text().withDefault(const Constant('None'))();
  RealColumn get stoneCarats  => real().withDefault(const Constant(0.0))();
  IntColumn  get stonePieces  => integer().withDefault(const Constant(0))();

  // ── 5. STONE VALUE (v2) ─────────────────────────────────────────────────
  // ⚠️  This is the ₹ value of the stone/diamond.
  //     It is ADDED to the invoice as a separate line — NOT deducted.
  //     Example: 18K ring has diamond worth ₹12,000 → metal bill + ₹12,000 stone bill.
  RealColumn get stoneValue   => real().withDefault(const Constant(0.0))();

  // ── 6. PRICING ─────────────────────────────────────────────────────────
  RealColumn get makingCharges      => real().withDefault(const Constant(0.0))();
  TextColumn get makingChargesType  => text().withDefault(const Constant('Per Gram (Rs/g)'))();

  // 🔒 Owner-only: rate/gram at which item was purchased.
  //    Used to calculate cost price and alert if selling below cost.
  RealColumn get purchaseRate       => real().withDefault(const Constant(0.0))();
  RealColumn get purchasePrice      => real().withDefault(const Constant(0.0))();
  RealColumn get mrp                => real().withDefault(const Constant(0.0))();

  // ── 7. GST & COMPLIANCE ────────────────────────────────────────────────
  TextColumn get hsnCode      => text().nullable()();
  TextColumn get huid         => text().nullable()();
  RealColumn get gstRate      => real().withDefault(const Constant(3.0))();

  // ── 8. INVENTORY ───────────────────────────────────────────────────────
  IntColumn  get quantity     => integer().withDefault(const Constant(1))();
  TextColumn get rackLocation => text().nullable()();

  // ── 9. SUPPLIER LINK (v2) ───────────────────────────────────────────────
  // supplierId: FK to Suppliers table (nullable — can be manual text only)
  IntColumn  get supplierId   => integer().nullable().references(Suppliers, #id)();
  // supplierName: plain text fallback / quick display without JOIN
  TextColumn get supplierName => text().nullable()();

  // ── 10. STATUS ─────────────────────────────────────────────────────────
  TextColumn get status       => text().withDefault(const Constant('Available'))();

  // ── 11. IMAGE ──────────────────────────────────────────────────────────
  TextColumn get imagePath    => text().nullable()();
}