import 'package:drift/drift.dart';
import 'base_table.dart';
import 'customers.dart';

@DataClassName('Loan')
@TableIndex(name: 'idx_loans_customer', columns: {#customerId})
class Loans extends Table with BaseTable {
  
  TextColumn get loanNo => text().unique()();
  IntColumn get customerId => integer().references(Customers, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get itemDesc => text()();
  RealColumn get grossWeight => real().withDefault(const Constant(0.0))();
  
  RealColumn get loanAmount => real().withDefault(const Constant(0.0))();
  RealColumn get interestRate => real().withDefault(const Constant(2.0))(); 
  
  DateTimeColumn get startDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
}