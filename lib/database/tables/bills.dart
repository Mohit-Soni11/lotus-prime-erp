import 'package:drift/drift.dart';
import 'base_table.dart';
import 'customers.dart';
import 'sales_orders.dart';

@DataClassName('Bill')
// ✅ Date par index lagaya taaki Dashboard "Today/Month" ka data turant laye
@TableIndex(name: 'idx_bills_date', columns: {#billDate})
@TableIndex(name: 'idx_bills_customer', columns: {#customerId})
class Bills extends Table with BaseTable {
  TextColumn get billNo => text().unique()();

  IntColumn get customerId => integer()
      .nullable()
      .references(Customers, #id, onDelete: KeyAction.setNull)();

  // Snapshot Data
  TextColumn get customerName => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get billingMode => text().withDefault(const Constant('RETAIL'))();
  TextColumn get billType => text().withDefault(const Constant('NORMAL'))();
  TextColumn get paymentStatus => text().withDefault(const Constant('PAID'))();

  // Financials
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get taxableAmount => real().withDefault(const Constant(0.0))();
  RealColumn get cgstAmount => real().withDefault(const Constant(0.0))();
  RealColumn get sgstAmount => real().withDefault(const Constant(0.0))();
  RealColumn get gstAmount => real().withDefault(const Constant(0.0))();
  RealColumn get makingTotal => real().withDefault(const Constant(0.0))();
  RealColumn get roundOffAmount => real().withDefault(const Constant(0.0))();
  RealColumn get finalAmount => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get cashPaid => real().withDefault(const Constant(0.0))();
  RealColumn get upiPaid => real().withDefault(const Constant(0.0))();
  RealColumn get cardPaid => real().withDefault(const Constant(0.0))();
  RealColumn get advancePaid => real().withDefault(const Constant(0.0))();
  RealColumn get dueAmount => real().withDefault(const Constant(0.0))();
  RealColumn get tradeInDeduction =>
      real().named('old_gold_deduction').withDefault(const Constant(0.0))();
  TextColumn get tradeInMode => text()
      .named('old_gold_mode')
      .withDefault(const Constant('CASH_ADJUST'))();

  // Meta
  DateTimeColumn get billDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get promiseDate => dateTime().nullable()();
  IntColumn get sourceAdvanceOrderId => integer()
      .nullable()
      .references(SalesOrders, #id, onDelete: KeyAction.setNull)();
  TextColumn get sourceAdvanceOrderNo => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
}
