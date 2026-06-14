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

class CustomerListLogic extends ChangeNotifier {
  final CustomerListRepository _repo;

  CustomerListLogic({CustomerListRepository? repo})
      : _repo = repo ?? CustomerListRepository() {
    _init();
  }

  CustomerListState _state = CustomerListState.loading;
  List<CustomerListItemModel> _allCustomers = [];
  List<CustomerListItemModel> _filteredList = [];
  CustomerListStatsModel _stats = CustomerListStatsModel.loading();
  CustomerFilter _activeFilter = CustomerFilter.all;
  CustomerSort _activeSort = CustomerSort.newest;
  String _searchQuery = "";
  String? _errorMessage;
  Timer? _searchDebounce;

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

  Future<void> _loadCustomers() async {
    _state = CustomerListState.loading;
    notifyListeners();

    try {
      final data = await _repo.getAllCustomers(
        filter: _activeFilter,
        sort: _activeSort,
      );

      _allCustomers = data;
      _applySearch();
      _state = _filteredList.isEmpty
          ? CustomerListState.empty
          : CustomerListState.loaded;
      _errorMessage = null;
    } catch (e) {
      debugPrint("CustomerListLogic load error: $e");
      _errorMessage = "Failed to load clients. Please try again.";
      _state = CustomerListState.error;
    }

    notifyListeners();
  }

  void onSearchChanged(String query) {
    _searchQuery = query.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
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
    _applySearch();
    _state = _filteredList.isEmpty
        ? CustomerListState.empty
        : CustomerListState.loaded;
    notifyListeners();
  }

  void setFilter(CustomerFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    _searchQuery = "";
    _loadCustomers();
  }

  void setSort(CustomerSort sort) {
    if (_activeSort == sort) return;
    _activeSort = sort;
    _loadCustomers();
  }

  Future<void> refresh() async {
    _state = CustomerListState.loading;
    notifyListeners();

    try {
      final allCustomers =
          await _repo.getAllCustomers(sort: CustomerSort.newest);
      _stats = CustomerListStatsModel.fromCustomers(allCustomers);

      if (_activeFilter == CustomerFilter.all &&
          _activeSort == CustomerSort.newest) {
        _allCustomers = allCustomers;
      } else {
        _allCustomers = await _repo.getAllCustomers(
          filter: _activeFilter,
          sort: _activeSort,
        );
      }

      _applySearch();
      _state = _filteredList.isEmpty
          ? CustomerListState.empty
          : CustomerListState.loaded;
      _errorMessage = null;
    } catch (e) {
      debugPrint("CustomerListLogic refresh error: $e");
      _stats = CustomerListStatsModel.empty();
      _errorMessage = "Failed to refresh clients. Please try again.";
      _state = CustomerListState.error;
    }

    notifyListeners();
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
    _searchDebounce?.cancel();
    super.dispose();
  }
}
