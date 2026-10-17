part of 'contact_recovery_model.dart';

class ContactRecoveryStats {
  final int totalCases;
  final int noticeDueCount;
  final int noticePendingCount;
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
    required this.noticePendingCount,
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
      noticePendingCount: 0,
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
      case ContactRecoveryFilter.noticeRequired:
        return item.stage == ContactRecoveryStage.noticeRequired;
      case ContactRecoveryFilter.noticePending:
        return item.stage == ContactRecoveryStage.noticePending;
      case ContactRecoveryFilter.disposalReady:
        return item.stage == ContactRecoveryStage.disposalReady;
      case ContactRecoveryFilter.recoveryInProgress:
        return item.stage == ContactRecoveryStage.recoveryInProgress;
      case ContactRecoveryFilter.settled:
        return item.stage == ContactRecoveryStage.settled;
    }
  }
}
