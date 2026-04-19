// ==========================================
// FILE: defaulter_model.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: Data models for defaulter list screen.
//              Defines DefaulterModel, DefaulterRiskLevel, DefaulterType,
//              and DefaulterStatsModel used across logic and UI.
// ==========================================

// ==========================================
// ENUMS
// ==========================================

enum DefaulterRiskLevel {
  critical, // > 90 days overdue
  high,     // 60–90 days
  medium,   // 30–60 days
  low,      // < 30 days (newly flagged)
}

enum DefaulterType {
  loan, // Overdue girvi / loan
  bill, // Unpaid bill balance
}

enum DefaulterSortBy {
  daysOverdue,
  amountDue,
  customerName,
}

enum DefaulterFilterBy {
  all,
  critical,
  high,
  medium,
  low,
  loanOnly,
}

// ==========================================
// DEFAULTER MODEL (Single Row)
// ==========================================

class DefaulterModel {
  final int customerId;
  final String customerName;
  final String mobile;
  final String city;
  final String customerType;    // 'Regular' | 'VIP'
  final DefaulterType defaulterType;
  final String referenceNo;     // e.g. "LN-205" or "INV-26-1012"
  final double principalAmount;
  final double interestRate;    // % per month
  final double interestAccrued; // Calculated: P × R × months
  final double totalDue;        // principal + interest
  final DateTime startDate;
  final int daysOverdue;
  final DefaulterRiskLevel riskLevel;

  const DefaulterModel({
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.city,
    required this.customerType,
    required this.defaulterType,
    required this.referenceNo,
    required this.principalAmount,
    required this.interestRate,
    required this.interestAccrued,
    required this.totalDue,
    required this.startDate,
    required this.daysOverdue,
    required this.riskLevel,
  });

  // ==========================================
  // FACTORY: Risk Level from days
  // ==========================================
  static DefaulterRiskLevel riskFromDays(int days) {
    if (days > 90) return DefaulterRiskLevel.critical;
    if (days > 60) return DefaulterRiskLevel.high;
    if (days > 30) return DefaulterRiskLevel.medium;
    return DefaulterRiskLevel.low;
  }

  // ==========================================
  // FACTORY: Simple Interest calculation
  // ==========================================
  static double calculateInterest({
    required double principal,
    required double ratePerMonth,
    required int daysElapsed,
  }) {
    final double months = daysElapsed / 30.0;
    return (principal * ratePerMonth * months) / 100.0;
  }

  // ==========================================
  // COPY WITH (for state updates)
  // ==========================================
  DefaulterModel copyWith({
    int? customerId,
    String? customerName,
    String? mobile,
    String? city,
    String? customerType,
    DefaulterType? defaulterType,
    String? referenceNo,
    double? principalAmount,
    double? interestRate,
    double? interestAccrued,
    double? totalDue,
    DateTime? startDate,
    int? daysOverdue,
    DefaulterRiskLevel? riskLevel,
  }) {
    return DefaulterModel(
      customerId:      customerId      ?? this.customerId,
      customerName:    customerName    ?? this.customerName,
      mobile:          mobile          ?? this.mobile,
      city:            city            ?? this.city,
      customerType:    customerType    ?? this.customerType,
      defaulterType:   defaulterType   ?? this.defaulterType,
      referenceNo:     referenceNo     ?? this.referenceNo,
      principalAmount: principalAmount ?? this.principalAmount,
      interestRate:    interestRate    ?? this.interestRate,
      interestAccrued: interestAccrued ?? this.interestAccrued,
      totalDue:        totalDue        ?? this.totalDue,
      startDate:       startDate       ?? this.startDate,
      daysOverdue:     daysOverdue     ?? this.daysOverdue,
      riskLevel:       riskLevel       ?? this.riskLevel,
    );
  }

  @override
  String toString() {
    return 'DefaulterModel(id: $customerId, name: $customerName, '
        'days: $daysOverdue, due: $totalDue, risk: $riskLevel)';
  }
}

// ==========================================
// STATS MODEL (Summary Panel)
// ==========================================

class DefaulterStatsModel {
  final int totalDefaulters;
  final double totalAmountDue;
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final String lastRefreshedAt;

  const DefaulterStatsModel({
    required this.totalDefaulters,
    required this.totalAmountDue,
    required this.criticalCount,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    required this.lastRefreshedAt,
  });

  factory DefaulterStatsModel.empty() {
    return const DefaulterStatsModel(
      totalDefaulters: 0,
      totalAmountDue: 0.0,
      criticalCount: 0,
      highCount: 0,
      mediumCount: 0,
      lowCount: 0,
      lastRefreshedAt: '--:--',
    );
  }

  factory DefaulterStatsModel.fromList(List<DefaulterModel> list) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return DefaulterStatsModel(
      totalDefaulters: list.length,
      totalAmountDue:  list.fold(0.0, (sum, d) => sum + d.totalDue),
      criticalCount:   list.where((d) => d.riskLevel == DefaulterRiskLevel.critical).length,
      highCount:       list.where((d) => d.riskLevel == DefaulterRiskLevel.high).length,
      mediumCount:     list.where((d) => d.riskLevel == DefaulterRiskLevel.medium).length,
      lowCount:        list.where((d) => d.riskLevel == DefaulterRiskLevel.low).length,
      lastRefreshedAt: time,
    );
  }
}

// ==========================================
// UI STATE MODEL (for logic layer)
// ==========================================

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
      allDefaulters:       [],
      displayedDefaulters: [],
      stats:               DefaulterStatsModel.empty(),
      activeFilter:        DefaulterFilterBy.all,
      activeSort:          DefaulterSortBy.daysOverdue,
      searchQuery:         '',
      isLoading:           true,
      errorMessage:        null,
    );
  }

  DefaulterScreenState copyWith({
    List<DefaulterModel>? allDefaulters,
    List<DefaulterModel>? displayedDefaulters,
    DefaulterStatsModel?  stats,
    DefaulterFilterBy?    activeFilter,
    DefaulterSortBy?      activeSort,
    String?               searchQuery,
    bool?                 isLoading,
    String?               errorMessage,
  }) {
    return DefaulterScreenState(
      allDefaulters:       allDefaulters       ?? this.allDefaulters,
      displayedDefaulters: displayedDefaulters ?? this.displayedDefaulters,
      stats:               stats               ?? this.stats,
      activeFilter:        activeFilter         ?? this.activeFilter,
      activeSort:          activeSort           ?? this.activeSort,
      searchQuery:         searchQuery          ?? this.searchQuery,
      isLoading:           isLoading            ?? this.isLoading,
      errorMessage:        errorMessage,
    );
  }
}