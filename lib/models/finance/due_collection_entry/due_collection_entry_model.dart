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
  final double discountAmount;
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
    required this.discountAmount,
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

class DueCollectionCustomerModel {
  final String key;
  final int? customerId;
  final String name;
  final String mobile;
  final String city;
  final String address;
  final List<DueCollectionBillModel> bills;

  const DueCollectionCustomerModel({
    required this.key,
    required this.customerId,
    required this.name,
    required this.mobile,
    required this.city,
    required this.address,
    required this.bills,
  });

  int get billCount => bills.length;
  double get totalBillAmount =>
      bills.fold(0.0, (sum, bill) => sum + bill.finalAmount);
  double get totalPaid => bills.fold(0.0, (sum, bill) => sum + bill.paidAmount);
  double get totalDue => bills.fold(0.0, (sum, bill) => sum + bill.dueAmount);
  int get overdueCount => bills.where((bill) => bill.isOverdue).length;
  bool get hasOverdue => overdueCount > 0;

  DateTime? get nextPromiseDate {
    DateTime? earliest;
    for (final bill in bills) {
      final date = bill.promiseDate;
      if (date == null) continue;
      if (earliest == null || date.isBefore(earliest)) earliest = date;
    }
    return earliest;
  }

  DueCollectionBillModel get firstBill => bills.first;

  static String keyForBill(DueCollectionBillModel bill) {
    final id = bill.customerId;
    if (id != null) return 'ID:$id';
    return 'WALK:${bill.customerName}|${bill.mobile}'.toLowerCase();
  }

  static List<DueCollectionCustomerModel> groupBills(
      List<DueCollectionBillModel> bills) {
    final buckets = <String, List<DueCollectionBillModel>>{};
    for (final bill in bills) {
      final key = keyForBill(bill);
      buckets.putIfAbsent(key, () => <DueCollectionBillModel>[]).add(bill);
    }

    final customers = <DueCollectionCustomerModel>[];
    for (final entry in buckets.entries) {
      final customerBills = List<DueCollectionBillModel>.from(entry.value)
        ..sort((a, b) {
          final promise = _promiseSortValue(a).compareTo(_promiseSortValue(b));
          if (promise != 0) return promise;
          return b.dueAmount.compareTo(a.dueAmount);
        });
      final first = customerBills.first;
      customers.add(
        DueCollectionCustomerModel(
          key: entry.key,
          customerId: first.customerId,
          name: first.customerName,
          mobile: first.mobile,
          city: first.city,
          address: first.address,
          bills: customerBills,
        ),
      );
    }

    customers.sort((a, b) {
      if (a.hasOverdue != b.hasOverdue) return a.hasOverdue ? -1 : 1;
      return b.totalDue.compareTo(a.totalDue);
    });
    return customers;
  }

  static int _promiseSortValue(DueCollectionBillModel bill) {
    if (bill.promiseDate == null) return 9999999999999;
    return bill.promiseDate!.millisecondsSinceEpoch;
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
      customers.add(DueCollectionCustomerModel.keyForBill(bill));
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
