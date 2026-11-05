import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/reports/day_book/day_book_customer_metal_sales.dart';

/// Saved invoice line weights; returns are reported as separate activity.
class DayBookCustomerMetalSalesRepository {
  const DayBookCustomerMetalSalesRepository(this._db);

  final AppDatabase _db;

  Future<DayBookCustomerMetalSales> fetch(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);
    final bills = await (_db.select(_db.bills)
          ..where((bill) =>
              bill.billDate.isBiggerOrEqualValue(start) &
              bill.billDate.isSmallerThanValue(end) &
              bill.status.isIn(const [
                'ACTIVE',
                'PARTIALLY_RETURNED',
                'RETURNED',
              ])))
        .get();
    if (bills.isEmpty) return const DayBookCustomerMetalSales();

    final ids = bills.map((bill) => bill.id).toList();
    final items = await (_db.select(_db.billItems)
          ..where((item) => item.billId.isIn(ids)))
        .get();

    var goldGrams = 0.0;
    var silverGrams = 0.0;
    final goldInvoices = <int>{};
    final silverInvoices = <int>{};
    for (final item in items) {
      final metal = item.metalType.trim().toLowerCase();
      if (metal.contains('gold')) {
        goldGrams += item.netWeight;
        goldInvoices.add(item.billId);
      } else if (metal.contains('silver')) {
        silverGrams += item.netWeight;
        silverInvoices.add(item.billId);
      }
    }
    return DayBookCustomerMetalSales(
      goldGrams: goldGrams,
      silverGrams: silverGrams,
      goldInvoices: goldInvoices.length,
      silverInvoices: silverInvoices.length,
    );
  }
}
