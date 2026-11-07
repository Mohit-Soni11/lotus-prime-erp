class DayBookBalanceVerification {
  const DayBookBalanceVerification({
    required this.date,
    required this.verifiedAt,
    required this.expectedCash,
    required this.actualCash,
    required this.cashVariance,
    required this.expectedBank,
    required this.actualBank,
    required this.bankVariance,
    this.cashCategory,
    this.cashReason,
    this.bankReason,
    this.cashAdjustmentTransactionId,
    this.verifiedBy,
  });

  final DateTime date;
  final DateTime verifiedAt;
  final double expectedCash;
  final double actualCash;
  final double cashVariance;
  final double expectedBank;
  final double actualBank;
  final double bankVariance;
  final String? cashCategory;
  final String? cashReason;
  final String? bankReason;
  final String? cashAdjustmentTransactionId;
  final String? verifiedBy;

  bool get cashAdjusted => cashAdjustmentTransactionId != null;
  bool get bankNeedsReview => bankVariance.abs() >= 0.01;
  bool get fullyMatched =>
      cashVariance.abs() < 0.01 && bankVariance.abs() < 0.01;
}
