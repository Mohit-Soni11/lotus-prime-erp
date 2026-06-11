import 'package:drift/drift.dart';

import '../base_table.dart';
import 'girvi_loans.dart';

@DataClassName('GirviLoanItem')
@TableIndex(name: 'idx_girvi_item_loan', columns: {#girviId})
@TableIndex(
  name: 'idx_girvi_item_loan_serial',
  columns: {#girviId, #serialNo},
  unique: true,
)
class GirviLoanItems extends Table with BaseTable {
  IntColumn get girviId =>
      integer().references(GirviLoans, #id, onDelete: KeyAction.cascade)();

  IntColumn get serialNo => integer()();
  TextColumn get itemName => text()();
  TextColumn get metalType => text()();
  TextColumn get purity => text()();
  RealColumn get purityFactor => real().withDefault(const Constant(0.0))();
  IntColumn get pieces => integer().withDefault(const Constant(1))();
  TextColumn get huidNumber => text().nullable()();

  RealColumn get grossWeight => real().withDefault(const Constant(0.0))();
  RealColumn get lessWeight => real().withDefault(const Constant(0.0))();
  RealColumn get netWeight => real().withDefault(const Constant(0.0))();

  TextColumn get valuationMethod =>
      text().withDefault(const Constant('PURITY'))();
  RealColumn get valuationPurityPercent => real().nullable()();
  RealColumn get fineWeight => real().withDefault(const Constant(0.0))();
  RealColumn get ratePerGram => real().withDefault(const Constant(0.0))();
  RealColumn get valuationAmount => real().withDefault(const Constant(0.0))();

  TextColumn get notes => text().nullable()();
  BoolColumn get isLegacy => boolean().withDefault(const Constant(false))();
}
