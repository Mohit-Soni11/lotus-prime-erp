import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/logging/app_logger.dart';
import '../../../models/reports/sales_report/sales_report_models.dart';
import '../../../repositories/reports/sales_report_repository.dart';

class SalesReportController extends ChangeNotifier {
  SalesReportController({
    SalesReportRepository? repository,
    SalesReportFilter? initialFilter,
  })  : _repository = repository ?? SalesReportRepository(),
        _filter = initialFilter ?? SalesReportFilter.initial() {
    load();
  }

  final SalesReportRepository _repository;
  final TextEditingController searchController = TextEditingController();

  SalesReportFilter _filter;
  SalesReportSnapshot? _snapshot;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0;
  int _loadGeneration = 0;
  Timer? _searchDebounce;
  bool _disposed = false;

  SalesReportFilter get filter => _filter;
  SalesReportSnapshot? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedTab => _selectedTab;

  Future<void> load({bool silent = false}) async {
    final generation = ++_loadGeneration;
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      _notify();
    }

    try {
      final snapshot = await _repository.fetchReport(_filter);
      if (_isStale(generation)) return;
      _snapshot = snapshot;
      _errorMessage = null;
    } catch (error, stackTrace) {
      if (_isStale(generation)) return;
      AppLogger.error('SalesReportController.load failed: $error');
      AppLogger.debug(stackTrace.toString());
      _errorMessage = 'Unable to load sales report.';
      _snapshot ??= SalesReportSnapshot.empty(_filter);
    } finally {
      if (!_isStale(generation)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  void selectTab(int index) {
    if (_selectedTab == index) return;
    _selectedTab = index;
    _notify();
  }

  void applyPreset(SalesReportDatePreset preset) {
    final now = DateTime.now();
    late final DateTime start;
    late final DateTime end;

    switch (preset) {
      case SalesReportDatePreset.today:
        start = DateTime(now.year, now.month, now.day);
        end = _endOfDay(start);
        break;
      case SalesReportDatePreset.yesterday:
        start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 1));
        end = _endOfDay(start);
        break;
      case SalesReportDatePreset.thisMonth:
        start = DateTime(now.year, now.month);
        end = _endOfDay(DateTime(now.year, now.month + 1, 0));
        break;
      case SalesReportDatePreset.lastMonth:
        start = DateTime(now.year, now.month - 1);
        end = _endOfDay(DateTime(now.year, now.month, 0));
        break;
      case SalesReportDatePreset.custom:
        return;
    }

    _filter = _filter.copyWith(
      preset: preset,
      startDate: start,
      endDate: end,
    );
    load();
  }

  void setReportMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = _endOfDay(DateTime(month.year, month.month + 1, 0));
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final previousMonth = DateTime(now.year, now.month - 1);

    final preset = start == currentMonth
        ? SalesReportDatePreset.thisMonth
        : start == previousMonth
            ? SalesReportDatePreset.lastMonth
            : SalesReportDatePreset.custom;

    _filter = _filter.copyWith(
      preset: preset,
      startDate: start,
      endDate: end,
    );
    load();
  }

  void shiftReportMonth(int monthOffset) {
    setReportMonth(
      DateTime(
        _filter.startDate.year,
        _filter.startDate.month + monthOffset,
      ),
    );
  }

  Future<void> selectCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _filter.startDate,
        end: _filter.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFFD4AF37),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    _filter = _filter.copyWith(
      preset: SalesReportDatePreset.custom,
      startDate: picked.start,
      endDate: picked.end,
    );
    load();
  }

  void setTaxMode(SalesReportTaxMode value) {
    if (_filter.taxMode == value) return;
    _filter = _filter.copyWith(taxMode: value);
    load();
  }

  void setPaymentFilter(SalesReportPaymentFilter value) {
    if (_filter.paymentFilter == value) return;
    _filter = _filter.copyWith(paymentFilter: value);
    load();
  }

  void setMetalType(String value) {
    final normalized = value.trim().isEmpty ? 'ALL' : value.trim();
    if (_filter.metalType.toUpperCase() == normalized.toUpperCase()) return;
    _filter = _filter.copyWith(metalType: normalized);
    load();
  }

  void applySearch() {
    _searchDebounce?.cancel();
    final query = searchController.text.trim();
    if (_filter.query == query) return;
    _filter = _filter.copyWith(query: query);
    load();
  }

  void scheduleSearch({
    Duration delay = const Duration(milliseconds: 320),
  }) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, applySearch);
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    if (searchController.text.isEmpty && _filter.query.isEmpty) return;
    searchController.clear();
    _filter = _filter.copyWith(query: '');
    load();
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  bool _isStale(int generation) {
    return _disposed || generation != _loadGeneration;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
