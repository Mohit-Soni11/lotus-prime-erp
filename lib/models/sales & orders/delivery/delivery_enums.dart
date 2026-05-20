// =============================================================================
// FILE        : delivery_enums.dart
// MODULE      : Sales → Delivery Management
// LAYER       : Models / Enums
// DESCRIPTION : All enums for the Delivery Management module.
//
// CHANGELOG:
//   v1 — Initial enums for Delivery Management module.
// =============================================================================

// ── 1. ORDER STATUS PIPELINE ─────────────────────────────────────────────────
enum DeliveryOrderStatus {
  booked('BOOKED'),
  inMaking('IN_MAKING'),
  ready('READY'),
  delivered('DELIVERED'),
  cancelled('CANCELLED');

  final String value;
  const DeliveryOrderStatus(this.value);

  static DeliveryOrderStatus fromString(String s) =>
      DeliveryOrderStatus.values.firstWhere(
        (e) => e.value == s.toUpperCase(),
        orElse: () => DeliveryOrderStatus.booked,
      );

  String get label {
    switch (this) {
      case DeliveryOrderStatus.booked:
        return 'Booked';
      case DeliveryOrderStatus.inMaking:
        return 'In Making';
      case DeliveryOrderStatus.ready:
        return 'Ready';
      case DeliveryOrderStatus.delivered:
        return 'Delivered';
      case DeliveryOrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// ── 2. ITEM STATUS ────────────────────────────────────────────────────────────
enum DeliveryItemStatus {
  pending('PENDING'),
  ready('READY'),
  delivered('DELIVERED');

  final String value;
  const DeliveryItemStatus(this.value);

  static DeliveryItemStatus fromString(String s) =>
      DeliveryItemStatus.values.firstWhere(
        (e) => e.value == s.toUpperCase(),
        orElse: () => DeliveryItemStatus.pending,
      );
}

// ── 3. PAYMENT STATUS ─────────────────────────────────────────────────────────
enum DeliveryPaymentStatus {
  unpaid('UNPAID'),
  partial('PARTIAL'),
  paid('PAID');

  final String value;
  const DeliveryPaymentStatus(this.value);

  static DeliveryPaymentStatus fromString(String s) =>
      DeliveryPaymentStatus.values.firstWhere(
        (e) => e.value == s.toUpperCase(),
        orElse: () => DeliveryPaymentStatus.unpaid,
      );

  String get label {
    switch (this) {
      case DeliveryPaymentStatus.unpaid:
        return 'Unpaid';
      case DeliveryPaymentStatus.partial:
        return 'Partial Due';
      case DeliveryPaymentStatus.paid:
        return 'Paid';
    }
  }
}

// ── 4. TAB FILTER ─────────────────────────────────────────────────────────────
enum DeliveryTab {
  activeOrders,
  actionRequired,
  dueLedger,
  completedBills,
}

// ── 5. SORT OPTIONS ───────────────────────────────────────────────────────────
enum DeliverySortBy {
  deliveryDateAsc,
  deliveryDateDesc,
  customerName,
  statusPipeline,
}

// ── 6. URGENCY LEVEL (for Action Required tab) ───────────────────────────────
enum DeliveryUrgency {
  overdue,
  today,
  tomorrow,
  thisWeek,
}
