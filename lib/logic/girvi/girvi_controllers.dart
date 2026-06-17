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
  List<GirviLoanWithCustomer> _allLoans = [];
  List<GirviLoanWithCustomer> _filteredLoans = [];
  GirviSummaryModel _summary = GirviSummaryModel.empty();
  GirviFilter _filter = GirviFilter.all;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  // ── GETTERS ────────────────────────────────────────────────────────────────
  List<GirviLoanWithCustomer> get loans => _filteredLoans;
  GirviSummaryModel get summary => _summary;
  GirviFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoans => _allLoans.isNotEmpty;

  // ── LOAD ───────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _isLoading = true;
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
      _summary = results[1] as GirviSummaryModel;
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
            return g.loan.isOverdue ||
                g.loan.girviStatus == GirviStatus.overdue;
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
      list = list
          .where((g) =>
              g.loan.ticketNo.toLowerCase().contains(_searchQuery) ||
              g.customerName.toLowerCase().contains(_searchQuery) ||
              g.customerMobile.contains(_searchQuery) ||
              g.loan.itemDescription.toLowerCase().contains(_searchQuery))
          .toList();
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
  final GirviLoanModel loan;
  final String customerName;

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
  double _penalty = 0.0;
  late double _total;

  double get principal => _principal;
  double get interest => _interest;
  double get penalty => _penalty;
  double get total => _total;

  void _initComputed() {
    _principal = loan.loanAmount;
    _interest = loan.accruedInterest;
    _penalty = loan.isOverdue ? _computeDefaultPenalty() : 0.0;
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
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
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
        loanId: loan.id,
        principal: _principal,
        interest: _interest,
        penalty: _penalty,
        totalAmount: _total,
        paymentMode: _paymentMode.dbValue,
        notes: notes,
        releasedBy: releasedBy,
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
// FILE        : girvi_interest_entry_controller.dart
// MODULE      : Girvi / Pawn
// LAYER       : Logic / Controller
// DESCRIPTION : Records running interest/principal payment entries against
//               active girvi tickets and keeps payment history in sync.
// =============================================================================

class GirviInterestEntryController extends ChangeNotifier {
  final GirviRepository _repo;

  GirviInterestEntryController(AppDatabase db) : _repo = GirviRepository(db);

  List<GirviLoanWithCustomer> _allLoans = [];
  List<GirviLoanWithCustomer> _filteredLoans = [];
  List<GirviCustomerGirviAccount> _customerAccounts = [];
  List<GirviCustomerGirviAccount> _filteredCustomerAccounts = [];
  List<GirviPaymentModel> _payments = [];
  GirviLoanWithCustomer? _selectedLoan;
  int? _selectedCustomerId;

  GirviPaymentType _paymentType = GirviPaymentType.interest;
  GirviPaymentMode _paymentMode = GirviPaymentMode.cash;
  DateTime _paymentDate = DateTime.now();
  DateTime? _interestFromDate;
  DateTime? _interestToDate;
  String _searchQuery = '';
  String _amountInput = '';
  String _monthsInput = '1';
  String _receiptNo = '';
  String _notes = '';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  List<GirviLoanWithCustomer> get loans => _filteredLoans;
  List<GirviCustomerGirviAccount> get customerAccounts =>
      _filteredCustomerAccounts;
  List<GirviPaymentModel> get payments => _payments;
  GirviLoanWithCustomer? get selectedLoan => _selectedLoan;
  int? get selectedCustomerId => _selectedCustomerId;
  GirviPaymentType get paymentType => _paymentType;
  GirviPaymentMode get paymentMode => _paymentMode;
  DateTime get paymentDate => _paymentDate;
  DateTime? get interestFromDate => _interestFromDate;
  DateTime? get interestToDate => _interestToDate;
  String get amountInput => _amountInput;
  String get monthsInput => _monthsInput;
  String get receiptNo => _receiptNo;
  String get notes => _notes;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get hasLoans => _allLoans.isNotEmpty;
  int get openCustomerCount => _customerAccounts.length;
  int get openTicketCount => _allLoans.length;
  bool get hasCustomerAccounts => _customerAccounts.isNotEmpty;
  GirviCustomerGirviAccount? get selectedCustomerAccount {
    final id = _selectedCustomerId;
    if (id == null) return null;
    for (final account in _filteredCustomerAccounts) {
      if (account.customerId == id) return account;
    }
    for (final account in _customerAccounts) {
      if (account.customerId == id) return account;
    }
    return null;
  }

  double get amount => double.tryParse(_amountInput) ?? 0.0;
  int get monthsCovered => int.tryParse(_monthsInput) ?? 0;
  bool get isInterestEntry =>
      _paymentType == GirviPaymentType.interest ||
      _paymentType == GirviPaymentType.partialInterest;
  int get interestMonthsCoveredByAmount {
    final loan = _selectedLoan?.loan;
    if (loan == null) return 0;
    final from =
        loan.lastInterestPaidDate ?? _interestFromDate ?? loan.startDate;
    return loan.interestMonthsCoveredByPayment(
      amount: amount,
      fromDate: from,
      paymentDate: _paymentDate,
    );
  }

  double get expectedInterest {
    final loan = _selectedLoan?.loan;
    if (loan == null) return 0.0;
    final months = monthsCovered <= 0 ? 1 : monthsCovered;
    return loan.interestForMonths(months.toDouble());
  }

  double get totalCollectedForSelected =>
      _payments.fold<double>(0, (sum, item) => sum + item.amount);

  double get principalRepaidForSelected => _payments
      .where((item) => item.type == GirviPaymentType.partialPrincipal)
      .fold<double>(0, (sum, item) => sum + item.amount);

  double get interestCollectedForSelected => _payments
      .where((item) =>
          item.type == GirviPaymentType.interest ||
          item.type == GirviPaymentType.partialInterest)
      .fold<double>(0, (sum, item) => sum + item.amount);

  double get principalDisbursedForSelected {
    final loan = _selectedLoan?.loan;
    if (loan == null) return 0;
    return loan.loanAmount + principalRepaidForSelected;
  }

  List<GirviPaymentType> get entryPaymentTypes => const [
        GirviPaymentType.interest,
        GirviPaymentType.partialInterest,
        GirviPaymentType.partialPrincipal,
        GirviPaymentType.penalty,
      ];

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.syncOverdueStatus();
      await _loadLoans();
      _applySearch();
      _clearSelectedLoan(clearCustomer: true);
    } catch (e) {
      debugPrint('GirviInterestEntryController.load error: $e');
      _errorMessage = 'Unable to load girvi interest entries.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final selectedId = _selectedLoan?.loan.id;
    await _reloadAfterMutation(selectedId: selectedId, keepMessages: true);
  }

  void selectCustomerAccount(GirviCustomerGirviAccount account) {
    final sameCustomer = _selectedCustomerId == account.customerId;
    _selectedCustomerId = account.customerId;
    if (!sameCustomer) {
      _clearSelectedLoan(clearCustomer: false);
    }
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> selectLoan(GirviLoanWithCustomer data) async {
    _selectedCustomerId = data.loan.customerId;
    await _setSelectedLoan(data);
  }

  void showBillSelectionForSelectedCustomer() {
    if (_selectedCustomerId == null) return;
    _clearSelectedLoan(clearCustomer: false);
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void onSearchChanged(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applySearch();
    notifyListeners();
  }

  void setPaymentType(GirviPaymentType value) {
    _paymentType = value;
    _errorMessage = null;
    _successMessage = null;

    if (value == GirviPaymentType.interest) {
      _amountInput = expectedInterest.toStringAsFixed(2);
      _syncMonthsFromAmount();
    } else if (value == GirviPaymentType.partialPrincipal ||
        value == GirviPaymentType.penalty) {
      _amountInput = '';
    }

    notifyListeners();
  }

  void setPaymentMode(GirviPaymentMode value) {
    _paymentMode = value;
    notifyListeners();
  }

  void setPaymentDate(DateTime value) {
    _paymentDate = value;
    if (_paymentType == GirviPaymentType.interest) {
      _syncMonthsFromAmount();
    }
    notifyListeners();
  }

  void setInterestFromDate(DateTime value) {
    _interestFromDate = value;
    _syncMonthsFromPeriod();
    notifyListeners();
  }

  void setInterestToDate(DateTime value) {
    _interestToDate = value;
    _syncMonthsFromPeriod();
    notifyListeners();
  }

  void onAmountChanged(String value) {
    _amountInput = value;
    if (_paymentType == GirviPaymentType.interest) {
      _syncMonthsFromAmount();
    }
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void onMonthsChanged(String value) {
    _monthsInput = value;
    if (_paymentType == GirviPaymentType.interest) {
      _amountInput = expectedInterest.toStringAsFixed(2);
    }
    notifyListeners();
  }

  void onReceiptChanged(String value) {
    _receiptNo = value.trim();
    notifyListeners();
  }

  void onNotesChanged(String value) {
    _notes = value;
    notifyListeners();
  }

  Future<bool> recordPayment() async {
    final selected = _selectedLoan;
    if (selected == null) {
      _errorMessage = 'Select a girvi ticket before recording a payment.';
      notifyListeners();
      return false;
    }

    final value = amount;
    if (value <= 0) {
      _errorMessage = 'Enter a valid payment amount.';
      notifyListeners();
      return false;
    }

    if (_paymentType == GirviPaymentType.partialPrincipal &&
        value > selected.loan.loanAmount) {
      _errorMessage = 'Principal payment cannot exceed outstanding principal.';
      notifyListeners();
      return false;
    }

    if (isInterestEntry) {
      if (_paymentType == GirviPaymentType.interest &&
          interestMonthsCoveredByAmount <= 0) {
        _errorMessage =
            'Interest payment must cover at least one full month. Use Partial Interest for a smaller amount.';
        notifyListeners();
        return false;
      }
      if (_paymentType == GirviPaymentType.partialInterest &&
          monthsCovered <= 0) {
        _errorMessage = 'Enter the number of interest months covered.';
        notifyListeners();
        return false;
      }
      final from = _interestFromDate;
      final to = _interestToDate;
      if (from != null && to != null && to.isBefore(from)) {
        _errorMessage = 'Interest period end date cannot be before start date.';
        notifyListeners();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repo.recordPayment(
        loanId: selected.loan.id,
        paymentType: _paymentType,
        paymentMode: _paymentMode,
        amount: value,
        paymentDate: _paymentDate,
        monthsCovered: _paymentType == GirviPaymentType.interest
            ? interestMonthsCoveredByAmount
            : isInterestEntry
                ? monthsCovered
                : null,
        interestFromDate: isInterestEntry ? _interestFromDate : null,
        interestToDate: isInterestEntry ? _interestToDate : null,
        receiptNo: _receiptNo.isEmpty ? null : _receiptNo,
        notes: _notes.trim().isEmpty ? null : _notes.trim(),
      );

      _successMessage = 'Payment entry recorded successfully.';
      await _reloadAfterMutation(selectedId: selected.loan.id);
      return true;
    } catch (e) {
      debugPrint('GirviInterestEntryController.recordPayment error: $e');
      _errorMessage = 'Payment entry failed. Please review and try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _loadLoans() async {
    final rows = await _repo.getLoansWithCustomer();
    _allLoans = rows.where((item) => !item.loan.isClosed).toList()
      ..sort((a, b) {
        final aDate = a.loan.updatedAt ?? a.loan.startDate;
        final bDate = b.loan.updatedAt ?? b.loan.startDate;
        return bDate.compareTo(aDate);
      });
    _customerAccounts = _buildCustomerAccounts(_allLoans);
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredLoans = List<GirviLoanWithCustomer>.from(_allLoans);
    } else {
      _filteredLoans = _allLoans.where((item) {
        final loan = item.loan;
        return loan.ticketNo.toLowerCase().contains(_searchQuery) ||
            item.customerName.toLowerCase().contains(_searchQuery) ||
            item.customerMobile.contains(_searchQuery) ||
            loan.itemDescription.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    _filteredCustomerAccounts = _buildCustomerAccounts(_filteredLoans);
    _syncSelectionWithFilteredResults();
  }

  Future<void> _setSelectedLoan(
    GirviLoanWithCustomer data, {
    bool notifyAtStart = true,
  }) async {
    _selectedCustomerId = data.loan.customerId;
    _selectedLoan = data;
    _payments = [];
    _errorMessage = null;
    _successMessage = null;
    _resetFormFromLoan(data.loan);

    if (notifyAtStart) notifyListeners();

    final results = await Future.wait([
      _repo.getPaymentModelsForLoan(data.loan.id),
      _repo.generateNextPaymentReceiptNo(),
    ]);

    _payments = results[0] as List<GirviPaymentModel>;
    _receiptNo = results[1] as String;
    notifyListeners();
  }

  Future<void> _reloadAfterMutation({
    int? selectedId,
    bool keepMessages = false,
  }) async {
    final success = _successMessage;
    final error = _errorMessage;
    await _loadLoans();
    _applySearch();

    GirviLoanWithCustomer? next;
    if (selectedId != null) {
      for (final item in _allLoans) {
        if (item.loan.id == selectedId) {
          next = item;
          break;
        }
      }
    }

    if (next == null) {
      _clearSelectedLoan(clearCustomer: _selectedCustomerId == null);
    } else {
      await _setSelectedLoan(next, notifyAtStart: false);
    }

    if (keepMessages) {
      _successMessage = success;
      _errorMessage = error;
    } else if (success != null) {
      _successMessage = success;
    }
  }

  List<GirviCustomerGirviAccount> _buildCustomerAccounts(
    List<GirviLoanWithCustomer> loans,
  ) {
    final grouped = <int, List<GirviLoanWithCustomer>>{};
    for (final item in loans) {
      grouped.putIfAbsent(item.loan.customerId, () => []).add(item);
    }

    final accounts = grouped.entries.map((entry) {
      final customerLoans = entry.value
        ..sort((a, b) {
          final aDate = a.loan.updatedAt ?? a.loan.startDate;
          final bDate = b.loan.updatedAt ?? b.loan.startDate;
          return bDate.compareTo(aDate);
        });
      return GirviCustomerGirviAccount(
        customerId: entry.key,
        customerName: customerLoans.first.customerName,
        customerMobile: customerLoans.first.customerMobile,
        customerCity: customerLoans.first.customerCity,
        loans: List.unmodifiable(customerLoans),
      );
    }).toList()
      ..sort((a, b) => b.latestActivity.compareTo(a.latestActivity));

    return List.unmodifiable(accounts);
  }

  void _syncSelectionWithFilteredResults() {
    final customerId = _selectedCustomerId;
    if (customerId == null) return;

    final customerVisible = _filteredCustomerAccounts.any(
      (account) => account.customerId == customerId,
    );
    if (!customerVisible) {
      _selectedCustomerId = null;
      _clearSelectedLoan(clearCustomer: false);
      return;
    }

    final selectedLoanId = _selectedLoan?.loan.id;
    if (selectedLoanId == null) return;

    final loanVisible = _filteredLoans.any(
      (item) => item.loan.id == selectedLoanId,
    );
    if (!loanVisible) {
      _clearSelectedLoan(clearCustomer: false);
    }
  }

  void _clearSelectedLoan({required bool clearCustomer}) {
    if (clearCustomer) _selectedCustomerId = null;
    _selectedLoan = null;
    _payments = [];
    _resetEmptyForm();
  }

  void _resetFormFromLoan(GirviLoanModel loan) {
    _paymentType = GirviPaymentType.interest;
    _paymentMode = GirviPaymentMode.cash;
    _paymentDate = DateTime.now();
    final interestFrom = loan.lastInterestPaidDate ?? loan.startDate;
    _interestFromDate = interestFrom;
    final suggestedMonths = _suggestedMonths(loan);
    _interestToDate =
        GirviLoanModel.addChargeableMonths(interestFrom, suggestedMonths);
    _monthsInput = suggestedMonths.toString();
    _amountInput =
        loan.interestForMonths(suggestedMonths.toDouble()).toStringAsFixed(2);
    _notes = '';
    _receiptNo = '';
  }

  void _resetEmptyForm() {
    _paymentType = GirviPaymentType.interest;
    _paymentMode = GirviPaymentMode.cash;
    _paymentDate = DateTime.now();
    _interestFromDate = null;
    _interestToDate = null;
    _monthsInput = '1';
    _amountInput = '';
    _receiptNo = '';
    _notes = '';
  }

  int _suggestedMonths(GirviLoanModel loan) {
    final from = loan.lastInterestPaidDate ?? loan.startDate;
    final months = GirviLoanModel.chargeableMonthsBetween(from, DateTime.now());
    if (months <= 0) return 1;
    return months.clamp(1, 120);
  }

  void _syncMonthsFromPeriod() {
    final from = _interestFromDate;
    final to = _interestToDate;
    if (from == null || to == null || to.isBefore(from)) return;
    final months =
        GirviLoanModel.chargeableMonthsBetween(from, to).clamp(1, 120);
    _monthsInput = months.toString();
    if (_paymentType == GirviPaymentType.interest) {
      _amountInput = expectedInterest.toStringAsFixed(2);
    }
  }

  void _syncMonthsFromAmount() {
    final coveredMonths = interestMonthsCoveredByAmount;
    _monthsInput = coveredMonths <= 0 ? '0' : coveredMonths.toString();
    final loan = _selectedLoan?.loan;
    final from = loan?.lastInterestPaidDate ?? _interestFromDate;
    if (loan != null && from != null && coveredMonths > 0) {
      _interestFromDate = from;
      _interestToDate = GirviLoanModel.addChargeableMonths(from, coveredMonths);
    }
  }
}

class GirviCustomerGirviAccount {
  const GirviCustomerGirviAccount({
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.customerCity,
    required this.loans,
  });

  final int customerId;
  final String customerName;
  final String customerMobile;
  final String? customerCity;
  final List<GirviLoanWithCustomer> loans;

  int get ticketCount => loans.length;

  double get outstandingPrincipal => loans.fold<double>(
        0,
        (sum, item) => sum + item.loan.loanAmount,
      );

  double get interestDue => loans.fold<double>(
        0,
        (sum, item) => sum + item.loan.accruedInterest,
      );

  int get overdueTicketCount =>
      loans.where((item) => item.loan.isOverdue).length;

  bool get hasOverdueTickets => overdueTicketCount > 0;

  DateTime get latestActivity {
    DateTime latest = loans.first.loan.updatedAt ?? loans.first.loan.startDate;
    for (final item in loans.skip(1)) {
      final current = item.loan.updatedAt ?? item.loan.startDate;
      if (current.isAfter(latest)) latest = current;
    }
    return latest;
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
  double _principal = 0.0;
  double _ratePerMonth = 2.0;
  int _months = 12;

  double get principal => _principal;
  double get ratePerMonth => _ratePerMonth;
  int get months => _months;

  // ── COMPUTED ───────────────────────────────────────────────────────────────
  double get monthlyInterest => _principal * (_ratePerMonth / 100);

  double get totalInterest => monthlyInterest * _months;

  double get totalDue => _principal + totalInterest;

  double get annualRate => _ratePerMonth * 12;

  /// Month-wise interest table
  List<MonthRow> get monthTable {
    final rows = <MonthRow>[];
    double balance = _principal;
    for (int m = 1; m <= _months; m++) {
      final interest = balance * (_ratePerMonth / 100);
      rows.add(
          MonthRow(month: m, interest: interest, balance: balance + interest));
    }
    return rows;
  }

  /// Compound interest total (for comparison)
  double get compoundTotalDue =>
      _principal *
      (1 + _ratePerMonth / 100).abs().toDouble() *
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
    _principal = 0.0;
    _ratePerMonth = 2.0;
    _months = 12;
    notifyListeners();
  }
}

class MonthRow {
  final int month;
  final double interest;
  final double balance;

  const MonthRow({
    required this.month,
    required this.interest,
    required this.balance,
  });
}
