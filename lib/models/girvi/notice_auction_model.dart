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

  bool get hasDisposalSettlement =>
      actionHistory.any((action) => action.isDisposalSettlement);

  int get preparedNoticeCount {
    final stages = <int>{};
    for (final action in noticeActions) {
      final stage = action.noticeStage;
      if (stage != null && stage >= 1 && stage <= 3) stages.add(stage);
    }
    return stages.length;
  }

  GirviNoticeType? get nextNoticeType {
    if (hasDisposalSettlement || isAuctioned) return null;
    if (preparedNoticeCount <= 0) return GirviNoticeType.first;
    if (preparedNoticeCount == 1) return GirviNoticeType.second;
    if (preparedNoticeCount == 2) return GirviNoticeType.finalNotice;
    return null;
  }

  bool get canCloseDisposal =>
      !hasDisposalSettlement && !isAuctioned && preparedNoticeCount >= 3;

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
      nextNoticeType?.stage ?? preparedNoticeCount.clamp(0, 3).toInt();

  String get noticeProgressLabel {
    if (stage == NoticeAuctionStage.settled) return 'Closed';
    return '$currentNoticeStageNumber/3';
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

  NoticeAuctionStage get stage {
    if (isAuctioned || hasDisposalSettlement) return NoticeAuctionStage.settled;
    if (preparedNoticeCount >= 3) return NoticeAuctionStage.disposalReady;
    if (preparedNoticeCount == 2) return NoticeAuctionStage.finalNoticeDue;
    if (preparedNoticeCount == 1) return NoticeAuctionStage.secondNoticeDue;
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
        return 'Prepare the first settlement warning.';
      case NoticeAuctionStage.secondNoticeDue:
        return 'Second warning is required before final notice.';
      case NoticeAuctionStage.finalNoticeDue:
        return 'Final redemption notice is pending.';
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
}
