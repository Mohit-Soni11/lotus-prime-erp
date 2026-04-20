// =============================================================================
// FILE        : delivery_orders.dart
// MODULE      : Sales → Delivery Management
// LAYER       : Database / Tables
// DESCRIPTION : DeliveryOrders table — master record for every order
//               that enters the delivery pipeline.
//               Linked to SalesOrders (booking) and Customers.
//               Tracks full lifecycle: BOOKED → IN_MAKING → READY → DELIVERED
//
// CHANGELOG:
//   v1 — Initial table for Delivery Management module.
// =============================================================================

import 'package:drift/drift.dart';
import '../base_table.dart';
import '../customers.dart';
import '../sales_orders.dart';

@DataClassName('DeliveryOrder')
@TableIndex(name: 'idx_delivery_status', columns: {#status})
@TableIndex(name: 'idx_delivery_customer', columns: {#customerId})
@TableIndex(name: 'idx_delivery_date', columns: {#expectedDeliveryDate})
class DeliveryOrders extends Table with BaseTable {
  // ── IDENTIFIERS ───────────────────────────────────────────────────────────
  TextColumn get deliveryNo => text().unique()();
  IntColumn get customerId =>
      integer().references(Customers, #id, onDelete: KeyAction.cascade)();
  IntColumn? get sourceOrderId => integer()
      .nullable()
      .references(SalesOrders, #id, onDelete: KeyAction.setNull)();

  // ── CUSTOMER SNAPSHOT (for display even if customer deleted) ───────────────
  TextColumn get customerName => text()();
  TextColumn get customerMobile => text()();

  // ── ORDER DETAILS ─────────────────────────────────────────────────────────
  TextColumn get itemName => text()();
  TextColumn get metalType => text().withDefault(const Constant('GOLD'))();
  TextColumn get purity => text().withDefault(const Constant('22K'))();
  RealColumn get approxWeight => real().withDefault(const Constant(0.0))();
  RealColumn get lockedRate => real().withDefault(const Constant(0.0))();

  // ── STATUS PIPELINE ───────────────────────────────────────────────────────
  // Values: BOOKED | IN_MAKING | READY | DELIVERED | CANCELLED
  TextColumn get status => text().withDefault(const Constant('BOOKED'))();

  // ── KARIGAR LINK (optional — when item is IN_MAKING) ─────────────────────
  IntColumn? get karigarId => integer().nullable()();
  TextColumn? get karigarName => text().nullable()();

  // ── FINANCIALS ────────────────────────────────────────────────────────────
  RealColumn get advancePaid => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  RealColumn get dueAmount => real().withDefault(const Constant(0.0))();

  // ── PAYMENT STATUS ────────────────────────────────────────────────────────
  // Values: UNPAID | PARTIAL | PAID
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('UNPAID'))();

  // ── DELIVERY DETAILS ──────────────────────────────────────────────────────
  DateTimeColumn? get expectedDeliveryDate => dateTime().nullable()();
  DateTimeColumn? get actualDeliveryDate => dateTime().nullable()();

  // ── MEDIA & NOTES ─────────────────────────────────────────────────────────
  TextColumn? get imagePath => text().nullable()();
  TextColumn? get notes => text().nullable()();

  // ── LINKED BILL (set after delivery + full payment) ───────────────────────
  IntColumn? get linkedBillId => integer().nullable()();
  TextColumn? get linkedBillNo => text().nullable()();
}
