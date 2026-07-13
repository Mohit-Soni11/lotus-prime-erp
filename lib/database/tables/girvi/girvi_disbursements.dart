import 'package:drift/drift.dart';

import 'package:lotus_erp/database/tables/base_table.dart';
import 'girvi_loans.dart';

@DataClassName('GirviDisbursement')
@TableIndex(name: 'idx_girvi_disbursement_loan', columns: {#girviId})
@TableIndex(
  name: 'idx_girvi_disbursement_order',
  columns: {#girviId, #sequenceNo},
  unique: true,
)
class GirviDisbursements extends Table with BaseTable {
  IntColumn get girviId =>
      integer().references(GirviLoans, #id, onDelete: KeyAction.cascade)();

  IntColumn get sequenceNo => integer()();
  TextColumn get mode => text()();
  TextColumn get displayLabel => text()();
  RealColumn get amount => real()();

  IntColumn get bankAccountId => integer().nullable()();
  TextColumn get accountName => text().nullable()();
  TextColumn get referenceNo => text().nullable()();
  TextColumn get details => text().nullable()();
  BoolColumn get isLegacy => boolean().withDefault(const Constant(false))();
}
