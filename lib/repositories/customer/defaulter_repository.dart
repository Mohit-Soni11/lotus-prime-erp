// =============================================================================
// FILE        : defaulter_repository.dart
// MODULE      : Risk & Collections
// LAYER       : Repository
// DESCRIPTION : Real-time Girvi risk queue backed by girvi_loans/payments.
// =============================================================================

import 'dart:math' as math;

import 'package:drift/drift.dart';

import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../features/customer/domain/services/customer_contact_value.dart';
import '../../logic/girvi/girvi_risk_policy.dart';
import '../../logic/girvi/girvi_notice_eligibility.dart';
import '../../logic/customer/risk_payment_monitoring.dart';
import '../../models/customer/defaulter_model.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import '../../models/girvi/girvi_customer_response_model.dart';
import '../../models/girvi/girvi_notice_review_period.dart';
import '../../models/girvi/girvi_recovery_eligibility.dart';
import '../girvi/girvi_repository.dart';
import '../girvi/girvi_interest_payment_adjustments.dart';

part 'defaulter_recovery_history.dart';
part 'defaulter_notice_followups.dart';
part 'defaulter_activity_snapshots.dart';

class DefaulterRepository {
  final AppDatabase _db;

  DefaulterRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<List<DefaulterModel>> fetchAllDefaulters({
    bool syncStatuses = true,
  }) async {
    try {
      if (syncStatuses) {
        final girviRepo = GirviRepository(_db);
        await girviRepo.syncOverdueStatus();
        await girviRepo.syncSettlementStatus();
      }

      final now = DateTime.now();
      final openStatuses = [
        GirviStatus.active.dbValue,
        GirviStatus.overdue.dbValue,
        GirviStatus.partialRelease.dbValue,
      ];

      final settledLoanIds = await _loadSettledRecoveryLoanIds();
      final query = _db.select(_db.girviLoans).join([
        innerJoin(
          _db.customers,
          _db.customers.id.equalsExp(_db.girviLoans.customerId),
        ),
      ])
        ..where(_db.girviLoans.status.isIn(openStatuses) |
            _db.girviLoans.id.isIn(settledLoanIds));

      final rows = await query.get();
      final loanIds =
          rows.map((row) => row.readTable(_db.girviLoans).id).toList();
      final paymentSummary = await _loadPaymentSummary(loanIds, now);
      final itemSnapshots = await _loadItemSnapshots(loanIds);
      final workflow = await _loadNoticeWorkflow(loanIds);

      final accounts = <DefaulterModel>[];
      for (final row in rows) {
        final loan = row.readTable(_db.girviLoans);
        final customer = row.readTable(_db.customers);
        final summary = paymentSummary[loan.id] ?? _PaymentSummary.empty();
        final itemSnapshot =
            itemSnapshots[loan.id] ?? _PledgedItemSnapshot.fromLoan(loan);
        final settlement = workflow.settlements[loan.id];
        final account = settlement != null &&
                GirviStatus.fromDb(loan.status) == GirviStatus.auctioned
            ? _mapRecoveredAccount(
                loan: loan,
                customer: customer,
                summary: summary,
                itemSnapshot: itemSnapshot,
                settlement: settlement,
                address: _formatCustomerAddress(customer),
              )
            : _mapRiskAccount(
                loan: loan,
                customer: customer,
                summary: summary,
                itemSnapshot: itemSnapshot,
                isCollateralRecovery: workflow.recoveryIds.contains(loan.id),
                hasNoticeWorkflow: workflow.noticeIds.contains(loan.id),
                noticeFollowUp: workflow.followUps[loan.id],
                now: now,
              );
        if (account != null) accounts.add(account);
      }

      accounts.sort((a, b) {
        final riskCompare = b.daysOverdue.compareTo(a.daysOverdue);
        if (riskCompare != 0) return riskCompare;
        return b.totalDue.compareTo(a.totalDue);
      });

      AppLogger.debug(
        'Risk & Collections: ${accounts.length} Girvi risk accounts loaded.',
      );
      return accounts;
    } catch (e) {
      AppLogger.debug('Risk & Collections fetch failed: $e');
      rethrow;
    }
  }

  Stream<List<DefaulterModel>> watchAllDefaulters() {
    return _db
        .customSelect(
          'SELECT 1 AS watch_key',
          readsFrom: {
            _db.girviLoans,
            _db.girviPayments,
            _db.girviNoticeActions,
            _db.girviCustomerResponses,
            _db.customers,
          },
        )
        .watch()
        .asyncMap((_) => fetchAllDefaulters());
  }

  Future<int> fetchDefaulterCount() async {
    try {
      final accounts = await fetchAllDefaulters();
      return accounts.where((account) => !account.isRecoverySettled).length;
    } catch (e) {
      AppLogger.debug('Risk & Collections count failed: $e');
      return 0;
    }
  }

  Future<Map<int, _PaymentSummary>> _loadPaymentSummary(
    List<int> loanIds,
    DateTime now,
  ) async {
    if (loanIds.isEmpty) return const {};

    final payments = await (_db.select(_db.girviPayments)
          ..where((payment) => payment.girviId.isIn(loanIds)))
        .get();

    final byLoan = <int, _PaymentSummary>{};
    final monthStart = DateTime(now.year, now.month);
    for (final payment in payments) {
      final current = byLoan[payment.girviId] ?? _PaymentSummary.empty();
      byLoan[payment.girviId] = current.add(
        payment,
        currentMonthStart: monthStart,
      );
    }
    return byLoan;
  }

  Future<Map<int, _PledgedItemSnapshot>> _loadItemSnapshots(
    List<int> loanIds,
  ) async {
    if (loanIds.isEmpty) return const {};

    final items = await (_db.select(_db.girviLoanItems)
          ..where((item) => item.girviId.isIn(loanIds))
          ..orderBy([
            (item) => OrderingTerm.asc(item.girviId),
            (item) => OrderingTerm.asc(item.serialNo),
          ]))
        .get();

    final grouped = <int, List<GirviLoanItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.girviId, () => <GirviLoanItem>[]).add(item);
    }

    return grouped.map(
      (loanId, items) => MapEntry(
        loanId,
        _PledgedItemSnapshot.fromItems(items),
      ),
    );
  }

  Future<Set<int>> _loadSettledRecoveryLoanIds() async {
    try {
      await _db.ensureGirviNoticeActionSchema();
      final rows = await (_db.selectOnly(_db.girviNoticeActions)
            ..addColumns([_db.girviNoticeActions.girviId])
            ..where(_db.girviNoticeActions.actionType
                .equals(GirviNoticeActionTypes.disposalSettled)))
          .get();
      return rows
          .map((row) => row.read(_db.girviNoticeActions.girviId))
          .whereType<int>()
          .toSet();
    } catch (error) {
      AppLogger.debug('Recovery register IDs unavailable: $error');
      return <int>{};
    }
  }

  Future<
      ({
        Set<int> recoveryIds,
        Set<int> noticeIds,
        Map<int, GirviNoticeActionData> settlements,
        Map<int, _NoticeFollowUpSnapshot> followUps,
      })> _loadNoticeWorkflow(
    List<int> loanIds,
  ) async {
    if (loanIds.isEmpty) {
      return (
        recoveryIds: <int>{},
        noticeIds: <int>{},
        settlements: <int, GirviNoticeActionData>{},
        followUps: <int, _NoticeFollowUpSnapshot>{},
      );
    }

    try {
      await _db.ensureGirviNoticeActionSchema();
      final rows = await (_db.select(_db.girviNoticeActions)
            ..where((action) => action.girviId.isIn(loanIds)))
          .get();

      final recoveryIds = <int>{};
      final noticeIds = <int>{};
      final settlements = <int, GirviNoticeActionData>{};
      final formalNotices = <int, GirviNoticeActionData>{};
      for (final row in rows) {
        if (row.actionType == GirviNoticeActionTypes.noticePrepared) {
          final previous = formalNotices[row.girviId];
          if (previous == null || row.actionAt.isAfter(previous.actionAt)) {
            formalNotices[row.girviId] = row;
          }
        }
        if (row.actionType == GirviNoticeActionTypes.disposalSettled) {
          final previous = settlements[row.girviId];
          if (previous == null || row.actionAt.isAfter(previous.actionAt)) {
            settlements[row.girviId] = row;
          }
        }
      }
      noticeIds.addAll(formalNotices.keys);
      final followUps =
          await _loadNoticeFollowUps(_db, loanIds, formalNotices, rows);
      for (final row in rows) {
        if (!_isOpenCollateralRecoveryAction(row.actionType)) continue;
        final formal = formalNotices[row.girviId];
        if (formal == null) continue;
        if (row.noticeActionId == formal.id ||
            (row.noticeActionId == null &&
                !row.actionAt.isBefore(formal.actionAt))) {
          recoveryIds.add(row.girviId);
        }
      }
      return (
        recoveryIds: recoveryIds,
        noticeIds: noticeIds,
        settlements: settlements,
        followUps: followUps,
      );
    } catch (error) {
      AppLogger.debug(
        'Risk & Collections: collateral recovery flags unavailable: $error',
      );
      return (
        recoveryIds: <int>{},
        noticeIds: <int>{},
        settlements: <int, GirviNoticeActionData>{},
        followUps: <int, _NoticeFollowUpSnapshot>{},
      );
    }
  }

  bool _isOpenCollateralRecoveryAction(String actionType) {
    return actionType == GirviNoticeActionTypes.collateralRecoveryInitiated;
  }

  DefaulterModel? _mapRiskAccount({
    required GirviLoan loan,
    required Customer customer,
    required _PaymentSummary summary,
    required _PledgedItemSnapshot itemSnapshot,
    required bool isCollateralRecovery,
    required bool hasNoticeWorkflow,
    required _NoticeFollowUpSnapshot? noticeFollowUp,
    required DateTime now,
  }) {
    final status = GirviStatus.fromDb(loan.status);
    final maturityDate = loan.maturityDate ??
        GirviLoanModel.addChargeableMonths(
          loan.startDate,
          loan.durationMonths,
        );

    final originalPrincipal = loan.loanAmount + summary.legacyPrincipalRepaid;
    final quote = GirviInterestCalculator.quoteAt(
      principal: originalPrincipal,
      monthlyRatePercent: loan.interestRate,
      startDate: loan.startDate,
      asOf: now,
      adjustments: summary.interestAdjustments,
    );
    final coveredInterestMonths = math.max(
      summary.coveredInterestMonths,
      GirviInterestCalculator.coveredMonthsForTimeline(
        principal: originalPrincipal,
        monthlyRatePercent: loan.interestRate,
        startDate: loan.startDate,
        asOf: now,
        adjustments: summary.interestAdjustments,
      ),
    );
    final interestOutstanding = quote.interestOutstanding;
    final principalOutstanding = math.max(
      0.0,
      loan.loanAmount - summary.principalPaid - summary.principalDiscount,
    );
    final totalDue = principalOutstanding + interestOutstanding;
    final assessment = GirviRiskPolicy.assess(
      status: status,
      startDate: loan.startDate,
      maturityDate: maturityDate,
      lastInterestPaidDate: loan.lastInterestPaidDate,
      principalDue: principalOutstanding,
      interestDue: interestOutstanding,
      hasCollectionHistory: summary.hasCollectionHistory,
      hasInterestPaidBeforeMaturity:
          summary.hasInterestPaidOnOrBefore(maturityDate),
      coveredInterestMonths: coveredInterestMonths,
      now: now,
    );

    if (!assessment.isRiskAccount) return null;

    final paymentMonitoring = summary.hasCollectionHistory &&
        RiskPaymentMonitoring.applies(
          isMaturityOverdue: assessment.isMaturityOverdue,
          totalDue: totalDue,
          maturityDate: maturityDate,
          lastPaymentDate: summary.lastPaymentDate,
          asOf: now,
        );
    final staleMonitoring = !paymentMonitoring &&
        assessment.stage == GirviRiskStage.collectionMonitoring;
    final followUpMonitoring = noticeFollowUp?.isMonitoringAt(now) ?? false;
    final followUpActionDue = noticeFollowUp?.isActionDueAt(now) ?? false;

    final lastActivityAt = _latestDate(
      loan.updatedAt,
      summary.lastPaymentDate,
      loan.createdAt,
    );

    return DefaulterModel(
      loanId: loan.id,
      customerId: customer.id,
      customerName: customer.name,
      mobile: CustomerContactValue.displayMobile(customer.mobile),
      city: _clean(customer.city, fallback: 'Not specified'),
      address: _formatCustomerAddress(customer),
      customerType: customer.customerTier,
      defaulterType: DefaulterType.loan,
      referenceNo: loan.ticketNo,
      itemSummary: itemSnapshot.summary,
      pledgedItemCount: itemSnapshot.itemCount,
      itemName: itemSnapshot.itemName,
      metalType: itemSnapshot.metalType,
      purity: itemSnapshot.purity,
      pieces: itemSnapshot.pieces,
      grossWeight: itemSnapshot.grossWeight,
      lessWeight: itemSnapshot.lessWeight,
      statusLabel: followUpActionDue
          ? 'Follow-up Due'
          : followUpMonitoring
              ? 'Promise Monitoring'
              : paymentMonitoring
                  ? 'Payment Monitoring'
                  : staleMonitoring
                      ? 'High Follow-up'
                      : assessment.statusLabel,
      statusValue: status.dbValue,
      principalAmount: originalPrincipal,
      principalOutstanding: principalOutstanding,
      interestRate: loan.interestRate,
      interestAccrued: quote.grossInterest,
      interestOutstanding: interestOutstanding,
      totalDue: totalDue,
      totalReceived: summary.totalReceived,
      currentMonthReceived: summary.currentMonthReceived,
      netWeight:
          itemSnapshot.netWeight > 0 ? itemSnapshot.netWeight : loan.netWeight,
      startDate: loan.startDate,
      maturityDate: maturityDate,
      lastPaymentDate: summary.lastPaymentDate,
      lastActivityAt: lastActivityAt,
      daysOverdue: assessment.riskAgeDays,
      monthsOverdue: assessment.riskAgeDays / 30.0,
      unpaidInterestMonths: assessment.unpaidInterestMonths,
      maturityOverdueDays: assessment.maturityOverdueDays,
      isInterestOverdue: assessment.isInterestOverdue,
      isMaturityOverdue: assessment.isMaturityOverdue,
      hasInterestPaidBeforeMaturity:
          summary.hasInterestPaidOnOrBefore(maturityDate),
      isCollateralRecovery: isCollateralRecovery,
      isPaymentMonitoring: paymentMonitoring || followUpMonitoring,
      noticeFollowUpKind: noticeFollowUp?.kind,
      noticePromisedDate: noticeFollowUp?.promiseDueAt,
      isNoticeFollowUpMonitoring: followUpMonitoring,
      isNoticeFollowUpActionDue: followUpActionDue,
      isNoticeEligible: GirviNoticeEligibility.hasMaturedBalance(
        status: status,
        maturityDate: maturityDate,
        principalDue: principalOutstanding,
        interestDue: interestOutstanding,
        asOf: now,
      ),
      hasNoticeWorkflow: hasNoticeWorkflow,
      riskLevel: followUpMonitoring
          ? DefaulterRiskLevel.medium
          : paymentMonitoring
              ? DefaulterRiskLevel.medium
              : staleMonitoring
                  ? DefaulterRiskLevel.high
                  : _mapSeverity(assessment.severity),
      collectionStage: followUpActionDue
          ? 'Follow-up Action Due'
          : followUpMonitoring
              ? 'Promise Monitoring'
              : paymentMonitoring
                  ? 'Payment Monitoring'
                  : staleMonitoring
                      ? 'High Follow-up'
                      : assessment.stageLabel,
      nextActionLabel: followUpActionDue
          ? 'Review the missed promise and open Notice & Recovery'
          : followUpMonitoring
              ? 'Follow up on the promised date'
              : paymentMonitoring
                  ? 'Review the remaining balance and follow up'
                  : assessment.nextActionLabel,
    );
  }

  DefaulterRiskLevel _mapSeverity(GirviRiskSeverity severity) {
    switch (severity) {
      case GirviRiskSeverity.critical:
        return DefaulterRiskLevel.critical;
      case GirviRiskSeverity.high:
        return DefaulterRiskLevel.high;
      case GirviRiskSeverity.medium:
        return DefaulterRiskLevel.medium;
      case GirviRiskSeverity.low:
      case GirviRiskSeverity.none:
        return DefaulterRiskLevel.low;
    }
  }

  String _formatCustomerAddress(Customer customer) {
    final parts = <String>[
      customer.addressLine1 ?? '',
      customer.addressLine2 ?? '',
      customer.city ?? '',
      customer.state ?? '',
      customer.pincode ?? '',
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }

  String _clean(String? value, {required String fallback}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
  }

  DateTime _latestDate(DateTime? a, DateTime? b, DateTime fallback) {
    var latest = fallback;
    for (final value in [a, b]) {
      if (value != null && value.isAfter(latest)) latest = value;
    }
    return latest;
  }
}
