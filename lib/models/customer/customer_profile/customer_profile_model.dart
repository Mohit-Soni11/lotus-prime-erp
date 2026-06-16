// -----------------------------------------------------------------------------
// FILE: customer_profile_model.dart
// MODULE: Customer -> Customer Profile
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../girvi/girvi_loan_model.dart';

enum CustomerGender { male, female }

enum CreditStatus {
  clear,
  due,
  defaulter;

  String get label {
    switch (this) {
      case CreditStatus.clear:
        return "DUE CLEAR";
      case CreditStatus.due:
        return "DUE OPEN";
      case CreditStatus.defaulter:
        return "LIMIT EXCEEDED";
    }
  }

  static CreditStatus calculate({
    required double outstanding,
    required double creditLimit,
  }) {
    if (outstanding <= 0) return CreditStatus.clear;
    if (outstanding <= creditLimit) return CreditStatus.due;
    return CreditStatus.defaulter;
  }
}

enum AdvanceOrderStatus {
  pending,
  ready,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case AdvanceOrderStatus.pending:
        return "PENDING";
      case AdvanceOrderStatus.ready:
        return "READY";
      case AdvanceOrderStatus.delivered:
        return "DELIVERED";
      case AdvanceOrderStatus.cancelled:
        return "CANCELLED";
    }
  }

  static AdvanceOrderStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'READY':
        return AdvanceOrderStatus.ready;
      case 'DELIVERED':
        return AdvanceOrderStatus.delivered;
      case 'CANCELLED':
        return AdvanceOrderStatus.cancelled;
      default:
        return AdvanceOrderStatus.pending;
    }
  }
}

@immutable
class CustomerBillModel {
  static const double _kPaymentTolerance = 0.01;

  final int id;
  final String billNo;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final DateTime billDate;
  final int? sourceAdvanceOrderId;
  final String? sourceAdvanceOrderNo;

  const CustomerBillModel({
    required this.id,
    required this.billNo,
    required this.totalAmount,
    required this.status,
    required this.billDate,
    this.sourceAdvanceOrderId,
    this.sourceAdvanceOrderNo,
    this.paidAmount = 0.0,
  });

  bool get isPaid {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'PAID' ||
        normalized == 'COMPLETE' ||
        normalized == 'COMPLETED') {
      return true;
    }
    return dueAmount <= _kPaymentTolerance;
  }

  bool get isPartial => !isPaid && paidAmount > _kPaymentTolerance;
  bool get isUnpaid => !isPaid && !isPartial;
  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isFromAdvanceOrder =>
      sourceAdvanceOrderId != null ||
      (sourceAdvanceOrderNo != null && sourceAdvanceOrderNo!.trim().isNotEmpty);

  String get advanceSourceLabel {
    final orderNo = sourceAdvanceOrderNo?.trim();
    return orderNo == null || orderNo.isEmpty
        ? 'Advance Order'
        : 'Advance Order $orderNo';
  }

  double get dueAmount =>
      (totalAmount - paidAmount).clamp(0.0, double.infinity);

  String get paymentLabel => isPaid
      ? "SETTLED"
      : isPartial
          ? "PARTIAL"
          : "UNPAID";

  String get formattedAmount => "\u20B9 ${totalAmount.toStringAsFixed(2)}";
  String get formattedPaidAmount => "\u20B9 ${paidAmount.toStringAsFixed(2)}";
  String get formattedDueAmount => "\u20B9 ${dueAmount.toStringAsFixed(2)}";

  String get formattedDate {
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
    return "${billDate.day.toString().padLeft(2, '0')} "
        "${months[billDate.month]} ${billDate.year}";
  }
}

@immutable
class CustomerBillLineItemModel {
  final String itemName;
  final String? huid;
  final String? purity;
  final double grossWeight;
  final double netWeight;
  final double rate;
  final double makingCharge;
  final double itemTotal;

  const CustomerBillLineItemModel({
    required this.itemName,
    required this.grossWeight,
    required this.netWeight,
    required this.rate,
    required this.makingCharge,
    required this.itemTotal,
    this.huid,
    this.purity,
  });
}

@immutable
class CustomerBillDetailModel {
  final CustomerBillModel bill;
  final String customerName;
  final String customerMobile;
  final List<CustomerBillLineItemModel> items;

  const CustomerBillDetailModel({
    required this.bill,
    required this.customerName,
    required this.customerMobile,
    required this.items,
  });
}

@immutable
class CustomerLoanModel {
  final int id;
  final String loanNo;
  final String itemDesc;
  final double grossWeight;
  final double loanAmount;
  final double interestRate;
  final DateTime startDate;
  final DateTime? lastInterestPaidDate;
  final String status;

  const CustomerLoanModel({
    required this.id,
    required this.loanNo,
    required this.itemDesc,
    required this.grossWeight,
    required this.loanAmount,
    required this.interestRate,
    required this.startDate,
    this.lastInterestPaidDate,
    required this.status,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isReleased => status.toUpperCase() == 'RELEASED';

  double get accruedInterest {
    final from = lastInterestPaidDate ?? startDate;
    final months = GirviLoanModel.chargeableMonthsBetween(from, DateTime.now());
    return GirviLoanModel.calculateCompoundInterest(
      principal: loanAmount,
      monthlyRatePercent: interestRate,
      months: months,
    );
  }

  String get formattedDate {
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
    return "${startDate.day.toString().padLeft(2, '0')} "
        "${months[startDate.month]} ${startDate.year}";
  }

  int get daysActive => DateTime.now().difference(startDate).inDays;
}

@immutable
class CustomerAdvanceOrderModel {
  final int id;
  final String orderNo;
  final String itemName;
  final String metalType;
  final String purity;
  final double approxWeight;
  final double lockedRate;
  final String bookingType;
  final AdvanceOrderStatus status;
  final DateTime? deliveryDate;
  final String? notes;
  final double totalAdvancePaid;
  final double estimatedTotal;
  final DateTime createdAt;

  const CustomerAdvanceOrderModel({
    required this.id,
    required this.orderNo,
    required this.itemName,
    required this.metalType,
    required this.purity,
    required this.approxWeight,
    required this.lockedRate,
    required this.bookingType,
    required this.status,
    required this.totalAdvancePaid,
    required this.estimatedTotal,
    required this.createdAt,
    this.deliveryDate,
    this.notes,
  });

  bool get isPending => status == AdvanceOrderStatus.pending;
  bool get isReady => status == AdvanceOrderStatus.ready;
  bool get isDelivered => status == AdvanceOrderStatus.delivered;
  bool get isCancelled => status == AdvanceOrderStatus.cancelled;

  double get remainingBalance =>
      (estimatedTotal - totalAdvancePaid).clamp(0.0, double.infinity);

  String get formattedDate {
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
    return "${createdAt.day.toString().padLeft(2, '0')} "
        "${months[createdAt.month]} ${createdAt.year}";
  }

  String get formattedDelivery {
    if (deliveryDate == null) return "No date set";
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
    return "${deliveryDate!.day.toString().padLeft(2, '0')} "
        "${months[deliveryDate!.month]} ${deliveryDate!.year}";
  }
}

@immutable
class CustomerDueModel {
  final int billId;
  final String billNo;
  final double totalAmount;
  final double paidAmount;
  final DateTime billDate;
  final int? sourceAdvanceOrderId;
  final String? sourceAdvanceOrderNo;

  const CustomerDueModel({
    required this.billId,
    required this.billNo,
    required this.totalAmount,
    required this.paidAmount,
    required this.billDate,
    this.sourceAdvanceOrderId,
    this.sourceAdvanceOrderNo,
  });

  bool get isFromAdvanceOrder =>
      sourceAdvanceOrderId != null ||
      (sourceAdvanceOrderNo != null && sourceAdvanceOrderNo!.trim().isNotEmpty);

  double get dueAmount =>
      (totalAmount - paidAmount).clamp(0.0, double.infinity);

  String get formattedDue => "\u20B9 ${dueAmount.toStringAsFixed(0)}";

  String get formattedDate {
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
    return "${billDate.day.toString().padLeft(2, '0')} "
        "${months[billDate.month]} ${billDate.year}";
  }
}

@immutable
class CustomerProfileModel {
  final int id;
  final String name;
  final String mobile;
  final String whatsapp;
  final String city;
  final String type;
  final DateTime createdAt;
  final double creditLimit;
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
    this.type = "Regular",
    required this.createdAt,
    this.creditLimit = 50000.0,
    this.outstanding = 0.0,
    this.bills = const [],
    this.loans = const [],
    this.advanceOrders = const [],
    this.dues = const [],
    required this.initials,
  });

  CustomerGender get gender {
    final nameLower = name.toLowerCase().trim();
    final parts = nameLower.split(RegExp(r'\s+'));
    final lastName = parts.length >= 2 ? parts.last : "";
    final firstName = parts.first;

    const femaleEndwords = [
      'devi',
      'kumari',
      'bai',
      'rani',
      'mata',
      'ben',
      'bhen',
      'priya',
      'lata',
      'prabha',
      'bala',
      'mala',
      'kala',
      'rekha',
      'radha',
      'sita',
      'geeta',
      'meeta',
      'neeta',
      'anita',
      'sunita',
      'kavita',
      'savita',
      'lalita',
      'mamta',
      'shanti',
      'tara',
      'usha',
      'asha',
      'nisha',
      'misha',
      'komal',
      'kamal',
      'deepa',
      'rupa',
      'sarla',
      'sudha',
      'vidya',
      'divya',
      'pooja',
      'puja',
      'jyoti',
      'kiran',
      'seema',
      'reema',
      'neha',
      'sneha',
      'ankita',
      'namita',
      'archana',
      'kanchan',
      'vandana',
      'preeti',
      'swati',
      'ritu',
      'mitu',
      'pintu',
      'rinku',
      'anjali',
      'manali',
      'shruti',
      'smriti',
      'aditi',
      'kriti',
      'arti',
      'bharti',
      'shobha',
      'prabha',
      'subha',
      'abha',
      'vibha',
      'shikha',
      'rekha',
      'leela',
      'sheela',
      'meela',
      'kamla',
      'vimla',
      'nirmala',
      'urmila',
      'sushila',
      'shushila',
      'pushpa',
      'champa',
      'chameli',
      'gulabi',
      'hemlata',
      'shakuntalaa',
    ];

    for (final word in femaleEndwords) {
      if (lastName == word ||
          firstName == word ||
          nameLower.contains(' $word') ||
          nameLower.endsWith(word)) {
        return CustomerGender.female;
      }
    }
    return CustomerGender.male;
  }

  bool get isFemale => gender == CustomerGender.female;
  bool get isVip => type.toLowerCase() == 'vip';

  CreditStatus get creditStatus => CreditStatus.calculate(
        outstanding: outstanding,
        creditLimit: creditLimit,
      );

  CreditStatus get accountStatus => creditStatus;

  double get dueLimit => creditLimit;

  double get availableCredit =>
      (creditLimit - outstanding).clamp(0, double.infinity);

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
      createdAt: createdAt,
      creditLimit: creditLimit ?? this.creditLimit,
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
