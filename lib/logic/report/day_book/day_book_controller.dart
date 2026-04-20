// =============================================================================
// FILE        : day_book_controller.dart
// MODULE      : Reports & Analytics → Day Book
// LAYER       : Logic / Controller
// DESCRIPTION : PRODUCTION GRADE ChangeNotifier controller.
//               Exact same pattern as CashBookController.
//               • Date navigation with stream-based live updates
//               • Section expand/collapse state
//               • EOD denomination calculator
//               • Day lock via SharedPreferences
//               • Auto-refresh when CashTransactions table changes
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../repositories/reports/day_book_repository.dart';

class DayBookController extends ChangeNotifier {
  DayBookController() {
    _init();
  }

  final DayBookRepository _repo = DayBookRepository();

  // ── Date ──────────────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String get formattedDate =>
      DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.day == now.day &&
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year;
  }

  bool get canGoNext {
    final now = DateTime.now();
    return _selectedDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  // ── Data State ────────────────────────────────────────────────────────────
  DayBookSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  DayBookSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Section Expand/Collapse ───────────────────────────────────────────────
  bool cashInExpanded = true;
  bool cashOutExpanded = true;
  bool metalInExpanded = false;
  bool metalOutExpanded = false;
  bool paymentExpanded = false;
  bool gstExpanded = true;
  bool nonGstExpanded = true;
  // ✅ Sub-section toggles (used by _GstBillSubSection & _NonGstBillSubSection)
  bool gstSectionExpanded = true;
  bool nonGstSectionExpanded = true;

  // ── EOD State ─────────────────────────────────────────────────────────────
  DenominationCount denomination = DenominationCount();

  final TextEditingController denom500Ctrl = TextEditingController(text: '0');
  final TextEditingController denom200Ctrl = TextEditingController(text: '0');
  final TextEditingController denom100Ctrl = TextEditingController(text: '0');
  final TextEditingController denom50Ctrl = TextEditingController(text: '0');
  final TextEditingController denom20Ctrl = TextEditingController(text: '0');
  final TextEditingController denom10Ctrl = TextEditingController(text: '0');
  final TextEditingController denomCoinsCtrl = TextEditingController(text: '0');

  // ── Stream subscription for live updates ──────────────────────────────────
  StreamSubscription<void>? _watchSub;

  // ── Prefs key for day lock ────────────────────────────────────────────────
  String _lockKey(DateTime d) =>
      'day_book_locked_${DateFormat('yyyyMMdd').format(d)}';

  // ==========================================================================
  // INIT
  // ==========================================================================
  void _init() {
    _setupDenomListeners();
    loadData();
    _startWatcher();
  }

  void _setupDenomListeners() {
    void _update() {
      denomination = DenominationCount(
        note500: int.tryParse(denom500Ctrl.text) ?? 0,
        note200: int.tryParse(denom200Ctrl.text) ?? 0,
        note100: int.tryParse(denom100Ctrl.text) ?? 0,
        note50: int.tryParse(denom50Ctrl.text) ?? 0,
        note20: int.tryParse(denom20Ctrl.text) ?? 0,
        note10: int.tryParse(denom10Ctrl.text) ?? 0,
        coins: double.tryParse(denomCoinsCtrl.text) ?? 0,
      );
      notifyListeners();
    }

    for (final c in [
      denom500Ctrl,
      denom200Ctrl,
      denom100Ctrl,
      denom50Ctrl,
      denom20Ctrl,
      denom10Ctrl,
      denomCoinsCtrl,
    ]) {
      c.addListener(_update);
    }
  }

  // Start watching CashTransactions for real-time UI updates
  void _startWatcher() {
    _watchSub?.cancel();
    if (isToday) {
      _watchSub = _repo.watchTodayChanges().listen((_) {
        loadData(silent: true); // Reload without showing spinner
      });
    }
  }

  // ==========================================================================
  // LOAD DATA
  // ==========================================================================
  Future<void> loadData({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final data = await _repo.fetchDayBook(_selectedDate);

      // Check day lock from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final locked = prefs.getBool(_lockKey(_selectedDate)) ?? false;

      _summary = DayBookSummary(
        date: data.date,
        openingCash: data.openingCash,
        openingGoldGrams: data.openingGoldGrams,
        openingSilverGrams: data.openingSilverGrams,
        cashIn: data.cashIn,
        cashOut: data.cashOut,
        metalIn: data.metalIn,
        metalOut: data.metalOut,
        paymentBreakup: data.paymentBreakup,
        anomalies: data.anomalies,
        prediction: data.prediction,
        isDayLocked: locked,
      );

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _summary = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================================================
  // DATE NAVIGATION
  // ==========================================================================
  void goToPreviousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    _watchSub?.cancel();
    _startWatcher();
    loadData();
  }

  void goToNextDay() {
    if (!canGoNext) return;
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    _watchSub?.cancel();
    _startWatcher();
    loadData();
  }

  void goToToday() {
    _selectedDate = DateTime.now();
    _watchSub?.cancel();
    _startWatcher();
    loadData();
  }

  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFD4AF37),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _selectedDate = picked;
      _watchSub?.cancel();
      _startWatcher();
      loadData();
    }
  }

  // ==========================================================================
  // SECTION TOGGLES
  // ==========================================================================
  void toggleCashIn() {
    cashInExpanded = !cashInExpanded;
    notifyListeners();
  }

  void toggleCashOut() {
    cashOutExpanded = !cashOutExpanded;
    notifyListeners();
  }

  void toggleMetalIn() {
    metalInExpanded = !metalInExpanded;
    notifyListeners();
  }

  void toggleMetalOut() {
    metalOutExpanded = !metalOutExpanded;
    notifyListeners();
  }

  void togglePayment() {
    paymentExpanded = !paymentExpanded;
    notifyListeners();
  }

  void toggleGst() {
    gstExpanded = !gstExpanded;
    notifyListeners();
  }

  void toggleNonGst() {
    nonGstExpanded = !nonGstExpanded;
    notifyListeners();
  }

  // ✅ Sub-section toggles for GST & Non-GST bill cards inside Cash In
  void toggleGstSection() {
    gstSectionExpanded = !gstSectionExpanded;
    notifyListeners();
  }

  void toggleNonGstSection() {
    nonGstSectionExpanded = !nonGstSectionExpanded;
    notifyListeners();
  }

  // ==========================================================================
  // ANOMALY DISMISS
  // ==========================================================================
  void dismissAnomaly(int index) {
    if (_summary == null) return;
    final updated = List<AnomalyAlert>.from(_summary!.anomalies)
      ..removeAt(index);
    _summary = DayBookSummary(
      date: _summary!.date,
      openingCash: _summary!.openingCash,
      openingGoldGrams: _summary!.openingGoldGrams,
      openingSilverGrams: _summary!.openingSilverGrams,
      cashIn: _summary!.cashIn,
      cashOut: _summary!.cashOut,
      metalIn: _summary!.metalIn,
      metalOut: _summary!.metalOut,
      paymentBreakup: _summary!.paymentBreakup,
      anomalies: updated,
      prediction: _summary!.prediction,
      isDayLocked: _summary!.isDayLocked,
    );
    notifyListeners();
  }

  // ==========================================================================
  // EOD HELPERS
  // ==========================================================================
  double get systemCashAmount => _summary?.closingCash ?? 0.0;
  double get physicalCashAmount => denomination.physicalTotal;
  double get cashDifference => physicalCashAmount - systemCashAmount;
  bool get isCashMatched => cashDifference.abs() < 1.0;

  void resetDenomination() {
    for (final c in [
      denom500Ctrl,
      denom200Ctrl,
      denom100Ctrl,
      denom50Ctrl,
      denom20Ctrl,
      denom10Ctrl,
      denomCoinsCtrl,
    ]) {
      c.text = '0';
    }
    denomination = DenominationCount();
    notifyListeners();
  }

  // ==========================================================================
  // CLOSE DAY & LOCK LEDGER
  // Persists lock flag to SharedPreferences
  // ==========================================================================
  Future<bool> closeDay() async {
    if (!isCashMatched) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lockKey(_selectedDate), true);
      await loadData(silent: true);
      return true;
    } catch (e) {
      debugPrint('❌ closeDay: $e');
      return false;
    }
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================
  @override
  void dispose() {
    _watchSub?.cancel();
    denom500Ctrl.dispose();
    denom200Ctrl.dispose();
    denom100Ctrl.dispose();
    denom50Ctrl.dispose();
    denom20Ctrl.dispose();
    denom10Ctrl.dispose();
    denomCoinsCtrl.dispose();
    super.dispose();
  }
}
