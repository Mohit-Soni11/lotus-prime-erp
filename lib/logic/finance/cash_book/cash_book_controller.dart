// =============================================================================
// FILE        : cash_book_controller.dart
// MODULE      : Accounts / Cash Book
// LAYER       : Logic / Controller
// DESCRIPTION : Master ChangeNotifier controller for Cash Book screen.
//               v2 — customLabelCtrl added for 'Other' category support.
//               Zero-lag state management — UI uses ListenableBuilder only.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../models/finance/cash_book/cash_transaction_model.dart';
import '../../../models/finance/cash_book/cash_book_summary_model.dart';
import '../../../repositories/finance/cash_book_repository.dart';

class CashBookController extends ChangeNotifier {
  CashBookController() {
    _init();
  }

  final CashBookRepository _repository = CashBookRepository();

  // ── View State ────────────────────────────────────────────────────────────
  CashBookViewMode _viewMode = CashBookViewMode.daily;
  CashBookFilter _filter = CashBookFilter.all;
  DateTime _activeDate = DateTime.now();

  CashBookViewMode get viewMode => _viewMode;
  CashBookFilter get filter => _filter;
  DateTime get activeDate => _activeDate;

  // ── Data State ────────────────────────────────────────────────────────────
  CashBookSummaryModel _summary = CashBookSummaryModel.loading();
  List<CashTransactionGroup> _groups = [];
  List<CashTransactionModel> _allTxns = [];
  bool _isLoading = true;
  String? _errorMessage;

  CashBookSummaryModel get summary => _summary;
  List<CashTransactionGroup> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Search ────────────────────────────────────────────────────────────────
  final TextEditingController searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Entry Form ────────────────────────────────────────────────────────────
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController partyNameCtrl = TextEditingController();
  final TextEditingController customLabelCtrl = TextEditingController(); // ✅ v2

  CashTransactionType _entryType = CashTransactionType.income;
  String _entryCategory = IncomeCategory.sale.dbValue;
  PaymentMode _entryMode = PaymentMode.cash;
  DateTime _entryDate = DateTime.now();
  bool _isSaving = false;

  CashTransactionType get entryType => _entryType;
  String get entryCategory => _entryCategory;
  PaymentMode get entryMode => _entryMode;
  DateTime get entryDate => _entryDate;
  bool get isSaving => _isSaving;

  /// Whether the currently selected category requires a custom label
  bool get entryNeedsCustomLabel {
    if (_entryType == CashTransactionType.income) {
      return IncomeCategory.fromDb(_entryCategory).requiresCustomLabel;
    }
    return ExpenseCategory.fromDb(_entryCategory).requiresCustomLabel;
  }

  // ── Stream ────────────────────────────────────────────────────────────────
  StreamSubscription<List<CashTransactionModel>>? _watchSub;

  // ==========================================================================
  // INIT
  // ==========================================================================

  void _init() {
    searchCtrl.addListener(_onSearchChanged);
    // ✅ BUG FIX: customLabelCtrl changes must trigger ListenableBuilder
    // so the Save button reactively enables/disables as user types
    customLabelCtrl.addListener(_notify);
    _startWatch();
  }

  void _notify() => notifyListeners();

  // ==========================================================================
  // LIVE WATCH
  // ==========================================================================

  void _startWatch() {
    _watchSub?.cancel();
    final range = _dateRange;

    _watchSub =
        _repository.watchTransactions(from: range.start, to: range.end).listen(
      (txns) async {
        _allTxns = txns;
        await _refreshSummary();
        _applyFiltersAndGroup();
      },
      onError: (e) {
        debugPrint('❌ CashBookController watch error: $e');
        _errorMessage = 'Failed to load transactions.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ==========================================================================
  // SUMMARY
  // ==========================================================================

  Future<void> _refreshSummary() async {
    final range = _dateRange;
    _summary = await _repository.computeSummary(
      from: range.start,
      to: range.end,
    );
    _isLoading = false;
    _errorMessage = null;
  }

  // ==========================================================================
  // FILTER + GROUP
  // ==========================================================================

  void _applyFiltersAndGroup() {
    var txns = List<CashTransactionModel>.from(_allTxns);

    if (_filter == CashBookFilter.incomeOnly) {
      txns = txns.where((t) => t.isIncome).toList();
    } else if (_filter == CashBookFilter.expenseOnly) {
      txns = txns.where((t) => t.isExpense).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      txns = txns.where((t) {
        return t.categoryLabel.toLowerCase().contains(q) ||
            (t.partyName?.toLowerCase().contains(q) ?? false) ||
            (t.description?.toLowerCase().contains(q) ?? false) ||
            (t.customLabel?.toLowerCase().contains(q) ?? false) ||
            t.txnId.toLowerCase().contains(q);
      }).toList();
    }

    _groups = _groupByDate(txns);
    notifyListeners();
  }

  List<CashTransactionGroup> _groupByDate(List<CashTransactionModel> txns) {
    final Map<String, List<CashTransactionModel>> map = {};

    for (final t in txns) {
      final key = DateFormat('yyyy-MM-dd').format(t.txnDate);
      map.putIfAbsent(key, () => []).add(t);
    }

    final groups = map.entries.map((e) {
      final list = e.value;
      final income =
          list.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
      final expense =
          list.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
      final date = DateFormat('yyyy-MM-dd').parse(e.key);

      return CashTransactionGroup(
        date: date,
        dateLabel: _buildDateLabel(date),
        transactions: list,
        groupIncome: income,
        groupExpense: expense,
        groupNet: income - expense,
      );
    }).toList();

    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  String _buildDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) {
      return 'Today — ${DateFormat('d MMM yyyy').format(date)}';
    }
    if (d == today.subtract(const Duration(days: 1))) {
      return 'Yesterday — ${DateFormat('d MMM yyyy').format(date)}';
    }
    return DateFormat('EEEE, d MMM yyyy').format(date);
  }

  // ==========================================================================
  // PUBLIC API — View Controls
  // ==========================================================================

  void setViewMode(CashBookViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    _isLoading = true;
    notifyListeners();
    _startWatch();
  }

  void setFilter(CashBookFilter f) {
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
  // PUBLIC API — Sync
  // ==========================================================================

  Future<void> syncTodaysBills() async {
    await _repository.syncBillsToIncome(DateTime.now());
  }

  // ==========================================================================
  // PUBLIC API — Entry Form
  // ==========================================================================

  void setEntryType(CashTransactionType type) {
    _entryType = type;
    _entryCategory = type == CashTransactionType.income
        ? IncomeCategory.sale.dbValue
        : ExpenseCategory.shopRent.dbValue;
    customLabelCtrl.clear(); // Reset custom label on type change
    notifyListeners();
  }

  void setEntryCategory(String categoryDbValue) {
    _entryCategory = categoryDbValue;
    customLabelCtrl.clear(); // Reset custom label on category change
    notifyListeners();
  }

  void setEntryMode(PaymentMode mode) {
    _entryMode = mode;
    notifyListeners();
  }

  void setEntryDate(DateTime date) {
    _entryDate = date;
    notifyListeners();
  }

  void resetEntryForm() {
    amountCtrl.clear();
    descriptionCtrl.clear();
    partyNameCtrl.clear();
    customLabelCtrl.clear();
    _entryType = CashTransactionType.income;
    _entryCategory = IncomeCategory.sale.dbValue;
    _entryMode = PaymentMode.cash;
    _entryDate = DateTime.now();
    notifyListeners();
  }

  Future<bool> saveEntry() async {
    final amountText = amountCtrl.text.trim();
    if (amountText.isEmpty) return false;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return false;

    // Validate: if 'Other' selected, customLabel must not be empty
    if (entryNeedsCustomLabel && customLabelCtrl.text.trim().isEmpty) {
      return false;
    }

    _isSaving = true;
    notifyListeners();

    final success = await _repository.saveTransaction(
      type: _entryType,
      categoryDbValue: _entryCategory,
      amount: amount,
      paymentMode: _entryMode,
      txnDate: _entryDate,
      customLabel: entryNeedsCustomLabel ? customLabelCtrl.text.trim() : null,
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

  Future<bool> voidTransaction(int id) async {
    return _repository.voidTransaction(id, 'Voided by user');
  }

  Future<bool> updateOpeningBalance(double amount) async {
    final success = await _repository.updateOpeningBalance(amount);
    if (success) await _refreshSummary();
    notifyListeners();
    return success;
  }

  // ==========================================================================
  // DISPLAY HELPERS
  // ==========================================================================

  String get activeDateLabel {
    switch (_viewMode) {
      case CashBookViewMode.daily:
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final d =
            DateTime(_activeDate.year, _activeDate.month, _activeDate.day);
        if (d == today) return 'Today';
        if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
        return DateFormat('d MMM yyyy').format(_activeDate);
      case CashBookViewMode.monthly:
        return DateFormat('MMMM yyyy').format(_activeDate);
      case CashBookViewMode.yearly:
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
    if (_entryType == CashTransactionType.income) {
      return IncomeCategory.values.map((e) => e.dbValue).toList();
    }
    return ExpenseCategory.values.map((e) => e.dbValue).toList();
  }

  String categoryLabel(String dbValue, CashTransactionType type) {
    if (type == CashTransactionType.income) {
      return IncomeCategory.fromDb(dbValue).displayLabel;
    }
    return ExpenseCategory.fromDb(dbValue).displayLabel;
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  ({DateTime start, DateTime end}) get _dateRange {
    switch (_viewMode) {
      case CashBookViewMode.daily:
        return (
          start: DateTime(_activeDate.year, _activeDate.month, _activeDate.day),
          end: DateTime(
              _activeDate.year, _activeDate.month, _activeDate.day, 23, 59, 59),
        );
      case CashBookViewMode.monthly:
        final last =
            DateTime(_activeDate.year, _activeDate.month + 1, 0, 23, 59, 59);
        return (
          start: DateTime(_activeDate.year, _activeDate.month, 1),
          end: last,
        );
      case CashBookViewMode.yearly:
        return (
          start: DateTime(_activeDate.year, 1, 1),
          end: DateTime(_activeDate.year, 12, 31, 23, 59, 59),
        );
    }
  }

  DateTime _shift(int delta) {
    switch (_viewMode) {
      case CashBookViewMode.daily:
        return _activeDate.add(Duration(days: delta));
      case CashBookViewMode.monthly:
        return DateTime(_activeDate.year, _activeDate.month + delta, 1);
      case CashBookViewMode.yearly:
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
    searchCtrl.removeListener(_onSearchChanged);
    customLabelCtrl.removeListener(_notify); // ✅ BUG FIX: cleanup listener
    searchCtrl.dispose();
    amountCtrl.dispose();
    descriptionCtrl.dispose();
    partyNameCtrl.dispose();
    customLabelCtrl.dispose();
    super.dispose();
  }
}
