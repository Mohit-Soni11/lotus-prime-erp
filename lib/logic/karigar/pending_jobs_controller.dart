// =============================================================================
// FILE        : pending_jobs_controller.dart
// MODULE      : Karigar
// LAYER       : Logic / Controller
// DESCRIPTION : Drives the Pending Jobs screen. Loads all open karigar issues,
//               computes overall stats for the summary header, and provides
//               real-time search + filter (All, Pending, In Progress, Overdue).
//               Quick status updates are also handled here.
// =============================================================================

import 'package:flutter/foundation.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/karigar/karigar_enums/karigar_enums.dart';
import '../../models/karigar/karigar_issue_model.dart';
import '../../models/karigar/karigar_stats_model.dart';
import '../../repositories/karigar/karigar_repository.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class PendingJobsController extends ChangeNotifier {
  final KarigarRepository _repo;

  PendingJobsController(AppDatabase db) : _repo = KarigarRepository(db);

  // ── STATE ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _errorMessage;

  List<KarigarIssueWithKarigar> _allJobs = [];
  List<KarigarIssueWithKarigar> _filteredJobs = [];
  OverallKarigarStats _stats = OverallKarigarStats.empty();

  String _searchQuery = '';
  PendingJobsFilter _activeFilter = PendingJobsFilter.all;

  // ── GETTERS ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasJobs => _filteredJobs.isNotEmpty;

  List<KarigarIssueWithKarigar> get filteredJobs => _filteredJobs;
  OverallKarigarStats get stats => _stats;
  PendingJobsFilter get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;

  // ── LOAD ───────────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.getAllIssuesWithKarigar(),
        _repo.getOverallStats(),
      ]);

      _allJobs = results[0] as List<KarigarIssueWithKarigar>;
      _stats = results[1] as OverallKarigarStats;
      _applyFilterAndSearch();
    } catch (e) {
      AppLogger.debug('PendingJobsController.loadData error: $e');
      _errorMessage = 'Failed to load pending jobs. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── FILTER & SEARCH ────────────────────────────────────────────────────────

  void onFilterChanged(PendingJobsFilter filter) {
    _activeFilter = filter;
    _applyFilterAndSearch();
    notifyListeners();
  }

  void onSearchChanged(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilterAndSearch();
    notifyListeners();
  }

  void _applyFilterAndSearch() {
    var result = List<KarigarIssueWithKarigar>.from(_allJobs);

    // Apply status filter
    switch (_activeFilter) {
      case PendingJobsFilter.all:
        // Show only active (not completed/cancelled)
        result = result.where((j) => j.statusEnum.isActive).toList();
        break;
      case PendingJobsFilter.pending:
        result =
            result.where((j) => j.statusEnum == IssueStatus.pending).toList();
        break;
      case PendingJobsFilter.inProgress:
        result = result
            .where((j) => j.statusEnum == IssueStatus.inProgress)
            .toList();
        break;
      case PendingJobsFilter.overdue:
        result = result.where((j) => j.isOverdue).toList();
        break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      result = result.where((j) {
        return j.karigarName.toLowerCase().contains(_searchQuery) ||
            j.issueNumber.toLowerCase().contains(_searchQuery) ||
            j.itemDescription.toLowerCase().contains(_searchQuery) ||
            j.metalType.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Sort: overdue first, then by issue date descending
    result.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return b.issueDate.compareTo(a.issueDate);
    });

    _filteredJobs = result;
  }

  // ── QUICK STATUS UPDATE ───────────────────────────────────────────────────

  Future<bool> markInProgress(int issueId) async {
    return _updateStatus(issueId, IssueStatus.inProgress);
  }

  Future<bool> markCancelled(int issueId) async {
    return _updateStatus(issueId, IssueStatus.cancelled);
  }

  Future<bool> _updateStatus(int issueId, IssueStatus newStatus) async {
    try {
      final success = await _repo.updateIssueStatus(issueId, newStatus);
      if (success) await loadData(); // Refresh list
      return success;
    } catch (e) {
      AppLogger.debug('PendingJobsController._updateStatus error: $e');
      return false;
    }
  }

  // ── REFRESH ────────────────────────────────────────────────────────────────

  Future<void> refresh() async => loadData();
}
