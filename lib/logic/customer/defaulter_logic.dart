// =============================================================================
// FILE        : defaulter_logic.dart
// MODULE      : Risk & Collections
// LAYER       : Controller
// DESCRIPTION : Live data loading, search, filter and sorting orchestration.
// =============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/logging/app_logger.dart';
import '../../models/customer/defaulter_model.dart';
import '../../repositories/customer/defaulter_repository.dart';

class DefaulterLogic extends ChangeNotifier {
  final DefaulterRepository _repository;

  DefaulterLogic({DefaulterRepository? repository})
      : _repository = repository ?? DefaulterRepository();

  DefaulterScreenState _state = DefaulterScreenState.initial();
  DefaulterScreenState get state => _state;

  StreamSubscription<List<DefaulterModel>>? _liveSubscription;

  static final _currencyFmt = NumberFormat('#,##,##0.00', 'en_IN');
  static final _compactFmt = NumberFormat('#,##,##0', 'en_IN');

  static String formatAmount(double amount) =>
      'Rs ${_currencyFmt.format(amount)}';
  static String formatAmountCompact(double amount) =>
      'Rs ${_compactFmt.format(amount)}';

  void init() {
    _startLiveWatch();
  }

  void _startLiveWatch() {
    _liveSubscription?.cancel();
    _liveSubscription = _repository.watchAllDefaulters().listen(
      _applyAll,
      onError: (error) {
        AppLogger.debug('Risk & Collections stream error: $error');
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: 'Collection data could not be loaded. Please refresh.',
        );
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final freshList = await _repository.fetchAllDefaulters();
      _applyAll(freshList);
    } catch (e) {
      AppLogger.debug('Risk & Collections refresh failed: $e');
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Refresh failed. Please check the database connection.',
      );
      notifyListeners();
    }
  }

  void onSearch(String query) {
    _state = _state.copyWith(searchQuery: query);
    _applyFiltersAndSort(_state.allDefaulters);
  }

  void clearSearch() {
    _state = _state.copyWith(searchQuery: '');
    _applyFiltersAndSort(_state.allDefaulters);
  }

  void setFilter(DefaulterFilterBy filter) {
    _state = _state.copyWith(activeFilter: filter);
    _applyFiltersAndSort(_state.allDefaulters);
  }

  void setSort(DefaulterSortBy sort) {
    _state = _state.copyWith(activeSort: sort);
    _applyFiltersAndSort(_state.allDefaulters);
  }

  void _applyAll(List<DefaulterModel> freshList) {
    _state = _state.copyWith(
      allDefaulters: freshList,
      stats: DefaulterStatsModel.fromList(freshList),
      isLoading: false,
      errorMessage: null,
    );

    _applyFiltersAndSort(freshList);
  }

  void _applyFiltersAndSort(List<DefaulterModel> source) {
    var result = List<DefaulterModel>.from(source);

    final query = _state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((d) {
        return d.customerName.toLowerCase().contains(query) ||
            d.mobile.contains(query) ||
            d.referenceNo.toLowerCase().contains(query) ||
            d.city.toLowerCase().contains(query) ||
            d.address.toLowerCase().contains(query) ||
            d.itemSummary.toLowerCase().contains(query) ||
            d.itemName.toLowerCase().contains(query) ||
            d.metalType.toLowerCase().contains(query) ||
            d.purity.toLowerCase().contains(query) ||
            d.statusLabel.toLowerCase().contains(query) ||
            d.collectionStage.toLowerCase().contains(query);
      }).toList();
    }

    switch (_state.activeFilter) {
      case DefaulterFilterBy.critical:
        result = result
            .where((d) => d.riskLevel == DefaulterRiskLevel.critical)
            .toList();
        break;
      case DefaulterFilterBy.high:
        result = result
            .where((d) => d.riskLevel == DefaulterRiskLevel.high)
            .toList();
        break;
      case DefaulterFilterBy.medium:
        result = result
            .where((d) => d.riskLevel == DefaulterRiskLevel.medium)
            .toList();
        break;
      case DefaulterFilterBy.low:
        result =
            result.where((d) => d.riskLevel == DefaulterRiskLevel.low).toList();
        break;
      case DefaulterFilterBy.overdue:
        result = result.where((d) => d.isOverdue).toList();
        break;
      case DefaulterFilterBy.settlementPending:
        result = result.where((d) => d.isSettlementPending).toList();
        break;
      case DefaulterFilterBy.all:
        break;
    }

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
      case DefaulterSortBy.lastActivity:
        result.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
        break;
    }

    _state = _state.copyWith(
      displayedDefaulters: result,
      isLoading: false,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    super.dispose();
  }
}
