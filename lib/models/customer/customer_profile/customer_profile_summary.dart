import 'package:flutter/foundation.dart';

import 'customer_profile_enums.dart';
import 'customer_bill_models.dart';
import 'customer_activity_models.dart';
import '../customer_enums/customer_list_enums.dart';
import '../../../features/customer/domain/services/customer_address_formatter.dart';

@immutable
class CustomerProfileModel {
  final int id;
  final String name;
  final String mobile;
  final String whatsapp;
  final String city;
  final String addressLine1;
  final String addressLine2;
  final String state;
  final String pincode;
  final String country;
  final String type;
  final CustomerGender gender;
  final DateTime createdAt;
  final double outstanding;
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
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.state = '',
    this.pincode = '',
    this.country = 'India',
    this.type = "Regular",
    this.gender = CustomerGender.unknown,
    required this.createdAt,
    this.outstanding = 0.0,
    this.bills = const [],
    this.loans = const [],
    this.advanceOrders = const [],
    this.dues = const [],
    required this.initials,
  });

  bool get isFemale => gender == CustomerGender.female;
  CustomerType get customerTier => CustomerType.fromString(type);
  bool get isVip => customerTier == CustomerType.elite;

  String? get formattedAddress => CustomerAddressFormatter.format(
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        pincode: pincode,
        country: country,
      );

  int get totalBills => bills.length;
  double get totalBillAmount =>
      bills.fold(0.0, (sum, bill) => sum + bill.totalAmount);
  double get totalPaidAmount =>
      bills.fold(0.0, (sum, bill) => sum + bill.paidAmount);
  int get dueInvoiceCount => dues.length;

  int get totalLoans => loans.length;
  int get activeLoans => loans.where((loan) => loan.isActive).length;
  int get completedLoans => loans.where((loan) => loan.isReleased).length;

  double get totalActiveLoanAmount => loans
      .where((loan) => loan.isActive)
      .fold(0.0, (sum, loan) => sum + loan.principalOutstanding);

  double get totalInterestAccrued => loans
      .where((loan) => loan.isActive)
      .fold(0.0, (sum, loan) => sum + loan.accruedInterest);

  double get totalLoanAmount =>
      loans.fold(0.0, (sum, loan) => sum + loan.originalPrincipal);

  double get totalGirviReceivable =>
      totalActiveLoanAmount + totalInterestAccrued;

  int get activeAdvanceCount =>
      advanceOrders.where((order) => order.isPending || order.isReady).length;

  double get totalAdvancePaid => advanceOrders
      .where((order) => order.isPending || order.isReady)
      .fold(0.0, (sum, order) => sum + order.totalAdvancePaid);

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
    String? name,
    String? mobile,
    String? whatsapp,
    String? city,
    String? type,
    List<CustomerAdvanceOrderModel>? advanceOrders,
    List<CustomerDueModel>? dues,
  }) {
    return CustomerProfileModel(
      id: id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      whatsapp: whatsapp ?? this.whatsapp,
      city: city ?? this.city,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      state: state,
      pincode: pincode,
      country: country,
      type: type ?? this.type,
      gender: gender,
      createdAt: createdAt,
      outstanding: outstanding,
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
