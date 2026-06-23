// =============================================================================
// FILE        : defaulter_model.dart
// MODULE      : Risk & Collections
// LAYER       : Presentation Model
// DESCRIPTION : Screen models for the Girvi risk and collection command center.
// =============================================================================

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
  final DefaulterRiskLevel riskLevel;

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
    required this.riskLevel,
  });

  bool get isOverdue => daysOverdue > 0;
  bool get isSettlementPending => statusValue == 'PARTIAL_RELEASE';
  bool get hasPaymentHistory => totalReceived > 0 || lastPaymentDate != null;

  String get collectionStage {
    if (isSettlementPending) return 'Settlement Pending';
    switch (riskLevel) {
      case DefaulterRiskLevel.critical:
        return 'Auction Review';
      case DefaulterRiskLevel.high:
        return 'Final Notice';
      case DefaulterRiskLevel.medium:
        return 'Payment Follow-up';
      case DefaulterRiskLevel.low:
        return 'Early Reminder';
    }
  }

  String get nextActionLabel {
    if (isSettlementPending) return 'Close settlement workflow';
    switch (riskLevel) {
      case DefaulterRiskLevel.critical:
        return 'Review for notice or auction';
      case DefaulterRiskLevel.high:
        return 'Call customer and collect interest';
      case DefaulterRiskLevel.medium:
        return 'Schedule payment follow-up';
      case DefaulterRiskLevel.low:
        return 'Send reminder';
    }
  }

  static DefaulterRiskLevel riskFromDays(int days) {
    if (days >= 90) return DefaulterRiskLevel.critical;
    if (days >= 60) return DefaulterRiskLevel.high;
    if (days >= 30) return DefaulterRiskLevel.medium;
    return DefaulterRiskLevel.low;
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
      lastRefreshedAt: '--:--',
    );
  }

  factory DefaulterStatsModel.fromList(List<DefaulterModel> list) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

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
