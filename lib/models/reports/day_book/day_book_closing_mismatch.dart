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

  List<ExpenseDraft> expenseDrafts(DateTime date) {
    final cash = cashVariance;
    final bank = bankVariance;
    if (cash == null || bank == null || hasOppositeMovements) return const [];
    return [
      if (cash < -0.005)
        ExpenseDraft(
          amount: _round(-cash),
          date: date,
          paymentMode: PaymentMode.cash,
        ),
      if (bank < -0.005)
        ExpenseDraft(
          amount: _round(-bank),
          date: date,
          paymentMode: PaymentMode.bank,
        ),
    ];
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}
