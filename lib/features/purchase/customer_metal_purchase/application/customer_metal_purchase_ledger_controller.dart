import 'package:flutter/material.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/data/customer_metal_purchase_ledger_drift_repository.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/repositories/customer_metal_purchase_ledger_repository.dart';

class CustomerMetalPurchaseLedgerController extends ChangeNotifier {
  final CustomerMetalPurchaseLedgerRepository _repository;

  bool isLoading = false;
  List<CustomerMetalPurchaseEntry> entries = [];
  String? error;

  DateTime? startDate;
  DateTime? endDate;
  CustomerMetalPurchaseQuickPeriod selectedPeriod =
      CustomerMetalPurchaseQuickPeriod.thisMonth;
  CustomerMetalPurchaseMetal? selectedMetal;
  CustomerMetalPurchaseReportTab selectedTab =
      CustomerMetalPurchaseReportTab.ledger;
  String paymentStatusFilter = 'ALL';
  final TextEditingController searchCtrl = TextEditingController();

  CustomerMetalPurchaseLedgerController({
    CustomerMetalPurchaseLedgerRepository? repository,
    DateTime? currentDate,
  }) : _repository = repository ??
            DriftCustomerMetalPurchaseLedgerRepository(AppDatabase()) {
    final now = currentDate ?? DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    searchCtrl.addListener(notifyListeners);
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      entries = await _repository.fetchLedger(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (exception) {
      error = exception.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    selectedPeriod = CustomerMetalPurchaseQuickPeriod.custom;
    startDate = start;
    endDate = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    fetchData();
  }

  void setQuickPeriod(CustomerMetalPurchaseQuickPeriod period) {
    selectedPeriod = period;
    final now = DateTime.now();
    switch (period) {
      case CustomerMetalPurchaseQuickPeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      case CustomerMetalPurchaseQuickPeriod.thisWeek:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        startDate = start;
        endDate = start.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
      case CustomerMetalPurchaseQuickPeriod.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      case CustomerMetalPurchaseQuickPeriod.lastMonth:
        final month = DateTime(now.year, now.month - 1, 1);
        startDate = month;
        endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
      case CustomerMetalPurchaseQuickPeriod.thisYear:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59, 999);
      case CustomerMetalPurchaseQuickPeriod.lastYear:
        startDate = DateTime(now.year - 1, 1, 1);
        endDate = DateTime(now.year - 1, 12, 31, 23, 59, 59, 999);
      case CustomerMetalPurchaseQuickPeriod.custom:
        return;
    }
    fetchData();
  }

  void setMonthYear({required int month, required int year}) {
    selectedPeriod = CustomerMetalPurchaseQuickPeriod.custom;
    startDate = DateTime(year, month, 1);
    endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    fetchData();
  }

  void selectMetal(CustomerMetalPurchaseMetal? metal) {
    selectedMetal = metal;
    selectedTab = CustomerMetalPurchaseReportTab.ledger;
    notifyListeners();
  }

  void selectTab(CustomerMetalPurchaseReportTab tab) {
    selectedTab = tab;
    notifyListeners();
  }

  void setPaymentStatusFilter(String value) {
    paymentStatusFilter = value;
    notifyListeners();
  }

  List<CustomerMetalPurchaseEntry> entriesForMetal(
    CustomerMetalPurchaseMetal metal, {
    CustomerMetalPurchaseEntryView view =
        CustomerMetalPurchaseEntryView.available,
  }) {
    return filteredEntries
        .where(
            (entry) => _normalizeMetal(entry.metalType) == metal.storageValue)
        .where((entry) => _matchesView(entry, view))
        .toList(growable: false);
  }

  CustomerMetalPurchaseMetalSummary summaryForMetal(
    CustomerMetalPurchaseMetal metal,
  ) {
    return buildCustomerMetalPurchaseSummary(
      metal: metal,
      entries: entriesForMetal(
        metal,
        view: CustomerMetalPurchaseEntryView.available,
      ),
    );
  }

  Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
      get metalSummaries {
    return {
      for (final metal in CustomerMetalPurchaseMetal.values)
        metal: summaryForMetal(metal),
    };
  }

  List<CustomerMetalPurchaseEntry> get filteredEntries {
    final search = searchCtrl.text.trim().toLowerCase();
    return entries.where((entry) {
      if (selectedMetal != null &&
          _normalizeMetal(entry.metalType) != selectedMetal!.storageValue) {
        return false;
      }
      if (!_matchesPaymentStatus(entry)) {
        return false;
      }
      if (search.isEmpty) {
        return true;
      }
      final haystack = [
        entry.customerName,
        entry.mobile ?? '',
        entry.referenceNo,
        entry.metalType,
        entry.itemDescription,
        entry.paymentModeLabel,
        entry.resolvedPaymentStatus,
      ].join(' ').toLowerCase();
      return haystack.contains(search);
    }).toList(growable: false);
  }

  Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
      get visibleMetalSummaries {
    final summaries = metalSummaries;
    final visible = {
      for (final entry in summaries.entries)
        if (entry.value.hasBusiness) entry.key: entry.value,
    };
    return visible.isEmpty ? summaries : visible;
  }

  CustomerMetalPurchaseDashboardSummary get dashboardSummary {
    final customerNames = <String>{};
    final voucherNos = <String>{};
    var grossWeight = 0.0;
    var netWeight = 0.0;
    var fineWeight = 0.0;
    var amount = 0.0;
    var paidAmount = 0.0;
    var pendingAmount = 0.0;
    var cashPaid = 0.0;
    var upiPaid = 0.0;
    var bankPaid = 0.0;
    var cardPaid = 0.0;

    for (final entry in filteredEntries) {
      grossWeight += entry.grossWeight;
      netWeight += entry.netWeight;
      fineWeight += entry.fineWeight;
      amount += entry.amount;
      paidAmount += entry.paidAmount;
      pendingAmount += entry.pendingAmount;
      cashPaid += entry.cashPaid;
      upiPaid += entry.upiPaid;
      bankPaid += entry.bankPaid;
      cardPaid += entry.cardPaid;
      final customerName = entry.customerName.trim().toUpperCase();
      if (customerName.isNotEmpty) {
        customerNames.add(customerName);
      }
      final voucherNo = entry.referenceNo.trim().toUpperCase();
      if (voucherNo.isNotEmpty) {
        voucherNos.add(voucherNo);
      }
    }

    return CustomerMetalPurchaseDashboardSummary(
      grossWeight: grossWeight,
      netWeight: netWeight,
      fineWeight: fineWeight,
      amount: amount,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      cashPaid: cashPaid,
      upiPaid: upiPaid,
      bankPaid: bankPaid,
      cardPaid: cardPaid,
      entryCount: filteredEntries.length,
      customerCount: customerNames.length,
      voucherCount: voucherNos.length,
    );
  }

  List<CustomerMetalPurchaseEntry> get pendingEntries {
    return filteredEntries
        .where((entry) => entry.pendingAmount > 0.005)
        .toList(growable: false);
  }

  List<CustomerMetalPurchaseSellerSummary> get sellerSummaries {
    final grouped = <String, List<CustomerMetalPurchaseEntry>>{};
    for (final entry in filteredEntries) {
      final key = entry.customerName.trim().toUpperCase();
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    final summaries = grouped.values.map((items) {
      final vouchers = <String>{
        for (final entry in items) entry.referenceNo.trim().toUpperCase(),
      };
      return CustomerMetalPurchaseSellerSummary(
        sellerName: items.first.customerName,
        mobile: items.first.mobile,
        amount: items.fold(0.0, (sum, entry) => sum + entry.amount),
        paidAmount: items.fold(0.0, (sum, entry) => sum + entry.paidAmount),
        pendingAmount:
            items.fold(0.0, (sum, entry) => sum + entry.pendingAmount),
        fineWeight: items.fold(0.0, (sum, entry) => sum + entry.fineWeight),
        entryCount: items.length,
        voucherCount: vouchers.length,
      );
    }).toList(growable: false);

    return [...summaries]..sort((a, b) => b.amount.compareTo(a.amount));
  }

  String get periodLabel {
    if (startDate == null || endDate == null) {
      return 'All Time';
    }
    if (startDate!.year == endDate!.year &&
        startDate!.month == endDate!.month) {
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[startDate!.month - 1]} ${startDate!.year}';
    }
    return '${_shortDate(startDate!)} - ${_shortDate(endDate!)}';
  }

  double get totalGoldGrossWeight => entries
      .where((entry) => entry.metalType.toUpperCase() == 'GOLD')
      .fold(0.0, (sum, entry) => sum + entry.grossWeight);

  double get totalGoldFineWeight => entries
      .where((entry) => entry.metalType.toUpperCase() == 'GOLD')
      .fold(0.0, (sum, entry) => sum + entry.fineWeight);

  double get totalSilverGrossWeight => entries
      .where((entry) => entry.metalType.toUpperCase() == 'SILVER')
      .fold(0.0, (sum, entry) => sum + entry.grossWeight);

  double get totalSilverFineWeight => entries
      .where((entry) => entry.metalType.toUpperCase() == 'SILVER')
      .fold(0.0, (sum, entry) => sum + entry.fineWeight);

  Future<void> markReturned(CustomerMetalPurchaseEntry entry) async {
    if (!entry.isAvailable) {
      return;
    }

    await _repository.markReturned(entry);
    await fetchData();
  }

  Future<String> createMeltingBatch({
    required CustomerMetalPurchaseMetal metal,
    required List<CustomerMetalPurchaseEntry> selectedEntries,
  }) async {
    final batchNo = await _repository.createMeltingBatch(
      metalType: metal.storageValue,
      entries: selectedEntries,
    );
    await fetchData();
    return batchNo;
  }

  String _normalizeMetal(String value) {
    return value.trim().toUpperCase();
  }

  bool _matchesView(
    CustomerMetalPurchaseEntry entry,
    CustomerMetalPurchaseEntryView view,
  ) {
    switch (view) {
      case CustomerMetalPurchaseEntryView.available:
        return entry.isAvailable;
      case CustomerMetalPurchaseEntryView.transferred:
        return entry.isTransferredToMelting;
      case CustomerMetalPurchaseEntryView.returned:
        return entry.isReturned;
      case CustomerMetalPurchaseEntryView.all:
        return true;
    }
  }

  bool _matchesPaymentStatus(CustomerMetalPurchaseEntry entry) {
    switch (paymentStatusFilter.toUpperCase()) {
      case 'PAID':
        return entry.pendingAmount <= 0.005;
      case 'PARTIAL':
        return entry.pendingAmount > 0.005 && entry.paidAmount > 0.005;
      case 'PENDING':
        return entry.pendingAmount > 0.005 && entry.paidAmount <= 0.005;
      default:
        return true;
    }
  }

  String _shortDate(DateTime value) {
    const months = [
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
      'Dec',
    ];
    return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }
}
