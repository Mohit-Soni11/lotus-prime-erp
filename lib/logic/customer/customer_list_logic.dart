// -----------------------------------------------------------------------------
// FILE: customer_list_logic.dart
// MODULE: Customer → Customer List
// DESCRIPTION: Main controller. Handles search, filter, sort, and state.
//              Uses ChangeNotifier for zero-lag UI updates.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../models/customer/customer_enums/customer_list_enums.dart';
import '../../repositories/customer/customer_list_repository.dart';

class CustomerListLogic extends ChangeNotifier {
  final CustomerListRepository _repo;

  CustomerListLogic({CustomerListRepository? repo})
      : _repo = repo ?? CustomerListRepository() {
    _init();
  }

  // ── STATE ─────────────────────────────────────────────────────────────────
  CustomerListState _state = CustomerListState.loading;
  List<CustomerListItemModel> _allCustomers = [];
  List<CustomerListItemModel> _filteredList = [];
  CustomerListStatsModel _stats = CustomerListStatsModel.loading();
  CustomerFilter _activeFilter = CustomerFilter.all;
  CustomerSort _activeSort = CustomerSort.newest;
  String _searchQuery = "";
  String? _errorMessage;

  // ── GETTERS ──────────────────────────────────────────────────────────────
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

  // Search debounce timer
  Timer? _searchDebounce;

  // ── INIT ─────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    await _loadStats();
    await _loadCustomers();
  }

  // ── LOAD DATA ────────────────────────────────────────────────────────────
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
    } catch (e) {
      debugPrint("❌ CustomerListLogic Error: $e");
      _errorMessage = "Failed to load customers. Please try again.";
      _state = CustomerListState.error;
    }

    notifyListeners();
  }

  Future<void> _loadStats() async {
    _stats = await _repo.fetchStats();
    notifyListeners();
  }

  // ── SEARCH ────────────────────────────────────────────────────────────────
  void onSearchChanged(String query) {
    _searchQuery = query;

    // Debounce: wait 300ms after user stops typing
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (_searchQuery.isEmpty) {
        _applySearch();
        _state = _filteredList.isEmpty
            ? CustomerListState.empty
            : CustomerListState.loaded;
        notifyListeners();
      } else {
        _state = CustomerListState.searching;
        notifyListeners();

        final results = await _repo.searchCustomers(_searchQuery);
        _filteredList = results;
        _state = _filteredList.isEmpty
            ? CustomerListState.empty
            : CustomerListState.loaded;
        notifyListeners();
      }
    });
  }

  void clearSearch() {
    _searchQuery = "";
    _applySearch();
    _state = _filteredList.isEmpty
        ? CustomerListState.empty
        : CustomerListState.loaded;
    notifyListeners();
  }

  // ── FILTER ────────────────────────────────────────────────────────────────
  void setFilter(CustomerFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    _searchQuery = "";
    _loadCustomers();
  }

  // ── SORT ──────────────────────────────────────────────────────────────────
  void setSort(CustomerSort sort) {
    if (_activeSort == sort) return;
    _activeSort = sort;
    _loadCustomers();
  }

  // ── REFRESH ───────────────────────────────────────────────────────────────
  Future<void> refresh() async {
    await _loadStats();
    await _loadCustomers();
  }

  // ── PRIVATE ───────────────────────────────────────────────────────────────
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredList = List.from(_allCustomers);
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredList = _allCustomers
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.mobile.contains(q) ||
              c.city.toLowerCase().contains(q))
          .toList();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
