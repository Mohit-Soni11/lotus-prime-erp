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
import '../../../core/logging/app_logger.dart';
import 'cash_book_export_service.dart';

class CashBookController extends ChangeNotifier {
  CashBookController({CashBookRepository? repository})
      : _repository = repository ?? CashBookRepository() {
    _init();
  }

  final CashBookRepository _repository;

  // ── View State ────────────────────────────────────────────────────────────
  CashBookFilter _filter = CashBookFilter.all;
  DateTime _activeDate = DateTime.now();

  CashBookFilter get filter => _filter;
  DateTime get activeDate => _activeDate;

  // ── Data State ────────────────────────────────────────────────────────────
  CashBookSummaryModel _summary = CashBookSummaryModel.loading();
  CashBookSummaryModel _monthSummary = CashBookSummaryModel.loading();
  List<CashTransactionGroup> _groups = [];
  List<CashTransactionModel> _allTxns = [];
  Map<int, double> _runningBalances = {};
  bool _isLoading = true;
  String? _errorMessage;

  CashBookSummaryModel get summary => _summary;
  CashBookSummaryModel get monthSummary => _monthSummary;
  List<CashTransactionGroup> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Entry Form ────────────────────────────────────────────────────────────
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController partyNameCtrl = TextEditingController();
  final TextEditingController customLabelCtrl = TextEditingController(); // ✅ v2

  String _entryCategory = IncomeCategory.miscIncome.dbValue;
  DateTime _entryDate = DateTime.now();
  bool _isSaving = false;
  String? _entryError;

  String get entryCategory => _entryCategory;
  DateTime get entryDate => _entryDate;
  bool get isSaving => _isSaving;
  String? get entryError => _entryError;

  /// Whether the currently selected category requires a custom label
  bool get entryNeedsCustomLabel =>
      IncomeCategory.fromDb(_entryCategory).requiresCustomLabel;

  // ── Stream ────────────────────────────────────────────────────────────────
  StreamSubscription<List<CashTransactionModel>>? _watchSub;
  int _watchGeneration = 0;

  // ==========================================================================
  // INIT
  // ==========================================================================

  void _init() {
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
    final generation = ++_watchGeneration;
    final range = _monthRange;
    final dayRange = _dateRange;

    _watchSub =
        _repository.watchTransactions(from: range.start, to: range.end).listen(
      (txns) async {
        try {
          final summary = await _repository.computeSummary(
              from: dayRange.start, to: dayRange.end);
          final monthSummary = await _repository.computeSummary(
              from: range.start, to: range.end);
          if (generation != _watchGeneration) return;
          _allTxns = txns;
          _summary = summary;
          _monthSummary = monthSummary;
          _computeRunningBalances();
          _isLoading = false;
          _errorMessage = null;
          _applyFiltersAndGroup();
        } catch (error, stackTrace) {
          if (generation != _watchGeneration) return;
          AppLogger.error('Cash Book could not refresh.',
              error: error, stackTrace: stackTrace);
          _errorMessage = 'Cash Book could not be loaded.';
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (e) {
        if (generation != _watchGeneration) return;
        AppLogger.debug('❌ CashBookController watch error: $e');
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
    final monthRange = _monthRange;
    _summary = await _repository.computeSummary(
      from: range.start,
      to: range.end,
    );
    _monthSummary = await _repository.computeSummary(
      from: monthRange.start,
      to: monthRange.end,
    );
    _computeRunningBalances();
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

    _groups = _groupByDate(txns);
    notifyListeners();
  }

  double? runningBalanceFor(int transactionId) =>
      _runningBalances[transactionId];

  CashBookExportData get exportData {
    final range = _dateRange;
    final transactions = _allTxns
        .where((txn) => DateUtils.isSameDay(txn.txnDate, _activeDate))
        .toList();
    return CashBookExportData(
      periodStart: range.start,
      periodEnd: range.end,
      summary: _summary,
      transactions: List.unmodifiable(transactions),
      runningBalances: Map.unmodifiable({
        for (final txn in transactions) txn.id: _runningBalances[txn.id]!,
      }),
    );
  }

  void _computeRunningBalances() {
    var balance = _monthSummary.closingBalance;
    final balances = <int, double>{};
    for (final txn in _allTxns) {
      balances[txn.id] = balance;
      balance += txn.isIncome ? -txn.amount : txn.amount;
    }
    _runningBalances = balances;
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

  void selectDate(DateTime date) {
    _activeDate = DateTime(date.year, date.month, date.day);
    _isLoading = true;
    _summary = CashBookSummaryModel.loading();
    _monthSummary = CashBookSummaryModel.loading();
    notifyListeners();
    _startWatch();
  }

  void setFilter(CashBookFilter f) {
    _filter = f;
    _applyFiltersAndGroup();
  }

  void retry() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _startWatch();
  }

  // ==========================================================================
  // PUBLIC API — Entry Form
  // ==========================================================================

  void setEntryCategory(String categoryDbValue) {
    _entryCategory = categoryDbValue;
    customLabelCtrl.clear(); // Reset custom label on category change
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
    _entryCategory = IncomeCategory.miscIncome.dbValue;
    _entryDate = DateTime.now();
    _entryError = null;
    notifyListeners();
  }

  Future<bool> saveEntry() async {
    if (_isSaving) return false;
    final amountText = amountCtrl.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || !amount.isFinite || amount <= 0) {
      _entryError = 'Enter an amount greater than zero.';
      notifyListeners();
      return false;
    }

    // Validate: if 'Other' selected, customLabel must not be empty
    if (entryNeedsCustomLabel && customLabelCtrl.text.trim().isEmpty) {
      _entryError = 'Enter a category name.';
      notifyListeners();
      return false;
    }
    if (descriptionCtrl.text.trim().isEmpty) {
      _entryError = 'Enter the reason for cash received.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _entryError = null;
    notifyListeners();

    final success = await _repository.saveExtraCashIncome(
      categoryDbValue: _entryCategory,
      amount: amount,
      txnDate: _entryDate,
      customLabel: entryNeedsCustomLabel ? customLabelCtrl.text.trim() : null,
      description: descriptionCtrl.text.trim().isEmpty
          ? null
          : descriptionCtrl.text.trim(),
      partyName:
          partyNameCtrl.text.trim().isEmpty ? null : partyNameCtrl.text.trim(),
    );

    _isSaving = false;
    if (success) {
      resetEntryForm();
    } else {
      _entryError =
          'Cash income could not be saved. Check whether this date is closed.';
    }
    notifyListeners();
    return success;
  }

  Future<bool> voidTransaction(int id, String reason) async {
    return _repository.voidTransaction(id, reason);
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

  List<String> get availableCategories {
    return [
      IncomeCategory.miscIncome.dbValue,
      IncomeCategory.otherIncome.dbValue
    ];
  }

  String categoryLabel(String dbValue) =>
      IncomeCategory.fromDb(dbValue).displayLabel;

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  ({DateTime start, DateTime end}) get _dateRange {
    return (
      start: DateTime(_activeDate.year, _activeDate.month, _activeDate.day),
      end: DateTime(
          _activeDate.year, _activeDate.month, _activeDate.day, 23, 59, 59),
    );
  }

  ({DateTime start, DateTime end}) get _monthRange {
    final nextMonth = DateTime(_activeDate.year, _activeDate.month + 1);
    return (
      start: DateTime(_activeDate.year, _activeDate.month),
      end: nextMonth.subtract(const Duration(seconds: 1)),
    );
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _watchGeneration++;
    _watchSub?.cancel();
    customLabelCtrl.removeListener(_notify); // ✅ BUG FIX: cleanup listener
    amountCtrl.dispose();
    descriptionCtrl.dispose();
    partyNameCtrl.dispose();
    customLabelCtrl.dispose();
    super.dispose();
  }
}
