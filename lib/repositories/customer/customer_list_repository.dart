// -----------------------------------------------------------------------------
// FILE: customer_list_repository.dart
// MODULE: Customer -> Customer List
// DESCRIPTION: Aggregates customer directory data from billing, advance, and
//              girvi records into fast UI-ready models.
// -----------------------------------------------------------------------------

import 'package:lotus_erp/database/db/app_database.dart';

import '../../models/customer/customer_enums/customer_list_enums.dart';
import '../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../core/logging/app_logger.dart';

class CustomerListRepository {
  final AppDatabase _db;

  CustomerListRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Stream<List<CustomerListItemModel>> watchAllCustomers() {
    return _db.select(_db.customers).watch().asyncMap(
          (_) => getAllCustomers(sort: CustomerSort.newest),
        );
  }

  Future<List<CustomerListItemModel>> searchCustomers(String query) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return getAllCustomers();

    final customers = await getAllCustomers(sort: CustomerSort.newest);
    return customers.where((customer) {
      return customer.name.toLowerCase().contains(term) ||
          customer.mobile.toLowerCase().contains(term) ||
          customer.city.toLowerCase().contains(term) ||
          customer.lastActivityLabel.toLowerCase().contains(term);
    }).toList();
  }

  Future<List<CustomerListItemModel>> getAllCustomers({
    CustomerFilter filter = CustomerFilter.all,
    CustomerSort sort = CustomerSort.newest,
  }) async {
    try {
      final rows = await _db.select(_db.customers).get();
      final models = await _mapCustomers(rows);
      final filtered = _applyFilter(models, filter);
      _sortCustomers(filtered, sort);
      return filtered;
    } catch (e) {
      AppLogger.error("Customer list fetch error: $e");
      return [];
    }
  }

  Future<CustomerListStatsModel> fetchStats() async {
    try {
      final customers = await getAllCustomers(sort: CustomerSort.newest);
      return CustomerListStatsModel.fromCustomers(customers);
    } catch (e) {
      AppLogger.error("Customer list stats error: $e");
      return CustomerListStatsModel.empty();
    }
  }

  Future<List<CustomerListItemModel>> _mapCustomers(
    List<Customer> customers,
  ) async {
    final aggregates = {
      for (final customer in customers)
        customer.id: _CustomerActivity(customer),
    };

    if (aggregates.isEmpty) return [];

    final bills = await _db.select(_db.bills).get();
    for (final bill in bills) {
      final customerId = bill.customerId;
      if (customerId == null || !aggregates.containsKey(customerId)) continue;

      final aggregate = aggregates[customerId]!;
      final status = bill.status.trim().toUpperCase();
      final isCancelled = status == 'CANCELLED' || status == 'VOID';
      final dueAmount =
          (bill.finalAmount - bill.paidAmount).clamp(0.0, double.infinity);

      if (!isCancelled) {
        aggregate.billCount += 1;
        aggregate.invoiceValue += bill.finalAmount;
        aggregate.dueAmount += dueAmount.toDouble();
      }

      final billLabel = bill.sourceAdvanceOrderNo?.trim().isNotEmpty == true
          ? "Advance invoice ${bill.billNo}"
          : "Invoice ${bill.billNo}";
      final detail = dueAmount > 0.01
          ? "Due ${_formatMoney(dueAmount.toDouble())}"
          : "Sales bill settled";

      aggregate.touch(
        when: bill.updatedAt ?? bill.billDate,
        kind: CustomerActivityKind.invoice,
        label: billLabel,
        detail: detail,
        priority: 40,
      );
    }

    final orders = await _db.select(_db.salesOrders).get();
    for (final order in orders) {
      final aggregate = aggregates[order.customerId];
      if (aggregate == null) continue;

      final status = order.status.trim().toUpperCase();
      final isOpen = status == 'PENDING' || status == 'READY';
      if (isOpen) aggregate.activeAdvanceCount += 1;

      final activityDate = _latestDate([
        order.updatedAt,
        order.deliveryDate,
        order.createdAt,
      ]);
      aggregate.touch(
        when: activityDate,
        kind: CustomerActivityKind.advance,
        label: isOpen
            ? "Advance order ${order.orderNo}"
            : "Advance ${status.toLowerCase()}",
        detail: "${order.itemName} - ${order.metalType} ${order.purity}",
        priority: 30,
      );
    }

    final girviLoans = await _db.select(_db.girviLoans).get();
    for (final loan in girviLoans) {
      final aggregate = aggregates[loan.customerId];
      if (aggregate == null) continue;

      final status = loan.status.trim().toUpperCase();
      final isOpen = status == 'ACTIVE' ||
          status == 'OVERDUE' ||
          status == 'PARTIAL_RELEASE' ||
          status == 'READY_FOR_DELIVERY';
      if (isOpen) aggregate.activeGirviCount += 1;

      final activityDate = _latestDate([
        loan.updatedAt,
        loan.releaseDate,
        loan.lastInterestPaidDate,
        loan.startDate,
      ]);
      aggregate.touch(
        when: activityDate,
        kind: CustomerActivityKind.girvi,
        label: "Girvi ticket ${loan.ticketNo}",
        detail: "${loan.itemDescription} - ${_formatMoney(loan.loanAmount)}",
        priority: 20,
      );
    }

    return aggregates.values.map((aggregate) => aggregate.toModel()).toList();
  }

  List<CustomerListItemModel> _applyFilter(
    List<CustomerListItemModel> customers,
    CustomerFilter filter,
  ) {
    switch (filter) {
      case CustomerFilter.standard:
        return customers
            .where((customer) => customer.type == CustomerType.standard)
            .toList();
      case CustomerFilter.silver:
        return customers
            .where((customer) => customer.type == CustomerType.silver)
            .toList();
      case CustomerFilter.gold:
        return customers
            .where((customer) => customer.type == CustomerType.gold)
            .toList();
      case CustomerFilter.elite:
        return customers
            .where((customer) => customer.type == CustomerType.elite)
            .toList();
      case CustomerFilter.today:
        return customers
            .where((customer) => customer.hasActivityToday)
            .toList();
      case CustomerFilter.all:
        return List<CustomerListItemModel>.from(customers);
    }
  }

  void _sortCustomers(
    List<CustomerListItemModel> customers,
    CustomerSort sort,
  ) {
    switch (sort) {
      case CustomerSort.nameAsc:
        customers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case CustomerSort.nameDesc:
        customers.sort((a, b) => b.name.compareTo(a.name));
        break;
      case CustomerSort.newest:
        customers.sort(
          (a, b) => b.lastActivityAt.compareTo(a.lastActivityAt),
        );
        break;
      case CustomerSort.oldest:
        customers.sort(
          (a, b) => a.lastActivityAt.compareTo(b.lastActivityAt),
        );
        break;
      case CustomerSort.mostBills:
        customers.sort((a, b) {
          final billSort = b.billCount.compareTo(a.billCount);
          if (billSort != 0) return billSort;
          return b.lastActivityAt.compareTo(a.lastActivityAt);
        });
        break;
    }
  }

  DateTime _latestDate(List<DateTime?> values) {
    final dates = values.whereType<DateTime>().toList();
    if (dates.isEmpty) return DateTime.now();
    dates.sort((a, b) => b.compareTo(a));
    return dates.first;
  }

  static String _formatMoney(double value) {
    final amount = value.abs();
    if (amount >= 10000000) {
      return "Rs ${(value / 10000000).toStringAsFixed(1)}Cr";
    }
    if (amount >= 100000) return "Rs ${(value / 100000).toStringAsFixed(1)}L";
    if (amount >= 1000) return "Rs ${(value / 1000).toStringAsFixed(1)}K";
    return "Rs ${value.toStringAsFixed(0)}";
  }
}

class _CustomerActivity {
  final Customer customer;

  int billCount = 0;
  int activeAdvanceCount = 0;
  int activeGirviCount = 0;
  double invoiceValue = 0;
  double dueAmount = 0;

  late DateTime lastActivityAt;
  CustomerActivityKind lastActivityKind = CustomerActivityKind.profile;
  String lastActivityLabel = "Client profile created";
  String lastActivityDetail = "No transaction posted yet";
  int _lastPriority = 0;

  _CustomerActivity(this.customer) {
    lastActivityAt = customer.updatedAt ?? customer.createdAt;
    if (customer.updatedAt != null) {
      lastActivityLabel = "Client profile updated";
      lastActivityDetail = "Profile information changed";
    }
  }

  void touch({
    required DateTime when,
    required CustomerActivityKind kind,
    required String label,
    required String detail,
    required int priority,
  }) {
    final isNewer = when.isAfter(lastActivityAt);
    final isSameMoment = when.isAtSameMomentAs(lastActivityAt);
    if (!isNewer && !(isSameMoment && priority > _lastPriority)) return;

    lastActivityAt = when;
    lastActivityKind = kind;
    lastActivityLabel = label;
    lastActivityDetail = detail;
    _lastPriority = priority;
  }

  CustomerListItemModel toModel() {
    final name =
        customer.name.trim().isEmpty ? "Unknown Client" : customer.name;
    return CustomerListItemModel(
      id: customer.id,
      name: name,
      mobile: customer.mobile,
      city: customer.city ?? "",
      type: CustomerType.fromString(customer.type),
      billCount: billCount,
      activeAdvanceCount: activeAdvanceCount,
      activeGirviCount: activeGirviCount,
      invoiceValue: invoiceValue,
      dueAmount: dueAmount,
      createdAt: customer.createdAt,
      lastActivityAt: lastActivityAt,
      lastActivityKind: lastActivityKind,
      lastActivityLabel: lastActivityLabel,
      lastActivityDetail: lastActivityDetail,
      initials: CustomerListItemModel.buildInitials(name),
    );
  }
}
