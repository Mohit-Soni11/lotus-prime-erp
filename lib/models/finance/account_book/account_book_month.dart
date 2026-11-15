import '../../reports/day_book/day_book_money_flow.dart';

enum AccountBookActivityType { money, document, stock, girvi, balance }

class AccountBookActivity {
  const AccountBookActivity({
    required this.date,
    required this.type,
    required this.title,
    required this.reference,
    this.detail,
    this.amount,
    this.incoming,
    this.isCash,
    this.isInternalTransfer = false,
  });

  final DateTime date;
  final AccountBookActivityType type;
  final String title;
  final String reference;
  final String? detail;
  final double? amount;
  final bool? incoming;
  final bool? isCash;
  final bool isInternalTransfer;
}

class AccountBookDay {
  const AccountBookDay({
    required this.date,
    required this.activities,
    required this.openingCash,
    required this.openingBank,
    required this.cashIn,
    required this.cashOut,
    required this.bankIn,
    required this.bankOut,
    this.bankOpeningAdditions = 0,
  });

  final DateTime date;
  final List<AccountBookActivity> activities;
  final double openingCash;
  final double openingBank;
  final double cashIn;
  final double cashOut;
  final double bankIn;
  final double bankOut;
  final double bankOpeningAdditions;

  double get closingCash => openingCash + cashIn - cashOut;
  double get closingBank =>
      openingBank + bankOpeningAdditions + bankIn - bankOut;
  double get closingTotal => closingCash + closingBank;
}

class AccountBookMonth {
  const AccountBookMonth({
    required this.month,
    required this.money,
    required this.days,
  });

  final DateTime month;
  final DayBookMoneyFlow money;
  final List<AccountBookDay> days;

  int get activityCount =>
      days.fold(0, (sum, day) => sum + day.activities.length);
  int count(AccountBookActivityType type) => days.fold(
      0,
      (sum, day) =>
          sum +
          day.activities.where((activity) => activity.type == type).length);
}
