import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/girvi/girvi_theme.dart';
import 'girvi_enums.dart';
import 'girvi_loan_model.dart';
import 'girvi_notice_action_model.dart';

enum NoticeAuctionStage {
  firstNoticeDue,
  secondNoticeDue,
  finalNoticeDue,
  disposalReady,
  settled,
}

enum NoticeAuctionFilter {
  all,
  firstNotice,
  secondNotice,
  finalNotice,
  disposalReady,
  settled,
}

class NoticeAuctionCase {
  final GirviLoanWithCustomer account;
  final int noticePeriodDays;
  final DateTime now;
  final GirviNoticeAction? latestAction;
  final List<GirviNoticeAction> actionHistory;

  const NoticeAuctionCase({
    required this.account,
    required this.noticePeriodDays,
    required this.now,
    this.latestAction,
    this.actionHistory = const [],
  });

  GirviLoanModel get loan => account.loan;

  bool get isAuctioned => loan.girviStatus == GirviStatus.auctioned;

  bool get hasNoticeActivity => latestAction != null;

  List<GirviNoticeAction> get noticeActions =>
      actionHistory.where((action) => action.isNotice).toList();

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

  int get preparedNoticeCount => preparedNoticeStages.length;

  GirviNoticeType? get nextNoticeType {
    if (hasDisposalSettlement || isAuctioned) return null;
    if (highestPreparedNoticeStage <= 0) return GirviNoticeType.first;
    if (highestPreparedNoticeStage == 1) return GirviNoticeType.second;
    if (highestPreparedNoticeStage == 2) return GirviNoticeType.finalNotice;
    return null;
  }

  bool get canCloseDisposal =>
      !hasDisposalSettlement &&
      !isAuctioned &&
      stage == NoticeAuctionStage.disposalReady;

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
    if (stage == NoticeAuctionStage.settled) return 'Closed';
    return '$currentNoticeStageNumber/3';
  }

  int? _noticeStageFor(GirviNoticeAction action) {
    final stage = action.noticeStage;
    if (stage != null) return stage;
    switch (action.actionType) {
      case GirviNoticeActionTypes.firstNoticePrepared:
      case GirviNoticeActionTypes.noticeDraftCopied:
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

  int get daysUntilAuctionReview => math.max(0, noticePeriodDays - overdueDays);

  int get daysPastNoticePeriod => math.max(0, overdueDays - noticePeriodDays);

  bool get isFinalNoticeCycleComplete {
    final finalAction = finalNoticeAction;
    if (finalAction == null) return false;
    final readyDate = DateUtils.dateOnly(
      finalAction.actionAt.add(Duration(days: noticePeriodDays)),
    );
    return !DateUtils.dateOnly(now).isBefore(readyDate);
  }

  NoticeAuctionStage get stage {
    if (isAuctioned || hasDisposalSettlement) return NoticeAuctionStage.settled;
    if (highestPreparedNoticeStage >= 3) {
      return isFinalNoticeCycleComplete
          ? NoticeAuctionStage.disposalReady
          : NoticeAuctionStage.finalNoticeDue;
    }
    if (highestPreparedNoticeStage == 2) {
      return NoticeAuctionStage.secondNoticeDue;
    }
    if (highestPreparedNoticeStage == 1) {
      return NoticeAuctionStage.firstNoticeDue;
    }
    return NoticeAuctionStage.firstNoticeDue;
  }

  String get stageLabel {
    switch (stage) {
      case NoticeAuctionStage.firstNoticeDue:
        return 'First Notice';
      case NoticeAuctionStage.secondNoticeDue:
        return 'Second Notice';
      case NoticeAuctionStage.finalNoticeDue:
        return 'Final Notice';
      case NoticeAuctionStage.disposalReady:
        return 'Disposal Ready';
      case NoticeAuctionStage.settled:
        return 'Closed';
    }
  }

  String get stageDescription {
    switch (stage) {
      case NoticeAuctionStage.firstNoticeDue:
        return highestPreparedNoticeStage == 0
            ? 'Prepare the first settlement warning.'
            : 'First notice is prepared. Continue with the second notice when required.';
      case NoticeAuctionStage.secondNoticeDue:
        return 'Second notice is prepared. Continue with the final notice when required.';
      case NoticeAuctionStage.finalNoticeDue:
        return 'Final notice is prepared. Wait for the notice cycle before disposal review.';
      case NoticeAuctionStage.disposalReady:
        return 'All three notices are prepared. Review disposal settlement.';
      case NoticeAuctionStage.settled:
        return 'Notice and disposal workflow is closed.';
    }
  }

  String get primaryActionLabel {
    switch (stage) {
      case NoticeAuctionStage.firstNoticeDue:
        return 'Prepare First Notice';
      case NoticeAuctionStage.secondNoticeDue:
        return 'Prepare Second Notice';
      case NoticeAuctionStage.finalNoticeDue:
        return 'Prepare Final Notice';
      case NoticeAuctionStage.disposalReady:
        return 'Close Disposal';
      case NoticeAuctionStage.settled:
        return 'Closed';
    }
  }

  Color get accentColor {
    switch (stage) {
      case NoticeAuctionStage.firstNoticeDue:
        return GirviColors.warning;
      case NoticeAuctionStage.secondNoticeDue:
        return GirviColors.danger;
      case NoticeAuctionStage.finalNoticeDue:
        return GirviColors.danger;
      case NoticeAuctionStage.disposalReady:
        return GirviColors.statusAuctioned;
      case NoticeAuctionStage.settled:
        return GirviColors.success;
    }
  }

  Color get accentBg {
    switch (stage) {
      case NoticeAuctionStage.firstNoticeDue:
        return GirviColors.warningBg;
      case NoticeAuctionStage.secondNoticeDue:
        return GirviColors.dangerBg;
      case NoticeAuctionStage.finalNoticeDue:
        return GirviColors.dangerBg;
      case NoticeAuctionStage.disposalReady:
        return GirviColors.statusAucBg;
      case NoticeAuctionStage.settled:
        return GirviColors.successBg;
    }
  }
}

class NoticeAuctionStats {
  final int totalCases;
  final int noticeDueCount;
  final int finalNoticeCount;
  final int disposalReadyCount;
  final int settledCount;
  final double principalExposure;
  final double interestExposure;
  final double totalExposure;
  final String lastUpdatedAt;

  const NoticeAuctionStats({
    required this.totalCases,
    required this.noticeDueCount,
    required this.finalNoticeCount,
    required this.disposalReadyCount,
    required this.settledCount,
    required this.principalExposure,
    required this.interestExposure,
    required this.totalExposure,
    required this.lastUpdatedAt,
  });

  factory NoticeAuctionStats.empty() {
    return const NoticeAuctionStats(
      totalCases: 0,
      noticeDueCount: 0,
      finalNoticeCount: 0,
      disposalReadyCount: 0,
      settledCount: 0,
      principalExposure: 0,
      interestExposure: 0,
      totalExposure: 0,
      lastUpdatedAt: 'Not updated yet',
    );
  }
}

class NoticeAuctionState {
  final List<NoticeAuctionCase> allCases;
  final List<NoticeAuctionCase> visibleCases;
  final NoticeAuctionStats stats;
  final NoticeAuctionFilter filter;
  final String searchQuery;
  final int noticePeriodDays;
  final bool isLoading;
  final String? errorMessage;
  final String? inlineMessage;

  const NoticeAuctionState({
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

  factory NoticeAuctionState.initial() {
    return NoticeAuctionState(
      allCases: const [],
      visibleCases: const [],
      stats: NoticeAuctionStats.empty(),
      filter: NoticeAuctionFilter.all,
      searchQuery: '',
      noticePeriodDays: 30,
      isLoading: true,
    );
  }

  NoticeAuctionState copyWith({
    List<NoticeAuctionCase>? allCases,
    List<NoticeAuctionCase>? visibleCases,
    NoticeAuctionStats? stats,
    NoticeAuctionFilter? filter,
    String? searchQuery,
    int? noticePeriodDays,
    bool? isLoading,
    String? errorMessage,
    String? inlineMessage,
    bool clearError = false,
    bool clearInlineMessage = false,
  }) {
    return NoticeAuctionState(
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

  int countForFilter(NoticeAuctionFilter filter) {
    return allCases.where((item) => _matchesFilter(item, filter)).length;
  }

  bool _matchesFilter(NoticeAuctionCase item, NoticeAuctionFilter filter) {
    switch (filter) {
      case NoticeAuctionFilter.all:
        return item.stage != NoticeAuctionStage.settled;
      case NoticeAuctionFilter.firstNotice:
        return item.stage == NoticeAuctionStage.firstNoticeDue;
      case NoticeAuctionFilter.secondNotice:
        return item.stage == NoticeAuctionStage.secondNoticeDue;
      case NoticeAuctionFilter.finalNotice:
        return item.stage == NoticeAuctionStage.finalNoticeDue;
      case NoticeAuctionFilter.disposalReady:
        return item.stage == NoticeAuctionStage.disposalReady;
      case NoticeAuctionFilter.settled:
        return item.stage == NoticeAuctionStage.settled;
    }
  }
}
