// =============================================================================
// FILE        : karigar_master_controller.dart
// MODULE      : Karigar
// LAYER       : Logic / Controller
// DESCRIPTION : Manages the Karigar master list — loading, adding, and
//               searching artisans. Shared across Issue, Receive, and Hisaab
//               screens via constructor injection.
//               ChangeNotifier pattern — zero setState in UI.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../repositories/karigar/karigar_repository.dart';
import '../../core/logging/app_logger.dart';

class KarigarMasterController extends ChangeNotifier {
  final KarigarRepository _repo;

  KarigarMasterController(AppDatabase db) : _repo = KarigarRepository(db);

  // ── STATE ──────────────────────────────────────────────────────────────────

  List<KarigarMaster> _allKarigars = [];
  List<KarigarMaster> _filteredKarigars = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // ── GETTERS ────────────────────────────────────────────────────────────────

  List<KarigarMaster> get allKarigars => _allKarigars;
  List<KarigarMaster> get filteredKarigars => _filteredKarigars;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasKarigars => _allKarigars.isNotEmpty;

  // ── LOAD ───────────────────────────────────────────────────────────────────

  Future<void> loadKarigars() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allKarigars = await _repo.getAllKarigars(activeOnly: true);
      _applySearch();
    } catch (e) {
      AppLogger.debug('KarigarMasterController.loadKarigars error: $e');
      _errorMessage = 'Failed to load karigar list. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── SEARCH ─────────────────────────────────────────────────────────────────

  void onSearchChanged(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredKarigars = List.from(_allKarigars);
    } else {
      _filteredKarigars = _allKarigars.where((k) {
        return k.name.toLowerCase().contains(_searchQuery) ||
            k.phone.contains(_searchQuery) ||
            (k.city?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }

  // ── ADD NEW KARIGAR ────────────────────────────────────────────────────────

  Future<KarigarMaster?> addKarigar({
    required String name,
    required String phone,
    String? alternatePhone,
    String specialization = 'All Metals',
    String rateType = 'Per Gram (Rs/g)',
    double rateAmount = 0.0,
    String? address,
    String? city,
    double openingBalance = 0.0,
    String? notes,
  }) async {
    try {
      final companion = KarigarMastersCompanion.insert(
        name: name.trim(),
        phone: phone.trim(),
        alternatePhone: drift.Value(alternatePhone?.trim().isEmpty == true
            ? null
            : alternatePhone?.trim()),
        specialization: drift.Value(specialization),
        rateType: drift.Value(rateType),
        rateAmount: drift.Value(rateAmount),
        address: drift.Value(
            address?.trim().isEmpty == true ? null : address?.trim()),
        city: drift.Value(city?.trim().isEmpty == true ? null : city?.trim()),
        openingBalance: drift.Value(openingBalance),
        notes:
            drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      );

      final id = await _repo.addKarigar(companion);
      final newKarigar = await _repo.getKarigarById(id);

      if (newKarigar != null) {
        _allKarigars.insert(0, newKarigar);
        _applySearch();
        notifyListeners();
        return newKarigar;
      }
      return null;
    } catch (e) {
      AppLogger.debug('KarigarMasterController.addKarigar error: $e');
      return null;
    }
  }
}
