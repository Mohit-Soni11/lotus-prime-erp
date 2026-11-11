import '../cash_book/cash_book_enums.dart';

/// Navigation-only prefill. Saving remains an explicit Expense Entry action.
class ExpenseDraft {
  const ExpenseDraft({
    required this.amount,
    required this.date,
    required this.paymentMode,
  });

  final double amount;
  final DateTime date;
  final PaymentMode paymentMode;
}
