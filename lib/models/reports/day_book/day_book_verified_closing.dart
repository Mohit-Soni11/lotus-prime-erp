import 'day_book_balance_verification.dart';
import 'day_book_money_flow.dart';

/// Rebuilds the closing from the saved opening count and posted day activity.
/// Opening adjustments are excluded from activity because the verified count
/// already contains their effect.
class DayBookVerifiedClosing {
  const DayBookVerifiedClosing({
    required this.opening,
    required this.money,
  });

  final DayBookBalanceVerification opening;
  final DayBookMoneyFlow money;

  double get cashActivity => _activity(isCash: true);
  double get bankActivity => _activity(isCash: false);
  double get closingCash => opening.actualCash + cashActivity;
  double get closingBank => opening.actualBank + bankActivity;
  double get closingTotal => closingCash + closingBank;

  bool get matchesLedger =>
      (opening.expectedCash - money.openingCash).abs() < 0.01 &&
      (opening.expectedBank - money.openingBank).abs() < 0.01 &&
      (closingCash - money.closingCash).abs() < 0.01 &&
      (closingBank - money.closingBank).abs() < 0.01;

  double _activity({required bool isCash}) => money.entries
      .where((entry) =>
          entry.isCash == isCash &&
          entry.referenceType?.toUpperCase() != 'DAY_BOOK_BALANCE')
      .fold<double>(
          0,
          (total, entry) =>
              total + (entry.incoming ? entry.amount : -entry.amount));
}
