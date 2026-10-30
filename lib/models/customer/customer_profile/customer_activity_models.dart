import 'package:flutter/foundation.dart';

import '../../girvi/girvi_loan_model.dart';
import '../../girvi/girvi_enums.dart';
import 'customer_profile_enums.dart';

@immutable
class CustomerLoanModel {
  final int id;
  final String loanNo;
  final String itemDesc;
  final double grossWeight;
  final double loanAmount;
  final double? originalPrincipalAmount;
  final double? principalOutstandingAmount;
  final double interestRate;
  final DateTime startDate;
  final DateTime? lastInterestPaidDate;
  final DateTime? lastInterestPaymentAt;
  final int interestPaymentCount;
  final bool isManagedGirvi;
  final bool canEditGirvi;
  final String status;
  final double? recordedInterestOutstanding;

  const CustomerLoanModel({
    required this.id,
    required this.loanNo,
    required this.itemDesc,
    required this.grossWeight,
    required this.loanAmount,
    this.originalPrincipalAmount,
    this.principalOutstandingAmount,
    required this.interestRate,
    required this.startDate,
    this.lastInterestPaidDate,
    this.lastInterestPaymentAt,
    this.interestPaymentCount = 0,
    this.isManagedGirvi = false,
    this.canEditGirvi = false,
    required this.status,
    this.recordedInterestOutstanding,
  });

  GirviStatus get lifecycleStatus => GirviStatus.fromDb(status);
  bool get isActive => lifecycleStatus.isOpen;
  bool get isReleased => lifecycleStatus.isClosed;
  double get originalPrincipal => originalPrincipalAmount ?? loanAmount;
  double get principalOutstanding =>
      isActive ? (principalOutstandingAmount ?? loanAmount) : 0;
  String get statusLabel => lifecycleStatus.displayName.toUpperCase();

  double get accruedInterest {
    if (recordedInterestOutstanding != null) {
      return recordedInterestOutstanding!;
    }
    final paidThroughMonths = lastInterestPaidDate == null
        ? 0
        : GirviInterestCalculator.chargeableMonthsBetween(
            startDate,
            lastInterestPaidDate!,
          );
    final currentMonths = GirviInterestCalculator.chargeableMonthsBetween(
      startDate,
      DateTime.now(),
    );
    return GirviInterestCalculator.interestBetweenMonths(
      principal: loanAmount,
      monthlyRatePercent: interestRate,
      fromMonth: paidThroughMonths,
      toMonth: currentMonths,
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
  final double? recordedDueAmount;
  final DateTime billDate;
  final int? sourceAdvanceOrderId;
  final String? sourceAdvanceOrderNo;

  const CustomerDueModel({
    required this.billId,
    required this.billNo,
    required this.totalAmount,
    required this.paidAmount,
    required this.billDate,
    this.recordedDueAmount,
    this.sourceAdvanceOrderId,
    this.sourceAdvanceOrderNo,
  });

  bool get isFromAdvanceOrder =>
      sourceAdvanceOrderId != null ||
      (sourceAdvanceOrderNo != null && sourceAdvanceOrderNo!.trim().isNotEmpty);

  double get dueAmount {
    final recorded = recordedDueAmount;
    if (recorded != null) {
      return recorded.clamp(0.0, double.infinity).toDouble();
    }
    return (totalAmount - paidAmount).clamp(0.0, double.infinity).toDouble();
  }

  String get formattedDue => "₹ ${dueAmount.toStringAsFixed(2)}";

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
