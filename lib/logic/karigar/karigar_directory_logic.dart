// =============================================================================
// FILE        : karigar_directory_logic.dart
// MODULE      : Karigar → Karigar Directory
// LAYER       : Logic / Controller
// DESCRIPTION : Main controller for the Karigar Directory list screen.
//               Handles load, search (debounced), filter, sort, refresh,
//               and deactivate. ChangeNotifier — zero setState in UI.
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/karigar/karigar_directory/karigar_directory_enums.dart';
import '../../models/karigar/karigar_directory/karigar_directory_ui_model.dart';
import '../../repositories/karigar/karigar_directory_repository.dart';

class KarigarDirectoryLogic extends ChangeNotifier {
  final KarigarDirectoryRepository _repo;

  KarigarDirectoryLogic({AppDatabase? db})
      : _repo = KarigarDirectoryRepository(db ?? AppDatabase()) {
    _init();
  }

  // ── STATE ──────────────────────────────────────────────────────────────────
  KarigarDirectoryState               _state         = KarigarDirectoryState.loading;
  List<KarigarDirectoryItemModel>     _allKarigars   = [];
  List<KarigarDirectoryItemModel>     _filteredList  = [];
  KarigarDirectoryStatsModel          _stats         = KarigarDirectoryStatsModel.loading();
  KarigarDirectoryFilter              _activeFilter  = KarigarDirectoryFilter.all;
  KarigarDirectorySort                _activeSort    = KarigarDirectorySort.nameAsc;
  String                              _searchQuery   = '';
  String?                             _errorMessage;
  Timer?                              _searchDebounce;

  // ── GETTERS ────────────────────────────────────────────────────────────────
  KarigarDirectoryState           get state         => _state;
  List<KarigarDirectoryItemModel> get karigars      => _filteredList;
  KarigarDirectoryStatsModel      get stats         => _stats;
  KarigarDirectoryFilter          get activeFilter  => _activeFilter;
  KarigarDirectorySort            get activeSort    => _activeSort;
  String                          get searchQuery   => _searchQuery;
  String?                         get errorMessage  => _errorMessage;
  bool                            get isLoading     => _state == KarigarDirectoryState.loading;
  bool                            get isEmpty       => _state == KarigarDirectoryState.empty;
  bool                            get isSearching   => _searchQuery.isNotEmpty;

  // ── INIT ───────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    await _loadStats();
    await _loadKarigars();
  }

  // ── LOAD DATA ──────────────────────────────────────────────────────────────
  Future<void> _loadKarigars() async {
    _state = KarigarDirectoryState.loading;
    notifyListeners();

    try {
      bool? activeOnly;
      if (_activeFilter == KarigarDirectoryFilter.active)   activeOnly = true;
      if (_activeFilter == KarigarDirectoryFilter.inactive) activeOnly = false;

      final data = await _repo.getAllKarigars(activeOnly: activeOnly);

      _allKarigars = data;
      _applyFilterAndSort();

      _state = _filteredList.isEmpty
          ? KarigarDirectoryState.empty
          : KarigarDirectoryState.loaded;
    } catch (e) {
      debugPrint('KarigarDirectoryLogic._loadKarigars error: $e');
      _errorMessage = 'Failed to load karigar list. Please try again.';
      _state        = KarigarDirectoryState.error;
    }
    notifyListeners();
  }

  Future<void> _loadStats() async {
    _stats = await _repo.fetchStats();
    notifyListeners();
  }

  // ── SEARCH ─────────────────────────────────────────────────────────────────
  void onSearchChanged(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () async {
      if (_searchQuery.isEmpty) {
        _applyFilterAndSort();
        _state = _filteredList.isEmpty
            ? KarigarDirectoryState.empty
            : KarigarDirectoryState.loaded;
        notifyListeners();
      } else {
        _state = KarigarDirectoryState.searching;
        notifyListeners();
        final results = await _repo.searchKarigars(_searchQuery);
        _filteredList = results;
        _state = _filteredList.isEmpty
            ? KarigarDirectoryState.empty
            : KarigarDirectoryState.loaded;
        notifyListeners();
      }
    });
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilterAndSort();
    _state = _filteredList.isEmpty
        ? KarigarDirectoryState.empty
        : KarigarDirectoryState.loaded;
    notifyListeners();
  }

  // ── FILTER ─────────────────────────────────────────────────────────────────
  void setFilter(KarigarDirectoryFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    _searchQuery  = '';
    _loadKarigars();
  }

  // ── SORT ───────────────────────────────────────────────────────────────────
  void setSort(KarigarDirectorySort sort) {
    if (_activeSort == sort) return;
    _activeSort = sort;
    _applyFilterAndSort();
    notifyListeners();
  }

  // ── REFRESH ────────────────────────────────────────────────────────────────
  Future<void> refresh() async {
    await _loadStats();
    await _loadKarigars();
  }

  // ── DEACTIVATE / REACTIVATE ────────────────────────────────────────────────
  Future<bool> toggleKarigarStatus(int id, bool newStatus) async {
    final ok = await _repo.setKarigarActiveStatus(id, newStatus);
    if (ok) {
      await _loadStats();
      await _loadKarigars();
    }
    return ok;
  }

  // ── AFTER ADD (refresh when new karigar added) ─────────────────────────────
  Future<void> onKarigarAdded() async {
    await _loadStats();
    await _loadKarigars();
  }

  // ── PRIVATE ────────────────────────────────────────────────────────────────
  void _applyFilterAndSort() {
    List<KarigarDirectoryItemModel> list = List.from(_allKarigars);

    // Apply "with jobs" filter (only here — active/inactive filtered in query)
    if (_activeFilter == KarigarDirectoryFilter.withJobs) {
      list = list.where((k) => k.hasActiveJobs).toList();
    }

    // Apply sort
    switch (_activeSort) {
      case KarigarDirectorySort.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case KarigarDirectorySort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case KarigarDirectorySort.mostJobs:
        list.sort((a, b) => b.activeJobCount.compareTo(a.activeJobCount));
        break;
      case KarigarDirectorySort.highestBalance:
        list.sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));
        break;
    }

    _filteredList = list;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
