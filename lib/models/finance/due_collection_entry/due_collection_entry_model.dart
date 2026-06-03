class DueCollectionDate {
  static DateTime only(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

enum DueCollectionPaymentMode {
  cash('CASH', 'Cash'),
  upi('UPI', 'UPI'),
  card('CARD', 'Card'),
  bank('BANK', 'Bank'),
  cheque('CHEQUE', 'Cheque');

  const DueCollectionPaymentMode(this.dbValue, this.label);
  final String dbValue;
  final String label;

  bool get usesBankLedger => this != DueCollectionPaymentMode.cash;
}

class DueCollectionBillModel {
  final int id;
  final String billNo;
  final int? customerId;
  final String customerName;
  final String mobile;
  final String city;
  final String address;
  final DateTime billDate;
  final DateTime? promiseDate;
  final double finalAmount;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus;
  final String billingMode;
  final String billType;

  const DueCollectionBillModel({
    required this.id,
    required this.billNo,
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.city,
    required this.address,
    required this.billDate,
    required this.promiseDate,
    required this.finalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.paymentStatus,
    required this.billingMode,
    required this.billType,
  });

  int get ageDays {
    final today = DueCollectionDate.only(DateTime.now());
    final billDay = DueCollectionDate.only(billDate);
    final days = today.difference(billDay).inDays;
    return days < 0 ? 0 : days;
  }

  bool get isOverdue {
    if (promiseDate == null) return false;
    final today = DueCollectionDate.only(DateTime.now());
    return DueCollectionDate.only(promiseDate!).isBefore(today);
  }

  bool get isDueToday {
    if (promiseDate == null) return false;
    final today = DueCollectionDate.only(DateTime.now());
    return DueCollectionDate.only(promiseDate!).isAtSameMomentAs(today);
  }

  String get statusLabel {
    if (paidAmount <= 0.5) return 'UNPAID';
    if (dueAmount > 0.5) return 'PARTIAL';
    return paymentStatus.trim().isEmpty ? 'DUE' : paymentStatus;
  }
}

class DueCollectionBankAccountModel {
  final int id;
  final String accountName;
  final String bankName;
  final bool isPrimary;

  const DueCollectionBankAccountModel({
    required this.id,
    required this.accountName,
    required this.bankName,
    required this.isPrimary,
  });

  String get label =>
      bankName.trim().isEmpty ? accountName : '$accountName - $bankName';
}

class DueCollectionStatsModel {
  final int billCount;
  final int customerCount;
  final double totalDue;
  final double overdueDue;
  final double selectedDue;

  const DueCollectionStatsModel({
    required this.billCount,
    required this.customerCount,
    required this.totalDue,
    required this.overdueDue,
    required this.selectedDue,
  });

  factory DueCollectionStatsModel.empty() {
    return const DueCollectionStatsModel(
      billCount: 0,
      customerCount: 0,
      totalDue: 0,
      overdueDue: 0,
      selectedDue: 0,
    );
  }

  factory DueCollectionStatsModel.fromBills(
    List<DueCollectionBillModel> bills,
    DueCollectionBillModel? selectedBill,
  ) {
    final customers = <String>{};
    double totalDue = 0;
    double overdueDue = 0;

    for (final bill in bills) {
      totalDue += bill.dueAmount;
      if (bill.isOverdue) overdueDue += bill.dueAmount;
      customers.add(bill.customerId?.toString() ??
          '${bill.customerName}|${bill.mobile}'.toLowerCase());
    }

    return DueCollectionStatsModel(
      billCount: bills.length,
      customerCount: customers.length,
      totalDue: totalDue,
      overdueDue: overdueDue,
      selectedDue: selectedBill?.dueAmount ?? 0,
    );
  }
}

class DueCollectionSaveResult {
  final bool success;
  final String message;
  final String? receiptNo;

  const DueCollectionSaveResult({
    required this.success,
    required this.message,
    this.receiptNo,
  });
}
