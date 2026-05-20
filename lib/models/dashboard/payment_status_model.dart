// =============================================================================
// FILE        : payment_status_model.dart
// MODULE      : Dashboard / Payment Status
// LAYER       : Models
// DESCRIPTION : Poore Payment Status Card ka data snapshot.
//               Summary stats + individual bill list.
// =============================================================================

import 'payment_bill_item.dart';

/// Active filter tab
enum PaymentFilterTab { all, due, paid }

/// Summary stats — header mein dikhega
class PaymentSummary {
  final int totalBills;
  final double totalCollected; // Sum of all paidAmount
  final double totalPending; // Sum of all dueAmount
  final int paidCount;
  final int partialCount;
  final int unpaidCount;

  const PaymentSummary({
    required this.totalBills,
    required this.totalCollected,
    required this.totalPending,
    required this.paidCount,
    required this.partialCount,
    required this.unpaidCount,
  });

  factory PaymentSummary.empty() => const PaymentSummary(
        totalBills: 0,
        totalCollected: 0,
        totalPending: 0,
        paidCount: 0,
        partialCount: 0,
        unpaidCount: 0,
      );

  factory PaymentSummary.loading() => const PaymentSummary(
        totalBills: -1, // -1 = loading indicator
        totalCollected: 0,
        totalPending: 0,
        paidCount: 0,
        partialCount: 0,
        unpaidCount: 0,
      );

  bool get isLoading => totalBills == -1;
}

/// Complete widget data model
class PaymentStatusModel {
  final PaymentSummary summary;
  final List<PaymentBillItem> bills; // All bills
  final PaymentFilterTab activeTab;

  const PaymentStatusModel({
    required this.summary,
    required this.bills,
    this.activeTab = PaymentFilterTab.all,
  });

  factory PaymentStatusModel.loading() => PaymentStatusModel(
        summary: PaymentSummary.loading(),
        bills: [],
      );

  factory PaymentStatusModel.empty() => PaymentStatusModel(
        summary: PaymentSummary.empty(),
        bills: [],
      );

  bool get isLoading => summary.isLoading;

  /// Active tab ke hisaab se filtered list
  List<PaymentBillItem> get filteredBills {
    switch (activeTab) {
      case PaymentFilterTab.all:
        return bills;
      case PaymentFilterTab.due:
        return bills
            .where((b) =>
                b.status == PaymentStatus.unpaid ||
                b.status == PaymentStatus.partial)
            .toList();
      case PaymentFilterTab.paid:
        return bills.where((b) => b.status == PaymentStatus.paid).toList();
    }
  }

  /// Tab switch ke saath copy
  PaymentStatusModel withTab(PaymentFilterTab tab) => PaymentStatusModel(
        summary: summary,
        bills: bills,
        activeTab: tab,
      );
}
