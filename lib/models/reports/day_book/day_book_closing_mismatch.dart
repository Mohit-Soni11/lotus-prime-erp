import '../../finance/cash_book/cash_book_enums.dart';
import '../../finance/expense/expense_draft.dart';

class DayBookClosingMismatch {
  const DayBookClosingMismatch({
    required this.expectedCash,
    required this.countedCash,
    required this.expectedBank,
    required this.countedBank,
  });

  final double expectedCash;
  final double? countedCash;
  final double expectedBank;
  final double? countedBank;

  double? get cashVariance =>
      countedCash == null ? null : countedCash! - expectedCash;
  double? get bankVariance =>
      countedBank == null ? null : countedBank! - expectedBank;

  bool get hasOppositeMovements {
    final cash = cashVariance;
    final bank = bankVariance;
    return cash != null &&
        bank != null &&
        ((cash < -0.005 && bank > 0.005) || (cash > 0.005 && bank < -0.005));
  }

  bool get hasCashShortage => (cashVariance ?? 0) < -0.005;
  bool get hasBankShortage => (bankVariance ?? 0) < -0.005;

  bool get hasMismatch =>
      (cashVariance?.abs() ?? 0) >= 0.005 ||
      (bankVariance?.abs() ?? 0) >= 0.005;

  List<ExpenseDraft> expenseDrafts(DateTime date) {
    if (hasOppositeMovements) return const [];
    return [
      if (hasCashShortage)
        ExpenseDraft(
          amount: _round(-cashVariance!),
          date: date,
          paymentMode: PaymentMode.cash,
        ),
      if (hasBankShortage)
        ExpenseDraft(
          amount: _round(-bankVariance!),
          date: date,
          paymentMode: PaymentMode.bank,
        ),
    ];
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}
