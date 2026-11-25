import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../models/reports/day_book/day_book_balance_verification.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../repositories/reports/day_book_manual_income_repository.dart';
import '../../../repositories/reports/day_book_balance_verification_repository.dart';
import '../../../repositories/reports/day_book_repository.dart';
import '../../../repositories/reports/day_book_metal_verification_repository.dart';
import '../../../models/reports/day_book/day_book_metal_count.dart';
import '../../../database/db/app_database.dart';
import '../../../features/finance/ledger/data/finance_day_closure_repository.dart';
import '../../../features/finance/ledger/data/finance_session_closure_repository.dart';
import '../../../core/logging/app_logger.dart';
import 'day_book_close_authorization.dart';

class DayBookController extends ChangeNotifier {
  DayBookController({DateTime? initialDate}) {
    if (initialDate != null) {
      _selectedDate =
          DateTime(initialDate.year, initialDate.month, initialDate.day);
    }
    _init();
  }

  final DayBookRepository _repo = DayBookRepository();
  final DayBookManualIncomeRepository _manualIncome =
      DayBookManualIncomeRepository(AppDatabase());
  final DayBookBalanceVerificationRepository _balanceVerifications =
      DayBookBalanceVerificationRepository(AppDatabase());
  final FinanceDayClosureRepository _closures =
      FinanceDayClosureRepository(AppDatabase());
  final FinanceSessionClosureRepository _sessionClosures =
      FinanceSessionClosureRepository(AppDatabase());
  final DayBookMetalVerificationRepository _metalVerifications =
      DayBookMetalVerificationRepository(AppDatabase());
  final DayBookCloseAuthorization _closeAuthorization =
      DayBookCloseAuthorization();
  String? closeError;
  bool _lastCloseSucceeded = false;
  bool get lastCloseSucceeded => _lastCloseSucceeded;

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

  Future<List<DayBookMetalCountLine>> loadMetalCountLines() =>
      _metalVerifications.expected();

  Future<void> verifyPhysicalMetal(
      List<DayBookPhysicalMetalCount> counts, bool emptyStockConfirmed) async {
    final actorId = await _closeAuthorization.authorizedActorId(
        action: 'verify physical metal stock');
    await _metalVerifications.verify(
      day: _selectedDate,
      actor: actorId,
      physical: counts,
      emptyStockConfirmed: emptyStockConfirmed,
    );
    await loadData(silent: true);
  }

  // ── EOD State ─────────────────────────────────────────────────────────────
  DenominationCount denomination = DenominationCount();

  final TextEditingController denom500Ctrl = TextEditingController(text: '0');
  final TextEditingController denom200Ctrl = TextEditingController(text: '0');
  final TextEditingController denom100Ctrl = TextEditingController(text: '0');
  final TextEditingController denom50Ctrl = TextEditingController(text: '0');
  final TextEditingController denom20Ctrl = TextEditingController(text: '0');
  final TextEditingController denom10Ctrl = TextEditingController(text: '0');
  final TextEditingController denomCoinsCtrl = TextEditingController(text: '0');
  final TextEditingController closingBankCtrl = TextEditingController();
  bool closingCashCountEntered = false;
  bool closingZeroCashConfirmed = false;
  bool _resettingClosingDraft = false;

  void markClosingCashCountEntered() {
    if (closingCashCountEntered) return;
    closingCashCountEntered = true;
    notifyListeners();
  }

  void setClosingZeroCashConfirmed(bool value) {
    if (closingZeroCashConfirmed == value) return;
    closingZeroCashConfirmed = value;
    notifyListeners();
  }

  void resetClosingDraft() {
    _lastCloseSucceeded = false;
    _resettingClosingDraft = true;
    try {
      for (final controller in [
        denom500Ctrl,
        denom200Ctrl,
        denom100Ctrl,
        denom50Ctrl,
        denom20Ctrl,
        denom10Ctrl,
        denomCoinsCtrl,
      ]) {
        controller.text = '0';
      }
      denomination = DenominationCount();
      closingCashCountEntered = false;
      closingZeroCashConfirmed = false;
      closingBankCtrl.clear();
    } finally {
      _resettingClosingDraft = false;
    }
    notifyListeners();
  }

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
      if (_resettingClosingDraft) return;
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

  // Keep the selected date current as source modules post or correct records.
  void _startWatcher() {
    _watchSub?.cancel();
    _watchSub = _repo.watchDayChanges(_selectedDate).listen(
      (_) => loadData(silent: true),
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed) return;
        AppLogger.debug('Day Book source watcher failed: $error\n$stackTrace');
        _errorMessage = error.toString();
        _summary = null;
        notifyListeners();
      },
    );
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

      // A counter-session close is deliberately not a daily source lock. Only
      // legacy/finalised dates before today stay read-only.
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final locked = requestedDate.isBefore(todayStart) &&
          await _closures.isClosed(requestedDate);
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

  Future<List<ManualIncomeBankAccount>> loadIncomeBankAccounts() =>
      _manualIncome.listActiveBankAccounts();

  Future<bool> addManualIncome({
    required double amount,
    required String category,
    required PaymentMode paymentMode,
    int? bankAccountId,
    String? customLabel,
  }) async {
    final now = DateTime.now();
    final saved = await _manualIncome.save(
      category: IncomeCategory.fromDb(category),
      amount: amount,
      paymentMode: paymentMode,
      bankAccountId: bankAccountId,
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      ),
      customLabel: customLabel,
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
    resetClosingDraft();
    _watchSub?.cancel();
    _startWatcher();
    loadData();
  }

  void goToNextDay() {
    if (!canGoNext) return;
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    resetClosingDraft();
    _watchSub?.cancel();
    _startWatcher();
    loadData();
  }

  void goToToday() {
    final today = DateTime.now();
    if (DateUtils.isSameDay(_selectedDate, today)) return;
    _selectedDate = DateTime(today.year, today.month, today.day);
    resetClosingDraft();
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
    if (picked != null && !DateUtils.isSameDay(picked, _selectedDate)) {
      _selectedDate = picked;
      resetClosingDraft();
      _watchSub?.cancel();
      _startWatcher();
      loadData();
    }
  }

  // ==========================================================================
  // EOD HELPERS
  // ==========================================================================
  double get systemCashAmount => _summary?.moneyFlow?.closingCash ?? 0.0;
  double get physicalCashAmount => denomination.physicalTotal;
  double get cashDifference => physicalCashAmount - systemCashAmount;
  bool get isCashMatched =>
      _summary?.moneyFlow != null && cashDifference.abs() < 0.01;
  bool get isMetalPositionVerified => _summary?.metalPositionVerified == true;
  bool get isRecordedMetalPositionConsistent {
    final position = _summary?.ownedStockPosition;
    return position != null &&
        position.gold.isConsistent &&
        position.silver.isConsistent;
  }

  bool get isCustodyPositionVerified =>
      _summary?.custodyPosition?.closingVerified == true;

  // ==========================================================================
  // CLOSE COUNTER SESSION
  // Persists immutable evidence without locking same-date source activity.
  // ==========================================================================
  Future<bool> closeDay({required double physicalBank}) async {
    _lastCloseSucceeded = false;
    closeError = null;
    final money = _summary?.moneyFlow;
    if (money == null) {
      closeError =
          'Day Book closing balances are unavailable. Refresh and retry.';
      return false;
    }
    if (!physicalBank.isFinite ||
        (physicalBank - money.closingBank).abs() >= 0.01) {
      closeError =
          'The bank balance does not match the recorded closing balance.';
      return false;
    }
    if (!isRecordedMetalPositionConsistent) {
      closeError =
          'Recorded gold or silver closing is unavailable or inconsistent. Review stock records before closing.';
      return false;
    }
    if (!isCustodyPositionVerified) {
      closeError =
          'Girvi custody handover dates are incomplete. Resolve missing dates before closing the day.';
      return false;
    }
    if (!isCashMatched) {
      closeError =
          'The physical cash count does not match the recorded cash balance.';
      return false;
    }
    try {
      final actorId = await _closeAuthorization.authorizedActorId();
      final closed = await _sessionClosures.closeSession(
        _selectedDate,
        closingCash: physicalCashAmount,
        physicalBank: physicalBank,
        closedBy: actorId,
        denominationCount: {
          '500': denomination.note500,
          '200': denomination.note200,
          '100': denomination.note100,
          '50': denomination.note50,
          '20': denomination.note20,
          '10': denomination.note10,
          'coins': denomination.coins,
        },
      );
      if (!closed) {
        closeError =
            'Cash or bank changed after the count. Refresh and recount before closing.';
        return false;
      }
      _lastCloseSucceeded = true;
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
    closingBankCtrl.dispose();
    super.dispose();
  }
}
