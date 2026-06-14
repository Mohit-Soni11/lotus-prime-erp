// =============================================================================
// FILE        : booking_advance_repository.dart
// MODULE      : Sales → Booking & Advance
// LAYER       : Repository / Database
// DESCRIPTION : All database operations for the Booking & Advance module.
//               ✅ v2: Added getNextBookingSequence() and
//                      getCurrentFinancialYear() for proper DB-synced
//                      booking numbers. No more reset on app restart.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:lotus_erp/database/db/app_database.dart';

class EditableBookingAdvance {
  const EditableBookingAdvance({
    required this.order,
    required this.customer,
    required this.advances,
  });

  final SalesOrder order;
  final Customer? customer;
  final List<OrderAdvance> advances;
}

class BookingAdvanceRepository {
  final AppDatabase _db;

  BookingAdvanceRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  // ===========================================================================
  // BOOKING NUMBER UTILITIES
  // ✅ v2: Controller calls these on init to sync booking number with DB.
  // ===========================================================================

  /// Returns the current Indian financial year string.
  /// Example: April 2025 → March 2026 = "2526"
  /// Indian FY starts in April, so months Jan/Feb/Mar belong to previous FY.
  String getCurrentFinancialYear() {
    final now = DateTime.now();
    final startYear = now.month < 4 ? now.year - 1 : now.year;
    final endYear = startYear + 1;
    return '${(startYear % 100).toString().padLeft(2, '0')}'
        '${(endYear % 100).toString().padLeft(2, '0')}';
  }

  /// Returns the next sequence number based on total existing bookings in DB.
  /// Guarantees booking numbers never reset on app restart.
  Future<int> getNextBookingSequence() async {
    final count = await _db.salesOrders.count().getSingle();
    return count + 1;
  }

  // ===========================================================================
  // SAVE NEW BOOKING
  // ===========================================================================

  Future<int> saveNewBooking({
    required int customerId,
    required String customerName,
    required String customerMobile,
    required String itemName,
    required String itemDesc,
    required String metalType,
    required String purity,
    required double approxWeight,
    required String bookingType,
    required double lockedRate,
    required DateTime? deliveryDate,
    required String? notes,
    required double totalAdvance,
    required double goldRate,
    required bool isGst,
  }) async {
    final fy = getCurrentFinancialYear();
    final seq = await getNextBookingSequence();
    final orderNo = 'BK-LJ-$fy-${seq.toString().padLeft(4, '0')}';

    return _db.transaction(() async {
      final orderId = await _db.into(_db.salesOrders).insert(
            SalesOrdersCompanion.insert(
              orderNo: orderNo,
              customerId: customerId,
              itemName: itemName,
              metalType: Value(metalType),
              purity: Value(purity),
              approxWeight: Value(approxWeight),
              bookingType: Value(bookingType),
              lockedRate: Value(lockedRate),
              status: const Value('PENDING'),
              deliveryDate: Value(deliveryDate),
              notes: Value(notes),
            ),
          );

      if (totalAdvance > 0) {
        await _db.into(_db.orderAdvances).insert(
              OrderAdvancesCompanion.insert(
                orderId: orderId,
                amountPaid: Value(totalAdvance),
                rateOnDate: Value(goldRate),
              ),
            );
      }

      debugPrint('✅ Booking saved: $orderNo | Advance: ₹$totalAdvance');
      return orderId;
    });
  }

  Future<EditableBookingAdvance?> fetchEditableBooking(int orderId) async {
    final order = await (_db.select(_db.salesOrders)
          ..where((tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
    if (order == null) return null;

    final customer = await (_db.select(_db.customers)
          ..where((tbl) => tbl.id.equals(order.customerId)))
        .getSingleOrNull();
    final advances = await (_db.select(_db.orderAdvances)
          ..where((tbl) => tbl.orderId.equals(orderId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.paymentDate)]))
        .get();

    return EditableBookingAdvance(
      order: order,
      customer: customer,
      advances: advances,
    );
  }

  Future<void> updateBooking({
    required int orderId,
    required int customerId,
    required String itemName,
    required String metalType,
    required String purity,
    required double approxWeight,
    required String bookingType,
    required double lockedRate,
    required DateTime? deliveryDate,
    required String? notes,
    required double totalAdvance,
    required double rateOnDate,
  }) async {
    await _db.transaction(() async {
      await (_db.update(_db.salesOrders)
            ..where((tbl) => tbl.id.equals(orderId)))
          .write(
        SalesOrdersCompanion(
          customerId: Value(customerId),
          itemName: Value(itemName),
          metalType: Value(metalType),
          purity: Value(purity),
          approxWeight: Value(approxWeight),
          bookingType: Value(bookingType),
          lockedRate: Value(lockedRate),
          deliveryDate: Value(deliveryDate),
          notes: Value(notes),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (_db.delete(_db.orderAdvances)
            ..where((tbl) => tbl.orderId.equals(orderId)))
          .go();

      if (totalAdvance > 0) {
        await _db.into(_db.orderAdvances).insert(
              OrderAdvancesCompanion.insert(
                orderId: orderId,
                amountPaid: Value(totalAdvance),
                rateOnDate: Value(rateOnDate),
              ),
            );
      }
    });
  }

  // ===========================================================================
  // CUSTOMER SEARCH
  // ===========================================================================

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    if (query.trim().length < 2) return [];
    final results = await (_db.select(_db.customers)
          ..where((t) => t.name.contains(query) | t.mobile.contains(query))
          ..limit(8))
        .get();
    return results
        .map((c) => {
              'id': c.id,
              'name': c.name,
              'mobile': c.mobile,
              'city': c.city ?? '',
            })
        .toList();
  }
}
