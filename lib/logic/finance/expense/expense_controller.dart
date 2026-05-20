// =============================================================================
// FILE        : expense_controller.dart
// MODULE      : Expense Entry
// LAYER       : Logic / Controller
// DESCRIPTION : Master ChangeNotifier controller for Expense Entry screen.
//               ✅ ListenableBuilder — zero setState in UI layer.
//               ✅ Live stream watch (auto-updates list when DB changes).
//               ✅ Date navigation (daily / monthly / yearly).
//               ✅ Category filter + search + sort.
//               ✅ Entry form state with custom label support.
//               ✅ Void (soft delete) with reason dialog.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../models/finance/expense/expense_enums.dart';
import '../../../models/finance/expense/expense_model.dart';
import '../../../models/finance/expense/expense_summary_model.dart';
import '../../../repositories/finance/expense_repository.dart';

class ExpenseController extends ChangeNotifier {
  ExpenseController() {
    _init();
  }

  final ExpenseRepository _repository = ExpenseRepository();

  // ── View State ────────────────────────────────────────────────────────────
  ExpenseViewMode _viewMode = ExpenseViewMode.daily;
  ExpenseFilter _filter = ExpenseFilter.all;
  ExpenseSortOrder _sortOrder = ExpenseSortOrder.dateDesc;
  DateTime _activeDate = DateTime.now();

  ExpenseViewMode get viewMode => _viewMode;
  ExpenseFilter get filter => _filter;
  ExpenseSortOrder get sortOrder => _sortOrder;
  DateTime get activeDate => _activeDate;

  // ── Data State ────────────────────────────────────────────────────────────
  ExpenseSummaryModel _summary = ExpenseSummaryModel.loading();
  List<ExpenseGroup> _groups = [];
  List<ExpenseModel> _allItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  ExpenseSummaryModel get summary => _summary;
  List<ExpenseGroup> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalCount => _allItems.length;

  // ── Search ────────────────────────────────────────────────────────────────
  final TextEditingController searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Entry Form ────────────────────────────────────────────────────────────
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController partyNameCtrl = TextEditingController();
  final TextEditingController customLabelCtrl = TextEditingController();

  ExpenseCategory _entryCategory = ExpenseCategory.shopRent;
  PaymentMode _entryMode = PaymentMode.cash;
  DateTime _entryDate = DateTime.now();
  bool _isSaving = false;

  ExpenseCategory get entryCategory => _entryCategory;
  PaymentMode get entryMode => _entryMode;
  DateTime get entryDate => _entryDate;
  bool get isSaving => _isSaving;

  bool get entryNeedsCustomLabel =>
      _entryCategory == ExpenseCategory.otherExpense;

  // ── Stream ────────────────────────────────────────────────────────────────
  StreamSubscription<List<ExpenseModel>>? _watchSub;

  // ==========================================================================
  // INIT
  // ==========================================================================

  void _init() {
    searchCtrl.addListener(_onSearchChanged);
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
        _repository.watchExpenses(from: range.start, to: range.end).listen(
      (expenses) async {
        _allItems = expenses;
        await _refreshSummary();
        _applyFiltersAndGroup();
      },
      onError: (e) {
        debugPrint('❌ ExpenseController watch error: $e');
        _errorMessage = 'Failed to load expenses.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ==========================================================================
  // VIEW MODE NAVIGATION
  // ==========================================================================

  void setViewMode(ExpenseViewMode mode) {
    _viewMode = mode;
    _activeDate = DateTime.now();
    _isLoading = true;
    notifyListeners();
    _startWatch();
  }

  void goToPrevious() {
    _activeDate = _shift(-1);
    _isLoading = true;
    notifyListeners();
    _startWatch();
  }

  void goToNext() {
    final shifted = _shift(1);
    if (shifted.isAfter(DateTime.now())) return;
    _activeDate = shifted;
    _isLoading = true;
    notifyListeners();
    _startWatch();
  }

  void goToToday() {
    _activeDate = DateTime.now();
    _isLoading = true;
    notifyListeners();
    _startWatch();
  }

  bool get isAtToday {
    final now = DateTime.now();
    return switch (_viewMode) {
      ExpenseViewMode.daily => _activeDate.year == now.year &&
          _activeDate.month == now.month &&
          _activeDate.day == now.day,
      ExpenseViewMode.monthly =>
        _activeDate.year == now.year && _activeDate.month == now.month,
      ExpenseViewMode.yearly => _activeDate.year == now.year,
    };
  }

  DateTime _shift(int delta) {
    return switch (_viewMode) {
      ExpenseViewMode.daily => _activeDate.add(Duration(days: delta)),
      ExpenseViewMode.monthly =>
        DateTime(_activeDate.year, _activeDate.month + delta, 1),
      ExpenseViewMode.yearly =>
        DateTime(_activeDate.year + delta, _activeDate.month, 1),
    };
  }

  // ── Date range for current view ───────────────────────────────────────────

  ({DateTime start, DateTime end}) get _dateRange {
    final d = _activeDate;
    return switch (_viewMode) {
      ExpenseViewMode.daily => (
          start: DateTime(d.year, d.month, d.day),
          end: DateTime(d.year, d.month, d.day, 23, 59, 59)
        ),
      ExpenseViewMode.monthly => (
          start: DateTime(d.year, d.month, 1),
          end: DateTime(d.year, d.month + 1, 0, 23, 59, 59)
        ),
      ExpenseViewMode.yearly => (
          start: DateTime(d.year, 1, 1),
          end: DateTime(d.year, 12, 31, 23, 59, 59)
        ),
    };
  }

  String get headerLabel {
    return switch (_viewMode) {
      ExpenseViewMode.daily =>
        DateFormat('EEEE, d MMM yyyy').format(_activeDate),
      ExpenseViewMode.monthly => DateFormat('MMMM yyyy').format(_activeDate),
      ExpenseViewMode.yearly => DateFormat('yyyy').format(_activeDate),
    };
  }

  // ==========================================================================
  // FILTER & SORT
  // ==========================================================================

  void setFilter(ExpenseFilter f) {
    _filter = f;
    _applyFiltersAndGroup();
  }

  void setSortOrder(ExpenseSortOrder s) {
    _sortOrder = s;
    _applyFiltersAndGroup();
  }

  void _onSearchChanged() {
    _searchQuery = searchCtrl.text;
    _applyFiltersAndGroup();
  }

  void _applyFiltersAndGroup() {
    var items = List<ExpenseModel>.from(_allItems);

    // Category filter
    final catDb = _filter.dbCategory;
    if (catDb != null) {
      items = items.where((e) => e.categoryDbValue == catDb).toList();
    }

    // Search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      items = items.where((e) {
        return e.categoryLabel.toLowerCase().contains(q) ||
            (e.partyName?.toLowerCase().contains(q) ?? false) ||
            (e.description?.toLowerCase().contains(q) ?? false) ||
            (e.customLabel?.toLowerCase().contains(q) ?? false) ||
            e.expenseId.toLowerCase().contains(q);
      }).toList();
    }

    // Sort
    switch (_sortOrder) {
      case ExpenseSortOrder.dateDesc:
        items.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      case ExpenseSortOrder.dateAsc:
        items.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
      case ExpenseSortOrder.amountDesc:
        items.sort((a, b) => b.amount.compareTo(a.amount));
      case ExpenseSortOrder.amountAsc:
        items.sort((a, b) => a.amount.compareTo(b.amount));
    }

    _groups = _buildGroups(items);
    _isLoading = false;
    notifyListeners();
  }

  List<ExpenseGroup> _buildGroups(List<ExpenseModel> items) {
    final Map<String, List<ExpenseModel>> map = {};
    for (final item in items) {
      final key = DateFormat('yyyy-MM-dd').format(item.expenseDate);
      map.putIfAbsent(key, () => []).add(item);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return map.entries.map((e) {
      final date = DateTime.parse(e.key);
      final total = e.value.fold(0.0, (s, x) => s + x.amount);

      String headerLabel;
      if (date == today) {
        headerLabel = 'Today';
      } else if (date == yesterday) {
        headerLabel = 'Yesterday';
      } else {
        headerLabel = DateFormat('d MMMM yyyy').format(date);
      }

      return ExpenseGroup(
        headerLabel: headerLabel,
        date: date,
        entries: e.value,
        groupTotal: total,
        groupTotalFormatted: ExpenseModel.formatAmount(total),
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ==========================================================================
  // SUMMARY REFRESH
  // ==========================================================================

  Future<void> _refreshSummary() async {
    final range = _dateRange;
    _summary =
        await _repository.computeSummary(from: range.start, to: range.end);
  }

  // ==========================================================================
  // ENTRY FORM
  // ==========================================================================

  void resetEntryForm() {
    amountCtrl.clear();
    descriptionCtrl.clear();
    partyNameCtrl.clear();
    customLabelCtrl.clear();
    _entryCategory = ExpenseCategory.shopRent;
    _entryMode = PaymentMode.cash;
    _entryDate = DateTime.now();
    _isSaving = false;
  }

  void setEntryCategory(ExpenseCategory cat) {
    _entryCategory = cat;
    if (cat != ExpenseCategory.otherExpense) customLabelCtrl.clear();
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

  Future<bool> saveExpense() async {
    final amountText = amountCtrl.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) return false;
    if (entryNeedsCustomLabel && customLabelCtrl.text.trim().isEmpty) {
      return false;
    }

    _isSaving = true;
    notifyListeners();

    final ok = await _repository.saveExpense(
      category: _entryCategory,
      amount: amount,
      paymentMode: _entryMode,
      expenseDate: _entryDate,
      customLabel: customLabelCtrl.text.trim().isEmpty
          ? null
          : customLabelCtrl.text.trim(),
      description: descriptionCtrl.text.trim().isEmpty
          ? null
          : descriptionCtrl.text.trim(),
      partyName:
          partyNameCtrl.text.trim().isEmpty ? null : partyNameCtrl.text.trim(),
    );

    _isSaving = false;
    notifyListeners();
    return ok;
  }

  // ==========================================================================
  // VOID
  // ==========================================================================

  Future<bool> voidExpense(int id, String reason) async {
    final ok = await _repository.voidExpense(id, reason);
    return ok;
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _watchSub?.cancel();
    searchCtrl.removeListener(_onSearchChanged);
    customLabelCtrl.removeListener(_notify);
    searchCtrl.dispose();
    amountCtrl.dispose();
    descriptionCtrl.dispose();
    partyNameCtrl.dispose();
    customLabelCtrl.dispose();
    super.dispose();
  }
}
