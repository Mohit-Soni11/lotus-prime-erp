import 'package:drift/drift.dart';
import 'base_table.dart';
import 'customers.dart';

@DataClassName('Bill')
// ✅ Date par index lagaya taaki Dashboard "Today/Month" ka data turant laye
@TableIndex(name: 'idx_bills_date', columns: {#billDate}) 
@TableIndex(name: 'idx_bills_customer', columns: {#customerId})
class Bills extends Table with BaseTable {
  
  TextColumn get billNo => text().unique()();
  
  IntColumn get customerId => integer().nullable().references(Customers, #id, onDelete: KeyAction.setNull)();
  
  // Snapshot Data
  TextColumn get customerName => text().nullable()(); 
  TextColumn get mobile => text().nullable()();

  // Financials
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get finalAmount => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount  => real().withDefault(const Constant(0.0))(); 
  
  // Meta
  DateTimeColumn get billDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
}