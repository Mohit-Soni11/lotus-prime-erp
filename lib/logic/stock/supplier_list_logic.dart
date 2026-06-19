// =============================================================================
// FILE        : supplier_list_logic.dart
// MODULE      : Supplier
// LAYER       : Logic / Controller
// DESCRIPTION : ChangeNotifier for Supplier List screen.
//               Pattern identical to CustomerListLogic.
// =============================================================================

import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/stock/supplier_model/supplier_model.dart';
import '../../models/stock/supplier_model/supplier_enums.dart';
import '../../repositories/supplier/supplier_repository.dart';
import '../../core/logging/app_logger.dart';

enum SupplierListState { loading, loaded, empty, error, searching }

class SupplierListLogic extends ChangeNotifier {
  late final SupplierRepository _repo;

  SupplierListLogic() {
    _repo = SupplierRepository(AppDatabase());
    _init();
  }

  // ── STATE ──────────────────────────────────────────────────────────────

  List<SupplierListItemModel> _allSuppliers = [];
  List<SupplierListItemModel> _displayed = [];
  SupplierListState _state = SupplierListState.loading;
  SupplierStats _stats = SupplierStats.loading;
  SupplierFilter _activeFilter = SupplierFilter.all;
  String _searchQuery = '';
  bool _isSearching = false;
  String? _errorMessage;

  // ── GETTERS ────────────────────────────────────────────────────────────

  List<SupplierListItemModel> get suppliers => _displayed;
  SupplierListState get state => _state;
  SupplierStats get stats => _stats;
  SupplierFilter get activeFilter => _activeFilter;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  // ── INIT ───────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await Future.wait([_loadSuppliers(), _loadStats()]);
  }

  Future<void> _loadSuppliers() async {
    _state = SupplierListState.loading;
    notifyListeners();
    try {
      _allSuppliers = await _repo.getAllSuppliers();
      _applyFilterAndSearch();
    } catch (e) {
      _state = SupplierListState.error;
      _errorMessage = 'Failed to load suppliers. Please try again.';
      AppLogger.debug('SupplierListLogic._loadSuppliers: $e');
      notifyListeners();
    }
  }

  Future<void> _loadStats() async {
    try {
      _stats = await _repo.getStats();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refresh() async {
    _searchQuery = '';
    _isSearching = false;
    _activeFilter = SupplierFilter.all;
    await _init();
  }

  // ── SEARCH ─────────────────────────────────────────────────────────────

  void onSearchChanged(String query) {
    _searchQuery = query;
    _isSearching = query.trim().isNotEmpty;
    _applyFilterAndSearch();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _applyFilterAndSearch();
    notifyListeners();
  }

  // ── FILTER ─────────────────────────────────────────────────────────────

  void setFilter(SupplierFilter filter) {
    _activeFilter = filter;
    _applyFilterAndSearch();
    notifyListeners();
  }

  // ── INTERNAL ───────────────────────────────────────────────────────────

  void _applyFilterAndSearch() {
    var result = List<SupplierListItemModel>.from(_allSuppliers);

    // 1. Type filter
    if (_activeFilter != SupplierFilter.all) {
      result = result
          .where((s) => s.supplierType.label == _activeFilter.label)
          .toList();
    }

    // 2. Search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result
          .where((s) =>
              s.businessName.toLowerCase().contains(q) ||
              s.mobile.contains(q) ||
              (s.contactPersonName?.toLowerCase().contains(q) ?? false) ||
              (s.gstNumber?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    _displayed = result;
    _state =
        _displayed.isEmpty ? SupplierListState.empty : SupplierListState.loaded;
  }

  // ── DEACTIVATE ─────────────────────────────────────────────────────────

  Future<bool> deactivateSupplier(int id) async {
    final success = await _repo.deactivateSupplier(id);
    if (success) await _loadSuppliers();
    return success;
  }
}
