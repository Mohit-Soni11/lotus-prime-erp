import 'package:drift/drift.dart';

import 'base_table.dart';
import 'bills.dart';

@DataClassName('BillOldGoldItem')
@TableIndex(name: 'idx_bill_old_gold_bill', columns: {#billId})
class BillOldGoldItems extends Table with BaseTable {
  IntColumn get billId =>
      integer().references(Bills, #id, onDelete: KeyAction.cascade)();

  IntColumn get lineNo => integer().withDefault(const Constant(1))();
  TextColumn get metalType => text().withDefault(const Constant('GOLD'))();
  TextColumn get itemDescription => text().withDefault(const Constant(''))();

  RealColumn get grossWeight => real().withDefault(const Constant(0.0))();
  RealColumn get lessWeight => real().withDefault(const Constant(0.0))();
  RealColumn get netWeight => real().withDefault(const Constant(0.0))();
  RealColumn get purity => real().withDefault(const Constant(0.0))();
  RealColumn get fineWeight => real().withDefault(const Constant(0.0))();
  RealColumn get rate => real().withDefault(const Constant(0.0))();
  RealColumn get lineAmount => real().withDefault(const Constant(0.0))();
}
