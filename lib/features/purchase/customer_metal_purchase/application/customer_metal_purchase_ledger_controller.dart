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

  CustomerMetalPurchaseLedgerController({
    CustomerMetalPurchaseLedgerRepository? repository,
    DateTime? currentDate,
  }) : _repository = repository ??
            DriftCustomerMetalPurchaseLedgerRepository(AppDatabase()) {
    final now = currentDate ?? DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
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
    startDate = start;
    endDate = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    fetchData();
  }

  List<CustomerMetalPurchaseEntry> entriesForMetal(
    CustomerMetalPurchaseMetal metal, {
    CustomerMetalPurchaseEntryView view =
        CustomerMetalPurchaseEntryView.available,
  }) {
    return entries
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
}
