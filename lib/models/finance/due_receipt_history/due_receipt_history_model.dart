class DueReceiptDate {
  static DateTime only(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

enum DueReceiptDateFilter { all, today, last7Days, last30Days, dueMarked }

extension DueReceiptDateFilterX on DueReceiptDateFilter {
  String get label {
    switch (this) {
      case DueReceiptDateFilter.all:
        return 'All';
      case DueReceiptDateFilter.today:
        return 'Today';
      case DueReceiptDateFilter.last7Days:
        return '7 Days';
      case DueReceiptDateFilter.last30Days:
        return '30 Days';
      case DueReceiptDateFilter.dueMarked:
        return 'Due Marked';
    }
  }
}

enum DueReceiptModeFilter { all, cash, upi, card, bank, cheque }

extension DueReceiptModeFilterX on DueReceiptModeFilter {
  String get label {
    switch (this) {
      case DueReceiptModeFilter.all:
        return 'All Modes';
      case DueReceiptModeFilter.cash:
        return 'Cash';
      case DueReceiptModeFilter.upi:
        return 'UPI';
      case DueReceiptModeFilter.card:
        return 'Card';
      case DueReceiptModeFilter.bank:
        return 'Bank';
      case DueReceiptModeFilter.cheque:
        return 'Cheque';
    }
  }
}

enum DueReceiptSort { latest, highestAmount, customerName, billNo }

extension DueReceiptSortX on DueReceiptSort {
  String get label {
    switch (this) {
      case DueReceiptSort.latest:
        return 'Latest First';
      case DueReceiptSort.highestAmount:
        return 'Highest Amount';
      case DueReceiptSort.customerName:
        return 'Customer Name';
      case DueReceiptSort.billNo:
        return 'Bill No';
    }
  }
}

class DueReceiptModel {
  final String id;
  final int ledgerId;
  final String ledgerSource;
  final String receiptNo;
  final String billNo;
  final int? billId;
  final int? customerId;
  final String customerName;
  final String mobile;
  final String city;
  final String address;
  final DateTime receiptDate;
  final DateTime? billDate;
  final double amount;
  final String paymentMode;
  final String channelLabel;
  final String? bankAccountName;
  final String? description;
  final String? referenceId;
  final double billAmount;
  final double billPaid;
  final double currentDue;
  final String billPaymentStatus;
  final bool isDueMarked;

  const DueReceiptModel({
    required this.id,
    required this.ledgerId,
    required this.ledgerSource,
    required this.receiptNo,
    required this.billNo,
    required this.billId,
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.city,
    required this.address,
    required this.receiptDate,
    required this.billDate,
    required this.amount,
    required this.paymentMode,
    required this.channelLabel,
    required this.bankAccountName,
    required this.description,
    required this.referenceId,
    required this.billAmount,
    required this.billPaid,
    required this.currentDue,
    required this.billPaymentStatus,
    required this.isDueMarked,
  });

  bool get isCashLedger => ledgerSource == 'CASH';
  bool get hasCurrentDue => currentDue > 0.5;
  bool get isClearedNow => !hasCurrentDue;

  String get receiptKind => 'Due Receipt';

  String get statusLabel {
    if (isClearedNow) return 'Due Cleared';
    return 'Due Received';
  }

  String get modeKey => paymentMode.trim().toUpperCase();
}

class DueReceiptStatsModel {
  final int receiptCount;
  final int customerCount;
  final int dueMarkedCount;
  final double totalCollected;
  final double todayCollected;
  final double cashTotal;
  final double bankTotal;
  final String lastRefreshedAt;

  const DueReceiptStatsModel({
    required this.receiptCount,
    required this.customerCount,
    required this.dueMarkedCount,
    required this.totalCollected,
    required this.todayCollected,
    required this.cashTotal,
    required this.bankTotal,
    required this.lastRefreshedAt,
  });

  factory DueReceiptStatsModel.empty() {
    return const DueReceiptStatsModel(
      receiptCount: 0,
      customerCount: 0,
      dueMarkedCount: 0,
      totalCollected: 0,
      todayCollected: 0,
      cashTotal: 0,
      bankTotal: 0,
      lastRefreshedAt: '--:--',
    );
  }

  factory DueReceiptStatsModel.fromReceipts(List<DueReceiptModel> receipts) {
    final today = DueReceiptDate.only(DateTime.now());
    final customers = <String>{};
    double total = 0;
    double todayTotal = 0;
    double cash = 0;
    double bank = 0;
    int dueMarked = 0;

    for (final receipt in receipts) {
      total += receipt.amount;
      if (DueReceiptDate.only(receipt.receiptDate).isAtSameMomentAs(today)) {
        todayTotal += receipt.amount;
      }
      if (receipt.isCashLedger) {
        cash += receipt.amount;
      } else {
        bank += receipt.amount;
      }
      if (receipt.isDueMarked) dueMarked++;
      customers.add(
          receipt.customerId?.toString() ?? receipt.customerName.toLowerCase());
    }

    final now = DateTime.now();
    return DueReceiptStatsModel(
      receiptCount: receipts.length,
      customerCount: customers.length,
      dueMarkedCount: dueMarked,
      totalCollected: total,
      todayCollected: todayTotal,
      cashTotal: cash,
      bankTotal: bank,
      lastRefreshedAt:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
  }
}
