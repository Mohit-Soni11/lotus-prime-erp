import 'package:flutter/foundation.dart';

import 'customer_profile_enums.dart';
import 'customer_bill_models.dart';
import 'customer_activity_models.dart';

@immutable
class CustomerProfileModel {
  final int id;
  final String name;
  final String mobile;
  final String whatsapp;
  final String city;
  final String type;
  final CustomerGender gender;
  final DateTime createdAt;
  final double creditLimit;
  final double outstanding;
  final double accountCreditBalance;
  final List<CustomerBillModel> bills;
  final List<CustomerLoanModel> loans;
  final List<CustomerAdvanceOrderModel> advanceOrders;
  final List<CustomerDueModel> dues;
  final String initials;

  const CustomerProfileModel({
    required this.id,
    required this.name,
    required this.mobile,
    this.whatsapp = "",
    this.city = "",
    this.type = "Regular",
    this.gender = CustomerGender.unknown,
    required this.createdAt,
    this.creditLimit = 50000.0,
    this.outstanding = 0.0,
    this.accountCreditBalance = 0.0,
    this.bills = const [],
    this.loans = const [],
    this.advanceOrders = const [],
    this.dues = const [],
    required this.initials,
  });

  bool get isFemale => gender == CustomerGender.female;
  bool get isVip => type.toLowerCase() == 'vip';

  CreditStatus get creditStatus => CreditStatus.calculate(
        outstanding: outstanding,
        creditLimit: creditLimit,
      );

  CreditStatus get accountStatus => creditStatus;

  double get dueLimit => creditLimit;

  double get availableCredit =>
      (creditLimit + accountCreditBalance - outstanding)
          .clamp(0, double.infinity);

  double get netOutstandingAfterCredit =>
      (outstanding - accountCreditBalance).clamp(0, double.infinity);

  double get usedPercent =>
      creditLimit > 0 ? (outstanding / creditLimit * 100).clamp(0, 100) : 0;

  int get totalBills => bills.length;
  double get totalBillAmount =>
      bills.fold(0.0, (sum, bill) => sum + bill.totalAmount);
  double get totalPaidAmount =>
      bills.fold(0.0, (sum, bill) => sum + bill.paidAmount);
  int get paidBillsCount => bills.where((bill) => bill.isPaid).length;
  int get unpaidBillsCount => bills.where((bill) => !bill.isPaid).length;

  int get totalLoans => loans.length;
  int get activeLoans => loans.where((loan) => loan.isActive).length;
  int get completedLoans => loans.where((loan) => loan.isReleased).length;

  double get totalActiveLoanAmount => loans
      .where((loan) => loan.isActive)
      .fold(0.0, (sum, loan) => sum + loan.loanAmount);

  double get totalInterestAccrued => loans
      .where((loan) => loan.isActive)
      .fold(0.0, (sum, loan) => sum + loan.accruedInterest);

  double get totalLoanAmount =>
      loans.fold(0.0, (sum, loan) => sum + loan.loanAmount);

  double get totalGirviReceivable =>
      totalActiveLoanAmount + totalInterestAccrued;

  int get activeAdvanceCount =>
      advanceOrders.where((order) => order.isPending || order.isReady).length;

  double get totalAdvancePaid =>
      advanceOrders.fold(0.0, (sum, order) => sum + order.totalAdvancePaid);

  double get totalAdvanceRemaining => advanceOrders
      .where((order) => !order.isDelivered && !order.isCancelled)
      .fold(0.0, (sum, order) => sum + order.remainingBalance);

  double get totalDueAmount =>
      dues.fold(0.0, (sum, due) => sum + due.dueAmount);

  double get totalDueBillAmount =>
      dues.fold(0.0, (sum, due) => sum + due.totalAmount);

  bool get hasDues => dues.isNotEmpty && totalDueAmount > 0;

  String get formattedMemberSince {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${months[createdAt.month]} ${createdAt.year}";
  }

  CustomerProfileModel copyWith({
    double? creditLimit,
    String? name,
    String? mobile,
    String? whatsapp,
    String? city,
    String? type,
    double? accountCreditBalance,
    List<CustomerAdvanceOrderModel>? advanceOrders,
    List<CustomerDueModel>? dues,
  }) {
    return CustomerProfileModel(
      id: id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      whatsapp: whatsapp ?? this.whatsapp,
      city: city ?? this.city,
      type: type ?? this.type,
      gender: gender,
      createdAt: createdAt,
      creditLimit: creditLimit ?? this.creditLimit,
      outstanding: outstanding,
      accountCreditBalance: accountCreditBalance ?? this.accountCreditBalance,
      bills: bills,
      loans: loans,
      advanceOrders: advanceOrders ?? this.advanceOrders,
      dues: dues ?? this.dues,
      initials: initials,
    );
  }

  static String buildInitials(String name) {
    if (name.trim().isEmpty) return "NA";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
