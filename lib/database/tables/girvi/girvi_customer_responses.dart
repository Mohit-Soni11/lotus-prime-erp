import 'package:drift/drift.dart';

import 'package:lotus_erp/database/tables/base_table.dart';

import 'girvi_loans.dart';
import 'girvi_notice_actions.dart';

/// Immutable customer-contact evidence recorded during the Girvi notice flow.
///
/// A notice proves what the business issued; this table records what the
/// customer said or committed to afterwards.
@DataClassName('GirviCustomerResponseData')
@TableIndex(
  name: 'idx_girvi_response_loan_received',
  columns: {#girviId, #receivedAt},
)
@TableIndex(
  name: 'idx_girvi_response_open_promise',
  columns: {#girviId, #status, #promiseDueAt},
)
@TableIndex(
  name: 'idx_girvi_response_notice_action',
  columns: {#noticeActionId},
)
class GirviCustomerResponses extends Table with BaseTable {
  IntColumn get girviId =>
      integer().references(GirviLoans, #id, onDelete: KeyAction.cascade)();

  /// The approved notice that prompted this response, when applicable.
  IntColumn get noticeActionId => integer()
      .nullable()
      .references(GirviNoticeActions, #id, onDelete: KeyAction.setNull)();

  IntColumn get noticeStage => integer().nullable()();
  TextColumn get responseKind => text()();
  TextColumn get contactChannel => text()();
  TextColumn get responseText => text()();

  RealColumn get promisedAmount => real().nullable()();
  DateTimeColumn get promiseDueAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('OPEN'))();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get resolutionNote => text().nullable()();

  /// File path, message export ID, acknowledgement number, etc.
  TextColumn get proofReference => text().nullable()();
  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get performedBy => text().nullable()();
}
