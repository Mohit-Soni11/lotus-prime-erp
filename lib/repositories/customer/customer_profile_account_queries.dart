part of 'customer_profile_repository.dart';

mixin _CustomerProfileAccountQueries {
  AppDatabase get _db;
  Future<List<CustomerAdvanceOrderModel>> _fetchAdvanceOrders(
    int customerId,
  ) async {
    try {
      final orderRows = await (_db.select(_db.salesOrders)
            ..where((t) => t.customerId.equals(customerId))
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
            ]))
          .get();

      final ids = orderRows.map((order) => order.id).toList(growable: false);
      final advances = ids.isEmpty
          ? const <OrderAdvance>[]
          : await (_db.select(_db.orderAdvances)
                ..where((row) => row.orderId.isIn(ids)))
              .get();
      final paidByOrder = <int, double>{};
      for (final advance in advances) {
        paidByOrder.update(
          advance.orderId,
          (total) => total + advance.amountPaid,
          ifAbsent: () => advance.amountPaid,
        );
      }

      final List<CustomerAdvanceOrderModel> result = [];
      for (final order in orderRows) {
        final totalAdvancePaid = paidByOrder[order.id] ?? 0;

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
}
