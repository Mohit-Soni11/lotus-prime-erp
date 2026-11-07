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
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../models/reports/day_book/day_book_balance_verification.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../repositories/finance/cash_book_repository.dart';
import '../../../repositories/reports/day_book_balance_verification_repository.dart';
import '../../../repositories/reports/day_book_repository.dart';
import '../../../database/db/app_database.dart';
import '../../../features/finance/ledger/data/finance_day_closure_repository.dart';
import '../../../core/logging/app_logger.dart';
import 'day_book_close_authorization.dart';

class DayBookController extends ChangeNotifier {
  DayBookController() {
    _init();
  }

  final DayBookRepository _repo = DayBookRepository();
  final CashBookRepository _cashEntries = CashBookRepository();
  final DayBookBalanceVerificationRepository _balanceVerifications =
      DayBookBalanceVerificationRepository(AppDatabase());
  final FinanceDayClosureRepository _closures =
      FinanceDayClosureRepository(AppDatabase());
  final DayBookCloseAuthorization _closeAuthorization =
      DayBookCloseAuthorization();
  String? closeError;

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
  int _loadGeneration = 0;
  bool _disposed = false;

  DayBookSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DayBookBalanceVerification? _balanceVerification;
  DayBookBalanceVerification? get balanceVerification => _balanceVerification;

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

  // ==========================================================================
  // INIT
  // ==========================================================================
  void _init() {
    _setupDenomListeners();
    loadData();
    _startWatcher();
  }

  void _setupDenomListeners() {
    void update() {
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
      c.addListener(update);
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
    final generation = ++_loadGeneration;
    final requestedDate = _selectedDate;
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      _summary = null;
      notifyListeners();
    }

    try {
      final data = await _repo.fetchDayBook(requestedDate);
      if (_disposed || generation != _loadGeneration) return;

      final locked = await _closures.isClosed(requestedDate);
      if (_disposed || generation != _loadGeneration) return;

      final balanceVerification =
          await _balanceVerifications.fetch(requestedDate);
      if (_disposed || generation != _loadGeneration) return;

      _summary = data.withDayLocked(locked);
      _balanceVerification = balanceVerification;

      _errorMessage = null;
    } catch (e) {
      if (_disposed || generation != _loadGeneration) return;
      _errorMessage = e.toString();
      _summary = null;
      _balanceVerification = null;
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addManualCashIncome({
    required double amount,
    required String category,
    required String description,
    String? customLabel,
    String? partyName,
  }) async {
    final now = DateTime.now();
    final saved = await _cashEntries.saveExtraCashIncome(
      categoryDbValue: category,
      amount: amount,
      txnDate: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      ),
      description: description,
      customLabel: customLabel,
      partyName: partyName,
    );
    if (saved) await loadData(silent: true);
    return saved;
  }

  Future<DayBookBalanceVerification> verifyBalance({
    required double actualCash,
    required double actualBank,
    ExpenseCategory? cashExpenseCategory,
    String? cashReason,
    String? bankReason,
  }) async {
    final flow = _summary?.moneyFlow;
    if (flow == null) throw StateError('Recorded balance is unavailable.');
    final actorId = await _closeAuthorization.authorizedActorId(
      action: 'verify the opening balance',
    );
    final result = await _balanceVerifications.verify(
      date: _selectedDate,
      expectedCash: flow.openingCash,
      actualCash: actualCash,
      expectedBank: flow.openingBank,
      actualBank: actualBank,
      cashExpenseCategory: cashExpenseCategory,
      cashReason: cashReason,
      bankReason: bankReason,
      verifiedBy: actorId,
    );
    await loadData(silent: true);
    return result;
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
    _summary = _summary!.copyWith(anomalies: updated);
    notifyListeners();
  }

  // ==========================================================================
  // EOD HELPERS
  // ==========================================================================
  double get systemCashAmount => _summary?.closingCash ?? 0.0;
  double get physicalCashAmount => denomination.physicalTotal;
  double get cashDifference => physicalCashAmount - systemCashAmount;
  bool get isCashMatched => cashDifference.abs() < 1.0;
  bool get isMetalPositionVerified => _summary?.metalPositionVerified == true;
  bool get isCustodyPositionVerified =>
      _summary?.custodyPosition?.closingVerified == true;

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
  // Persists the close in the finance ledger database.
  // ==========================================================================
  Future<bool> closeDay() async {
    closeError = null;
    if (_balanceVerification == null) {
      closeError =
          'Verify today’s opening cash and bank in Set Balance before closing the day.';
      return false;
    }
    if (!isMetalPositionVerified) {
      closeError =
          'Owned metal opening and closing are not verified. Day closing is unavailable until stock reconciliation is complete.';
      return false;
    }
    if (!isCustodyPositionVerified) {
      closeError =
          'Girvi custody is not verified. Resolve missing handover dates before closing the day.';
      return false;
    }
    if (!isCashMatched) {
      closeError =
          'The physical cash count does not match the recorded cash balance.';
      return false;
    }
    try {
      final actorId = await _closeAuthorization.authorizedActorId();
      final closed = await _closures.closeDay(
        _selectedDate,
        closingCash: physicalCashAmount,
        closedBy: actorId,
      );
      if (!closed) {
        closeError =
            'Cash changed after the count. Refresh and recount before closing.';
        return false;
      }
      await loadData(silent: true);
      return true;
    } catch (e) {
      AppLogger.debug('❌ closeDay: $e');
      closeError = e.toString().replaceFirst('Bad state: ', '');
      return false;
    }
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================
  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++;
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
