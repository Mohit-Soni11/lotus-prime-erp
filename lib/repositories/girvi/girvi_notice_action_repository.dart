import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_notice_action_model.dart';

class GirviNoticeActionRepository {
  GirviNoticeActionRepository(this._db);

  final AppDatabase _db;
  bool _schemaReady = false;

  Future<void> ensureSchema() async {
    if (_schemaReady) return;
    await _db.ensureGirviNoticeActionSchema();
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

  Future<void> recordNoticeDeliveryProof({
    required int girviId,
    required GirviNoticeType noticeType,
    required String noticeText,
    required String actionType,
    required String deliveryChannel,
    required String deliveryStatus,
    String? deliveryReference,
    DateTime? deliveredAt,
  }) {
    return recordAction(
      girviId: girviId,
      actionType: actionType,
      noticeStage: noticeType.stage,
      noticeText: noticeText,
      actionNote:
          '${noticeType.label} $deliveryStatus through $deliveryChannel.',
      deliveryChannel: deliveryChannel,
      deliveryStatus: deliveryStatus,
      deliveryReference: deliveryReference,
      deliveredAt: deliveredAt ?? DateTime.now(),
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
    String? deliveryChannel,
    String? deliveryStatus,
    String? deliveryReference,
    DateTime? deliveredAt,
  }) async {
    await ensureSchema();
    final now = DateTime.now();
    await _db.into(_db.girviNoticeActions).insert(
          GirviNoticeActionsCompanion.insert(
            girviId: girviId,
            actionType: actionType,
            createdAt: Value(now),
            actionAt: Value(now),
            noticeStage: Value(noticeStage),
            noticeText: Value(_normalizeText(noticeText)),
            actionNote: Value(_normalizeText(actionNote)),
            pledgedValuation: Value(pledgedValuation),
            recoveredAmount: Value(recoveredAmount),
            penaltyAmount: Value(penaltyAmount),
            settlementTotal: Value(settlementTotal),
            customerBalanceDue: Value(customerBalanceDue),
            customerSurplus: Value(customerSurplus),
            deliveryChannel: Value(_normalizeText(deliveryChannel)),
            deliveryStatus: Value(_normalizeText(deliveryStatus)),
            deliveryReference: Value(_normalizeText(deliveryReference)),
            deliveredAt: Value(deliveredAt),
          ),
        );
  }

  Future<Map<int, GirviNoticeAction>> latestByGirviIds(
    List<int> girviIds,
  ) async {
    await ensureSchema();
    if (girviIds.isEmpty) return {};

    final rows = await (_db.select(_db.girviNoticeActions)
          ..where((row) => row.girviId.isIn(girviIds))
          ..orderBy([
            (row) => OrderingTerm.desc(row.actionAt),
            (row) => OrderingTerm.desc(row.id),
          ]))
        .get();

    final result = <int, GirviNoticeAction>{};
    for (final row in rows) {
      final action = _mapData(row);
      result[action.girviId] ??= action;
    }
    return result;
  }

  Future<Map<int, List<GirviNoticeAction>>> actionsByGirviIds(
    List<int> girviIds,
  ) async {
    await ensureSchema();
    if (girviIds.isEmpty) return {};

    final rows = await (_db.select(_db.girviNoticeActions)
          ..where((row) => row.girviId.isIn(girviIds))
          ..orderBy([
            (row) => OrderingTerm.desc(row.actionAt),
            (row) => OrderingTerm.desc(row.id),
          ]))
        .get();

    final result = <int, List<GirviNoticeAction>>{};
    for (final row in rows) {
      final action = _mapData(row);
      result.putIfAbsent(action.girviId, () => []).add(action);
    }
    return result;
  }

  GirviNoticeAction _mapData(GirviNoticeActionData row) {
    return GirviNoticeAction(
      id: row.id,
      girviId: row.girviId,
      actionType: row.actionType,
      noticeStage: row.noticeStage,
      noticeText: _normalizeText(row.noticeText),
      actionNote: _normalizeText(row.actionNote),
      pledgedValuation: row.pledgedValuation,
      recoveredAmount: row.recoveredAmount,
      penaltyAmount: row.penaltyAmount,
      settlementTotal: row.settlementTotal,
      customerBalanceDue: row.customerBalanceDue,
      customerSurplus: row.customerSurplus,
      deliveryChannel: _normalizeText(row.deliveryChannel),
      deliveryStatus: _normalizeText(row.deliveryStatus),
      deliveryReference: _normalizeText(row.deliveryReference),
      deliveredAt: row.deliveredAt,
      actionAt: row.actionAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  String? _normalizeText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
