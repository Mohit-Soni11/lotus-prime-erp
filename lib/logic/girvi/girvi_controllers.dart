import 'package:flutter/foundation.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';

import '../../models/customer/defaulter_model.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../repositories/customer/defaulter_repository.dart';
import '../../repositories/girvi/girvi_repository.dart';
import 'girvi_ticket_number_order.dart';

export 'interest_entry/girvi_interest_entry_controller.dart';

/// Manages Girvi list loading, filtering, and overdue settlement sync.
class GirviListController extends ChangeNotifier {
  final AppDatabase _db;
  final GirviRepository _repo;

  GirviListController(AppDatabase db)
      : _db = db,
        _repo = GirviRepository(db);

  List<GirviLoanWithCustomer> _allLoans = [];
  List<GirviLoanWithCustomer> _filteredLoans = [];
  List<GirviPaymentModel> _selectedPayments = [];
  Map<int, DefaulterModel> _riskCasesByLoan = const {};
  GirviSummaryModel _summary = GirviSummaryModel.empty();
  GirviFilter _filter = GirviFilter.all;
  String _searchQuery = '';
  int? _selectedPaymentLoanId;
  bool _isLoading = true;
  bool _isLoadingSelectedPayments = false;
  String? _errorMessage;

  List<GirviLoanWithCustomer> get loans => _filteredLoans;
  List<GirviPaymentModel> get selectedPayments => _selectedPayments;
  DefaulterModel? riskCaseForLoan(int loanId) => _riskCasesByLoan[loanId];
  GirviSummaryModel get summary => _summary;
  GirviFilter get filter => _filter;
  int? get selectedPaymentLoanId => _selectedPaymentLoanId;
  bool get isLoading => _isLoading;
  bool get isLoadingSelectedPayments => _isLoadingSelectedPayments;
  String? get errorMessage => _errorMessage;
  bool get hasLoans => _allLoans.isNotEmpty;
  int countForFilter(GirviFilter filter) => _allLoans
      .where((item) => _matchesFilter(item, filter) && _matchesSearch(item))
      .length;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.syncOverdueStatus();
      await _repo.syncSettlementStatus();
      final accounts = await _repo.getLoansWithCustomer(includeAuctioned: true);
      final riskCases = await DefaulterRepository(db: _db)
          .fetchAllDefaulters(syncStatuses: false);
      accounts.sort((a, b) {
        final statusOrder = _registerPriority(a.loan.girviStatus)
            .compareTo(_registerPriority(b.loan.girviStatus));
        if (statusOrder != 0) return statusOrder;
        final ticketOrder = GirviTicketNumberOrder.compareNewestFirst(
          a.loan.ticketNo,
          b.loan.ticketNo,
        );
        return ticketOrder != 0 ? ticketOrder : b.loan.id.compareTo(a.loan.id);
      });
      _allLoans = accounts;
      _riskCasesByLoan = {for (final risk in riskCases) risk.loanId: risk};
      _summary = await _repo.getSummary(loans: accounts);
      _applyFilter();
      _syncSelectedPaymentsWithVisibleLoans();
    } catch (e) {
      AppLogger.debug('GirviListController.load error: $e');
      _errorMessage = 'Failed to load girvi data. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
    if (_filter != GirviFilter.all) {
      list = list.where((item) => _matchesFilter(item, _filter)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where(_matchesSearch).toList();
    }

    _filteredLoans = list;
  }

  int _registerPriority(GirviStatus status) => switch (status) {
        GirviStatus.active ||
        GirviStatus.overdue ||
        GirviStatus.partialRelease =>
          0,
        GirviStatus.readyForDelivery => 1,
        GirviStatus.released || GirviStatus.auctioned => 2,
      };

  bool _matchesSearch(GirviLoanWithCustomer item) {
    if (_searchQuery.isEmpty) return true;
    return item.loan.ticketNo.toLowerCase().contains(_searchQuery) ||
        item.customerName.toLowerCase().contains(_searchQuery) ||
        item.customerMobile.contains(_searchQuery) ||
        item.loan.itemDescription.toLowerCase().contains(_searchQuery) ||
        item.loan.metalType.toLowerCase().contains(_searchQuery) ||
        item.loan.metalPurity.toLowerCase().contains(_searchQuery);
  }

  bool _matchesFilter(GirviLoanWithCustomer item, GirviFilter filter) {
    final loan = item.loan;
    switch (filter) {
      case GirviFilter.all:
        return true;
      case GirviFilter.active:
        return loan.girviStatus == GirviStatus.active ||
            loan.girviStatus == GirviStatus.overdue ||
            loan.girviStatus == GirviStatus.partialRelease;
      case GirviFilter.overdue:
        return loan.isOverdue || loan.girviStatus == GirviStatus.overdue;
      case GirviFilter.readyForDelivery:
        return loan.girviStatus == GirviStatus.readyForDelivery;
      case GirviFilter.released:
        return loan.girviStatus == GirviStatus.released;
      case GirviFilter.actionRegister:
        final risk = _riskCasesByLoan[loan.id];
        return risk != null &&
            risk.isNoticeFollowUpActionDue &&
            !risk.isCollateralRecovery &&
            !risk.isRecoverySettled;
      case GirviFilter.recoveryRegister:
        return _riskCasesByLoan[loan.id]?.isCollateralRecovery ?? false;
    }
  }

  Future<void> loadPaymentsForLoan(int loanId) async {
    if (_selectedPaymentLoanId == loanId && _selectedPayments.isNotEmpty) {
      return;
    }

    _selectedPaymentLoanId = loanId;
    _selectedPayments = [];
    _isLoadingSelectedPayments = true;
    notifyListeners();

    try {
      _selectedPayments = await _repo.getPaymentModelsForLoan(loanId);
    } catch (e) {
      AppLogger.debug('GirviListController.loadPaymentsForLoan error: $e');
      _selectedPayments = [];
    } finally {
      _isLoadingSelectedPayments = false;
      notifyListeners();
    }
  }

  void _syncSelectedPaymentsWithVisibleLoans() {
    if (_filteredLoans.any((item) => item.loan.id == _selectedPaymentLoanId)) {
      return;
    }
    _selectedPaymentLoanId = null;
    _selectedPayments = [];
    _isLoadingSelectedPayments = false;
  }

  Future<void> reload() => load(showLoading: false);
}

/// Handles legacy release-screen delivery without bypassing settlement.
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

  late double _principal;
  late double _interest;
  double _penalty = 0.0;
  late double _total;

  double get principal => _principal;
  double get interest => _interest;
  double get penalty => _penalty;
  double get total => _total;

  void _initComputed() {
    final settled = loan.girviStatus == GirviStatus.readyForDelivery ||
        loan.girviStatus == GirviStatus.released;
    _principal = settled ? 0 : loan.loanAmount;
    _interest = settled ? 0 : loan.accruedInterest;
    _penalty = settled ? 0 : (loan.isOverdue ? _computeDefaultPenalty() : 0.0);
    _recomputeTotal();
  }

  double _computeDefaultPenalty() {
    // 1% of principal per overdue month
    return (_principal * 0.01 * loan.overdueMonths).clamp(0, double.infinity);
  }

  void _recomputeTotal() {
    _total = _principal + _interest + _penalty;
  }

  void onPenaltyChanged(String v) {
    _penalty = double.tryParse(v) ?? 0.0;
    _recomputeTotal();
    notifyListeners();
  }

  GirviPaymentMode _paymentMode = GirviPaymentMode.cash;
  GirviPaymentMode get paymentMode => _paymentMode;

  void setPaymentMode(GirviPaymentMode v) {
    _paymentMode = v;
    notifyListeners();
  }

  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> processRelease({String? notes, String? releasedBy}) async {
    if (loan.girviStatus == GirviStatus.released) {
      _errorMessage = 'Girvi is already delivered and closed.';
      notifyListeners();
      return false;
    }
    if (loan.girviStatus != GirviStatus.readyForDelivery) {
      _errorMessage =
          'Complete the settlement in Interest Entry before delivery.';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repo.markGirviDelivered(
        loanId: loan.id,
        deliveredAt: DateTime.now(),
        deliveredBy: releasedBy,
      );

      if (ok) {
        _successMessage = 'Girvi ${loan.ticketNo} delivered successfully!';
      } else {
        _errorMessage = 'Delivery failed. Please try again.';
      }

      _isProcessing = false;
      notifyListeners();
      return ok;
    } catch (e) {
      AppLogger.debug('GirviReleaseController.processRelease error: $e');
      _errorMessage = 'An error occurred during release.';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
}
