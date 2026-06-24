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
    for (final statement in _columnSafetySql) {
      try {
        await _db.customStatement(statement);
      } catch (_) {}
    }
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

  Future<void> recordNoticePrepared({
    required int girviId,
    required GirviNoticeType noticeType,
    required String noticeText,
  }) {
    return recordAction(
      girviId: girviId,
      actionType: noticeType.actionType,
      noticeStage: noticeType.stage,
      noticeText: noticeText,
      actionNote: '${noticeType.label} prepared for customer communication.',
    );
  }

  Future<void> recordAuctionMarked({required int girviId}) {
    return recordAction(
      girviId: girviId,
      actionType: GirviNoticeActionTypes.auctionMarked,
      actionNote: 'Account marked as auctioned from Notice and Auction.',
    );
  }

  Future<void> recordDisposalSettlement({
    required int girviId,
    required double pledgedValuation,
    required double recoveredAmount,
    required double penaltyAmount,
    required double settlementTotal,
    required double customerBalanceDue,
    required double customerSurplus,
    String? note,
  }) {
    return recordAction(
      girviId: girviId,
      actionType: GirviNoticeActionTypes.disposalSettled,
      actionNote: note ?? 'Disposal settlement closed after final notice.',
      pledgedValuation: pledgedValuation,
      recoveredAmount: recoveredAmount,
      penaltyAmount: penaltyAmount,
      settlementTotal: settlementTotal,
      customerBalanceDue: customerBalanceDue,
      customerSurplus: customerSurplus,
    );
  }

  Future<void> recordAction({
    required int girviId,
    required String actionType,
    int? noticeStage,
    String? noticeText,
    String? actionNote,
    double pledgedValuation = 0,
    double recoveredAmount = 0,
    double penaltyAmount = 0,
    double settlementTotal = 0,
    double customerBalanceDue = 0,
    double customerSurplus = 0,
  }) async {
    await ensureSchema();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customInsert(
      '''
      INSERT INTO girvi_notice_actions (
        girvi_id,
        action_type,
        notice_stage,
        notice_text,
        action_note,
        pledged_valuation,
        recovered_amount,
        penalty_amount,
        settlement_total,
        customer_balance_due,
        customer_surplus,
        action_at,
        created_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withInt(girviId),
        Variable.withString(actionType),
        noticeStage == null
            ? const Variable<int>(null)
            : Variable.withInt(noticeStage),
        Variable.withString(noticeText ?? ''),
        Variable.withString(actionNote ?? ''),
        Variable.withReal(pledgedValuation),
        Variable.withReal(recoveredAmount),
        Variable.withReal(penaltyAmount),
        Variable.withReal(settlementTotal),
        Variable.withReal(customerBalanceDue),
        Variable.withReal(customerSurplus),
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

  Future<Map<int, List<GirviNoticeAction>>> actionsByGirviIds(
    List<int> girviIds,
  ) async {
    await ensureSchema();
    if (girviIds.isEmpty) return {};

    final placeholders = List.filled(girviIds.length, '?').join(', ');
    final rows = await _db.customSelect(
      '''
      SELECT *
      FROM girvi_notice_actions
      WHERE girvi_id IN ($placeholders)
      ORDER BY action_at DESC, id DESC
      ''',
      variables: girviIds.map(Variable.withInt).toList(),
    ).get();

    final result = <int, List<GirviNoticeAction>>{};
    for (final row in rows) {
      final action = _mapRow(row.data);
      result.putIfAbsent(action.girviId, () => []).add(action);
    }
    return result;
  }

  GirviNoticeAction _mapRow(Map<String, dynamic> row) {
    return GirviNoticeAction(
      id: row['id'] as int,
      girviId: row['girvi_id'] as int,
      actionType: row['action_type'] as String,
      noticeStage: _nullableInt(row['notice_stage']),
      noticeText: _nullableText(row['notice_text']),
      actionNote: _nullableText(row['action_note']),
      pledgedValuation: _doubleValue(row['pledged_valuation']),
      recoveredAmount: _doubleValue(row['recovered_amount']),
      penaltyAmount: _doubleValue(row['penalty_amount']),
      settlementTotal: _doubleValue(row['settlement_total']),
      customerBalanceDue: _doubleValue(row['customer_balance_due']),
      customerSurplus: _doubleValue(row['customer_surplus']),
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

  int? _nullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse('$value');
  }

  double _doubleValue(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
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
  notice_stage INTEGER,
  notice_text TEXT,
  action_note TEXT,
  pledged_valuation REAL NOT NULL DEFAULT 0.0,
  recovered_amount REAL NOT NULL DEFAULT 0.0,
  penalty_amount REAL NOT NULL DEFAULT 0.0,
  settlement_total REAL NOT NULL DEFAULT 0.0,
  customer_balance_due REAL NOT NULL DEFAULT 0.0,
  customer_surplus REAL NOT NULL DEFAULT 0.0,
  action_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  FOREIGN KEY (girvi_id) REFERENCES girvi_loans (id) ON DELETE CASCADE
)
''';

const List<String> _columnSafetySql = [
  'ALTER TABLE girvi_notice_actions ADD COLUMN notice_stage INTEGER',
  'ALTER TABLE girvi_notice_actions ADD COLUMN pledged_valuation REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE girvi_notice_actions ADD COLUMN recovered_amount REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE girvi_notice_actions ADD COLUMN penalty_amount REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE girvi_notice_actions ADD COLUMN settlement_total REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE girvi_notice_actions ADD COLUMN customer_balance_due REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE girvi_notice_actions ADD COLUMN customer_surplus REAL NOT NULL DEFAULT 0.0',
];

const List<String> _indexSql = [
  '''
  CREATE INDEX IF NOT EXISTS idx_girvi_notice_action_loan
  ON girvi_notice_actions (girvi_id, action_at DESC)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_girvi_notice_action_stage
  ON girvi_notice_actions (girvi_id, notice_stage)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS idx_girvi_notice_action_type
  ON girvi_notice_actions (action_type)
  ''',
];
