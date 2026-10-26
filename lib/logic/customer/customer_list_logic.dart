// -----------------------------------------------------------------------------
// FILE: customer_list_logic.dart
// MODULE: Customer -> Customer List
// DESCRIPTION: Controller for search, filter, sort, refresh, and UI state.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/customer/customer_enums/customer_list_enums.dart';
import '../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../repositories/customer/customer_list_repository.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class CustomerListLogic extends ChangeNotifier {
  final CustomerListRepository _repo;

  CustomerListLogic({CustomerListRepository? repo})
      : _repo = repo ?? CustomerListRepository() {
    _init();
  }

  CustomerListState _state = CustomerListState.loading;
  List<CustomerListItemModel> _sourceCustomers = [];
  List<CustomerListItemModel> _allCustomers = [];
  List<CustomerListItemModel> _filteredList = [];
  CustomerListStatsModel _stats = CustomerListStatsModel.loading();
  CustomerFilter _activeFilter = CustomerFilter.all;
  CustomerSort _activeSort = CustomerSort.newest;
  String _searchQuery = "";
  String? _errorMessage;
  Timer? _searchDebounce;
  int _requestId = 0;
  bool _isDisposed = false;

  CustomerListState get state => _state;
  List<CustomerListItemModel> get customers => _filteredList;
  CustomerListStatsModel get stats => _stats;
  CustomerFilter get activeFilter => _activeFilter;
  CustomerSort get activeSort => _activeSort;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == CustomerListState.loading;
  bool get isEmpty => _state == CustomerListState.empty;
  bool get isSearching => _searchQuery.isNotEmpty;
  int get totalLoadedCount => _allCustomers.length;

  Future<void> _init() async {
    await refresh();
  }

  void onSearchChanged(String query) {
    _searchQuery = query.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (_isDisposed ||
          _state == CustomerListState.loading ||
          _state == CustomerListState.error) {
        return;
      }
      _applySearch();
      _state = _filteredList.isEmpty
          ? CustomerListState.empty
          : CustomerListState.loaded;
      notifyListeners();
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _searchQuery = "";
    if (_state == CustomerListState.loading ||
        _state == CustomerListState.error) {
      notifyListeners();
      return;
    }
    _applySearch();
    _state = _filteredList.isEmpty
        ? CustomerListState.empty
        : CustomerListState.loaded;
    notifyListeners();
  }

  void setFilter(CustomerFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    _searchDebounce?.cancel();
    _searchQuery = "";
    if (_state == CustomerListState.error) {
      refresh();
      return;
    }
    if (_state != CustomerListState.loading &&
        _state != CustomerListState.error) {
      _rebuildVisibleCustomers();
    }
    notifyListeners();
  }

  void setSort(CustomerSort sort) {
    if (_activeSort == sort) return;
    _activeSort = sort;
    if (_state == CustomerListState.error) {
      refresh();
      return;
    }
    if (_state != CustomerListState.loading &&
        _state != CustomerListState.error) {
      _rebuildVisibleCustomers();
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    final requestId = ++_requestId;
    _state = CustomerListState.loading;
    notifyListeners();

    try {
      final allCustomers =
          await _repo.getAllCustomers(sort: CustomerSort.newest);
      if (_isDisposed || requestId != _requestId) return;
      _sourceCustomers = allCustomers;
      _stats = CustomerListStatsModel.fromCustomers(allCustomers);
      _rebuildVisibleCustomers();
      _errorMessage = null;
    } catch (error, stackTrace) {
      if (_isDisposed || requestId != _requestId) return;
      AppLogger.error(
        'Customer list refresh failed.',
        error: error,
        stackTrace: stackTrace,
      );
      _stats = CustomerListStatsModel.empty();
      _errorMessage = "Failed to refresh customers. Please try again.";
      _state = CustomerListState.error;
    }

    notifyListeners();
  }

  void _rebuildVisibleCustomers() {
    _allCustomers = _repo.filterAndSort(
      _sourceCustomers,
      filter: _activeFilter,
      sort: _activeSort,
    );
    _applySearch();
    _state = _filteredList.isEmpty
        ? CustomerListState.empty
        : CustomerListState.loaded;
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredList = List<CustomerListItemModel>.from(_allCustomers);
      return;
    }

    final query = _searchQuery.toLowerCase();
    _filteredList = _allCustomers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.mobile.toLowerCase().contains(query) ||
          customer.city.toLowerCase().contains(query) ||
          customer.type.value.toLowerCase().contains(query) ||
          customer.type.displayLabel.toLowerCase().contains(query) ||
          customer.lastActivityLabel.toLowerCase().contains(query) ||
          customer.lastActivityDetail.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _requestId++;
    _searchDebounce?.cancel();
    super.dispose();
  }
}
