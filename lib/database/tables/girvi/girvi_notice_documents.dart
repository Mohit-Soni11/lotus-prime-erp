import 'package:drift/drift.dart';

import 'package:lotus_erp/database/tables/base_table.dart';

import 'girvi_loans.dart';
import 'girvi_notice_actions.dart';

/// Immutable, language-specific document snapshots for an approved notice.
/// The parent action owns the workflow stage; this table owns its documents.
@DataClassName('GirviNoticeDocumentData')
@TableIndex(
  name: 'idx_girvi_notice_document_loan_stage',
  columns: {#girviId, #noticeStage},
)
@TableIndex(
  name: 'idx_girvi_notice_document_action_language',
  columns: {#noticeActionId, #language},
)
class GirviNoticeDocuments extends Table with BaseTable {
  IntColumn get girviId =>
      integer().references(GirviLoans, #id, onDelete: KeyAction.cascade)();

  IntColumn get noticeActionId => integer()
      .references(GirviNoticeActions, #id, onDelete: KeyAction.cascade)();

  IntColumn get noticeStage => integer()();
  TextColumn get language => text()();
  TextColumn get noticeText => text()();
  TextColumn get documentHash => text()();
  TextColumn get generatedText => text().nullable()();
  BoolColumn get wasManuallyEdited =>
      boolean().withDefault(const Constant(false))();
  TextColumn get approvedBy => text().nullable()();
  DateTimeColumn get approvedAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {noticeActionId, language},
      ];
}
