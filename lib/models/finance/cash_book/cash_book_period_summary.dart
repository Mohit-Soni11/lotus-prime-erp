class CashBookPeriodSummary {
  const CashBookPeriodSummary({
    required this.year,
    required this.month,
    required this.openingBalance,
    required this.cashIn,
    required this.cashOut,
    required this.closingBalance,
    required this.transactionCount,
  });

  final int year;
  final int? month;
  final double openingBalance;
  final double cashIn;
  final double cashOut;
  final double closingBalance;
  final int transactionCount;

  double get netMovement => cashIn - cashOut;
}

class CashBookHistorySnapshot {
  const CashBookHistorySnapshot({
    required this.months,
    required this.years,
  });

  const CashBookHistorySnapshot.empty()
      : months = const [],
        years = const [];

  final List<CashBookPeriodSummary> months;
  final List<CashBookPeriodSummary> years;
}
