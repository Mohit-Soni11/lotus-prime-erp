import 'package:drift/drift.dart';

import '../base_table.dart';
import 'girvi_loans.dart';

@DataClassName('GirviNoticeActionData')
@TableIndex(
  name: 'idx_girvi_notice_action_loan',
  columns: {#girviId, #actionAt},
)
@TableIndex(
  name: 'idx_girvi_notice_action_stage',
  columns: {#girviId, #noticeStage},
)
@TableIndex(name: 'idx_girvi_notice_action_type', columns: {#actionType})
class GirviNoticeActions extends Table with BaseTable {
  IntColumn get girviId =>
      integer().references(GirviLoans, #id, onDelete: KeyAction.cascade)();

  TextColumn get actionType => text()();
  IntColumn get noticeStage => integer().nullable()();
  TextColumn get noticeText => text().nullable()();
  TextColumn get actionNote => text().nullable()();

  RealColumn get pledgedValuation => real().withDefault(const Constant(0.0))();
  RealColumn get recoveredAmount => real().withDefault(const Constant(0.0))();
  RealColumn get penaltyAmount => real().withDefault(const Constant(0.0))();
  RealColumn get settlementTotal => real().withDefault(const Constant(0.0))();
  RealColumn get customerBalanceDue =>
      real().withDefault(const Constant(0.0))();
  RealColumn get customerSurplus => real().withDefault(const Constant(0.0))();

  DateTimeColumn get actionAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get deliveryChannel => text().nullable()();
  TextColumn get deliveryStatus => text().nullable()();
  TextColumn get deliveryReference => text().nullable()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
}
