// =============================================================================
// FILE        : delivery_items.dart
// MODULE      : Sales → Delivery Management
// LAYER       : Database / Tables
// DESCRIPTION : DeliveryItems — individual line items within a DeliveryOrder.
//               Enables the "Partial Delivery / Smart Split" flow:
//               - A single order can have multiple items.
//               - Staff can mark individual items as delivered.
//               - Remaining items stay PENDING in the master order.
//
// CHANGELOG:
//   v1 — Initial table for Delivery Management module.
// =============================================================================

import 'package:drift/drift.dart';
import '../base_table.dart';
import 'delivery_orders.dart';

@DataClassName('DeliveryItem')
@TableIndex(name: 'idx_ditem_order', columns: {#deliveryOrderId})
@TableIndex(name: 'idx_ditem_status', columns: {#itemStatus})
class DeliveryItems extends Table with BaseTable {
  // ── PARENT LINK ───────────────────────────────────────────────────────────
  IntColumn get deliveryOrderId =>
      integer().references(DeliveryOrders, #id, onDelete: KeyAction.cascade)();

  // ── ITEM DETAILS ──────────────────────────────────────────────────────────
  TextColumn get itemName => text()();
  TextColumn get metalType => text().withDefault(const Constant('GOLD'))();
  TextColumn get purity => text().withDefault(const Constant('22K'))();
  RealColumn get approxWeight => real().withDefault(const Constant(0.0))();
  RealColumn get finalWeight => real().withDefault(const Constant(0.0))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn? get imagePath => text().nullable()();
  TextColumn? get notes => text().nullable()();

  // ── ITEM STATUS ───────────────────────────────────────────────────────────
  // Values: PENDING | READY | DELIVERED
  TextColumn get itemStatus => text().withDefault(const Constant('PENDING'))();

  // ── KARIGAR LINK ──────────────────────────────────────────────────────────
  IntColumn? get karigarId => integer().nullable()();
  TextColumn? get karigarName => text().nullable()();

  // ── DELIVERY TIMESTAMP ────────────────────────────────────────────────────
  DateTimeColumn? get deliveredAt => dateTime().nullable()();
}
