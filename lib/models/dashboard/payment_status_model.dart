import 'payment_bill_item.dart';

enum PaymentFilterTab { all, due, paid }

class PaymentSummary {
  const PaymentSummary({
    required this.totalBills,
    required this.cashCollected,
    required this.bankCollected,
    required this.bankByMode,
  });

  final int totalBills;
  final double cashCollected;
  final double bankCollected;
  final Map<String, double> bankByMode;

  double get totalCollected => cashCollected + bankCollected;

  static const empty = PaymentSummary(
    totalBills: 0,
    cashCollected: 0,
    bankCollected: 0,
    bankByMode: {},
  );
}

class PaymentStatusModel {
  const PaymentStatusModel({
    required this.summary,
    required this.bills,
    this.activeTab = PaymentFilterTab.all,
    this.isLoading = false,
  });

  final PaymentSummary summary;
  final List<PaymentBillItem> bills;
  final PaymentFilterTab activeTab;
  final bool isLoading;

  static const loading = PaymentStatusModel(
    summary: PaymentSummary.empty,
    bills: [],
    isLoading: true,
  );

  List<PaymentBillItem> get filteredBills => switch (activeTab) {
        PaymentFilterTab.all => bills,
        PaymentFilterTab.due =>
          bills.where((bill) => bill.dueAmount > 0.5).toList(),
        PaymentFilterTab.paid =>
          bills.where((bill) => bill.status == PaymentStatus.paid).toList(),
      };

  PaymentStatusModel withTab(PaymentFilterTab tab) => PaymentStatusModel(
        summary: summary,
        bills: bills,
        activeTab: tab,
        isLoading: isLoading,
      );
}
