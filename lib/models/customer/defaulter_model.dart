// =============================================================================
// FILE        : defaulter_model.dart
// MODULE      : Risk & Collections
// LAYER       : Presentation Model
// DESCRIPTION : Screen models for the Girvi risk and collection command center.
// =============================================================================

import 'package:intl/intl.dart';

enum DefaulterRiskLevel {
  critical,
  high,
  medium,
  low,
}

enum DefaulterType {
  loan,
  bill,
}

enum DefaulterSortBy {
  daysOverdue,
  amountDue,
  customerName,
  lastActivity,
}

enum DefaulterFilterBy {
  all,
  critical,
  high,
  medium,
  low,
  overdue,
  settlementPending,
}

class DefaulterModel {
  final int loanId;
  final int customerId;
  final String customerName;
  final String mobile;
  final String city;
  final String address;
  final String customerType;
  final DefaulterType defaulterType;
  final String referenceNo;
  final String itemSummary;
  final int pledgedItemCount;
  final String itemName;
  final String metalType;
  final String purity;
  final int pieces;
  final double grossWeight;
  final double lessWeight;
  final String statusLabel;
  final String statusValue;
  final double principalAmount;
  final double principalOutstanding;
  final double interestRate;
  final double interestAccrued;
  final double interestOutstanding;
  final double totalDue;
  final double totalReceived;
  final double totalItemValue;
  final double netWeight;
  final DateTime startDate;
  final DateTime? maturityDate;
  final DateTime? lastPaymentDate;
  final DateTime lastActivityAt;
  final int daysOverdue;
  final double monthsOverdue;
  final int unpaidInterestMonths;
  final int maturityOverdueDays;
  final bool isInterestOverdue;
  final bool isMaturityOverdue;
  final DefaulterRiskLevel riskLevel;
  final String collectionStage;
  final String nextActionLabel;

  const DefaulterModel({
    required this.loanId,
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.city,
    required this.address,
    required this.customerType,
    required this.defaulterType,
    required this.referenceNo,
    required this.itemSummary,
    required this.pledgedItemCount,
    required this.itemName,
    required this.metalType,
    required this.purity,
    required this.pieces,
    required this.grossWeight,
    required this.lessWeight,
    required this.statusLabel,
    required this.statusValue,
    required this.principalAmount,
    required this.principalOutstanding,
    required this.interestRate,
    required this.interestAccrued,
    required this.interestOutstanding,
    required this.totalDue,
    required this.totalReceived,
    required this.totalItemValue,
    required this.netWeight,
    required this.startDate,
    required this.maturityDate,
    required this.lastPaymentDate,
    required this.lastActivityAt,
    required this.daysOverdue,
    required this.monthsOverdue,
    required this.unpaidInterestMonths,
    required this.maturityOverdueDays,
    required this.isInterestOverdue,
    required this.isMaturityOverdue,
    required this.riskLevel,
    required this.collectionStage,
    required this.nextActionLabel,
  });

  bool get isOverdue => isInterestOverdue || isMaturityOverdue;
  bool get isSettlementPending => statusValue == 'PARTIAL_RELEASE';
  bool get hasPaymentHistory => totalReceived > 0 || lastPaymentDate != null;

  String get riskAgeLabel {
    if (unpaidInterestMonths > 0) {
      return '$unpaidInterestMonths '
          'month${unpaidInterestMonths == 1 ? '' : 's'} unpaid';
    }
    if (maturityOverdueDays > 0) return '$maturityOverdueDays days overdue';
    return 'Current';
  }

  String get riskAgeFullLabel {
    if (unpaidInterestMonths > 0) {
      return '$unpaidInterestMonths '
          'month${unpaidInterestMonths == 1 ? '' : 's'} of interest '
          '${unpaidInterestMonths == 1 ? 'is' : 'are'} unpaid';
    }
    if (maturityOverdueDays > 0) {
      return '$maturityOverdueDays '
          'day${maturityOverdueDays == 1 ? '' : 's'} past maturity';
    }
    return 'No overdue collection age';
  }

  @override
  String toString() {
    return 'DefaulterModel(loanId: $loanId, ticket: $referenceNo, '
        'customer: $customerName, due: $totalDue, risk: $riskLevel)';
  }
}

class DefaulterStatsModel {
  final int totalRiskAccounts;
  final int overdueCount;
  final int settlementPendingCount;
  final double totalAmountDue;
  final double totalPrincipalDue;
  final double totalInterestDue;
  final double totalReceived;
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final int highestRiskDays;
  final String lastRefreshedAt;

  const DefaulterStatsModel({
    required this.totalRiskAccounts,
    required this.overdueCount,
    required this.settlementPendingCount,
    required this.totalAmountDue,
    required this.totalPrincipalDue,
    required this.totalInterestDue,
    required this.totalReceived,
    required this.criticalCount,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    required this.highestRiskDays,
    required this.lastRefreshedAt,
  });

  int get totalDefaulters => totalRiskAccounts;

  factory DefaulterStatsModel.empty() {
    return const DefaulterStatsModel(
      totalRiskAccounts: 0,
      overdueCount: 0,
      settlementPendingCount: 0,
      totalAmountDue: 0,
      totalPrincipalDue: 0,
      totalInterestDue: 0,
      totalReceived: 0,
      criticalCount: 0,
      highCount: 0,
      mediumCount: 0,
      lowCount: 0,
      highestRiskDays: 0,
      lastRefreshedAt: 'Not updated yet',
    );
  }

  factory DefaulterStatsModel.fromList(List<DefaulterModel> list) {
    final now = DateTime.now();
    final time = DateFormat('hh:mm a').format(now);

    return DefaulterStatsModel(
      totalRiskAccounts: list.length,
      overdueCount: list.where((d) => d.isOverdue).length,
      settlementPendingCount: list.where((d) => d.isSettlementPending).length,
      totalAmountDue: list.fold(0.0, (sum, d) => sum + d.totalDue),
      totalPrincipalDue:
          list.fold(0.0, (sum, d) => sum + d.principalOutstanding),
      totalInterestDue: list.fold(0.0, (sum, d) => sum + d.interestOutstanding),
      totalReceived: list.fold(0.0, (sum, d) => sum + d.totalReceived),
      criticalCount:
          list.where((d) => d.riskLevel == DefaulterRiskLevel.critical).length,
      highCount:
          list.where((d) => d.riskLevel == DefaulterRiskLevel.high).length,
      mediumCount:
          list.where((d) => d.riskLevel == DefaulterRiskLevel.medium).length,
      lowCount: list.where((d) => d.riskLevel == DefaulterRiskLevel.low).length,
      highestRiskDays: list.fold<int>(
        0,
        (max, d) => d.daysOverdue > max ? d.daysOverdue : max,
      ),
      lastRefreshedAt: time,
    );
  }
}

class DefaulterScreenState {
  final List<DefaulterModel> allDefaulters;
  final List<DefaulterModel> displayedDefaulters;
  final DefaulterStatsModel stats;
  final DefaulterFilterBy activeFilter;
  final DefaulterSortBy activeSort;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const DefaulterScreenState({
    required this.allDefaulters,
    required this.displayedDefaulters,
    required this.stats,
    required this.activeFilter,
    required this.activeSort,
    required this.searchQuery,
    required this.isLoading,
    this.errorMessage,
  });

  factory DefaulterScreenState.initial() {
    return DefaulterScreenState(
      allDefaulters: const [],
      displayedDefaulters: const [],
      stats: DefaulterStatsModel.empty(),
      activeFilter: DefaulterFilterBy.all,
      activeSort: DefaulterSortBy.daysOverdue,
      searchQuery: '',
      isLoading: true,
      errorMessage: null,
    );
  }

  DefaulterScreenState copyWith({
    List<DefaulterModel>? allDefaulters,
    List<DefaulterModel>? displayedDefaulters,
    DefaulterStatsModel? stats,
    DefaulterFilterBy? activeFilter,
    DefaulterSortBy? activeSort,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DefaulterScreenState(
      allDefaulters: allDefaulters ?? this.allDefaulters,
      displayedDefaulters: displayedDefaulters ?? this.displayedDefaulters,
      stats: stats ?? this.stats,
      activeFilter: activeFilter ?? this.activeFilter,
      activeSort: activeSort ?? this.activeSort,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
