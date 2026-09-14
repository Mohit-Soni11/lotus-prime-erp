import 'package:lotus_erp/database/db/app_database.dart';

enum DueVisibilitySurface {
  financeCollection,
  customerAccount,
}

class BillDuePolicy {
  static const List<String> eligibleBillStatuses = [
    'ACTIVE',
    'PARTIALLY_RETURNED',
    'RETURNED',
  ];

  static const double financeVisibilityTolerance = 0.5;
  static const double customerPrecisionTolerance = 0.005;

  static final Set<String> _settledPaymentStatuses = {
    'PAID',
    'SETTLED',
    'COMPLETE',
    'COMPLETED',
  };

  static final Set<String> _openPaymentStatuses = {
    'PARTIAL',
    'DUE',
    'UNPAID',
  };

  const BillDuePolicy._();

  static bool isEligibleBillStatus(String status) {
    return eligibleBillStatuses.contains(status.trim().toUpperCase());
  }

  static bool isSettledPaymentStatus(String paymentStatus) {
    return _settledPaymentStatuses.contains(paymentStatus.trim().toUpperCase());
  }

  static bool isOpenPaymentStatus(String paymentStatus) {
    return _openPaymentStatuses.contains(paymentStatus.trim().toUpperCase());
  }

  static double currentDue(
    Bill bill, {
    DueVisibilitySurface surface = DueVisibilitySurface.financeCollection,
  }) {
    final paymentStatus = bill.paymentStatus.trim().toUpperCase();
    if (_settledPaymentStatuses.contains(paymentStatus)) {
      return 0;
    }

    final tolerance = switch (surface) {
      DueVisibilitySurface.financeCollection => financeVisibilityTolerance,
      DueVisibilitySurface.customerAccount => customerPrecisionTolerance,
    };

    if (bill.dueAmount > tolerance ||
        _openPaymentStatuses.contains(paymentStatus)) {
      return _positive(bill.dueAmount);
    }

    return _positive(bill.finalAmount - bill.paidAmount);
  }

  static double financeDue(Bill bill) {
    return currentDue(
      bill,
      surface: DueVisibilitySurface.financeCollection,
    );
  }

  static double customerDue(Bill bill) {
    return currentDue(
      bill,
      surface: DueVisibilitySurface.customerAccount,
    );
  }

  static double? authoritativeCustomerDueSnapshot(Bill bill) {
    final paymentStatus = bill.paymentStatus.trim().toUpperCase();
    if (bill.dueAmount > customerPrecisionTolerance ||
        _settledPaymentStatuses.contains(paymentStatus) ||
        _openPaymentStatuses.contains(paymentStatus)) {
      return _positive(bill.dueAmount);
    }
    return null;
  }

  static bool isVisibleFinanceDue(Bill bill) {
    return financeDue(bill) > financeVisibilityTolerance;
  }

  static bool isVisibleCustomerDue(Bill bill) {
    return customerDue(bill) > customerPrecisionTolerance;
  }

  static double _positive(double value) {
    return value.clamp(0.0, double.infinity).toDouble();
  }
}
