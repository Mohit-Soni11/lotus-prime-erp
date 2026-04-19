import 'package:drift/drift.dart';
import 'base_table.dart';
import 'bills.dart';

@DataClassName('BillItem')
// ✅ Bill ID par index zaroori hai kyunki hum hamesha "WHERE bill_id = X" karte hain
@TableIndex(name: 'idx_bill_items_bill', columns: {#billId})
class BillItems extends Table with BaseTable {
  
  IntColumn get billId => integer().references(Bills, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get itemName => text()();
  TextColumn get huid => text().nullable()(); 
  TextColumn get purity => text().withDefault(const Constant("22K"))();
  
  RealColumn get grossWeight => real().withDefault(const Constant(0.0))();
  RealColumn get netWeight => real().withDefault(const Constant(0.0))();
  
  RealColumn get rate => real().withDefault(const Constant(0.0))();
  RealColumn get makingCharge => real().withDefault(const Constant(0.0))();
  RealColumn get itemTotal => real().withDefault(const Constant(0.0))();
}