// =============================================================================
// FILE        : delivery_repository.dart
// MODULE      : Sales ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ Delivery Management
// LAYER       : Repository / Database
// DESCRIPTION : All database operations for the Delivery Management module.
//               Implements the full Order-to-Cash pipeline:
//               BOOKED ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ IN_MAKING ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ READY ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ DELIVERED
//               Partial delivery, payment routing, due ledger.
//
// CHANGELOG:
//   v1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Initial repository for Delivery Management module.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../../models/sales_orders/delivery/delivery_model.dart';
import '../../../models/sales_orders/delivery/delivery_enums.dart';
import '../../../core/logging/app_logger.dart';

class DeliveryRepository {
  final AppDatabase _db;
  DeliveryRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  // ===========================================================================
  // DELIVERY NUMBER UTILITY
  // ===========================================================================

  String _getCurrentFinancialYear() {
    final now = DateTime.now();
    final startYear = now.month < 4 ? now.year - 1 : now.year;
    final endYear = startYear + 1;
    return '${(startYear % 100).toString().padLeft(2, '0')}'
        '${(endYear % 100).toString().padLeft(2, '0')}';
  }

  Future<int> _getNextDeliverySequence() async {
    final count = await _db.deliveryOrders.count().getSingle();
    return count + 1;
  }

  Future<String> generateDeliveryNo() async {
    final fy = _getCurrentFinancialYear();
    final seq = await _getNextDeliverySequence();
    return 'DM-LJ-$fy-${seq.toString().padLeft(4, '0')}';
  }

  // ===========================================================================
  // CREATE ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â New Delivery Order (from Booking Advance)
  // ===========================================================================

  Future<int> createFromBooking({
    required int customerId,
    required String customerName,
    required String customerMobile,
    required String itemName,
    required String metalType,
    required String purity,
    required double approxWeight,
    required double lockedRate,
    required double advancePaid,
    required DateTime? expectedDeliveryDate,
    required String? notes,
    required String? imagePath,
    int? sourceOrderId,
    int? karigarId,
    String? karigarName,
    List<Map<String, dynamic>> extraItems = const [],
  }) async {
    return _db.transaction(() async {
      final deliveryNo = await generateDeliveryNo();
      final orderId = await _db.into(_db.deliveryOrders).insert(
            DeliveryOrdersCompanion.insert(
              deliveryNo: deliveryNo,
              customerId: customerId,
              sourceOrderId: Value(sourceOrderId),
              customerName: customerName,
              customerMobile: customerMobile,
              itemName: itemName,
              metalType: Value(metalType),
              purity: Value(purity),
              approxWeight: Value(approxWeight),
              lockedRate: Value(lockedRate),
              status: const Value('BOOKED'),
              karigarId: Value(karigarId),
              karigarName: Value(karigarName),
              advancePaid: Value(advancePaid),
              totalAmount: const Value(0.0),
              dueAmount: const Value(0.0),
              paymentStatus: const Value('UNPAID'),
              expectedDeliveryDate: Value(expectedDeliveryDate),
              notes: Value(notes),
              imagePath: Value(imagePath),
            ),
          );

      // Insert the primary item
      await _db.into(_db.deliveryItems).insert(
            DeliveryItemsCompanion.insert(
              deliveryOrderId: orderId,
              itemName: itemName,
              metalType: Value(metalType),
              purity: Value(purity),
              approxWeight: Value(approxWeight),
              itemStatus: const Value('PENDING'),
              karigarId: Value(karigarId),
              karigarName: Value(karigarName),
              notes: Value(notes),
              imagePath: Value(imagePath),
            ),
          );

      // Insert any additional items (multi-item orders)
      for (final item in extraItems) {
        await _db.into(_db.deliveryItems).insert(
              DeliveryItemsCompanion.insert(
                deliveryOrderId: orderId,
                itemName: item['itemName'] as String,
                metalType: Value(item['metalType'] as String? ?? metalType),
                purity: Value(item['purity'] as String? ?? purity),
                approxWeight:
                    Value((item['approxWeight'] as num?)?.toDouble() ?? 0.0),
                itemStatus: const Value('PENDING'),
                notes: Value(item['notes'] as String?),
                imagePath: Value(item['imagePath'] as String?),
              ),
            );
      }

      return orderId;
    });
  }

  // ===========================================================================
  // READ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â List queries for each tab
  // ===========================================================================

  /// Tab 1: Active Orders ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â BOOKED + IN_MAKING + READY
  Future<List<DeliveryOrderUiModel>> getActiveOrders({String? search}) async {
    final query = _db.select(_db.deliveryOrders)
      ..where((t) => t.status.isIn(['BOOKED', 'IN_MAKING', 'READY']))
      ..orderBy([(t) => OrderingTerm(expression: t.expectedDeliveryDate)]);

    if (search != null && search.isNotEmpty) {
      query.where((t) =>
          t.customerName.like('%$search%') |
          t.customerMobile.like('%$search%') |
          t.deliveryNo.like('%$search%') |
          t.itemName.like('%$search%'));
    }

    final rows = await query.get();
    return Future.wait(rows.map((r) => _toUiModel(r)));
  }

  /// Tab 2: Action Required ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â overdue + today + tomorrow (not delivered/cancelled)
  Future<List<DeliveryOrderUiModel>> getActionRequired() async {
    final tomorrow = DateTime.now().add(const Duration(days: 2));
    final query = _db.select(_db.deliveryOrders)
      ..where((t) =>
          t.status.isIn(['BOOKED', 'IN_MAKING', 'READY']) &
          t.expectedDeliveryDate.isSmallerOrEqualValue(tomorrow))
      ..orderBy([(t) => OrderingTerm(expression: t.expectedDeliveryDate)]);
    final rows = await query.get();
    return Future.wait(rows.map((r) => _toUiModel(r)));
  }

  /// Tab 3: Due Ledger ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â delivered but payment PARTIAL
  Future<List<DeliveryOrderUiModel>> getDueLedger({String? search}) async {
    final query = _db.select(_db.deliveryOrders)
      ..where((t) =>
          t.status.equals('DELIVERED') & t.paymentStatus.equals('PARTIAL'))
      ..orderBy([
        (t) => OrderingTerm(
            expression: t.actualDeliveryDate, mode: OrderingMode.desc)
      ]);

    if (search != null && search.isNotEmpty) {
      query.where((t) =>
          t.customerName.like('%$search%') |
          t.customerMobile.like('%$search%'));
    }

    final rows = await query.get();
    return Future.wait(rows.map((r) => _toUiModel(r)));
  }

  /// Tab 4: Completed Bills ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â DELIVERED + PAID
  Future<List<DeliveryOrderUiModel>> getCompletedBills({String? search}) async {
    final query = _db.select(_db.deliveryOrders)
      ..where(
          (t) => t.status.equals('DELIVERED') & t.paymentStatus.equals('PAID'))
      ..orderBy([
        (t) => OrderingTerm(
            expression: t.actualDeliveryDate, mode: OrderingMode.desc)
      ]);

    if (search != null && search.isNotEmpty) {
      query.where((t) =>
          t.customerName.like('%$search%') | t.deliveryNo.like('%$search%'));
    }

    final rows = await query.get();
    return Future.wait(rows.map((r) => _toUiModel(r)));
  }

  /// Get items for a specific order
  Future<List<DeliveryItemUiModel>> getItemsForOrder(int orderId) async {
    final rows = await (_db.select(_db.deliveryItems)
          ..where((t) => t.deliveryOrderId.equals(orderId)))
        .get();
    return rows.map(_toItemUiModel).toList();
  }

  /// Summary stats for header cards
  Future<DeliverySummaryModel> getSummary() async {
    try {
      final allActive = await (_db.select(_db.deliveryOrders)
            ..where((t) => t.status.isIn(['BOOKED', 'IN_MAKING', 'READY'])))
          .get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      int overdue = 0, todayCount = 0;
      for (final o in allActive) {
        if (o.expectedDeliveryDate == null) {
          continue;
        }
        final d = DateTime(
          o.expectedDeliveryDate!.year,
          o.expectedDeliveryDate!.month,
          o.expectedDeliveryDate!.day,
        );
        if (d.isBefore(today)) {
          overdue++;
        } else if (d.isAtSameMomentAs(today)) {
          todayCount++;
        } else if (d.isAtSameMomentAs(tomorrow)) {
          // Tomorrow is counted in actionRequired.
        }
      }

      final dueLedger = await (_db.select(_db.deliveryOrders)
            ..where((t) =>
                t.status.equals('DELIVERED') &
                t.paymentStatus.equals('PARTIAL')))
          .get();

      final completed = await (_db.select(_db.deliveryOrders)
            ..where((t) =>
                t.status.equals('DELIVERED') & t.paymentStatus.equals('PAID')))
          .get();

      final totalDue = dueLedger.fold<double>(0, (s, o) => s + o.dueAmount);

      return DeliverySummaryModel(
        totalActive: allActive.length,
        actionRequired: overdue + todayCount,
        overdueCount: overdue,
        todayCount: todayCount,
        dueLedgerCount: dueLedger.length,
        completedCount: completed.length,
        totalDueAmount: totalDue,
        totalRecoveredToday: 0.0,
      );
    } catch (e) {
      AppLogger.debug('ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ‚Â´ DeliveryRepo.getSummary error: $e');
      return DeliverySummaryModel.empty();
    }
  }

  // ===========================================================================
  // UPDATE ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Status transitions
  // ===========================================================================

  /// Move order to IN_MAKING (assign karigar)
  Future<void> markInMaking(int orderId,
      {int? karigarId, String? karigarName}) async {
    await (_db.update(_db.deliveryOrders)..where((t) => t.id.equals(orderId)))
        .write(DeliveryOrdersCompanion(
      status: const Value('IN_MAKING'),
      karigarId: Value(karigarId),
      karigarName: Value(karigarName),
    ));
  }

  /// Move order to READY
  Future<void> markReady(int orderId) async {
    await (_db.update(_db.deliveryOrders)..where((t) => t.id.equals(orderId)))
        .write(const DeliveryOrdersCompanion(
      status: Value('READY'),
    ));
  }

  /// Mark specific items as READY
  Future<void> markItemReady(int itemId) async {
    await (_db.update(_db.deliveryItems)..where((t) => t.id.equals(itemId)))
        .write(const DeliveryItemsCompanion(
      itemStatus: Value('READY'),
    ));
  }

  // ===========================================================================
  // DELIVER ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â The core One-Click conversion flow
  // ===========================================================================

  /// Full delivery: all items delivered, sets status + payment routing.
  /// Returns the generated bill number.
  Future<String> deliverOrder({
    required int orderId,
    required double finalAmount,
    required double paidNow,
    required double advancePaid,
    required String paymentMode, // 'CASH' | 'UPI' | 'CARD' | 'MIXED'
    String? linkedBillNo,
    int? linkedBillId,
  }) async {
    return _db.transaction(() async {
      final dueAmount =
          (finalAmount - paidNow - advancePaid).clamp(0.0, double.infinity);
      final paymentStatus = dueAmount > 0.5 ? 'PARTIAL' : 'PAID';

      await (_db.update(_db.deliveryOrders)..where((t) => t.id.equals(orderId)))
          .write(DeliveryOrdersCompanion(
        status: const Value('DELIVERED'),
        paymentStatus: Value(paymentStatus),
        totalAmount: Value(finalAmount),
        dueAmount: Value(dueAmount),
        actualDeliveryDate: Value(DateTime.now()),
        linkedBillNo: Value(linkedBillNo),
        linkedBillId: Value(linkedBillId),
      ));

      // Mark all items as delivered
      await (_db.update(_db.deliveryItems)
            ..where((t) => t.deliveryOrderId.equals(orderId)))
          .write(DeliveryItemsCompanion(
        itemStatus: const Value('DELIVERED'),
        deliveredAt: Value(DateTime.now()),
      ));

      AppLogger.debug(
          'ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ Order $orderId delivered. Status: $paymentStatus, Due: $dueAmount');
      return linkedBillNo ?? 'DM-$orderId';
    });
  }

  /// Partial delivery: deliver selected items, keep others PENDING.
  /// Creates a sub-invoice record.
  Future<void> partialDeliver({
    required int orderId,
    required List<int> deliveredItemIds,
    required double finalAmount,
    required double paidNow,
    required double advancePaid,
    String? linkedBillNo,
    int? linkedBillId,
  }) async {
    await _db.transaction(() async {
      final now = DateTime.now();

      // Mark selected items as delivered
      for (final itemId in deliveredItemIds) {
        await (_db.update(_db.deliveryItems)..where((t) => t.id.equals(itemId)))
            .write(DeliveryItemsCompanion(
          itemStatus: const Value('DELIVERED'),
          deliveredAt: Value(now),
        ));
      }

      // Check remaining items
      final remaining = await (_db.select(_db.deliveryItems)
            ..where((t) =>
                t.deliveryOrderId.equals(orderId) &
                t.itemStatus.isNotIn(['DELIVERED'])))
          .get();

      final dueAmount =
          (finalAmount - paidNow - advancePaid).clamp(0.0, double.infinity);
      final paymentStatus = dueAmount > 0.5 ? 'PARTIAL' : 'PAID';

      // If all items delivered, mark order as delivered
      if (remaining.isEmpty) {
        await (_db.update(_db.deliveryOrders)
              ..where((t) => t.id.equals(orderId)))
            .write(DeliveryOrdersCompanion(
          status: const Value('DELIVERED'),
          paymentStatus: Value(paymentStatus),
          totalAmount: Value(finalAmount),
          dueAmount: Value(dueAmount),
          actualDeliveryDate: Value(now),
          linkedBillNo: Value(linkedBillNo),
          linkedBillId: Value(linkedBillId),
        ));
      } else {
        // Order still active ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â update financials only
        await (_db.update(_db.deliveryOrders)
              ..where((t) => t.id.equals(orderId)))
            .write(DeliveryOrdersCompanion(
          dueAmount: Value(dueAmount),
          paymentStatus: Value(paymentStatus),
          linkedBillNo: Value(linkedBillNo),
          linkedBillId: Value(linkedBillId),
        ));
      }
    });
  }

  /// Collect due payment (clears from Due Ledger tab)
  Future<void> collectDue({
    required int orderId,
    required double amountCollected,
  }) async {
    final order = await (_db.select(_db.deliveryOrders)
          ..where((t) => t.id.equals(orderId)))
        .getSingle();

    final newDue =
        (order.dueAmount - amountCollected).clamp(0.0, double.infinity);
    final newPaymentStatus = newDue < 0.5 ? 'PAID' : 'PARTIAL';

    await (_db.update(_db.deliveryOrders)..where((t) => t.id.equals(orderId)))
        .write(DeliveryOrdersCompanion(
      dueAmount: Value(newDue),
      paymentStatus: Value(newPaymentStatus),
    ));
  }

  /// Cancel an order
  Future<void> cancelOrder(int orderId) async {
    await (_db.update(_db.deliveryOrders)..where((t) => t.id.equals(orderId)))
        .write(const DeliveryOrdersCompanion(
      status: Value('CANCELLED'),
    ));
  }

  // ===========================================================================
  // HELPER ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â DB row ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ UI model
  // ===========================================================================

  Future<DeliveryOrderUiModel> _toUiModel(DeliveryOrder row) async {
    final items = await getItemsForOrder(row.id);
    return DeliveryOrderUiModel(
      id: row.id,
      deliveryNo: row.deliveryNo,
      customerId: row.customerId,
      customerName: row.customerName,
      customerMobile: row.customerMobile,
      itemName: row.itemName,
      metalType: row.metalType,
      purity: row.purity,
      approxWeight: row.approxWeight,
      lockedRate: row.lockedRate,
      status: DeliveryOrderStatus.fromString(row.status),
      paymentStatus: DeliveryPaymentStatus.fromString(row.paymentStatus),
      advancePaid: row.advancePaid,
      totalAmount: row.totalAmount,
      dueAmount: row.dueAmount,
      expectedDeliveryDate: row.expectedDeliveryDate,
      actualDeliveryDate: row.actualDeliveryDate,
      imagePath: row.imagePath,
      notes: row.notes,
      karigarName: row.karigarName,
      linkedBillNo: row.linkedBillNo,
      items: items,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt ?? row.createdAt,
    );
  }

  DeliveryItemUiModel _toItemUiModel(DeliveryItem row) {
    return DeliveryItemUiModel(
      id: row.id,
      deliveryOrderId: row.deliveryOrderId,
      itemName: row.itemName,
      metalType: row.metalType,
      purity: row.purity,
      approxWeight: row.approxWeight,
      finalWeight: row.finalWeight,
      quantity: row.quantity,
      imagePath: row.imagePath,
      notes: row.notes,
      itemStatus: DeliveryItemStatus.fromString(row.itemStatus),
      karigarName: row.karigarName,
      deliveredAt: row.deliveredAt,
    );
  }
}
