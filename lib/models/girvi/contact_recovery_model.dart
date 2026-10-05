import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/girvi/girvi_theme.dart';
import 'girvi_enums.dart';
import 'girvi_loan_model.dart';
import 'girvi_interest_period_snapshot.dart';
import 'girvi_notice_action_model.dart';

enum ContactRecoveryStage {
  firstNoticeDue,
  secondNoticeDue,
  finalNoticeDue,
  disposalReady,
  recoveryInProgress,
  settled,
}

enum ContactRecoveryFilter {
  all,
  firstNotice,
  secondNotice,
  finalNotice,
  disposalReady,
  recoveryInProgress,
  settled,
}

enum RecoverySettlementPaymentMethod {
  cash('CASH', 'Cash', false),
  upi('UPI', 'UPI', true),
  neft('NEFT', 'NEFT', true),
  rtgs('RTGS', 'RTGS', true),
  imps('IMPS', 'IMPS', true),
  cheque('CHEQUE', 'Cheque', true);

  const RecoverySettlementPaymentMethod(
    this.dbValue,
    this.label,
    this.requiresBankAccount,
  );

  final String dbValue;
  final String label;
  final bool requiresBankAccount;
}

class RecoveryBankAccountOption {
  const RecoveryBankAccountOption({
    required this.id,
    required this.label,
  });

  final int id;
  final String label;
}

class ContactRecoveryCase {
  final GirviLoanWithCustomer account;
  final int noticePeriodDays;
  final DateTime now;
  final GirviNoticeAction? latestAction;
  final List<GirviNoticeAction> actionHistory;
  final List<GirviPaymentModel> paymentHistory;
  final List<GirviInterestPeriodSnapshot> interestPeriodSnapshots;
  final List<String> itemPhotoPaths;

  const ContactRecoveryCase({
    required this.account,
    required this.noticePeriodDays,
    required this.now,
    this.latestAction,
    this.actionHistory = const [],
    this.paymentHistory = const [],
    this.interestPeriodSnapshots = const [],
    this.itemPhotoPaths = const [],
  });

  GirviLoanModel get loan => account.loan;

  bool get isRecoveryClosed => loan.girviStatus == GirviStatus.auctioned;

  bool get hasNoticeActivity => latestAction != null;

  bool get hasItemPhotos =>
      itemPhotoPaths.any((path) => path.trim().isNotEmpty);

  List<GirviNoticeAction> get noticeActions =>
      actionHistory.where((action) => action.isNoticePreparation).toList();

  List<GirviNoticeAction> get noticeDeliveryProofActions =>
      actionHistory.where((action) => action.isNoticeDeliveryProof).toList();

  List<GirviNoticeAction> get preparedNoticeActions {
    final stageMap = <int, GirviNoticeAction>{};
    for (final action in noticeActions) {
      final stage = _noticeStageFor(action);
      if (stage != null && stage >= 1 && stage <= 3) {
        stageMap.putIfAbsent(stage, () => action);
      }
    }
    final stages = stageMap.keys.toList()..sort();
    return [for (final stage in stages) stageMap[stage]!];
  }

  List<GirviNoticeAction> deliveryProofsForStage(int stage) {
    return noticeDeliveryProofActions
        .where((action) => _noticeStageFor(action) == stage)
        .toList();
  }

  bool get hasVerifiedInterestTimeline => interestPeriodSnapshots.isNotEmpty;

  double get verifiedGrossInterest => interestPeriodSnapshots.fold<double>(
        0,
        (sum, snapshot) => sum + snapshot.periodInterest,
      );

  double get verifiedInterestDue {
    final due = verifiedGrossInterest -
        account.interestPaidTotal -
        account.interestDiscountTotal;
    return due <= 0 ? 0 : due;
  }

  double get verifiedTotalPayable => account.principalDue + verifiedInterestDue;

  int get verifiedChargeableInterestMonths => interestPeriodSnapshots.fold<int>(
        0,
        (sum, snapshot) => sum + snapshot.chargeableMonths,
      );

  GirviNoticeAction? latestDeliveryProofForStage(int stage) {
    final proofs = deliveryProofsForStage(stage);
    return proofs.isEmpty ? null : proofs.first;
  }

  Set<int> get preparedNoticeStages {
    return {
      for (final action in noticeActions)
        if (_noticeStageFor(action) case final stage?)
          if (stage >= 1 && stage <= 3) stage,
    };
  }

  int get highestPreparedNoticeStage {
    final stages = preparedNoticeStages;
    if (stages.contains(3)) return 3;
    if (stages.contains(2)) return 2;
    if (stages.contains(1)) return 1;
    return 0;
  }

  GirviNoticeAction? get finalNoticeAction {
    for (final action in preparedNoticeActions) {
      if (_noticeStageFor(action) == 3) return action;
    }
    return null;
  }

  bool get hasDisposalSettlement =>
      actionHistory.any((action) => action.isDisposalSettlement);

  bool get hasCollateralRecoveryInitiated =>
      actionHistory.any((action) => action.isCollateralRecoveryInitiated);

  int get preparedNoticeCount => preparedNoticeStages.length;

  GirviNoticeType? get nextNoticeType {
    if (hasDisposalSettlement ||
        hasCollateralRecoveryInitiated ||
        isRecoveryClosed) {
      return null;
    }
    if (highestPreparedNoticeStage <= 0) return GirviNoticeType.first;
    if (highestPreparedNoticeStage == 1) return GirviNoticeType.second;
    if (highestPreparedNoticeStage == 2) return GirviNoticeType.finalNotice;
    return null;
  }

  GirviNoticeAction? get latestPreparedNoticeAction {
    final notices = preparedNoticeActions;
    return notices.isEmpty ? null : notices.last;
  }

  DateTime? get nextNoticeAvailableAt {
    final latest = latestPreparedNoticeAction;
    if (latest == null || highestPreparedNoticeStage >= 3) return null;
    return latest.noticeDeadlineAt ??
        latest.actionAt.add(Duration(days: noticePeriodDays));
  }

  bool get canPrepareNextNotice {
    final availableAt = nextNoticeAvailableAt;
    return nextNoticeType != null &&
        (availableAt == null ||
            !DateUtils.dateOnly(now).isBefore(DateUtils.dateOnly(availableAt)));
  }

  int get daysUntilNextNotice {
    final availableAt = nextNoticeAvailableAt;
    if (availableAt == null) return 0;
    return math.max(
      0,
      DateUtils.dateOnly(availableAt)
          .difference(DateUtils.dateOnly(now))
          .inDays,
    );
  }

  bool get canInitiateCollateralRecovery =>
      !hasDisposalSettlement &&
      !hasCollateralRecoveryInitiated &&
      !isRecoveryClosed &&
      stage == ContactRecoveryStage.disposalReady;

  bool get canCloseDisposal =>
      !hasDisposalSettlement &&
      hasCollateralRecoveryInitiated &&
      !isRecoveryClosed &&
      stage == ContactRecoveryStage.recoveryInProgress;

  int get overdueDays {
    final maturity = loan.maturityDate;
    if (maturity == null) return 0;
    return math.max(
        0,
        DateUtils.dateOnly(now)
            .difference(
              DateUtils.dateOnly(maturity),
            )
            .inDays);
  }

  GirviElapsedPeriod get loanAgePeriod =>
      GirviLoanModel.elapsedPeriodBetween(loan.startDate, now);

  String get loanAgeLabel => loanAgePeriod.displayLabel;

  String get loanAgeMonthsDaysLabel => _monthsDaysLabel(loanAgePeriod);

  int get chargeableInterestMonths =>
      GirviLoanModel.chargeableMonthsBetween(loan.startDate, now);

  String get chargeableInterestMonthsLabel {
    final months = chargeableInterestMonths;
    return '$months chargeable month${months == 1 ? '' : 's'}';
  }

  List<GirviInterestBreakdownLine> get compoundInterestBreakdown {
    if (GirviInterestCalculationType.isSimple(account.interestType)) {
      return const [];
    }
    return [
      for (final snapshot in interestPeriodSnapshots) snapshot.breakdownLine,
    ];
  }

  double get recordedMonthlyInterestAmount => interestPeriodSnapshots.isEmpty
      ? 0
      : interestPeriodSnapshots.first.interestPerMonth;

  double get recordedInterestClosingAmount => interestPeriodSnapshots.isEmpty
      ? 0
      : interestPeriodSnapshots.last.closingAmount;

  GirviElapsedPeriod get overdueAgePeriod {
    final maturity = loan.maturityDate;
    if (maturity == null) {
      return const GirviElapsedPeriod(years: 0, months: 0, days: 0);
    }
    return GirviLoanModel.elapsedPeriodBetween(maturity, now);
  }

  String get overdueAgeLabel => overdueAgePeriod.displayLabel;

  String get overdueAgeMonthsDaysLabel => _monthsDaysLabel(overdueAgePeriod);

  int get currentNoticeStageNumber =>
      nextNoticeType?.stage ?? highestPreparedNoticeStage.clamp(0, 3).toInt();

  String get noticesSentLabel => '$preparedNoticeCount/3 Sent';

  String get noticeProgressLabel {
    if (stage == ContactRecoveryStage.settled) return 'Closed';
    if (stage == ContactRecoveryStage.recoveryInProgress) return 'Recovery';
    return '$currentNoticeStageNumber/3';
  }

  int? _noticeStageFor(GirviNoticeAction action) {
    final stage = action.noticeStage;
    if (stage != null) return stage;
    switch (action.actionType) {
      case GirviNoticeActionTypes.firstNoticePrepared:
        return 1;
      case GirviNoticeActionTypes.secondNoticePrepared:
        return 2;
      case GirviNoticeActionTypes.finalNoticePrepared:
        return 3;
      default:
        return null;
    }
  }

  String _monthsDaysLabel(GirviElapsedPeriod period) {
    final months = (period.years * 12) + period.months;
    final parts = <String>[
      if (months > 0) '$months month${months == 1 ? '' : 's'}',
      if (period.days > 0 || months == 0)
        '${period.days} day${period.days == 1 ? '' : 's'}',
    ];
    return parts.join(' ');
  }

  int get daysUntilRecoveryReview =>
      math.max(0, noticePeriodDays - overdueDays);

  int get daysPastNoticePeriod => math.max(0, overdueDays - noticePeriodDays);

  bool get isFinalNoticeCycleComplete {
    final finalAction = finalNoticeAction;
    if (finalAction == null) return false;
    final readyDate = DateUtils.dateOnly(finalAction.noticeDeadlineAt ??
        finalAction.actionAt.add(Duration(days: noticePeriodDays)));
    return !DateUtils.dateOnly(now).isBefore(readyDate);
  }

  ContactRecoveryStage get stage {
    if (isRecoveryClosed || hasDisposalSettlement) {
      return ContactRecoveryStage.settled;
    }
    if (hasCollateralRecoveryInitiated) {
      return ContactRecoveryStage.recoveryInProgress;
    }
    if (highestPreparedNoticeStage >= 3) {
      return isFinalNoticeCycleComplete
          ? ContactRecoveryStage.disposalReady
          : ContactRecoveryStage.finalNoticeDue;
    }
    if (highestPreparedNoticeStage == 2) {
      return ContactRecoveryStage.secondNoticeDue;
    }
    if (highestPreparedNoticeStage == 1) {
      return ContactRecoveryStage.firstNoticeDue;
    }
    return ContactRecoveryStage.firstNoticeDue;
  }

  String get stageLabel {
    switch (stage) {
      case ContactRecoveryStage.firstNoticeDue:
        return 'First Notice';
      case ContactRecoveryStage.secondNoticeDue:
        return 'Second Notice';
      case ContactRecoveryStage.finalNoticeDue:
        return 'Final Notice';
      case ContactRecoveryStage.disposalReady:
        return 'Recovery Approval';
      case ContactRecoveryStage.recoveryInProgress:
        return 'Collateral Recovery';
      case ContactRecoveryStage.settled:
        return 'Closed';
    }
  }

  String get stageDescription {
    switch (stage) {
      case ContactRecoveryStage.firstNoticeDue:
        return highestPreparedNoticeStage == 0
            ? 'Prepare the first customer notice.'
            : canPrepareNextNotice
                ? 'First notice is complete. The second notice can now be prepared.'
                : 'First notice is complete. Second notice is available in $daysUntilNextNotice day${daysUntilNextNotice == 1 ? '' : 's'}.';
      case ContactRecoveryStage.secondNoticeDue:
        return canPrepareNextNotice
            ? 'Second notice is complete. The final notice can now be prepared.'
            : 'Second notice is complete. Final notice is available in $daysUntilNextNotice day${daysUntilNextNotice == 1 ? '' : 's'}.';
      case ContactRecoveryStage.finalNoticeDue:
        return 'Final notice is prepared. Wait for the review cycle before recovery approval.';
      case ContactRecoveryStage.disposalReady:
        return 'All three notices are complete. Send the collateral to recovery only after final approval.';
      case ContactRecoveryStage.recoveryInProgress:
        return 'Collateral is in recovery. Record the final recovered value to close the case.';
      case ContactRecoveryStage.settled:
        return 'Notice and recovery workflow is closed.';
    }
  }

  String get primaryActionLabel {
    switch (stage) {
      case ContactRecoveryStage.firstNoticeDue:
        return highestPreparedNoticeStage == 0
            ? 'Prepare First Notice'
            : canPrepareNextNotice
                ? 'Prepare Second Notice'
                : 'Second Notice Pending';
      case ContactRecoveryStage.secondNoticeDue:
        return canPrepareNextNotice
            ? 'Prepare Final Notice'
            : 'Final Notice Pending';
      case ContactRecoveryStage.finalNoticeDue:
        return 'Prepare Final Notice';
      case ContactRecoveryStage.disposalReady:
        return 'Send to Recovery';
      case ContactRecoveryStage.recoveryInProgress:
        return 'Recovery Active';
      case ContactRecoveryStage.settled:
        return 'Closed';
    }
  }

  Color get accentColor {
    switch (stage) {
      case ContactRecoveryStage.firstNoticeDue:
        return GirviColors.warning;
      case ContactRecoveryStage.secondNoticeDue:
        return GirviColors.danger;
      case ContactRecoveryStage.finalNoticeDue:
        return GirviColors.danger;
      case ContactRecoveryStage.disposalReady:
        return GirviColors.info;
      case ContactRecoveryStage.recoveryInProgress:
        return GirviColors.brandGold;
      case ContactRecoveryStage.settled:
        return GirviColors.success;
    }
  }

  Color get accentBg {
    switch (stage) {
      case ContactRecoveryStage.firstNoticeDue:
        return GirviColors.warningBg;
      case ContactRecoveryStage.secondNoticeDue:
        return GirviColors.dangerBg;
      case ContactRecoveryStage.finalNoticeDue:
        return GirviColors.dangerBg;
      case ContactRecoveryStage.disposalReady:
        return GirviColors.infoBg;
      case ContactRecoveryStage.recoveryInProgress:
        return GirviColors.brandGoldLight;
      case ContactRecoveryStage.settled:
        return GirviColors.successBg;
    }
  }
}

class ContactRecoveryStats {
  final int totalCases;
  final int noticeDueCount;
  final int finalNoticeCount;
  final int disposalReadyCount;
  final int recoveryInProgressCount;
  final int settledCount;
  final double principalExposure;
  final double interestExposure;
  final double totalExposure;
  final String lastUpdatedAt;

  const ContactRecoveryStats({
    required this.totalCases,
    required this.noticeDueCount,
    required this.finalNoticeCount,
    required this.disposalReadyCount,
    required this.recoveryInProgressCount,
    required this.settledCount,
    required this.principalExposure,
    required this.interestExposure,
    required this.totalExposure,
    required this.lastUpdatedAt,
  });

  factory ContactRecoveryStats.empty() {
    return const ContactRecoveryStats(
      totalCases: 0,
      noticeDueCount: 0,
      finalNoticeCount: 0,
      disposalReadyCount: 0,
      recoveryInProgressCount: 0,
      settledCount: 0,
      principalExposure: 0,
      interestExposure: 0,
      totalExposure: 0,
      lastUpdatedAt: 'Not updated yet',
    );
  }
}

class ContactRecoveryState {
  final List<ContactRecoveryCase> allCases;
  final List<ContactRecoveryCase> visibleCases;
  final ContactRecoveryStats stats;
  final ContactRecoveryFilter filter;
  final String searchQuery;
  final int noticePeriodDays;
  final bool isLoading;
  final String? errorMessage;
  final String? inlineMessage;

  const ContactRecoveryState({
    required this.allCases,
    required this.visibleCases,
    required this.stats,
    required this.filter,
    required this.searchQuery,
    required this.noticePeriodDays,
    required this.isLoading,
    this.errorMessage,
    this.inlineMessage,
  });

  factory ContactRecoveryState.initial() {
    return ContactRecoveryState(
      allCases: const [],
      visibleCases: const [],
      stats: ContactRecoveryStats.empty(),
      filter: ContactRecoveryFilter.all,
      searchQuery: '',
      noticePeriodDays: 7,
      isLoading: true,
    );
  }

  ContactRecoveryState copyWith({
    List<ContactRecoveryCase>? allCases,
    List<ContactRecoveryCase>? visibleCases,
    ContactRecoveryStats? stats,
    ContactRecoveryFilter? filter,
    String? searchQuery,
    int? noticePeriodDays,
    bool? isLoading,
    String? errorMessage,
    String? inlineMessage,
    bool clearError = false,
    bool clearInlineMessage = false,
  }) {
    return ContactRecoveryState(
      allCases: allCases ?? this.allCases,
      visibleCases: visibleCases ?? this.visibleCases,
      stats: stats ?? this.stats,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      noticePeriodDays: noticePeriodDays ?? this.noticePeriodDays,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      inlineMessage:
          clearInlineMessage ? null : inlineMessage ?? this.inlineMessage,
    );
  }

  int countForFilter(ContactRecoveryFilter filter) {
    return allCases.where((item) => _matchesFilter(item, filter)).length;
  }

  bool _matchesFilter(ContactRecoveryCase item, ContactRecoveryFilter filter) {
    switch (filter) {
      case ContactRecoveryFilter.all:
        return item.stage != ContactRecoveryStage.settled;
      case ContactRecoveryFilter.firstNotice:
        return item.stage == ContactRecoveryStage.firstNoticeDue;
      case ContactRecoveryFilter.secondNotice:
        return item.stage == ContactRecoveryStage.secondNoticeDue;
      case ContactRecoveryFilter.finalNotice:
        return item.stage == ContactRecoveryStage.finalNoticeDue;
      case ContactRecoveryFilter.disposalReady:
        return item.stage == ContactRecoveryStage.disposalReady;
      case ContactRecoveryFilter.recoveryInProgress:
        return item.stage == ContactRecoveryStage.recoveryInProgress;
      case ContactRecoveryFilter.settled:
        return item.stage == ContactRecoveryStage.settled;
    }
  }
}
