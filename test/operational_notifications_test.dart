import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/notifications/data/operational_alert_repository.dart';
import 'package:lotus_erp/features/notifications/domain/operational_alert_policy.dart';
import 'package:lotus_erp/logic/dashboard/dashboard_repository.dart';

void main() {
  late AppDatabase db;
  late int customerId;
  final today = DateTime(2026, 11, 20);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
              name: 'Test Customer', mobile: '9000000000'),
        );
  });
  tearDown(() => db.close());

  Future<SalesOrder> order(DateTime date, {String status = 'PENDING'}) async {
    final id = await db.into(db.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'ORDER-1',
            customerId: customerId,
            itemName: 'Gold Chain',
            deliveryDate: drift.Value(date),
            status: drift.Value(status),
          ),
        );
    return (db.select(db.salesOrders)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<Bill> bill() async {
    final id = await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'INV-1',
            customerId: drift.Value(customerId),
            customerName: const drift.Value('Test Customer'),
            finalAmount: const drift.Value(1000),
            paidAmount: const drift.Value(750),
            dueAmount: const drift.Value(250),
            paymentStatus: const drift.Value('PARTIAL'),
            promiseDate: drift.Value(today),
          ),
        );
    return (db.select(db.bills)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<GirviLoan> loan() async {
    final id = await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV-1',
            customerId: customerId,
            itemDescription: 'Gold Ring',
            startDate: drift.Value(DateTime(2025, 11, 20)),
            maturityDate: drift.Value(DateTime(2026, 11, 20)),
            loanAmount: const drift.Value(10000),
          ),
        );
    return (db.select(db.girviLoans)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  test('order countdown starts three days before and becomes due today',
      () async {
    final row = await order(DateTime(2026, 11, 23, 23));
    expect(OperationalAlertPolicy.order(row, 'Customer', today)!.title,
        contains('due in 3 days'));
    expect(
        OperationalAlertPolicy.order(row, 'Customer', DateTime(2026, 11, 19)),
        isNull);
    expect(
        OperationalAlertPolicy.order(row, 'Customer', DateTime(2026, 11, 23))!
            .title,
        contains('due today'));
    expect(
        OperationalAlertPolicy.order(row, 'Customer', DateTime(2026, 11, 24))!
            .title,
        contains('overdue by 1 day'));
    expect(
        OperationalAlertPolicy.order(
            row.copyWith(status: 'DELIVERED'), 'Customer', today),
        isNull);
    expect(
        OperationalAlertPolicy.order(
            row.copyWith(status: 'CANCELLED'), 'Customer', today),
        isNull);
  });

  test('extending delivery date replaces the previous reminder', () async {
    final row = await order(today);
    final repo = OperationalAlertRepository(db);
    expect((await repo.load(today)).where((a) => a.category == 'Orders'),
        hasLength(1));
    await (db.update(db.salesOrders)..where((t) => t.id.equals(row.id))).write(
      SalesOrdersCompanion(deliveryDate: drift.Value(DateTime(2026, 12, 1))),
    );
    expect(
        (await repo.load(today)).where((a) => a.category == 'Orders'), isEmpty);
  });

  test('collection reminder persists overdue and resolves on payment',
      () async {
    final row = await bill();
    expect(OperationalAlertPolicy.due(row, DateTime(2026, 11, 19)), isNull);
    final due = OperationalAlertPolicy.due(row, today)!;
    expect(due.title, contains('Call Test Customer'));
    expect(due.description, contains('250.00'));
    expect(OperationalAlertPolicy.due(row, DateTime(2026, 12, 1)), isNotNull);
    expect(
        OperationalAlertPolicy.due(
            row.copyWith(dueAmount: 0, paidAmount: 1000, paymentStatus: 'PAID'),
            today),
        isNull);
    expect(OperationalAlertPolicy.due(row.copyWith(status: 'CANCELLED'), today),
        isNull);
    expect(
        OperationalAlertPolicy.due(
            row.copyWith(promiseDate: drift.Value(DateTime(2026, 12, 1))),
            today),
        isNull);
  });

  test('girvi alerts follow maturity and annual policy without monthly alerts',
      () async {
    final row = await loan();
    expect(OperationalAlertPolicy.girvi(row, 'Customer', DateTime(2026, 1, 20)),
        isEmpty);
    expect(OperationalAlertPolicy.girvi(row, 'Customer', today), isEmpty);
    final nextDay =
        OperationalAlertPolicy.girvi(row, 'Customer', DateTime(2026, 11, 21));
    expect(
        nextDay.map((a) => a.key),
        containsAll([
          'girvi:maturity:${row.id}',
          'girvi:compound:${row.id}',
        ]));
    for (final status in ['RELEASED', 'AUCTIONED', 'READY_FOR_DELIVERY']) {
      expect(
          OperationalAlertPolicy.girvi(
              row.copyWith(status: status), 'Customer', DateTime(2027, 1, 1)),
          isEmpty);
    }
  });

  test('notifications update live and mark read cannot dismiss active due',
      () async {
    final row = await bill();
    await (db.update(db.bills)..where((t) => t.id.equals(row.id))).write(
      BillsCompanion(promiseDate: drift.Value(DateTime(2000))),
    );
    final repository = DashboardRepository(db: db);
    addTearDown(repository.dispose);
    final initial = repository.notificationsStream.first;
    repository.loadNotifications('owner');
    final items = await initial.timeout(const Duration(seconds: 5));
    expect(items.where((a) => a.eventKey == 'due:${row.id}'), hasLength(1));
    final afterRead = repository.notificationsStream.first;
    await repository.markAllRead('owner');
    final acknowledged = await afterRead;
    expect(acknowledged.where((a) => a.isOperational), isNotEmpty);
    expect(acknowledged.where((a) => !a.isRead), isEmpty);
    final cleared = repository.notificationsStream.firstWhere(
      (items) => !items.any((a) => a.eventKey == 'due:${row.id}'),
    );
    await (db.update(db.bills)..where((t) => t.id.equals(row.id))).write(
      const BillsCompanion(
          dueAmount: drift.Value(0), paymentStatus: drift.Value('PAID')),
    );
    await cleared.timeout(const Duration(seconds: 5));
  });

  test(
      'gold and silver alerts show item availability and resolve after restock',
      () async {
    await db.ensureStockInventorySchema();
    for (final metal in ['Gold', 'Silver']) {
      final stockId = await db.into(db.stockItems).insert(
            StockItemsCompanion.insert(
                sku: '$metal-1',
                itemName: '$metal Ring',
                category: metal,
                subCategory: 'Ring',
                metalType: drift.Value(metal)),
          );
      for (var i = 0; i < 10; i++) {
        await db.customStatement('''INSERT INTO stock_item_units
          (stock_item_id, batch_code, unit_code, piece_no, metal_type, item_type,
           segment, item_name, gross_weight, less_weight, net_weight,
           purity_percent, actual_fine_weight, supplier_name, status, created_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''', [
          stockId,
          'BATCH',
          '$metal-$i',
          i + 1,
          metal,
          'Ring',
          'General',
          '$metal Ring',
          5.0,
          0.0,
          5.0,
          metal == 'Gold' ? 91.6 : 925.0,
          4.5,
          'Supplier',
          metal == 'Gold' && i < 2 ? 'Available' : 'Sold',
          today.millisecondsSinceEpoch
        ]);
      }
    }
    final repo = OperationalAlertRepository(db);
    final alerts = (await repo.load(today))
        .where((a) => a.category == 'Inventory')
        .toList();
    expect(alerts, hasLength(2));
    expect(alerts.singleWhere((a) => a.title.contains('Gold')).description,
        contains('2'));
    expect(alerts.singleWhere((a) => a.title.contains('Silver')).title,
        contains('out of stock'));
    await db
        .customStatement("UPDATE stock_item_units SET status = 'Available'");
    expect((await repo.load(today)).where((a) => a.category == 'Inventory'),
        isEmpty);
  });
}
