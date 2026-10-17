import 'package:drift/drift.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/girvi/girvi_customer_response_model.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';

/// Persistence boundary for customer replies and settlement promises.
/// Financial entries remain exclusively owned by the Girvi payment repository.
class GirviCustomerResponseRepository {
  GirviCustomerResponseRepository(this._db);

  final AppDatabase _db;

  Future<int> record({
    required int girviId,
    required GirviCustomerResponseKind kind,
    required GirviContactChannel channel,
    required String responseText,
    int? noticeActionId,
    int? noticeStage,
    double? promisedAmount,
    DateTime? promiseDueAt,
    String? proofReference,
    DateTime? receivedAt,
    String performedBy = 'LOCAL_OPERATOR',
  }) async {
    final text = _requiredText(responseText, 'Customer response is required.');
    if (promisedAmount != null &&
        (promisedAmount.isNaN || promisedAmount < 0)) {
      throw ArgumentError.value(
        promisedAmount,
        'promisedAmount',
        'Promised amount must be zero or greater.',
      );
    }
    if (kind.isPromise && promiseDueAt == null) {
      throw ArgumentError('A promise date is required for ${kind.label}.');
    }
    if (kind == GirviCustomerResponseKind.partialPayment &&
        (promisedAmount == null || promisedAmount <= 0)) {
      throw ArgumentError('A promised amount is required for partial payment.');
    }
    if (noticeStage != null && (noticeStage < 1 || noticeStage > 3)) {
      throw ArgumentError.value(
          noticeStage, 'noticeStage', 'Invalid notice stage.');
    }

    await _db.ensureGirviCustomerResponseSchema();
    return _db.transaction(() async {
      final linkedNotice = await _resolveApprovedNotice(
        girviId: girviId,
        noticeActionId: noticeActionId,
        noticeStage: noticeStage,
      );
      final effectiveStage = noticeStage ?? linkedNotice?.noticeStage;
      return _db.into(_db.girviCustomerResponses).insert(
            GirviCustomerResponsesCompanion.insert(
              girviId: girviId,
              noticeActionId: Value(linkedNotice?.id),
              noticeStage: Value(effectiveStage),
              responseKind: kind.dbValue,
              contactChannel: channel.dbValue,
              responseText: text,
              promisedAmount: Value(promisedAmount),
              promiseDueAt: Value(promiseDueAt),
              status: Value(
                kind.isPromise
                    ? GirviPromiseStatus.open.dbValue
                    : GirviPromiseStatus.recorded.dbValue,
              ),
              proofReference: Value(_optionalText(proofReference)),
              receivedAt: Value(receivedAt ?? DateTime.now()),
              performedBy: Value(_optionalText(performedBy)),
            ),
          );
    });
  }

  Future<void> resolve({
    required int responseId,
    required GirviPromiseStatus status,
    String? resolutionNote,
    String performedBy = 'LOCAL_OPERATOR',
  }) async {
    if (!status.isResolved) {
      throw ArgumentError('Use OPEN only when recording a new promise.');
    }
    await _db.ensureGirviCustomerResponseSchema();
    final existing = await (_db.select(_db.girviCustomerResponses)
          ..where((row) => row.id.equals(responseId))
          ..limit(1))
        .getSingleOrNull();
    if (existing == null) throw StateError('Customer response was not found.');
    if (existing.status != GirviPromiseStatus.open.dbValue) {
      throw StateError('This customer response has already been resolved.');
    }
    await (_db.update(_db.girviCustomerResponses)
          ..where((row) => row.id.equals(responseId)))
        .write(
      GirviCustomerResponsesCompanion(
        status: Value(status.dbValue),
        resolvedAt: Value(DateTime.now()),
        resolutionNote: Value(_optionalText(resolutionNote)),
        performedBy: Value(_optionalText(performedBy)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<Map<int, List<GirviCustomerResponse>>> byGirviIds(
    List<int> girviIds,
  ) async {
    await _db.ensureGirviCustomerResponseSchema();
    if (girviIds.isEmpty) return const {};
    final rows = await (_db.select(_db.girviCustomerResponses)
          ..where((row) => row.girviId.isIn(girviIds))
          ..orderBy([
            (row) => OrderingTerm.desc(row.receivedAt),
            (row) => OrderingTerm.desc(row.id),
          ]))
        .get();
    final grouped = <int, List<GirviCustomerResponse>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.girviId, () => []).add(_map(row));
    }
    return grouped;
  }

  Future<GirviNoticeActionData?> _resolveApprovedNotice({
    required int girviId,
    required int? noticeActionId,
    required int? noticeStage,
  }) async {
    if (noticeActionId == null && noticeStage == null) return null;
    final query = _db.select(_db.girviNoticeActions)
      ..where((row) =>
          row.girviId.equals(girviId) &
          row.actionType.isIn(GirviNoticeActionTypes.preparationTypes));
    if (noticeActionId != null) {
      query.where((row) => row.id.equals(noticeActionId));
    }
    if (noticeStage != null) {
      query.where((row) => row.noticeStage.equals(noticeStage));
    }
    final row = await (query
          ..orderBy([(entry) => OrderingTerm.desc(entry.actionAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) {
      throw StateError('Record a response only against an approved notice.');
    }
    return row;
  }

  GirviCustomerResponse _map(GirviCustomerResponseData row) =>
      GirviCustomerResponse(
        id: row.id,
        girviId: row.girviId,
        noticeActionId: row.noticeActionId,
        noticeStage: row.noticeStage,
        kind: GirviCustomerResponseKind.fromDb(row.responseKind),
        channel: GirviContactChannel.fromDb(row.contactChannel),
        responseText: row.responseText,
        promisedAmount: row.promisedAmount,
        promiseDueAt: row.promiseDueAt,
        status: GirviPromiseStatus.fromDb(row.status),
        resolvedAt: row.resolvedAt,
        resolutionNote: _optionalText(row.resolutionNote),
        proofReference: _optionalText(row.proofReference),
        receivedAt: row.receivedAt,
        performedBy: _optionalText(row.performedBy),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  String _requiredText(String value, String message) {
    final clean = value.trim();
    if (clean.isEmpty) throw ArgumentError(message);
    return clean;
  }

  String? _optionalText(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }
}
