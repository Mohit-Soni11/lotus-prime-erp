import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../repositories/girvi/girvi_repository.dart';
import 'girvi_customer_girvi_account.dart';

export 'girvi_customer_girvi_account.dart';

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
  String _releasePrincipalInput = '';
  String _releaseInterestInput = '';
  String _releaseDiscountInput = '';
  String _monthsInput = '1';
  String _paymentReferenceNo = '';
  String _notes = '';
  DateTime _expectedDeliveryDate = DateTime.now();

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
  String get releasePrincipalInput => _releasePrincipalInput;
  String get releaseInterestInput => _releaseInterestInput;
  String get releaseDiscountInput => _releaseDiscountInput;
  String get monthsInput => _monthsInput;
  String get notes => _notes;
  DateTime get expectedDeliveryDate => _expectedDeliveryDate;
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
  double get releasePrincipalReceived =>
      double.tryParse(_releasePrincipalInput) ?? 0.0;
  double get releaseInterestReceived =>
      double.tryParse(_releaseInterestInput) ?? 0.0;
  double get releaseDiscount => double.tryParse(_releaseDiscountInput) ?? 0.0;
  double get releaseEntryTotal =>
      releasePrincipalReceived + releaseInterestReceived;
  double get releaseSettlementValue => releaseEntryTotal + releaseDiscount;
  int get monthsCovered => int.tryParse(_monthsInput) ?? 0;
  bool get isInterestEntry => _paymentType == GirviPaymentType.interest;
  int get interestMonthsCoveredByAmount {
    final monthlyInterest = currentLedgerMonthlyInterestForSelected;
    if (amount <= 0 || monthlyInterest <= 0) return 0;
    return amount ~/ monthlyInterest;
  }

  double get expectedInterest {
    final months = monthsCovered;
    if (months <= 0) return 0.0;
    return currentLedgerMonthlyInterestForSelected * months;
  }

  double get totalCollectedForSelected =>
      _payments.fold<double>(0, (sum, item) => sum + item.amount);

  double get principalRepaidForSelected => _payments
      .where((item) => item.type == GirviPaymentType.partialPrincipal)
      .fold<double>(0, (sum, item) => sum + item.amount);

  double get interestCollectedForSelected =>
      _payments.fold<double>(0, (sum, item) {
        if (item.type == GirviPaymentType.interest ||
            item.type == GirviPaymentType.partialInterest) {
          return sum + item.amount;
        }
        if (item.type == GirviPaymentType.fullRelease) {
          return sum + item.interestComponent;
        }
        return sum;
      });

  double get releasePrincipalCollectedForSelected => _payments
      .where((item) => item.type == GirviPaymentType.fullRelease)
      .fold<double>(0, (sum, item) => sum + item.principalComponent);

  double get releaseInterestCollectedForSelected => _payments
      .where((item) => item.type == GirviPaymentType.fullRelease)
      .fold<double>(0, (sum, item) => sum + item.interestComponent);

  double get releasePrincipalDiscountForSelected => _payments
      .where((item) => item.type == GirviPaymentType.fullRelease)
      .fold<double>(
        0,
        (sum, item) => sum + item.principalDiscountComponent,
      );

  double get releaseInterestDiscountForSelected => _payments
      .where((item) => item.type == GirviPaymentType.fullRelease)
      .fold<double>(
        0,
        (sum, item) => sum + item.interestDiscountComponent,
      );

  double get releaseDiscountForSelected =>
      releasePrincipalDiscountForSelected + releaseInterestDiscountForSelected;

  double get currentLedgerMonthlyInterestForSelected {
    final selected = _selectedLoan;
    if (selected == null) return 0;
    final loan = selected.loan;
    final breakdown = GirviLoanModel.calculateCompoundInterestBreakdown(
      principal: selected.originalPrincipal,
      monthlyRatePercent: loan.interestRate,
      months: loan.monthsElapsed.ceil(),
    );
    if (breakdown.isEmpty) {
      return selected.originalPrincipal * (loan.interestRate / 100);
    }
    return breakdown.last.monthlyInterest;
  }

  double get grossInterestAccruedForSelected {
    return _selectedLoan?.grossInterestAccrued ?? 0;
  }

  double get netInterestDueForSelected {
    final due = grossInterestAccruedForSelected -
        interestCollectedForSelected -
        releaseInterestDiscountForSelected;
    return due <= 0 ? 0 : due;
  }

  double get advanceInterestCreditForSelected {
    final credit =
        interestCollectedForSelected - grossInterestAccruedForSelected;
    return credit <= 0 ? 0 : credit;
  }

  double get releaseTotalDueForSelected {
    return releasePrincipalDueForSelected + netInterestDueForSelected;
  }

  double get releasePrincipalDueForSelected {
    return _selectedLoan?.principalDue ?? 0;
  }

  bool get isReadyForDelivery =>
      _selectedLoan?.loan.girviStatus == GirviStatus.readyForDelivery;

  double get principalDisbursedForSelected {
    return _selectedLoan?.originalPrincipal ?? 0;
  }

  List<GirviPaymentType> get entryPaymentTypes => const [
        GirviPaymentType.interest,
        GirviPaymentType.fullRelease,
      ];

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.syncOverdueStatus();
      await _repo.syncSettlementStatus();
      await _loadLoans();
      _applySearch();
      _clearSelectedLoan(clearCustomer: true);
    } catch (e) {
      AppLogger.debug('GirviInterestEntryController.load error: $e');
      _errorMessage = 'Unable to load girvi interest entries.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final selectedId = _selectedLoan?.loan.id;
    await _repo.syncSettlementStatus();
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

  Future<bool> selectLoanByTicketNo(String ticketNo) async {
    final normalizedTicketNo = ticketNo.trim().toLowerCase();
    if (normalizedTicketNo.isEmpty) return false;

    GirviLoanWithCustomer? match;
    for (final item in _allLoans) {
      if (item.loan.ticketNo.toLowerCase() == normalizedTicketNo) {
        match = item;
        break;
      }
    }

    _searchQuery = normalizedTicketNo;
    _applySearch();

    if (match == null) {
      _errorMessage = 'Selected girvi ticket is not available for payment.';
      notifyListeners();
      return false;
    }

    await _setSelectedLoan(match);
    return true;
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
      _amountInput = _formatAmountInput(netInterestDueForSelected);
      _syncMonthsFromAmount();
    } else if (value == GirviPaymentType.fullRelease) {
      _releaseDiscountInput = '';
      _releasePrincipalInput =
          _formatAmountInput(releasePrincipalDueForSelected);
      _releaseInterestInput = _formatAmountInput(netInterestDueForSelected);
      _expectedDeliveryDate =
          _selectedLoan?.loan.expectedDeliveryDate ?? DateTime.now();
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

  void onReleasePrincipalChanged(String value) {
    _releasePrincipalInput = value;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void onReleaseInterestChanged(String value) {
    _releaseInterestInput = value;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void onReleaseDiscountChanged(String value) {
    _releaseDiscountInput = value;
    final discount = releaseDiscount;
    if (discount >= 0 && discount <= releaseTotalDueForSelected) {
      _fillReleaseSettlementForDiscount(discount);
    }
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void fillFullReleaseSettlement() {
    final discount =
        releaseDiscount.clamp(0.0, releaseTotalDueForSelected).toDouble();
    _fillReleaseSettlementForDiscount(discount);
    notifyListeners();
  }

  void setExpectedDeliveryDate(DateTime value) {
    _expectedDeliveryDate = value;
    notifyListeners();
  }

  void onMonthsChanged(String value) {
    _monthsInput = value;
    if (_paymentType == GirviPaymentType.interest) {
      _amountInput = _formatAmountInput(expectedInterest);
    }
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

    final value = isInterestEntry ? amount : releaseSettlementValue;
    if (!isReadyForDelivery && value <= 0) {
      _errorMessage = 'Enter a valid payment amount.';
      notifyListeners();
      return false;
    }

    if (_paymentType == GirviPaymentType.fullRelease) {
      if (releaseDiscount < 0) {
        _errorMessage = 'Discount cannot be negative.';
        notifyListeners();
        return false;
      }
      if (releasePrincipalReceived > releasePrincipalDueForSelected + 0.01) {
        _errorMessage = 'Principal received cannot exceed principal due.';
        notifyListeners();
        return false;
      }
      if (releaseInterestReceived > netInterestDueForSelected + 0.01) {
        _errorMessage = 'Interest received cannot exceed interest due.';
        notifyListeners();
        return false;
      }
      if (releaseSettlementValue > releaseTotalDueForSelected + 0.01) {
        _errorMessage =
            'Payment plus discount cannot exceed the total settlement due.';
        notifyListeners();
        return false;
      }
      if (releaseDiscount > 0.01 &&
          releaseSettlementValue + 0.01 < releaseTotalDueForSelected) {
        _errorMessage =
            'Discount can only be approved when the complete Girvi settlement is cleared.';
        notifyListeners();
        return false;
      }
      if (_expectedDeliveryDate.isBefore(
        DateTime(_paymentDate.year, _paymentDate.month, _paymentDate.day),
      )) {
        _errorMessage =
            'Expected pickup date cannot be before collection date.';
        notifyListeners();
        return false;
      }
    }

    if (isInterestEntry) {
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
      if (_paymentType == GirviPaymentType.fullRelease) {
        if (isReadyForDelivery) {
          await _repo.markGirviDelivered(
            loanId: selected.loan.id,
            deliveredAt: DateTime.now(),
            deliveredBy: 'Staff',
          );
          _successMessage = 'Girvi item delivered successfully.';
        } else {
          final result = await _repo.recordReleaseSettlement(
            loanId: selected.loan.id,
            principalDue: releasePrincipalDueForSelected,
            interestDue: netInterestDueForSelected,
            principalReceived: releasePrincipalReceived,
            interestReceived: releaseInterestReceived,
            discountAmount: releaseDiscount,
            paymentMode: _paymentMode,
            paymentDate: _paymentDate,
            expectedDeliveryDate: _expectedDeliveryDate,
            receiptNo: _paymentReferenceNo.isEmpty ? null : _paymentReferenceNo,
            notes: _notes.trim().isEmpty ? null : _notes.trim(),
            processedBy: 'Staff',
          );
          _successMessage = result.fullySettled
              ? result.discountApplied > 0
                  ? 'Settlement complete with discount. Girvi is ready for delivery.'
                  : 'Settlement complete. Girvi is ready for delivery.'
              : 'Partial settlement recorded. Balance remains pending.';
        }
      } else {
        await _repo.recordInterestLedgerPayment(
          loanId: selected.loan.id,
          paymentMode: _paymentMode,
          amount: value,
          paymentDate: _paymentDate,
          monthsCovered: interestMonthsCoveredByAmount <= 0
              ? null
              : interestMonthsCoveredByAmount,
          interestFromDate: null,
          interestToDate: null,
          receiptNo: _paymentReferenceNo.isEmpty ? null : _paymentReferenceNo,
          notes: _notes.trim().isEmpty ? null : _notes.trim(),
        );
      }

      _successMessage ??= 'Interest payment recorded successfully.';
      await _reloadAfterMutation(selectedId: selected.loan.id);
      return true;
    } catch (e) {
      AppLogger.debug('GirviInterestEntryController.recordPayment error: $e');
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
    _paymentReferenceNo = results[1] as String;
    if (_paymentType == GirviPaymentType.interest) {
      _amountInput = _formatAmountInput(netInterestDueForSelected);
      _syncMonthsFromAmount();
    } else if (_paymentType == GirviPaymentType.fullRelease) {
      _releasePrincipalInput =
          _formatAmountInput(releasePrincipalDueForSelected);
      _releaseInterestInput = _formatAmountInput(netInterestDueForSelected);
      _releaseDiscountInput = '';
      _expectedDeliveryDate = data.loan.expectedDeliveryDate ?? DateTime.now();
    }
    notifyListeners();
  }

  Future<void> _reloadAfterMutation({
    int? selectedId,
    bool keepMessages = false,
  }) async {
    final success = _successMessage;
    final error = _errorMessage;
    final previousPaymentType = _paymentType;
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
      if (previousPaymentType == GirviPaymentType.fullRelease &&
          next.loan.girviStatus == GirviStatus.partialRelease) {
        _paymentType = GirviPaymentType.fullRelease;
        _releasePrincipalInput =
            _formatAmountInput(releasePrincipalDueForSelected);
        _releaseInterestInput = _formatAmountInput(netInterestDueForSelected);
        _releaseDiscountInput = '';
      }
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
    _paymentType = loan.girviStatus == GirviStatus.readyForDelivery
        ? GirviPaymentType.fullRelease
        : GirviPaymentType.interest;
    _paymentMode = GirviPaymentMode.cash;
    _paymentDate = DateTime.now();
    final interestFrom = loan.startDate;
    _interestFromDate = interestFrom;
    final suggestedMonths = _suggestedMonths(loan);
    _interestToDate = suggestedMonths <= 0
        ? interestFrom
        : GirviLoanModel.addChargeableMonths(interestFrom, suggestedMonths);
    _monthsInput = suggestedMonths.toString();
    _amountInput = suggestedMonths <= 0
        ? ''
        : _formatAmountInput(
            loan.interestForMonths(suggestedMonths.toDouble()));
    _releasePrincipalInput = '';
    _releaseInterestInput = '';
    _releaseDiscountInput = '';
    _expectedDeliveryDate = loan.expectedDeliveryDate ?? DateTime.now();
    _notes = '';
    _paymentReferenceNo = '';
  }

  void _resetEmptyForm() {
    _paymentType = GirviPaymentType.interest;
    _paymentMode = GirviPaymentMode.cash;
    _paymentDate = DateTime.now();
    _interestFromDate = null;
    _interestToDate = null;
    _monthsInput = '1';
    _amountInput = '';
    _releasePrincipalInput = '';
    _releaseInterestInput = '';
    _releaseDiscountInput = '';
    _paymentReferenceNo = '';
    _notes = '';
    _expectedDeliveryDate = DateTime.now();
  }

  int _suggestedMonths(GirviLoanModel loan) {
    final from = loan.startDate;
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
      _amountInput = _formatAmountInput(expectedInterest);
    }
  }

  void _syncMonthsFromAmount() {
    final coveredMonths = interestMonthsCoveredByAmount;
    _monthsInput = coveredMonths <= 0 ? '0' : coveredMonths.toString();
    final loan = _selectedLoan?.loan;
    final from = _interestFromDate ?? loan?.startDate;
    if (loan != null && from != null && coveredMonths > 0) {
      _interestFromDate = from;
      _interestToDate = GirviLoanModel.addChargeableMonths(from, coveredMonths);
    }
  }

  String _formatAmountInput(double value) {
    if (value <= 0) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _fillReleaseSettlementForDiscount(double discount) {
    final interestDiscount =
        discount.clamp(0.0, netInterestDueForSelected).toDouble();
    final principalDiscount = discount - interestDiscount;
    _releaseInterestInput = _formatAmountInput(
      netInterestDueForSelected - interestDiscount,
    );
    _releasePrincipalInput = _formatAmountInput(
      releasePrincipalDueForSelected - principalDiscount,
    );
  }
}
