import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/features/stock/shared/data/repositories/market_refill_report_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/market_refill/market_refill_models.dart';

enum MarketRefillPreset { thisMonth, last7Days, last30Days, allTime }

class MarketRefillReportController extends ChangeNotifier {
  final MarketRefillReportRepository _repository;

  MarketRefillReportController(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  MarketRefillPreset _preset = MarketRefillPreset.thisMonth;
  MarketRefillReport _report =
      MarketRefillReport.empty(_rangeFor(MarketRefillPreset.thisMonth));

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MarketRefillPreset get preset => _preset;
  MarketRefillReport get report => _report;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final range = _rangeFor(_preset);
      _report = await _repository.loadReport(range);
    } catch (_) {
      _report = MarketRefillReport.empty(_rangeFor(_preset));
      _errorMessage = 'Market refill report could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectPreset(MarketRefillPreset preset) async {
    if (_preset == preset) return;
    _preset = preset;
    await load();
  }

  Future<String> exportCsv(String path) async {
    final exportPath = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    final csv = _repository.buildCsv(_report);
    await File(exportPath).writeAsString(csv);
    return exportPath;
  }

  String suggestedFileName() {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'lotus_market_refill_${_preset.name}_$stamp.csv';
  }

  static MarketRefillDateRange _rangeFor(MarketRefillPreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    switch (preset) {
      case MarketRefillPreset.thisMonth:
        return MarketRefillDateRange(
          start: DateTime(now.year, now.month),
          end: DateTime(now.year, now.month + 1),
          label: 'This Month',
        );
      case MarketRefillPreset.last7Days:
        return MarketRefillDateRange(
          start: today.subtract(const Duration(days: 6)),
          end: tomorrow,
          label: 'Last 7 Days',
        );
      case MarketRefillPreset.last30Days:
        return MarketRefillDateRange(
          start: today.subtract(const Duration(days: 29)),
          end: tomorrow,
          label: 'Last 30 Days',
        );
      case MarketRefillPreset.allTime:
        return MarketRefillDateRange(
          start: DateTime(2000),
          end: tomorrow,
          label: 'All Time',
        );
    }
  }
}
