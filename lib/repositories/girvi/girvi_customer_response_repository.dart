import 'package:drift/drift.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/girvi/girvi_customer_response_model.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_review_period.dart';

/// Persistence boundary for customer replies and their recovery effect.
/// Financial entries remain exclusively owned by the Girvi payment repository.
class GirviCustomerResponseRepository {
  GirviCustomerResponseRepository(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<int> record({
    required int girviId,
    required GirviCustomerResponseKind kind,
    required GirviContactChannel channel,
    required String responseText,
    int? noticeActionId,
    int? noticeStage,
    DateTime? promiseDueAt,
    DateTime? receivedAt,
    String performedBy = 'LOCAL_OPERATOR',
  }) async {
    final text = _requiredText(responseText, 'Customer response is required.');
    if (kind.requiresFollowUpDate && promiseDueAt == null) {
      throw ArgumentError('A follow-up date is required for ${kind.label}.');
    }
    if (!kind.requiresFollowUpDate && promiseDueAt != null) {
      throw ArgumentError('This response does not use a follow-up date.');
    }
    if (noticeStage != null && noticeStage != GirviNoticeType.formal.stage) {
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
      if (linkedNotice == null) {
        throw StateError(
            'Record a response only against a saved formal notice.');
      }
      final currentNotice = await (_db.select(_db.girviNoticeActions)
            ..where((row) =>
                row.girviId.equals(girviId) &
                row.actionType.equals(GirviNoticeActionTypes.noticePrepared))
            ..orderBy([
              (row) => OrderingTerm.desc(row.actionAt),
              (row) => OrderingTerm.desc(row.id),
            ])
            ..limit(1))
          .getSingleOrNull();
      if (currentNotice?.id != linkedNotice.id) {
        throw StateError('Record the response against the current notice.');
      }
      final delivery = await (_db.select(_db.girviNoticeActions)
            ..where((row) =>
                row.girviId.equals(girviId) &
                row.noticeActionId.equals(linkedNotice.id) &
                row.actionType.equals(
                  GirviNoticeActionTypes.noticeDeliveryRecorded,
                ))
            ..orderBy([(row) => OrderingTerm.asc(row.deliveredAt)])
            ..limit(1))
          .getSingleOrNull();
      if (delivery == null) {
        throw StateError(
            'Confirm notice delivery before recording a customer response.');
      }
      final responseAt = receivedAt ?? _now();
      final deliveredAt = delivery.deliveredAt ?? delivery.actionAt;
      if (responseAt.isBefore(deliveredAt)) {
        throw StateError('A response cannot predate notice delivery.');
      }
      if (kind.requiresFollowUpDate &&
          promiseDueAt != null &&
          DateTime(promiseDueAt.year, promiseDueAt.month, promiseDueAt.day)
              .isBefore(DateTime(
                  responseAt.year, responseAt.month, responseAt.day))) {
        throw ArgumentError('The follow-up date cannot be in the past.');
      }
      if (kind == GirviCustomerResponseKind.noResponse) {
        final deadline = GirviNoticeReviewPeriod.deadline(
          approvedAt: linkedNotice.actionAt,
          approvedDeadline: linkedNotice.noticeDeadlineAt,
          deliveredAt: deliveredAt,
          fallbackDays: 7,
        );
        if (deadline == null || responseAt.isBefore(deadline)) {
          throw StateError(
              'No response can be recorded only after the notice deadline.');
        }
      }
      final effectiveStage = noticeStage ?? linkedNotice.noticeStage;
      return _db.into(_db.girviCustomerResponses).insert(
            GirviCustomerResponsesCompanion.insert(
              girviId: girviId,
              noticeActionId: Value(linkedNotice.id),
              noticeStage: Value(effectiveStage),
              responseKind: kind.dbValue,
              contactChannel: channel.dbValue,
              responseText: text,
              promiseDueAt: Value(promiseDueAt),
              status: Value(
                kind.requiresFollowUpDate
                    ? GirviPromiseStatus.open.dbValue
                    : GirviPromiseStatus.recorded.dbValue,
              ),
              receivedAt: Value(responseAt),
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
      throw ArgumentError(
          'Use OPEN only when recording a new customer follow-up.');
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
        promiseDueAt: row.promiseDueAt,
        status: GirviPromiseStatus.fromDb(row.status),
        resolvedAt: row.resolvedAt,
        resolutionNote: _optionalText(row.resolutionNote),
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
