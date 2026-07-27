import 'package:flutter/material.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/purchase/metal_inward/metal_inward_entry.dart';
import 'package:lotus_erp/repositories/purchase/metal_inward/metal_inward_ledger_repository.dart';

class MetalInwardLedgerController extends ChangeNotifier {
  final MetalInwardLedgerRepository _repository = MetalInwardLedgerRepository(AppDatabase());

  bool isLoading = false;
  List<MetalInwardEntry> entries = [];
  String? error;

  DateTime? startDate;
  DateTime? endDate;

  MetalInwardLedgerController() {
    // Default to this month
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0);
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      entries = await _repository.fetchMetalInwardLedger(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    startDate = start;
    endDate = end;
    fetchData();
  }

  double get totalGoldGrossWeight => entries
      .where((e) => e.metalType.toUpperCase() == 'GOLD')
      .fold(0.0, (sum, e) => sum + e.grossWeight);

  double get totalGoldFineWeight => entries
      .where((e) => e.metalType.toUpperCase() == 'GOLD')
      .fold(0.0, (sum, e) => sum + e.fineWeight);

  double get totalSilverGrossWeight => entries
      .where((e) => e.metalType.toUpperCase() == 'SILVER')
      .fold(0.0, (sum, e) => sum + e.grossWeight);

  double get totalSilverFineWeight => entries
      .where((e) => e.metalType.toUpperCase() == 'SILVER')
      .fold(0.0, (sum, e) => sum + e.fineWeight);
}
