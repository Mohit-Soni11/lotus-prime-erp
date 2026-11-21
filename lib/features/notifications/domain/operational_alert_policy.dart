import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/due_management/domain/services/bill_due_policy.dart';
import 'package:lotus_erp/features/notifications/domain/operational_alert.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/models/girvi/girvi_interest_calculator.dart';

class OperationalAlertPolicy {
  const OperationalAlertPolicy._();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _moneyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  static OperationalAlert? order(
      SalesOrder order, String customerName, DateTime now) {
    if (!{'PENDING', 'READY'}.contains(order.status.toUpperCase()) ||
        order.deliveryDate == null) {
      return null;
    }
    final days = _daysUntil(order.deliveryDate!, now);
    if (days > 3) return null;
    final timing = days < 0
        ? 'overdue by ${-days} day${days == -1 ? '' : 's'}'
        : days == 0
            ? 'due today'
            : 'due in $days day${days == 1 ? '' : 's'}';
    return OperationalAlert(
      key: 'order:${order.id}',
      category: 'Orders',
      title: 'Delivery $timing',
      description:
          'Order ${order.orderNo} · $customerName · ${order.itemName}. '
          'Delivery date: ${_dateFormat.format(order.deliveryDate!)}.',
      routeId: AppRoutes.bookingAdvanceRoute,
      location: Uri(
          path: RoutePaths.salesBooking,
          queryParameters: {'editAdvanceId': '${order.id}'}).toString(),
      priority: days <= 0 ? 0 : 1,
      customerId: order.customerId,
    );
  }

  static OperationalAlert? due(Bill bill, DateTime now) {
    final promise = bill.promiseDate;
    if (promise == null || !BillDuePolicy.isEligibleBillStatus(bill.status)) {
      return null;
    }
    final amount = BillDuePolicy.customerDue(bill);
    if (amount <= 0.005 || _daysUntil(promise, now) > 0) return null;
    final customer = bill.customerName?.trim().isNotEmpty == true
        ? bill.customerName!.trim()
        : 'Customer';
    final overdueDays = -_daysUntil(promise, now);
    return OperationalAlert(
      key: 'due:${bill.id}',
      category: 'Collections',
      title: overdueDays == 0
          ? 'Invoice payment due today'
          : 'Invoice payment overdue',
      description: '$customer · Invoice ${bill.billNo} · '
          '${_moneyFormat.format(amount)} outstanding. '
          'Promised payment: ${_dateFormat.format(promise)}. Contact the customer to collect payment.',
      routeId: AppRoutes.dueReportRoute,
      priority: 0,
      billId: bill.id,
      customerId: bill.customerId,
    );
  }

  static List<OperationalAlert> girvi(
      GirviLoan loan, String customerName, DateTime now) {
    final status = GirviStatus.fromDb(loan.status);
    if (status.isClosed || status == GirviStatus.readyForDelivery) {
      return const [];
    }
    final result = <OperationalAlert>[];
    final maturity = loan.maturityDate ??
        (loan.durationMonths > 0
            ? _addMonths(loan.startDate, loan.durationMonths)
            : null);
    if (maturity != null && _daysUntil(maturity, now) < 0) {
      result.add(OperationalAlert(
        key: 'girvi:maturity:${loan.id}',
        category: 'Girvi',
        title: 'Girvi account past maturity',
        description: '${loan.ticketNo} · $customerName · '
            'Matured ${_dateFormat.format(maturity)}. Contact the customer to arrange settlement.',
        routeId: AppRoutes.girviReleaseRoute,
        priority: 0,
        loanId: loan.id,
        customerId: loan.customerId,
      ));
    }
    final anniversary = _addMonths(
      loan.startDate,
      GirviInterestCalculator.compoundCycleMonths,
    );
    if (GirviInterestCalculator.chargeableMonthsBetween(
          loan.startDate,
          now,
        ) >
        GirviInterestCalculator.compoundCycleMonths) {
      result.add(OperationalAlert(
        key: 'girvi:compound:${loan.id}',
        category: 'Girvi',
        title: 'Annual interest review required',
        description:
            '${loan.ticketNo} · $customerName · Annual cycle completed '
            '${_dateFormat.format(anniversary)}. Review compound interest in the account.',
        routeId: AppRoutes.girviReleaseRoute,
        priority: 1,
        loanId: loan.id,
        customerId: loan.customerId,
      ));
    }
    return result;
  }

  static int _daysUntil(DateTime target, DateTime now) =>
      DateTime.utc(target.year, target.month, target.day)
          .difference(DateTime.utc(now.year, now.month, now.day))
          .inDays;

  static DateTime _addMonths(DateTime start, int months) {
    final first = DateTime(start.year, start.month + months);
    final last = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(first.year, first.month, math.min(start.day, last));
  }
}
