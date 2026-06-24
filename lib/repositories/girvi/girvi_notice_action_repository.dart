import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_notice_action_model.dart';

class GirviNoticeActionRepository {
  GirviNoticeActionRepository(this._db);

  final AppDatabase _db;
  bool _schemaReady = false;

  Future<void> ensureSchema() async {
    if (_schemaReady) return;
    await _db.customStatement(_createTableSql);
    for (final statement in _indexSql) {
      await _db.customStatement(statement);
    }
    _schemaReady = true;
  }

  Future<void> recordNoticeDraft({
    required int girviId,
    required String noticeText,
  }) {
    return recordAction(
      girviId: girviId,
      actionType: GirviNoticeActionTypes.noticeDraftCopied,
      noticeText: noticeText,
      actionNote: 'Legal notice draft copied for customer communication.',
    );
  }

  Future<void> recordAuctionMarked({required int girviId}) {
    return recordAction(
      girviId: girviId,
      actionType: GirviNoticeActionTypes.auctionMarked,
      actionNote: 'Account marked as auctioned from Notice and Auction.',
    );
  }

  Future<void> recordAction({
    required int girviId,
    required String actionType,
    String? noticeText,
    String? actionNote,
  }) async {
    await ensureSchema();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customInsert(
      '''
      INSERT INTO girvi_notice_actions (
        girvi_id,
        action_type,
        notice_text,
        action_note,
        action_at,
        created_at
      )
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withInt(girviId),
        Variable.withString(actionType),
        Variable.withString(noticeText ?? ''),
        Variable.withString(actionNote ?? ''),
        Variable.withInt(now),
        Variable.withInt(now),
      ],
    );
  }

  Future<Map<int, GirviNoticeAction>> latestByGirviIds(
    List<int> girviIds,
  ) async {
    await ensureSchema();
    if (girviIds.isEmpty) return {};

    final placeholders = List.filled(girviIds.length, '?').join(', ');
    final rows = await _db.customSelect(
      '''
      SELECT action.*
      FROM girvi_notice_actions AS action
      INNER JOIN (
        SELECT girvi_id, MAX(action_at) AS latest_action_at
        FROM girvi_notice_actions
        WHERE girvi_id IN ($placeholders)
        GROUP BY girvi_id
      ) AS latest
        ON latest.girvi_id = action.girvi_id
       AND latest.latest_action_at = action.action_at
      ORDER BY action.action_at DESC, action.id DESC
      ''',
      variables: girviIds.map(Variable.withInt).toList(),
    ).get();

    final result = <int, GirviNoticeAction>{};
    for (final row in rows) {
      final action = _mapRow(row.data);
      result[action.girviId] ??= action;
    }
    return result;
  }

  GirviNoticeAction _mapRow(Map<String, dynamic> row) {
    return GirviNoticeAction(
      id: row['id'] as int,
      girviId: row['girvi_id'] as int,
      actionType: row['action_type'] as String,
      noticeText: _nullableText(row['notice_text']),
      actionNote: _nullableText(row['action_note']),
      actionAt: _dateFromMillis(row['action_at']),
      createdAt: _dateFromMillis(row['created_at']),
      updatedAt:
          row['updated_at'] == null ? null : _dateFromMillis(row['updated_at']),
    );
  }

  DateTime _dateFromMillis(Object value) {
    final millis = value is int ? value : int.tryParse('$value') ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  String? _nullableText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

const String _createTableSql = '''
CREATE TABLE IF NOT EXISTS girvi_notice_actions (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  girvi_id INTEGER NOT NULL,
  action_type TEXT NOT NULL,
  notice_text TEXT,
  action_note TEXT,
  action_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  FOREIGN KEY (girvi_id) REFERENCES girvi_loans (id) ON DELETE CASCADE
)
''';

const List<String> _indexSql = [
  '''
  CREATE INDEX IF NOT EXISTS idx_girvi_notice_action_loan
  ON girvi_notice_actions (girvi_id, action_at DESC)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_girvi_notice_action_type
  ON girvi_notice_actions (action_type)
  ''',
];
