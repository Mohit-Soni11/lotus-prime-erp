part of 'defaulter_repository.dart';

class _NoticeFollowUpSnapshot {
  const _NoticeFollowUpSnapshot({
    required this.kind,
    required this.status,
    required this.promiseDueAt,
    required this.actionAvailableAt,
  });

  final GirviCustomerResponseKind kind;
  final GirviPromiseStatus status;
  final DateTime? promiseDueAt;
  final DateTime? actionAvailableAt;

  bool isMonitoringAt(DateTime now) {
    final availableAt = actionAvailableAt;
    return kind.requiresFollowUpDate &&
        status.isOpen &&
        promiseDueAt != null &&
        availableAt != null &&
        now.isBefore(availableAt);
  }

  bool isActionDueAt(DateTime now) {
    final availableAt = actionAvailableAt;
    if (availableAt == null || now.isBefore(availableAt)) return false;
    return kind == GirviCustomerResponseKind.recoveryRequest ||
        (kind.requiresFollowUpDate && status.isOpen);
  }
}

Future<Map<int, _NoticeFollowUpSnapshot>> _loadNoticeFollowUps(
  AppDatabase db,
  List<int> loanIds,
  Map<int, GirviNoticeActionData> formalNotices,
  List<GirviNoticeActionData> noticeActions,
) async {
  if (loanIds.isEmpty || formalNotices.isEmpty) return const {};
  await db.ensureGirviCustomerResponseSchema();
  final rows = await (db.select(db.girviCustomerResponses)
        ..where((row) => row.girviId.isIn(loanIds))
        ..orderBy([
          (row) => OrderingTerm.desc(row.receivedAt),
          (row) => OrderingTerm.desc(row.id),
        ]))
      .get();
  final latest = <int, GirviCustomerResponseData>{};
  final latestOpen = <int, GirviCustomerResponseData>{};
  final latestOpenDate = <int, DateTime>{};
  final firstDeliveries = <int, DateTime>{};
  for (final action in noticeActions) {
    if (action.actionType != GirviNoticeActionTypes.noticeDeliveryRecorded ||
        formalNotices[action.girviId]?.id != action.noticeActionId) {
      continue;
    }
    final deliveredAt = action.deliveredAt ?? action.actionAt;
    final prior = firstDeliveries[action.girviId];
    if (prior == null || deliveredAt.isBefore(prior)) {
      firstDeliveries[action.girviId] = deliveredAt;
    }
  }
  for (final row in rows) {
    if (formalNotices[row.girviId]?.id != row.noticeActionId) continue;
    latest.putIfAbsent(row.girviId, () => row);
    final kind = GirviCustomerResponseKind.fromDb(row.responseKind);
    final status = GirviPromiseStatus.fromDb(row.status);
    final due = row.promiseDueAt;
    if (!kind.requiresFollowUpDate || !status.isOpen || due == null) continue;
    latestOpen.putIfAbsent(row.girviId, () => row);
    final previous = latestOpenDate[row.girviId];
    if (previous == null || due.isAfter(previous)) {
      latestOpenDate[row.girviId] = due;
    }
  }
  final result = <int, _NoticeFollowUpSnapshot>{};
  for (final entry in latest.entries) {
    final loanId = entry.key;
    final notice = formalNotices[loanId]!;
    final deliveryAt = firstDeliveries[loanId];
    final followUpDate = latestOpenDate[loanId];
    final kind = GirviCustomerResponseKind.fromDb(
      entry.value.responseKind ==
              GirviCustomerResponseKind.recoveryRequest.dbValue
          ? entry.value.responseKind
          : latestOpen[loanId]?.responseKind ?? entry.value.responseKind,
    );
    final deadline = GirviNoticeReviewPeriod.deadline(
      approvedAt: notice.actionAt,
      approvedDeadline: notice.noticeDeadlineAt,
      deliveredAt: deliveryAt,
      fallbackDays: 7,
    );
    result[loanId] = _NoticeFollowUpSnapshot(
      kind: kind,
      status: followUpDate != null
          ? GirviPromiseStatus.open
          : GirviPromiseStatus.fromDb(entry.value.status),
      promiseDueAt: followUpDate,
      actionAvailableAt: GirviRecoveryEligibility.availableAt(
        deliveredAt: deliveryAt,
        noticeDeadline: deadline,
        responseKind: kind,
        followUpDate: followUpDate,
      ),
    );
  }
  return result;
}
