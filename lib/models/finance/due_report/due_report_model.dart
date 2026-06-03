class DueReportDate {
  static DateTime only(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

enum DueReportFilter { all, overdue, dueToday, partial, unpaid, noPromise }

extension DueReportFilterX on DueReportFilter {
  String get label {
    switch (this) {
      case DueReportFilter.all:
        return 'All Due';
      case DueReportFilter.overdue:
        return 'Overdue';
      case DueReportFilter.dueToday:
        return 'Due Today';
      case DueReportFilter.partial:
        return 'Partial';
      case DueReportFilter.unpaid:
        return 'Unpaid';
      case DueReportFilter.noPromise:
        return 'No Promise';
    }
  }
}

enum DueReportSort {
  highestDue,
  oldestBill,
  customerName,
  billCount,
  promiseDate,
}

extension DueReportSortX on DueReportSort {
  String get label {
    switch (this) {
      case DueReportSort.highestDue:
        return 'Highest Due';
      case DueReportSort.oldestBill:
        return 'Oldest Bill';
      case DueReportSort.customerName:
        return 'Customer Name';
      case DueReportSort.billCount:
        return 'Bill Count';
      case DueReportSort.promiseDate:
        return 'Promise Date';
    }
  }
}

enum DueBillBucket { overdue, dueToday, promised, noPromise }

class DueBillModel {
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

  const DueBillModel({
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

  String get groupKey {
    if (customerId != null) return 'customer:$customerId';
    return 'snapshot:${customerName.toLowerCase()}|$mobile';
  }

  int get ageDays {
    final today = DueReportDate.only(DateTime.now());
    final billDay = DueReportDate.only(billDate);
    final days = today.difference(billDay).inDays;
    return days < 0 ? 0 : days;
  }

  bool get isUnpaid => paidAmount <= 0.5;
  bool get isPartial => paidAmount > 0.5 && dueAmount > 0.5;

  bool get isDueToday {
    if (promiseDate == null) return false;
    final today = DueReportDate.only(DateTime.now());
    return DueReportDate.only(promiseDate!).isAtSameMomentAs(today);
  }

  bool get isOverdue {
    if (promiseDate == null) return false;
    final today = DueReportDate.only(DateTime.now());
    return DueReportDate.only(promiseDate!).isBefore(today);
  }

  int get promiseOverdueDays {
    if (!isOverdue || promiseDate == null) return 0;
    final today = DueReportDate.only(DateTime.now());
    return today.difference(DueReportDate.only(promiseDate!)).inDays;
  }

  DueBillBucket get bucket {
    if (isOverdue) return DueBillBucket.overdue;
    if (isDueToday) return DueBillBucket.dueToday;
    if (promiseDate == null) return DueBillBucket.noPromise;
    return DueBillBucket.promised;
  }

  String get statusLabel {
    final status = paymentStatus.trim().toUpperCase();
    if (isUnpaid) return 'UNPAID';
    if (isPartial) return 'PARTIAL';
    return status.isEmpty ? 'DUE' : status;
  }
}

class DueCustomerGroupModel {
  final String key;
  final int? customerId;
  final String customerName;
  final String mobile;
  final String city;
  final String address;
  final List<DueBillModel> bills;
  final double totalBilled;
  final double totalPaid;
  final double totalDue;
  final double overdueAmount;
  final int overdueBillCount;
  final int dueTodayBillCount;
  final int noPromiseBillCount;
  final DateTime oldestBillDate;
  final DateTime? nearestPromiseDate;

  const DueCustomerGroupModel({
    required this.key,
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.city,
    required this.address,
    required this.bills,
    required this.totalBilled,
    required this.totalPaid,
    required this.totalDue,
    required this.overdueAmount,
    required this.overdueBillCount,
    required this.dueTodayBillCount,
    required this.noPromiseBillCount,
    required this.oldestBillDate,
    required this.nearestPromiseDate,
  });

  factory DueCustomerGroupModel.fromBills(List<DueBillModel> source) {
    final bills = List<DueBillModel>.from(source)
      ..sort((a, b) => a.billDate.compareTo(b.billDate));
    final first = bills.first;
    final promises = bills
        .where((b) => b.promiseDate != null)
        .map((b) => b.promiseDate!)
        .toList()
      ..sort();

    return DueCustomerGroupModel(
      key: first.groupKey,
      customerId: first.customerId,
      customerName: first.customerName,
      mobile: first.mobile,
      city: first.city,
      address: first.address,
      bills: bills,
      totalBilled: bills.fold(0.0, (sum, b) => sum + b.finalAmount),
      totalPaid: bills.fold(0.0, (sum, b) => sum + b.paidAmount),
      totalDue: bills.fold(0.0, (sum, b) => sum + b.dueAmount),
      overdueAmount: bills
          .where((b) => b.isOverdue)
          .fold(0.0, (sum, b) => sum + b.dueAmount),
      overdueBillCount: bills.where((b) => b.isOverdue).length,
      dueTodayBillCount: bills.where((b) => b.isDueToday).length,
      noPromiseBillCount: bills.where((b) => b.promiseDate == null).length,
      oldestBillDate: bills.first.billDate,
      nearestPromiseDate: promises.isEmpty ? null : promises.first,
    );
  }

  int get billCount => bills.length;
  bool get hasOverdue => overdueBillCount > 0;
  bool get hasDueToday => dueTodayBillCount > 0;
}

class DueReportStatsModel {
  final int customerCount;
  final int billCount;
  final double totalDue;
  final double overdueAmount;
  final int overdueBillCount;
  final int dueTodayBillCount;
  final int noPromiseBillCount;
  final double highestCustomerDue;
  final String lastRefreshedAt;

  const DueReportStatsModel({
    required this.customerCount,
    required this.billCount,
    required this.totalDue,
    required this.overdueAmount,
    required this.overdueBillCount,
    required this.dueTodayBillCount,
    required this.noPromiseBillCount,
    required this.highestCustomerDue,
    required this.lastRefreshedAt,
  });

  factory DueReportStatsModel.empty() {
    return const DueReportStatsModel(
      customerCount: 0,
      billCount: 0,
      totalDue: 0,
      overdueAmount: 0,
      overdueBillCount: 0,
      dueTodayBillCount: 0,
      noPromiseBillCount: 0,
      highestCustomerDue: 0,
      lastRefreshedAt: '--:--',
    );
  }

  factory DueReportStatsModel.fromGroups(List<DueCustomerGroupModel> groups) {
    final now = DateTime.now();
    return DueReportStatsModel(
      customerCount: groups.length,
      billCount: groups.fold(0, (sum, g) => sum + g.billCount),
      totalDue: groups.fold(0.0, (sum, g) => sum + g.totalDue),
      overdueAmount: groups.fold(0.0, (sum, g) => sum + g.overdueAmount),
      overdueBillCount: groups.fold(0, (sum, g) => sum + g.overdueBillCount),
      dueTodayBillCount: groups.fold(0, (sum, g) => sum + g.dueTodayBillCount),
      noPromiseBillCount: groups.fold(
        0,
        (sum, g) => sum + g.noPromiseBillCount,
      ),
      highestCustomerDue: groups.isEmpty
          ? 0
          : groups.map((g) => g.totalDue).reduce((a, b) => a > b ? a : b),
      lastRefreshedAt:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
  }
}
