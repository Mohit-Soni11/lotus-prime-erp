import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/girvi/girvi_theme.dart';
import 'girvi_enums.dart';
import 'girvi_loan_model.dart';
import 'girvi_notice_action_model.dart';

enum NoticeAuctionStage {
  noticeDue,
  auctionReview,
  auctioned,
}

enum NoticeAuctionFilter {
  all,
  noticeDue,
  auctionReview,
  auctioned,
}

class NoticeAuctionCase {
  final GirviLoanWithCustomer account;
  final int noticePeriodDays;
  final DateTime now;
  final GirviNoticeAction? latestAction;

  const NoticeAuctionCase({
    required this.account,
    required this.noticePeriodDays,
    required this.now,
    this.latestAction,
  });

  GirviLoanModel get loan => account.loan;

  bool get isAuctioned => loan.girviStatus == GirviStatus.auctioned;

  bool get hasNoticeActivity => latestAction != null;

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

  int get daysUntilAuctionReview => math.max(0, noticePeriodDays - overdueDays);

  int get daysPastNoticePeriod => math.max(0, overdueDays - noticePeriodDays);

  NoticeAuctionStage get stage {
    if (isAuctioned) return NoticeAuctionStage.auctioned;
    if (overdueDays >= noticePeriodDays) {
      return NoticeAuctionStage.auctionReview;
    }
    return NoticeAuctionStage.noticeDue;
  }

  String get stageLabel {
    switch (stage) {
      case NoticeAuctionStage.noticeDue:
        return 'Notice Due';
      case NoticeAuctionStage.auctionReview:
        return 'Auction Review';
      case NoticeAuctionStage.auctioned:
        return 'Auctioned';
    }
  }

  String get stageDescription {
    switch (stage) {
      case NoticeAuctionStage.noticeDue:
        return '$daysUntilAuctionReview day${daysUntilAuctionReview == 1 ? '' : 's'} before auction review.';
      case NoticeAuctionStage.auctionReview:
        return '$daysPastNoticePeriod day${daysPastNoticePeriod == 1 ? '' : 's'} past notice period.';
      case NoticeAuctionStage.auctioned:
        return 'Account has been marked as auctioned.';
    }
  }

  String get primaryActionLabel {
    switch (stage) {
      case NoticeAuctionStage.noticeDue:
        return 'Prepare Notice';
      case NoticeAuctionStage.auctionReview:
        return 'Review Auction';
      case NoticeAuctionStage.auctioned:
        return 'Closed';
    }
  }

  Color get accentColor {
    switch (stage) {
      case NoticeAuctionStage.noticeDue:
        return GirviColors.warning;
      case NoticeAuctionStage.auctionReview:
        return GirviColors.danger;
      case NoticeAuctionStage.auctioned:
        return GirviColors.statusAuctioned;
    }
  }

  Color get accentBg {
    switch (stage) {
      case NoticeAuctionStage.noticeDue:
        return GirviColors.warningBg;
      case NoticeAuctionStage.auctionReview:
        return GirviColors.dangerBg;
      case NoticeAuctionStage.auctioned:
        return GirviColors.statusAucBg;
    }
  }
}

class NoticeAuctionStats {
  final int totalCases;
  final int noticeDueCount;
  final int auctionReviewCount;
  final int auctionedCount;
  final double principalExposure;
  final double interestExposure;
  final double totalExposure;
  final String lastUpdatedAt;

  const NoticeAuctionStats({
    required this.totalCases,
    required this.noticeDueCount,
    required this.auctionReviewCount,
    required this.auctionedCount,
    required this.principalExposure,
    required this.interestExposure,
    required this.totalExposure,
    required this.lastUpdatedAt,
  });

  factory NoticeAuctionStats.empty() {
    return const NoticeAuctionStats(
      totalCases: 0,
      noticeDueCount: 0,
      auctionReviewCount: 0,
      auctionedCount: 0,
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
