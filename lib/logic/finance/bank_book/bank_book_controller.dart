// =============================================================================
// FILE        : bank_book_controller.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : Logic / Controller
// DESCRIPTION : Master ChangeNotifier controller for the Bank Book screen.
//               Zero-lag state management — UI uses ListenableBuilder only.
//               Handles account selection, view-mode, date navigation,
//               transaction filtering, entry saving, cheque management,
//               reconciliation, and summary computation.
//
// PATTERN     : ChangeNotifier (identical to CashBookController)
// DB LAYER    : BankBookRepository (never calls DB directly)
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/bank_book/bank_book_enums.dart';
import '../../../models/finance/bank_book/bank_account_model.dart';
import '../../../models/finance/bank_book/bank_book_summary_model.dart';
import '../../../repositories/finance/bank_book_repository.dart';
import '../../../core/logging/app_logger.dart';

class BankBookController extends ChangeNotifier {
  BankBookController() {
    _init();
  }

  // ── Dependencies ──────────────────────────────────────────────────────────
  final BankBookRepository _repository = BankBookRepository();

  // ── Account State ─────────────────────────────────────────────────────────
  List<BankAccountModel> _accounts = [];
  BankAccountModel? _selectedAccount;
  bool _accountsLoading = true;

  List<BankAccountModel> get accounts => _accounts;
  BankAccountModel? get selectedAccount => _selectedAccount;
  bool get accountsLoading => _accountsLoading;

  // ── View State ────────────────────────────────────────────────────────────
  BankBookViewMode _viewMode = BankBookViewMode.daily;
  BankBookFilter _filter = BankBookFilter.all;
  DateTime _activeDate = DateTime.now();

  BankBookViewMode get viewMode => _viewMode;
  BankBookFilter get filter => _filter;
  DateTime get activeDate => _activeDate;

  // ── Data State ────────────────────────────────────────────────────────────
  BankBookSummaryModel _summary = BankBookSummaryModel.loading();
  List<BankTransactionGroup> _groups = [];
  List<BankTransactionModel> _allTxns = [];
  bool _isLoading = true;
  String? _errorMessage;

  BankBookSummaryModel get summary => _summary;
  List<BankTransactionGroup> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Search ────────────────────────────────────────────────────────────────
  final TextEditingController searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Entry Form Controllers ────────────────────────────────────────────────
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController partyNameCtrl = TextEditingController();
  final TextEditingController chequeNumberCtrl = TextEditingController();

  BankTransactionType _entryType = BankTransactionType.credit;
  String _entryCategory = BankCreditCategory.salePayment.dbValue;
  BankPaymentMode _entryMode = BankPaymentMode.neft;
  DateTime _entryDate = DateTime.now();
  DateTime? _entryValueDate;
  ChequeStatus _entryChequeStatus = ChequeStatus.issued;
  bool _isSaving = false;

  BankTransactionType get entryType => _entryType;
  String get entryCategory => _entryCategory;
  BankPaymentMode get entryMode => _entryMode;
  DateTime get entryDate => _entryDate;
  DateTime? get entryValueDate => _entryValueDate;
  ChequeStatus get entryChequeStatus => _entryChequeStatus;
  bool get isSaving => _isSaving;
  bool get isChequeMode => _entryMode == BankPaymentMode.cheque;

  // ── Stream ────────────────────────────────────────────────────────────────
  StreamSubscription<List<BankTransactionModel>>? _watchSub;
  StreamSubscription<List<BankAccountModel>>? _accountWatchSub;

  // ==========================================================================
  // INIT
  // ==========================================================================

  void _init() {
    searchCtrl.addListener(_onSearchChanged);
    _loadAccounts();
  }

  // ==========================================================================
  // ACCOUNTS
  // ==========================================================================

  Future<void> _loadAccounts() async {
    _accountsLoading = true;
    notifyListeners();

    _accounts = await _repository.fetchAccounts();
    _accountsLoading = false;

    if (_accounts.isNotEmpty) {
      // Auto-select primary, else first
      _selectedAccount = _accounts.firstWhere(
        (a) => a.isPrimary,
        orElse: () => _accounts.first,
      );
      _startWatch();
    } else {
      _isLoading = false;
    }

    notifyListeners();
  }

  void selectAccount(BankAccountModel account) {
    if (_selectedAccount?.id == account.id) return;
    _selectedAccount = account;
    _isLoading = true;
    notifyListeners();
    _startWatch();
  }

  Future<bool> addAccount({
    required String accountName,
    required String bankName,
    required String accountNumber,
    required BankAccountType accountType,
    String? holderName,
    String? ifscCode,
    String? branchName,
    String? upiId,
    double openingBalance = 0.0,
    bool isPrimary = false,
  }) async {
    final id = await _repository.saveAccount(
      accountName: accountName,
      bankName: bankName,
      accountNumber: accountNumber,
      accountType: accountType,
      holderName: holderName,
      ifscCode: ifscCode,
      branchName: branchName,
      upiId: upiId,
      openingBalance: openingBalance,
      isPrimary: isPrimary,
    );

    if (id != null) {
      await _loadAccounts();
      return true;
    }
    return false;
  }

  Future<bool> updateOpeningBalance(double amount) async {
    final accId = _selectedAccount?.id;
    if (accId == null) return false;

    final success = await _repository.updateOpeningBalance(accId, amount);
    if (success) {
      await _loadAccounts();
      await _refreshSummary();
    }
    return success;
  }

  // ==========================================================================
  // LIVE WATCH
  // ==========================================================================

  void _startWatch() {
    _watchSub?.cancel();
    final accId = _selectedAccount?.id;
    if (accId == null) return;

    final range = _dateRange;

    _watchSub = _repository
        .watchTransactions(accountId: accId, from: range.start, to: range.end)
        .listen(
      (txns) async {
        _allTxns = txns;
        await _refreshSummary();
        _applyFiltersAndGroup();
      },
      onError: (e) {
        AppLogger.debug('❌ BankBookController watch error: $e');
        _errorMessage = 'Failed to load transactions.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ==========================================================================
  // SUMMARY REFRESH
  // ==========================================================================

  Future<void> _refreshSummary() async {
    final accId = _selectedAccount?.id;
    if (accId == null) {
      _summary = BankBookSummaryModel.zero();
      _isLoading = false;
      return;
    }

    final range = _dateRange;
    _summary = await _repository.computeSummary(
      accountId: accId,
      from: range.start,
      to: range.end,
    );
    _isLoading = false;
    _errorMessage = null;
  }

  // ==========================================================================
  // FILTERING + GROUPING
  // ==========================================================================

  void _applyFiltersAndGroup() {
    var txns = List<BankTransactionModel>.from(_allTxns);

    switch (_filter) {
      case BankBookFilter.creditOnly:
        txns = txns.where((t) => t.isCredit).toList();
      case BankBookFilter.debitOnly:
        txns = txns.where((t) => t.isDebit).toList();
      case BankBookFilter.chequeOnly:
        txns = txns.where((t) => t.isCheque).toList();
      case BankBookFilter.pendingReconciliation:
        txns = txns.where((t) => !t.isReconciled).toList();
      case BankBookFilter.all:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      txns = txns.where((t) {
        return t.categoryLabel.toLowerCase().contains(q) ||
            (t.partyName?.toLowerCase().contains(q) ?? false) ||
            (t.description?.toLowerCase().contains(q) ?? false) ||
            t.txnId.toLowerCase().contains(q) ||
            (t.chequeNumber?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    _groups = _groupByDate(txns);
    notifyListeners();
  }

  List<BankTransactionGroup> _groupByDate(List<BankTransactionModel> txns) {
    final Map<String, List<BankTransactionModel>> map = {};

    for (final t in txns) {
      final key = DateFormat('yyyy-MM-dd').format(t.txnDate);
      map.putIfAbsent(key, () => []).add(t);
    }

    final groups = map.entries.map((e) {
      final list = e.value;
      final credit =
          list.where((t) => t.isCredit).fold(0.0, (s, t) => s + t.amount);
      final debit =
          list.where((t) => t.isDebit).fold(0.0, (s, t) => s + t.amount);
      final date = DateFormat('yyyy-MM-dd').parse(e.key);

      return BankTransactionGroup(
        date: date,
        dateLabel: _buildDateLabel(date),
        transactions: list,
        groupCredit: credit,
        groupDebit: debit,
        groupNet: credit - debit,
      );
    }).toList();

    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  String _buildDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today — ${DateFormat('d MMM yyyy').format(date)}';
    if (d == today.subtract(const Duration(days: 1))) {
      return 'Yesterday — ${DateFormat('d MMM yyyy').format(date)}';
    }
    return DateFormat('EEEE, d MMM yyyy').format(date);
  }

  // ==========================================================================
  // PUBLIC API — View Controls
  // ==========================================================================

  void setViewMode(BankBookViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    _isLoading = true;
    notifyListeners();
    _startWatch();
  }

  void setFilter(BankBookFilter f) {
    _filter = f;
    _applyFiltersAndGroup();
  }

  void navigatePrevious() {
    _activeDate = _shift(-1);
    _isLoading = true;
    notifyListeners();
    _startWatch();
  }

  void navigateNext() {
    final shifted = _shift(1);
    if (shifted.isAfter(DateTime.now())) return;
    _activeDate = shifted;
    _isLoading = true;
    notifyListeners();
    _startWatch();
  }

  void jumpToToday() {
    _activeDate = DateTime.now();
    _isLoading = true;
    notifyListeners();
    _startWatch();
  }

  // ==========================================================================
  // PUBLIC API — Sync Bills
  // ==========================================================================

  Future<int> syncTodaysBills() async {
    final accId = _selectedAccount?.id;
    if (accId == null) return 0;
    return _repository.syncBillsToBank(accountId: accId, date: DateTime.now());
  }

  // ==========================================================================
  // PUBLIC API — Entry Form
  // ==========================================================================

  void setEntryType(BankTransactionType type) {
    _entryType = type;
    _entryCategory = type == BankTransactionType.credit
        ? BankCreditCategory.salePayment.dbValue
        : BankDebitCategory.supplierPayment.dbValue;
    notifyListeners();
  }

  void setEntryCategory(String categoryDbValue) {
    _entryCategory = categoryDbValue;
    notifyListeners();
  }

  void setEntryMode(BankPaymentMode mode) {
    _entryMode = mode;
    notifyListeners();
  }

  void setEntryDate(DateTime date) {
    _entryDate = date;
    notifyListeners();
  }

  void setEntryValueDate(DateTime? date) {
    _entryValueDate = date;
    notifyListeners();
  }

  void setEntryChequeStatus(ChequeStatus status) {
    _entryChequeStatus = status;
    notifyListeners();
  }

  void resetEntryForm() {
    amountCtrl.clear();
    descriptionCtrl.clear();
    partyNameCtrl.clear();
    chequeNumberCtrl.clear();
    _entryType = BankTransactionType.credit;
    _entryCategory = BankCreditCategory.salePayment.dbValue;
    _entryMode = BankPaymentMode.neft;
    _entryDate = DateTime.now();
    _entryValueDate = null;
    _entryChequeStatus = ChequeStatus.issued;
    notifyListeners();
  }

  Future<bool> saveEntry() async {
    final amountText = amountCtrl.text.trim();
    if (amountText.isEmpty) return false;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return false;

    final accId = _selectedAccount?.id;
    if (accId == null) return false;

    _isSaving = true;
    notifyListeners();

    final success = await _repository.saveTransaction(
      accountId: accId,
      type: _entryType,
      categoryDbValue: _entryCategory,
      amount: amount,
      paymentMode: _entryMode,
      txnDate: _entryDate,
      valueDate: _entryValueDate,
      chequeNumber: isChequeMode ? chequeNumberCtrl.text.trim() : null,
      chequeStatus: isChequeMode ? _entryChequeStatus : null,
      description: descriptionCtrl.text.trim().isEmpty
          ? null
          : descriptionCtrl.text.trim(),
      partyName:
          partyNameCtrl.text.trim().isEmpty ? null : partyNameCtrl.text.trim(),
    );

    _isSaving = false;
    if (success) resetEntryForm();
    notifyListeners();
    return success;
  }

  // ==========================================================================
  // PUBLIC API — Cheque & Reconciliation
  // ==========================================================================

  Future<bool> updateChequeStatus(int txnId, ChequeStatus status) async {
    return _repository.updateChequeStatus(txnId, status);
  }

  Future<bool> markReconciled(int txnId, {String? note}) async {
    return _repository.markReconciled(txnId, note: note);
  }

  Future<bool> voidTransaction(int id) async {
    return _repository.voidTransaction(id, 'Voided by user');
  }

  // ==========================================================================
  // DISPLAY HELPERS
  // ==========================================================================

  String get activeDateLabel {
    switch (_viewMode) {
      case BankBookViewMode.daily:
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final d =
            DateTime(_activeDate.year, _activeDate.month, _activeDate.day);
        if (d == today) return 'Today';
        if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
        return DateFormat('d MMM yyyy').format(_activeDate);
      case BankBookViewMode.monthly:
        return DateFormat('MMMM yyyy').format(_activeDate);
      case BankBookViewMode.yearly:
        return _activeDate.year.toString();
    }
  }

  bool get isToday {
    final now = DateTime.now();
    return _activeDate.year == now.year &&
        _activeDate.month == now.month &&
        _activeDate.day == now.day;
  }

  List<String> get availableCategories {
    if (_entryType == BankTransactionType.credit) {
      return BankCreditCategory.values.map((e) => e.dbValue).toList();
    }
    return BankDebitCategory.values.map((e) => e.dbValue).toList();
  }

  String categoryLabel(String dbValue, BankTransactionType type) {
    if (type == BankTransactionType.credit) {
      return BankCreditCategory.fromDb(dbValue).displayLabel;
    }
    return BankDebitCategory.fromDb(dbValue).displayLabel;
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  ({DateTime start, DateTime end}) get _dateRange {
    switch (_viewMode) {
      case BankBookViewMode.daily:
        return (
          start: DateTime(_activeDate.year, _activeDate.month, _activeDate.day),
          end: DateTime(
              _activeDate.year, _activeDate.month, _activeDate.day, 23, 59, 59),
        );
      case BankBookViewMode.monthly:
        return (
          start: DateTime(_activeDate.year, _activeDate.month, 1),
          end: DateTime(_activeDate.year, _activeDate.month + 1, 0, 23, 59, 59),
        );
      case BankBookViewMode.yearly:
        return (
          start: DateTime(_activeDate.year, 1, 1),
          end: DateTime(_activeDate.year, 12, 31, 23, 59, 59),
        );
    }
  }

  DateTime _shift(int delta) {
    switch (_viewMode) {
      case BankBookViewMode.daily:
        return _activeDate.add(Duration(days: delta));
      case BankBookViewMode.monthly:
        return DateTime(_activeDate.year, _activeDate.month + delta, 1);
      case BankBookViewMode.yearly:
        return DateTime(_activeDate.year + delta, 1, 1);
    }
  }

  void _onSearchChanged() {
    _searchQuery = searchCtrl.text.trim();
    _applyFiltersAndGroup();
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _watchSub?.cancel();
    _accountWatchSub?.cancel();
    searchCtrl.removeListener(_onSearchChanged);
    searchCtrl.dispose();
    amountCtrl.dispose();
    descriptionCtrl.dispose();
    partyNameCtrl.dispose();
    chequeNumberCtrl.dispose();
    super.dispose();
  }
}
