part of 'customer_profile_repository.dart';

mixin _CustomerProfileAccountQueries {
  AppDatabase get _db;
  Future<List<CustomerAdvanceOrderModel>> _fetchAdvanceOrders(
    int customerId,
  ) async {
    try {
      final orderRows = await (_db.select(_db.salesOrders)
            ..where(
              (t) =>
                  t.customerId.equals(customerId) &
                  (t.status.equals('PENDING') | t.status.equals('READY')),
            )
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
            ]))
          .get();

      final List<CustomerAdvanceOrderModel> result = [];

      for (final order in orderRows) {
        final advances = await (_db.select(_db.orderAdvances)
              ..where((t) => t.orderId.equals(order.id)))
            .get();

        final totalAdvancePaid =
            advances.fold(0.0, (sum, advance) => sum + advance.amountPaid);

        final estimatedTotal = order.bookingType == 'LOCKED'
            ? order.approxWeight * order.lockedRate
            : 0.0;

        result.add(
          CustomerAdvanceOrderModel(
            id: order.id,
            orderNo: order.orderNo,
            itemName: order.itemName,
            metalType: order.metalType,
            purity: order.purity,
            approxWeight: order.approxWeight,
            lockedRate: order.lockedRate,
            bookingType: order.bookingType,
            status: AdvanceOrderStatus.fromString(order.status),
            deliveryDate: order.deliveryDate,
            notes: order.notes,
            totalAdvancePaid: totalAdvancePaid,
            estimatedTotal: estimatedTotal,
            createdAt: order.createdAt,
          ),
        );
      }

      return result;
    } catch (e) {
      AppLogger.error("Customer advance orders fetch error: $e");
      rethrow;
    }
  }

  Future<double> _fetchCustomerAccountCreditBalance(int customerId) async {
    try {
      final rows = await (_db.select(_db.customerAccountLedger)
            ..where(
              (t) => t.customerId.equals(customerId) & t.isVoided.equals(false),
            ))
          .get();

      return rows.fold<double>(0.0, (sum, entry) {
        final amount = entry.amount;
        if (entry.entryType.toUpperCase() == 'DEBIT') {
          return sum - amount;
        }
        return sum + amount;
      });
    } catch (e) {
      AppLogger.error("Customer account credit fetch error: $e");
      rethrow;
    }
  }
}
