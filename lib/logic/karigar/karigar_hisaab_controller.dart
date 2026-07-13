// =============================================================================
// FILE        : karigar_hisaab_controller.dart
// MODULE      : Karigar
// LAYER       : Logic / Controller
// DESCRIPTION : Drives the Karigar Hisaab (Ledger) screen.
//               Manages the karigar list in the left panel, karigar selection,
//               chronological transaction timeline, and per-karigar stats for
//               the summary cards on the right panel.
// =============================================================================

import 'package:flutter/foundation.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/karigar/karigar_issue_model.dart';
import '../../models/karigar/karigar_stats_model.dart';
import '../../repositories/karigar/karigar_repository.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class KarigarHisaabController extends ChangeNotifier {
  final KarigarRepository _repo;

  KarigarHisaabController(AppDatabase db) : _repo = KarigarRepository(db);

  // ── STATE ──────────────────────────────────────────────────────────────────

  bool _isLoadingKarigars = false;
  bool _isLoadingLedger = false;
  String? _errorMessage;

  // Left panel — karigar list
  List<KarigarMaster> _allKarigars = [];
  List<KarigarMaster> _filteredKarigars = [];
  String _karigarSearch = '';

  // Right panel — selected karigar
  KarigarMaster? _selectedKarigar;
  List<KarigarTxnEntry> _ledgerEntries = [];
  KarigarStatsModel _stats = KarigarStatsModel.empty();

  // ── GETTERS ────────────────────────────────────────────────────────────────

  bool get isLoadingKarigars => _isLoadingKarigars;
  bool get isLoadingLedger => _isLoadingLedger;
  String? get errorMessage => _errorMessage;

  List<KarigarMaster> get filteredKarigars => _filteredKarigars;
  KarigarMaster? get selectedKarigar => _selectedKarigar;
  List<KarigarTxnEntry> get ledgerEntries => _ledgerEntries;
  KarigarStatsModel get stats => _stats;
  bool get hasKarigar => _selectedKarigar != null;
  bool get hasEntries => _ledgerEntries.isNotEmpty;

  // ── LOAD KARIGAR LIST ──────────────────────────────────────────────────────

  Future<void> loadKarigars() async {
    _isLoadingKarigars = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allKarigars = await _repo.getAllKarigars(activeOnly: false);
      _applyKarigarSearch();

      // Auto-select first karigar if none selected
      if (_selectedKarigar == null && _allKarigars.isNotEmpty) {
        await selectKarigar(_allKarigars.first);
        return; // selectKarigar calls notifyListeners
      }
    } catch (e) {
      AppLogger.debug('KarigarHisaabController.loadKarigars error: $e');
      _errorMessage = 'Failed to load karigar list.';
    } finally {
      _isLoadingKarigars = false;
      notifyListeners();
    }
  }

  // ── SELECT KARIGAR ─────────────────────────────────────────────────────────

  Future<void> selectKarigar(KarigarMaster karigar) async {
    _selectedKarigar = karigar;
    _isLoadingLedger = true;
    _ledgerEntries = [];
    _stats = KarigarStatsModel.empty();
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.getKarigarLedger(karigar.id),
        _repo.getKarigarStats(karigar.id,
            openingBalance: karigar.openingBalance),
      ]);
      _ledgerEntries = results[0] as List<KarigarTxnEntry>;
      _stats = results[1] as KarigarStatsModel;
    } catch (e) {
      AppLogger.debug('KarigarHisaabController.selectKarigar error: $e');
      _errorMessage = 'Failed to load ledger for ${karigar.name}.';
    } finally {
      _isLoadingLedger = false;
      notifyListeners();
    }
  }

  // ── KARIGAR SEARCH ─────────────────────────────────────────────────────────

  void onKarigarSearchChanged(String query) {
    _karigarSearch = query.toLowerCase().trim();
    _applyKarigarSearch();
    notifyListeners();
  }

  void _applyKarigarSearch() {
    if (_karigarSearch.isEmpty) {
      _filteredKarigars = List.from(_allKarigars);
    } else {
      _filteredKarigars = _allKarigars.where((k) {
        return k.name.toLowerCase().contains(_karigarSearch) ||
            k.phone.contains(_karigarSearch);
      }).toList();
    }
  }

  // ── REFRESH ────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    await loadKarigars();
    if (_selectedKarigar != null) {
      await selectKarigar(_selectedKarigar!);
    }
  }
}
