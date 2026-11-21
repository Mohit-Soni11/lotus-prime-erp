import 'package:lotus_erp/database/db/app_database.dart';
import 'business_day_alert_repository.dart';
import 'package:lotus_erp/features/notifications/domain/operational_alert.dart';
import 'package:lotus_erp/features/notifications/domain/operational_alert_policy.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/low_stock_alert_repository.dart';

class OperationalAlertRepository {
  final AppDatabase db;

  const OperationalAlertRepository(this.db);

  Stream<void> watchChanges() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.stockItems,
          db.stockMovements,
          db.salesOrders,
          db.bills,
          db.girviLoans,
          db.customers,
          db.notifications,
          db.metalRateRevisions,
        },
      )
      .watch()
      .map((_) {});

  Future<List<OperationalAlert>> load(DateTime now) async {
    final results = await (
      LowStockAlertRepository(db).loadDashboard(),
      (db.select(db.salesOrders)
            ..where((t) => t.status.isIn(const ['PENDING', 'READY'])))
          .get(),
      (db.select(db.bills)
            ..where((t) => t.status.isIn(const [
                  'ACTIVE',
                  'PARTIALLY_RETURNED',
                  'RETURNED',
                ]))
            ..where((t) => t.promiseDate.isNotNull()))
          .get(),
      (db.select(db.girviLoans)
            ..where((t) => t.status.isIn(const [
                  'ACTIVE',
                  'OVERDUE',
                  'PARTIAL_RELEASE',
                ])))
          .get(),
    ).wait;
    final (stock, orders, bills, loans) = results;
    final customerIds = {
      ...orders.map((order) => order.customerId),
      ...loans.map((loan) => loan.customerId),
    };
    final customers = customerIds.isEmpty
        ? <Customer>[]
        : await (db.select(db.customers)..where((t) => t.id.isIn(customerIds)))
            .get();
    final names = {
      for (final customer in customers) customer.id: customer.name
    };

    final alerts = <OperationalAlert>[
      ...await BusinessDayAlertRepository(db).load(now),
      for (final card in stock.itemTypeCards)
        if (OperationalAlertPolicy.stock(card) case final alert?) alert,
      for (final order in orders)
        if (OperationalAlertPolicy.order(
                order, names[order.customerId] ?? 'Customer', now)
            case final alert?)
          alert,
      for (final bill in bills)
        if (OperationalAlertPolicy.due(bill, now) case final alert?) alert,
      for (final loan in loans)
        ...OperationalAlertPolicy.girvi(
          loan,
          names[loan.customerId] ?? 'Customer',
          now,
        ),
    ];
    alerts.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      return priority != 0 ? priority : a.key.compareTo(b.key);
    });
    return alerts;
  }
}
