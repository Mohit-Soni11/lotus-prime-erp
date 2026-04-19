// ==========================================
// FILE: defaulter_logic.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: Business logic controller (ChangeNotifier pattern).
//              Handles: data loading, filtering, sorting, search.
//              UI widgets listen via ChangeNotifierProvider or setState.
// ==========================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../models/customer/defaulter_model.dart';
import '../../../repositories/customer/defaulter_repository.dart';

class DefaulterLogic extends ChangeNotifier {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  final DefaulterRepository _repository;

  DefaulterLogic({DefaulterRepository? repository})
      : _repository = repository ?? DefaulterRepository();

  // ==========================================
  // STATE
  // ==========================================
  DefaulterScreenState _state = DefaulterScreenState.initial();
  DefaulterScreenState get state => _state;

  StreamSubscription<List<DefaulterModel>>? _liveSubscription;

  // ==========================================
  // FORMATTERS
  // ==========================================
  static final _currencyFmt = NumberFormat('#,##,##0.00', 'en_IN');
  static final _compactFmt  = NumberFormat('#,##,##0', 'en_IN');

  static String formatAmount(double amount) => '₹${_currencyFmt.format(amount)}';
  static String formatAmountCompact(double amount) => '₹${_compactFmt.format(amount)}';

  // ==========================================
  // LIFECYCLE: init (call from State.initState)
  // ==========================================
  void init() {
    _startLiveWatch();
  }

  // ==========================================
  // LIVE WATCH (real-time DB stream)
  // ==========================================
  void _startLiveWatch() {
    _liveSubscription?.cancel();

    _liveSubscription = _repository.watchAllDefaulters().listen(
      (freshList) {
        _applyAll(freshList);
      },
      onError: (error) {
        debugPrint('❌ DefaulterLogic stream error: $error');
        _state = _state.copyWith(
          isLoading:    false,
          errorMessage: 'Failed to load data. Please refresh.',
        );
        notifyListeners();
      },
    );
  }

  // ==========================================
  // MANUAL REFRESH
  // ==========================================
  Future<void> refresh() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final freshList = await _repository.fetchAllDefaulters();
      _applyAll(freshList);
    } catch (e) {
      debugPrint('❌ DefaulterLogic.refresh Error: $e');
      _state = _state.copyWith(
        isLoading:    false,
        errorMessage: 'Refresh failed. Check connection.',
      );
      notifyListeners();
    }
  }

  // ==========================================
  // SEARCH
  // ==========================================
  void onSearch(String query) {
    _state = _state.copyWith(searchQuery: query);
    _applyFiltersAndSort(_state.allDefaulters);
  }

  void clearSearch() {
    _state = _state.copyWith(searchQuery: '');
    _applyFiltersAndSort(_state.allDefaulters);
  }

  // ==========================================
  // FILTER
  // ==========================================
  void setFilter(DefaulterFilterBy filter) {
    _state = _state.copyWith(activeFilter: filter);
    _applyFiltersAndSort(_state.allDefaulters);
  }

  // ==========================================
  // SORT
  // ==========================================
  void setSort(DefaulterSortBy sort) {
    _state = _state.copyWith(activeSort: sort);
    _applyFiltersAndSort(_state.allDefaulters);
  }

  // ==========================================
  // INTERNAL: Apply all filters + sort + search
  // ==========================================
  void _applyAll(List<DefaulterModel> freshList) {
    final stats = DefaulterStatsModel.fromList(freshList);

    _state = _state.copyWith(
      allDefaulters: freshList,
      stats:         stats,
      isLoading:     false,
      errorMessage:  null,
    );

    _applyFiltersAndSort(freshList);
  }

  void _applyFiltersAndSort(List<DefaulterModel> source) {
    List<DefaulterModel> result = List.from(source);

    // 1. Apply search
    final query = _state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((d) {
        return d.customerName.toLowerCase().contains(query) ||
               d.mobile.contains(query) ||
               d.referenceNo.toLowerCase().contains(query) ||
               d.city.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Apply filter
    switch (_state.activeFilter) {
      case DefaulterFilterBy.critical:
        result = result.where((d) => d.riskLevel == DefaulterRiskLevel.critical).toList();
        break;
      case DefaulterFilterBy.high:
        result = result.where((d) => d.riskLevel == DefaulterRiskLevel.high).toList();
        break;
      case DefaulterFilterBy.medium:
        result = result.where((d) => d.riskLevel == DefaulterRiskLevel.medium).toList();
        break;
      case DefaulterFilterBy.low:
        result = result.where((d) => d.riskLevel == DefaulterRiskLevel.low).toList();
        break;
      case DefaulterFilterBy.loanOnly:
        result = result.where((d) => d.defaulterType == DefaulterType.loan).toList();
        break;
      case DefaulterFilterBy.all:
        break;
    }

    // 3. Apply sort
    switch (_state.activeSort) {
      case DefaulterSortBy.daysOverdue:
        result.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
        break;
      case DefaulterSortBy.amountDue:
        result.sort((a, b) => b.totalDue.compareTo(a.totalDue));
        break;
      case DefaulterSortBy.customerName:
        result.sort((a, b) => a.customerName.compareTo(b.customerName));
        break;
    }

    _state = _state.copyWith(
      displayedDefaulters: result,
      isLoading: false,
    );
    notifyListeners();
  }

  // ==========================================
  // LIFECYCLE: dispose
  // ==========================================
  @override
  void dispose() {
    _liveSubscription?.cancel();
    super.dispose();
  }
}