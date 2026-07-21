import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/features/stock/shared/data/repositories/market_refill_report_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/market_refill/market_refill_models.dart';

class MarketRefillReportController extends ChangeNotifier {
  final MarketRefillReportRepository _repository;

  MarketRefillReportController(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  MarketRefillReport _report = MarketRefillReport.empty(_activeRange());

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MarketRefillReport get report => _report;
  List<MarketRefillCheckoutRecord> get recentCheckouts =>
      _report.recentCheckouts;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await _repository.loadActiveReport();
    } catch (_) {
      _report = MarketRefillReport.empty(_activeRange());
      _errorMessage = 'Market refill report could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkoutAndClear() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.checkoutAndClear(report: _report);
    } catch (_) {
      _errorMessage = 'Market refill list could not be checked out.';
    } finally {
      _isLoading = false;
    }
    await load();
  }

  Future<void> restoreClearedList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.restoreClearedList();
    } catch (_) {
      _errorMessage = 'Market refill list could not be restored.';
    } finally {
      _isLoading = false;
    }
    await load();
  }

  Future<void> updateLineProgress(
    MarketRefillItemRow row, {
    int? boughtQuantity,
    bool? purchaseDone,
  }) async {
    final nextBoughtQuantity = boughtQuantity ?? row.boughtQuantity;
    final nextPurchaseDone = purchaseDone ?? row.purchaseDone;
    await _repository.saveLineProgress(
      progressScope: _report.progressScope,
      rowKey: row.rowKey,
      boughtQuantity: nextBoughtQuantity,
      purchaseDone: nextPurchaseDone,
    );
    final rows = [
      for (final current in _report.rows)
        current.rowKey == row.rowKey
            ? current.copyWith(
                boughtQuantity: nextBoughtQuantity,
                purchaseDone: nextPurchaseDone,
              )
            : current,
    ];
    _report = MarketRefillReport(
      range: _report.range,
      summary: _report.summary,
      metals: _report.metals,
      rows: rows,
      recentCheckouts: _report.recentCheckouts,
      progressScope: _report.progressScope,
      lastClearedAt: _report.lastClearedAt,
    );
    notifyListeners();
  }

  Future<String> exportCsv(String path) async {
    final exportPath = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    final csv = _repository.buildCsv(_report);
    await File(exportPath).writeAsString(csv);
    return exportPath;
  }

  String suggestedFileName() {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'lotus_market_refill_active_$stamp.csv';
  }

  static MarketRefillDateRange _activeRange() {
    final now = DateTime.now();
    return MarketRefillDateRange(
      start: DateTime(2000),
      end: now.add(const Duration(days: 1)),
      label: 'Active Purchase List',
    );
  }
}
