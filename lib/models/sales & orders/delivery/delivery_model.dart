// =============================================================================
// FILE        : delivery_model.dart
// MODULE      : Sales → Delivery Management
// LAYER       : Models
// DESCRIPTION : UI-layer data models for the Delivery Management module.
//               DeliveryOrderUiModel — used in list views & detail panels.
//               DeliveryItemUiModel  — used in partial delivery selector.
//               DeliverySummaryModel — used in stats header.
//
// CHANGELOG:
//   v1 — Initial models for Delivery Management module.
// =============================================================================

import 'delivery_enums.dart';

// =============================================================================
// 1. DELIVERY ORDER UI MODEL — for list rows & side panel
// =============================================================================
class DeliveryOrderUiModel {
  final int    id;
  final String deliveryNo;
  final int    customerId;
  final String customerName;
  final String customerMobile;
  final String itemName;
  final String metalType;
  final String purity;
  final double approxWeight;
  final double lockedRate;
  final DeliveryOrderStatus   status;
  final DeliveryPaymentStatus paymentStatus;
  final double advancePaid;
  final double totalAmount;
  final double dueAmount;
  final DateTime?  expectedDeliveryDate;
  final DateTime?  actualDeliveryDate;
  final String?    imagePath;
  final String?    notes;
  final String?    karigarName;
  final String?    linkedBillNo;
  final List<DeliveryItemUiModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeliveryOrderUiModel({
    required this.id,
    required this.deliveryNo,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.itemName,
    required this.metalType,
    required this.purity,
    required this.approxWeight,
    required this.lockedRate,
    required this.status,
    required this.paymentStatus,
    required this.advancePaid,
    required this.totalAmount,
    required this.dueAmount,
    required this.expectedDeliveryDate,
    required this.actualDeliveryDate,
    required this.imagePath,
    required this.notes,
    required this.karigarName,
    required this.linkedBillNo,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Computed helpers ──────────────────────────────────────────────────────

  /// True if delivery date has passed and order is not yet delivered
  bool get isOverdue {
    if (status == DeliveryOrderStatus.delivered ||
        status == DeliveryOrderStatus.cancelled) return false;
    if (expectedDeliveryDate == null) return false;
    return expectedDeliveryDate!.isBefore(
      DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0),
    );
  }

  bool get isToday {
    if (expectedDeliveryDate == null) return false;
    final now = DateTime.now();
    final d   = expectedDeliveryDate!;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool get isTomorrow {
    if (expectedDeliveryDate == null) return false;
    final tmrw = DateTime.now().add(const Duration(days: 1));
    final d    = expectedDeliveryDate!;
    return d.year == tmrw.year && d.month == tmrw.month && d.day == tmrw.day;
  }

  DeliveryUrgency? get urgency {
    if (status == DeliveryOrderStatus.delivered ||
        status == DeliveryOrderStatus.cancelled) return null;
    if (isOverdue)  return DeliveryUrgency.overdue;
    if (isToday)    return DeliveryUrgency.today;
    if (isTomorrow) return DeliveryUrgency.tomorrow;
    return null;
  }

  int get pendingItemCount =>
      items.where((i) => i.itemStatus != DeliveryItemStatus.delivered).length;

  int get deliveredItemCount =>
      items.where((i) => i.itemStatus == DeliveryItemStatus.delivered).length;

  int get totalItemCount => items.length;

  bool get hasMultipleItems => items.length > 1;
}

// =============================================================================
// 2. DELIVERY ITEM UI MODEL — for partial delivery selector
// =============================================================================
class DeliveryItemUiModel {
  final int    id;
  final int    deliveryOrderId;
  final String itemName;
  final String metalType;
  final String purity;
  final double approxWeight;
  final double finalWeight;
  final int    quantity;
  final String? imagePath;
  final String? notes;
  final DeliveryItemStatus itemStatus;
  final String? karigarName;
  final DateTime? deliveredAt;

  const DeliveryItemUiModel({
    required this.id,
    required this.deliveryOrderId,
    required this.itemName,
    required this.metalType,
    required this.purity,
    required this.approxWeight,
    required this.finalWeight,
    required this.quantity,
    required this.imagePath,
    required this.notes,
    required this.itemStatus,
    required this.karigarName,
    required this.deliveredAt,
  });
}

// =============================================================================
// 3. DELIVERY SUMMARY MODEL — for stats header cards
// =============================================================================
class DeliverySummaryModel {
  final int totalActive;
  final int actionRequired;   // overdue + today + tomorrow
  final int overdueCount;
  final int todayCount;
  final int dueLedgerCount;
  final int completedCount;
  final double totalDueAmount;
  final double totalRecoveredToday;

  const DeliverySummaryModel({
    required this.totalActive,
    required this.actionRequired,
    required this.overdueCount,
    required this.todayCount,
    required this.dueLedgerCount,
    required this.completedCount,
    required this.totalDueAmount,
    required this.totalRecoveredToday,
  });

  factory DeliverySummaryModel.empty() => const DeliverySummaryModel(
    totalActive: 0,
    actionRequired: 0,
    overdueCount: 0,
    todayCount: 0,
    dueLedgerCount: 0,
    completedCount: 0,
    totalDueAmount: 0.0,
    totalRecoveredToday: 0.0,
  );
}
