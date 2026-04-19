// =============================================================================
// FILE        : girvi_list_controller.dart
// MODULE      : Girvi / Pawn
// LAYER       : Logic / Controller
// DESCRIPTION : Manages the Girvi list screen state.
//               Loads all loans with customer join, supports filtering by
//               status, text search, and triggers overdue sync on load.
// =============================================================================

import 'package:flutter/foundation.dart';
import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../repositories/girvi/girvi_repository.dart';

class GirviListController extends ChangeNotifier {

  final GirviRepository _repo;

  GirviListController(AppDatabase db) : _repo = GirviRepository(db);

  // ── STATE ──────────────────────────────────────────────────────────────────
  List<GirviLoanWithCustomer> _allLoans      = [];
  List<GirviLoanWithCustomer> _filteredLoans = [];
  GirviSummaryModel           _summary       = GirviSummaryModel.empty();
  GirviFilter                 _filter        = GirviFilter.all;
  String                      _searchQuery   = '';
  bool                        _isLoading     = true;
  String?                     _errorMessage;

  // ── GETTERS ────────────────────────────────────────────────────────────────
  List<GirviLoanWithCustomer> get loans       => _filteredLoans;
  GirviSummaryModel           get summary     => _summary;
  GirviFilter                 get filter      => _filter;
  bool                        get isLoading   => _isLoading;
  String?                     get errorMessage => _errorMessage;
  bool                        get hasLoans    => _allLoans.isNotEmpty;

  // ── LOAD ───────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sync overdue status
      await _repo.syncOverdueStatus();

      // Load all loans + summary in parallel
      final results = await Future.wait([
        _repo.getLoansWithCustomer(),
        _repo.getSummary(),
      ]);

      _allLoans = results[0] as List<GirviLoanWithCustomer>;
      _summary  = results[1] as GirviSummaryModel;
      _applyFilter();
    } catch (e) {
      debugPrint('GirviListController.load error: $e');
      _errorMessage = 'Failed to load girvi data. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── FILTER ─────────────────────────────────────────────────────────────────

  void setFilter(GirviFilter f) {
    _filter = f;
    _applyFilter();
    notifyListeners();
  }

  void onSearchChanged(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    var list = List<GirviLoanWithCustomer>.from(_allLoans);

    // Status filter
    if (_filter != GirviFilter.all) {
      list = list.where((g) {
        switch (_filter) {
          case GirviFilter.active:
            return g.loan.isActive && !g.loan.isOverdue;
          case GirviFilter.overdue:
            return g.loan.isOverdue || g.loan.girviStatus == GirviStatus.overdue;
          case GirviFilter.released:
            return g.loan.girviStatus == GirviStatus.released;
          case GirviFilter.auctioned:
            return g.loan.girviStatus == GirviStatus.auctioned;
          default:
            return true;
        }
      }).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      list = list.where((g) =>
        g.loan.ticketNo.toLowerCase().contains(_searchQuery)  ||
        g.customerName.toLowerCase().contains(_searchQuery)   ||
        g.customerMobile.contains(_searchQuery)               ||
        g.loan.itemDescription.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    _filteredLoans = list;
  }

  // ── RELOAD (after release/update) ─────────────────────────────────────────
  Future<void> reload() => load();
}


// =============================================================================
// FILE        : girvi_release_controller.dart
// MODULE      : Girvi / Pawn
// LAYER       : Logic / Controller
// DESCRIPTION : Manages girvi release/redemption flow.
//               Computes principal + interest + penalty, allows penalty
//               override, validates payment, calls releaseLoan on repo.
// =============================================================================

class GirviReleaseController extends ChangeNotifier {

  final GirviRepository _repo;
  final GirviLoanModel  loan;
  final String          customerName;

  GirviReleaseController({
    required AppDatabase db,
    required this.loan,
    required this.customerName,
  }) : _repo = GirviRepository(db) {
    _initComputed();
  }

  // ── COMPUTED ───────────────────────────────────────────────────────────────
  late double _principal;
  late double _interest;
  double      _penalty       = 0.0;
  late double _total;

  double get principal => _principal;
  double get interest  => _interest;
  double get penalty   => _penalty;
  double get total     => _total;

  void _initComputed() {
    _principal = loan.loanAmount;
    _interest  = loan.accruedInterest;
    _penalty   = loan.isOverdue ? _computeDefaultPenalty() : 0.0;
    _recomputeTotal();
  }

  double _computeDefaultPenalty() {
    // 1% of principal per overdue month
    return (_principal * 0.01 * loan.overdueMonths).clamp(0, double.infinity);
  }

  void _recomputeTotal() {
    _total = _principal + _interest + _penalty;
  }

  // ── PENALTY OVERRIDE ───────────────────────────────────────────────────────
  void onPenaltyChanged(String v) {
    _penalty = double.tryParse(v) ?? 0.0;
    _recomputeTotal();
    notifyListeners();
  }

  // ── PAYMENT MODE ───────────────────────────────────────────────────────────
  GirviPaymentMode _paymentMode = GirviPaymentMode.cash;
  GirviPaymentMode get paymentMode => _paymentMode;

  void setPaymentMode(GirviPaymentMode v) {
    _paymentMode = v;
    notifyListeners();
  }

  // ── STATUS ─────────────────────────────────────────────────────────────────
  bool    _isProcessing  = false;
  String? _errorMessage;
  String? _successMessage;

  bool    get isProcessing  => _isProcessing;
  String? get errorMessage  => _errorMessage;
  String? get successMessage => _successMessage;

  // ── RELEASE ACTION ─────────────────────────────────────────────────────────

  Future<bool> processRelease({String? notes, String? releasedBy}) async {
    if (_total <= 0) {
      _errorMessage = 'Total release amount must be greater than zero';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repo.releaseLoan(
        loanId:       loan.id,
        principal:    _principal,
        interest:     _interest,
        penalty:      _penalty,
        totalAmount:  _total,
        paymentMode:  _paymentMode.dbValue,
        notes:        notes,
        releasedBy:   releasedBy,
      );

      if (ok) {
        _successMessage = 'Girvi ${loan.ticketNo} released successfully!';
      } else {
        _errorMessage = 'Release failed. Please try again.';
      }

      _isProcessing = false;
      notifyListeners();
      return ok;
    } catch (e) {
      debugPrint('GirviReleaseController.processRelease error: $e');
      _errorMessage = 'An error occurred during release.';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
}


// =============================================================================
// FILE        : interest_calc_controller.dart
// MODULE      : Girvi / Pawn
// LAYER       : Logic / Controller
// DESCRIPTION : Pure computation controller for the standalone Interest
//               Calculator screen. No DB operations — just reactive math.
//               Computes simple interest, EMI breakdown, month-wise
//               interest table, and compound interest comparison.
// =============================================================================

class InterestCalcController extends ChangeNotifier {

  // ── INPUTS ─────────────────────────────────────────────────────────────────
  double _principal    = 0.0;
  double _ratePerMonth = 2.0;
  int    _months       = 12;

  double get principal    => _principal;
  double get ratePerMonth => _ratePerMonth;
  int    get months       => _months;

  // ── COMPUTED ───────────────────────────────────────────────────────────────
  double get monthlyInterest =>
      _principal * (_ratePerMonth / 100);

  double get totalInterest =>
      monthlyInterest * _months;

  double get totalDue =>
      _principal + totalInterest;

  double get annualRate =>
      _ratePerMonth * 12;

  /// Month-wise interest table
  List<MonthRow> get monthTable {
    final rows = <MonthRow>[];
    double balance = _principal;
    for (int m = 1; m <= _months; m++) {
      final interest = balance * (_ratePerMonth / 100);
      rows.add(MonthRow(month: m, interest: interest, balance: balance + interest));
    }
    return rows;
  }

  /// Compound interest total (for comparison)
  double get compoundTotalDue =>
      _principal * (1 + _ratePerMonth / 100).abs().toDouble() *
      (1.0 + (_ratePerMonth / 100)) //  simplified for display
          .clamp(1, double.infinity);

  // ── SETTERS ────────────────────────────────────────────────────────────────

  void onPrincipalChanged(String v) {
    _principal = double.tryParse(v) ?? 0.0;
    notifyListeners();
  }

  void onRateChanged(String v) {
    _ratePerMonth = double.tryParse(v) ?? 2.0;
    notifyListeners();
  }

  void onMonthsChanged(String v) {
    _months = int.tryParse(v) ?? 12;
    notifyListeners();
  }

  void reset() {
    _principal    = 0.0;
    _ratePerMonth = 2.0;
    _months       = 12;
    notifyListeners();
  }
}

class MonthRow {
  final int    month;
  final double interest;
  final double balance;

  const MonthRow({
    required this.month,
    required this.interest,
    required this.balance,
  });
}
