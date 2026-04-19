// =============================================================================
// FILE        : new_girvi_controller.dart
// MODULE      : Girvi / Pawn
// LAYER       : Logic / Controller
// DESCRIPTION : ChangeNotifier controller for the New Girvi screen.
//               Handles: customer selection, item entry, weight calculation,
//               valuation, loan amount computation, ticket generation,
//               form validation, and DB save.
//               Zero setState in UI — UI uses ListenableBuilder only.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../repositories/girvi/girvi_repository.dart';

class NewGirviController extends ChangeNotifier {

  final GirviRepository _repo;

  NewGirviController(AppDatabase db)
      : _repo = GirviRepository(db);

  // ── TICKET ────────────────────────────────────────────────────────────────
  String _ticketNo = '';
  String get ticketNo => _ticketNo;

  // ── CUSTOMER ──────────────────────────────────────────────────────────────
  Customer? _selectedCustomer;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get hasCustomer => _selectedCustomer != null;

  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void clearCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }

  // ── ITEM DETAILS ──────────────────────────────────────────────────────────
  int _itemCount = 1;
  int get itemCount => _itemCount;

  void setItemCount(int count) {
    _itemCount = count.clamp(1, 99);
    notifyListeners();
  }

  MetalType _metalType = MetalType.gold;
  MetalType get metalType => _metalType;

  void setMetalType(MetalType v) {
    _metalType = v;
    // Reset purity to relevant default
    if (v == MetalType.gold) {
      _metalPurity = MetalPurity.k22;
    } else if (v == MetalType.silver) {
      _metalPurity = MetalPurity.s925;
    } else {
      _metalPurity = MetalPurity.k22;
    }
    _recalculate();
    notifyListeners();
  }

  MetalPurity _metalPurity = MetalPurity.k22;
  MetalPurity get metalPurity => _metalPurity;

  void setMetalPurity(MetalPurity v) {
    _metalPurity = v;
    _recalculate();
    notifyListeners();
  }

  // ── WEIGHT ────────────────────────────────────────────────────────────────
  double _grossWeight = 0.0;
  double _stoneWeight = 0.0;
  double get grossWeight => _grossWeight;
  double get stoneWeight => _stoneWeight;

  double get netWeight =>
      (_grossWeight - _stoneWeight).clamp(0.0, double.infinity);

  void onGrossWeightChanged(String v) {
    _grossWeight = double.tryParse(v) ?? 0.0;
    _recalculate();
    notifyListeners();
  }

  void onStoneWeightChanged(String v) {
    _stoneWeight = double.tryParse(v) ?? 0.0;
    _recalculate();
    notifyListeners();
  }

  // ── VALUATION ─────────────────────────────────────────────────────────────
  double _ratePerGram = 0.0;
  double get ratePerGram => _ratePerGram;

  /// Computed: netWeight × ratePerGram
  double get totalValue => netWeight * _ratePerGram;

  void onRatePerGramChanged(String v) {
    _ratePerGram = double.tryParse(v) ?? 0.0;
    _recalculate();
    notifyListeners();
  }

  // ── LOAN AMOUNT ───────────────────────────────────────────────────────────
  double _loanAmount     = 0.0;
  double _ltvPercent     = 70.0; // default 70% LTV
  double get loanAmount  => _loanAmount;
  double get ltvPercent  => _ltvPercent;

  /// Computed from loanAmount / totalValue
  double get computedLtv =>
      totalValue > 0 ? ((_loanAmount / totalValue) * 100) : 0.0;

  void onLoanAmountChanged(String v) {
    _loanAmount = double.tryParse(v) ?? 0.0;
    _ltvPercent = computedLtv;
    notifyListeners();
  }

  /// Called when user changes LTV slider — auto-fills loan amount
  void onLtvChanged(double ltv) {
    _ltvPercent = ltv;
    _loanAmount = totalValue * (ltv / 100);
    notifyListeners();
  }

  /// Auto-suggest loan amount at given LTV %
  double suggestedLoanAt(double ltv) => totalValue * (ltv / 100);

  // ── INTEREST RATE ─────────────────────────────────────────────────────────
  double _interestRate = 2.0; // 2% per month default
  int    _durationMonths = 12;

  double get interestRate    => _interestRate;
  int    get durationMonths  => _durationMonths;

  void onInterestRateChanged(String v) {
    _interestRate = double.tryParse(v) ?? 2.0;
    notifyListeners();
  }

  void onDurationChanged(String v) {
    _durationMonths = int.tryParse(v) ?? 12;
    notifyListeners();
  }

  // ── DISBURSEMENT MODE ─────────────────────────────────────────────────────
  GirviPaymentMode _disbursementMode = GirviPaymentMode.cash;
  GirviPaymentMode get disbursementMode => _disbursementMode;

  void setDisbursementMode(GirviPaymentMode v) {
    _disbursementMode = v;
    notifyListeners();
  }

  // ── START DATE ────────────────────────────────────────────────────────────
  DateTime _startDate = DateTime.now();
  DateTime get startDate => _startDate;

  /// Computed maturity date
  DateTime get maturityDate {
    int month = _startDate.month + _durationMonths;
    int year  = _startDate.year;
    while (month > 12) {
      month -= 12;
      year++;
    }
    final day = _startDate.day;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }

  void setStartDate(DateTime d) {
    _startDate = d;
    notifyListeners();
  }

  // ── KYC ───────────────────────────────────────────────────────────────────
  GirviIdProofType? _idProofType;
  GirviIdProofType? get idProofType => _idProofType;

  void setIdProofType(GirviIdProofType? v) {
    _idProofType = v;
    notifyListeners();
  }

  // ── COMPUTED INTEREST PREVIEW ─────────────────────────────────────────────
  double get monthlyInterest => _loanAmount * (_interestRate / 100);
  double get totalInterestAtMaturity => monthlyInterest * _durationMonths;
  double get totalDueAtMaturity => _loanAmount + totalInterestAtMaturity;

  // ── STATUS ────────────────────────────────────────────────────────────────
  bool    _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  bool    _initialized = false;

  bool    get isSaving      => _isSaving;
  String? get errorMessage  => _errorMessage;
  String? get successMessage => _successMessage;
  bool    get isFormReady   => hasCustomer && _loanAmount > 0 && netWeight > 0;

  // ── INIT ──────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _ticketNo = await _repo.generateNextTicketNo();
    } catch (e) {
      _ticketNo = 'GRV/${DateTime.now().year}/-----';
      debugPrint('NewGirviController.initialize error: $e');
    }
    notifyListeners();
  }

  // ── RECALCULATE ───────────────────────────────────────────────────────────

  void _recalculate() {
    // Re-apply LTV to update loanAmount if total value changed
    if (_ltvPercent > 0 && totalValue > 0) {
      _loanAmount = totalValue * (_ltvPercent / 100);
    }
  }

  // ── VALIDATION ────────────────────────────────────────────────────────────

  String? validateItemDescription(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Item description is required';
    }
    if (v.trim().length < 3) {
      return 'Description too short';
    }
    return null;
  }

  String? validateGrossWeight(String? v) {
    if (v == null || v.isEmpty) return 'Enter gross weight';
    final d = double.tryParse(v);
    if (d == null || d <= 0) return 'Enter valid weight (> 0)';
    return null;
  }

  String? validateRatePerGram(String? v) {
    if (v == null || v.isEmpty) return 'Enter rate per gram';
    final d = double.tryParse(v);
    if (d == null || d <= 0) return 'Enter valid rate (> 0)';
    return null;
  }

  String? validateLoanAmount(String? v) {
    if (v == null || v.isEmpty) return 'Enter loan amount';
    final d = double.tryParse(v);
    if (d == null || d <= 0) return 'Amount must be > 0';
    if (totalValue > 0 && d > totalValue) {
      return 'Loan cannot exceed item value (₹${totalValue.toStringAsFixed(0)})';
    }
    return null;
  }

  String? validateInterestRate(String? v) {
    if (v == null || v.isEmpty) return 'Enter interest rate';
    final d = double.tryParse(v);
    if (d == null || d < 0) return 'Rate must be ≥ 0';
    if (d > 30) return 'Rate seems too high (max 30%)';
    return null;
  }

  String? validateDuration(String? v) {
    if (v == null || v.isEmpty) return 'Enter duration';
    final i = int.tryParse(v);
    if (i == null || i < 1) return 'Duration must be ≥ 1 month';
    if (i > 120) return 'Max 120 months (10 years)';
    return null;
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────

  Future<bool> saveLoan({
    required String itemDescription,
    required String? idProofNumber,
    required String? notes,
  }) async {
    if (!hasCustomer) {
      _errorMessage = 'Please select a customer first';
      notifyListeners();
      return false;
    }
    if (netWeight <= 0) {
      _errorMessage = 'Net weight must be greater than zero';
      notifyListeners();
      return false;
    }
    if (_loanAmount <= 0) {
      _errorMessage = 'Loan amount must be greater than zero';
      notifyListeners();
      return false;
    }

    _isSaving     = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final companion = GirviLoansCompanion.insert(
        ticketNo:        _ticketNo,
        customerId:      _selectedCustomer!.id,
        itemDescription: itemDescription.trim(),
        itemCount:       drift.Value(_itemCount),
        metalType:       drift.Value(_metalType.dbValue),
        metalPurity:     drift.Value(_metalPurity.dbValue),
        grossWeight:     drift.Value(_grossWeight),
        stoneWeight:     drift.Value(_stoneWeight),
        netWeight:       drift.Value(netWeight),
        ratePerGram:     drift.Value(_ratePerGram),
        totalValue:      drift.Value(totalValue),
        ltvPercent:      drift.Value(computedLtv),
        loanAmount:      drift.Value(_loanAmount),
        interestRate:    drift.Value(_interestRate),
        durationMonths:  drift.Value(_durationMonths),
        disbursementMode: drift.Value(_disbursementMode.dbValue),
        startDate:       drift.Value(_startDate),
        maturityDate:    drift.Value(maturityDate),
        idProofType:     drift.Value(_idProofType?.dbValue),
        idProofNumber:   drift.Value(idProofNumber?.trim().isEmpty == true ? null : idProofNumber?.trim()),
        notes:           drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      );

      await _repo.createLoan(companion);

      _successMessage = 'Girvi ticket $_ticketNo created successfully!';
      _isSaving       = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('NewGirviController.saveLoan error: $e');
      _errorMessage = 'Failed to save girvi. Please try again.';
      _isSaving     = false;
      notifyListeners();
      return false;
    }
  }

  // ── RESET ─────────────────────────────────────────────────────────────────

  Future<void> resetForm() async {
    _selectedCustomer  = null;
    _itemCount         = 1;
    _metalType         = MetalType.gold;
    _metalPurity       = MetalPurity.k22;
    _grossWeight       = 0.0;
    _stoneWeight       = 0.0;
    _ratePerGram       = 0.0;
    _ltvPercent        = 70.0;
    _loanAmount        = 0.0;
    _interestRate      = 2.0;
    _durationMonths    = 12;
    _disbursementMode  = GirviPaymentMode.cash;
    _startDate         = DateTime.now();
    _idProofType       = null;
    _errorMessage      = null;
    _successMessage    = null;
    _initialized       = false;
    await initialize(); // regenerates ticket number
  }
}
