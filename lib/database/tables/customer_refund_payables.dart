import 'package:drift/drift.dart';

import 'base_table.dart';
import 'customers.dart';

@DataClassName('CustomerRefundPayableEntry')
@TableIndex(name: 'idx_customer_refund_customer', columns: {#customerId})
@TableIndex(name: 'idx_customer_refund_reference', columns: {#sourceReference})
@TableIndex(name: 'idx_customer_refund_date', columns: {#entryDate})
class CustomerRefundPayables extends Table with BaseTable {
  IntColumn get customerId =>
      integer().references(Customers, #id, onDelete: KeyAction.restrict)();

  TextColumn get entryType => text()();
  TextColumn get sourceType => text()();
  TextColumn get sourceReference => text().nullable()();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMode => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get entryDate => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isVoided => boolean().withDefault(const Constant(false))();
  TextColumn get voidReason => text().nullable()();
}
