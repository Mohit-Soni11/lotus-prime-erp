import 'package:drift/drift.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_document_record_model.dart';

class GirviNoticeDocumentRepository {
  GirviNoticeDocumentRepository(this._db);

  final AppDatabase _db;

  Future<Map<int, List<GirviNoticeDocumentRecord>>> byGirviIds(
    List<int> girviIds,
  ) async {
    await _db.ensureGirviNoticeDocumentSchema();
    if (girviIds.isEmpty) return const {};
    final rows = await (_db.select(_db.girviNoticeDocuments)
          ..where((row) => row.girviId.isIn(girviIds))
          ..orderBy([
            (row) => OrderingTerm.desc(row.createdAt),
            (row) => OrderingTerm.desc(row.id),
          ]))
        .get();
    final result = <int, List<GirviNoticeDocumentRecord>>{};
    for (final row in rows) {
      result.putIfAbsent(row.girviId, () => []).add(_map(row));
    }
    return result;
  }

  GirviNoticeDocumentRecord _map(GirviNoticeDocumentData row) =>
      GirviNoticeDocumentRecord(
        id: row.id,
        girviId: row.girviId,
        noticeActionId: row.noticeActionId,
        noticeStage: row.noticeStage,
        language: GirviNoticeLanguage.values.firstWhere(
          (language) => language.fileLabel == row.language,
          orElse: () => throw StateError(
              'Unsupported saved notice language: ${row.language}'),
        ),
        noticeText: row.noticeText,
        documentHash: row.documentHash,
        generatedText: row.generatedText,
        wasManuallyEdited: row.wasManuallyEdited,
        approvedBy: row.approvedBy,
        approvedAt: row.approvedAt,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
