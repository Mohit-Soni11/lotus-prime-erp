import 'package:drift/drift.dart';
import 'base_table.dart';
import 'customers.dart';

@DataClassName('SalesOrder')
@TableIndex(
    name: 'idx_orders_status',
    columns: {#status}) // Pending orders filter karne ke liye
class SalesOrders extends Table with BaseTable {
  TextColumn get orderNo => text().unique()();
  IntColumn get customerId =>
      integer().references(Customers, #id, onDelete: KeyAction.cascade)();

  TextColumn get itemName => text()();
  TextColumn get metalType => text().withDefault(const Constant('GOLD'))();
  TextColumn get purity => text().withDefault(const Constant('22K'))();

  RealColumn get approxWeight => real().withDefault(const Constant(0.0))();

  TextColumn get bookingType => text().withDefault(const Constant('OPEN'))();
  RealColumn get lockedRate => real().withDefault(const Constant(0.0))();

  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get deliveryDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('OrderAdvance')
@TableIndex(
    name: 'idx_advances_order',
    columns: {#orderId}) // Fast retrieval of payments
class OrderAdvances extends Table with BaseTable {
  IntColumn get orderId =>
      integer().references(SalesOrders, #id, onDelete: KeyAction.cascade)();

  RealColumn get amountPaid => real().withDefault(const Constant(0.0))();
  RealColumn get rateOnDate => real().withDefault(const Constant(0.0))();
  DateTimeColumn get paymentDate =>
      dateTime().withDefault(currentDateAndTime)();
}
