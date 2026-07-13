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

import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_persistence_models.dart';
import '../../models/setting/billing_setup/girvi_billing_model.dart';
import '../../repositories/girvi/girvi_details_repository.dart';
import '../../repositories/girvi/girvi_repository.dart';
import '../../repositories/setting/billing_setup/girvi_billing_repo.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class NewGirviController extends ChangeNotifier {
  final AppDatabase _db;
  final GirviRepository _repo;
  final GirviDetailsRepository _detailsRepo;
  final GirviBillingRepo _billingRepo;

  NewGirviController(
    AppDatabase db, {
    GirviBillingRepo? billingRepo,
  })  : _db = db,
        _repo = GirviRepository(db),
        _detailsRepo = GirviDetailsRepository(db),
        _billingRepo = billingRepo ?? GirviBillingRepo(db: db);

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
  double _loanAmount = 0.0;
  double _ltvPercent = 50.0;
  double get loanAmount => _loanAmount;
  double get ltvPercent => _ltvPercent;

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
  double _interestRate = 5.0;
  int _durationMonths = 12;

  double get interestRate => _interestRate;
  int get durationMonths => _durationMonths;

  void onInterestRateChanged(String v) {
    _interestRate = double.tryParse(v) ?? 5.0;
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
    int year = _startDate.year;
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
  bool _isSaving = false;
  bool _isLoadingEdit = false;
  bool _isEditMode = false;
  int? _editingLoanId;
  int? _lastSavedLoanId;
  GirviLoanDetails? _editingDetails;
  String? _errorMessage;
  String? _successMessage;
  bool _initialized = false;

  bool get isSaving => _isSaving;
  bool get isLoadingEdit => _isLoadingEdit;
  bool get isEditMode => _isEditMode;
  int? get editingLoanId => _editingLoanId;
  int? get lastSavedLoanId => _lastSavedLoanId;
  GirviLoanDetails? get editingDetails => _editingDetails;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isFormReady => hasCustomer && _loanAmount > 0 && netWeight > 0;
  GirviBillingModel _billingSettings = GirviBillingModel.defaults;
  GirviBillingModel get billingSettings => _billingSettings;

  // ── INIT ──────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _billingSettings = await _billingRepo.fetch();
      _interestRate = _billingSettings.defaultInterestRate;
      _durationMonths = _durationMonthsFromLabel(
        _billingSettings.defaultDuration,
      );
      _ticketNo = await _repo.generateNextTicketNo(
        prefix: _billingSettings.girviPrefix,
        startingNumber: _billingSettings.startingNumber,
      );
    } catch (e) {
      _billingSettings = GirviBillingModel.defaults;
      _interestRate = _billingSettings.defaultInterestRate;
      _durationMonths =
          _durationMonthsFromLabel(_billingSettings.defaultDuration);
      _ticketNo = 'GRV-----';
      AppLogger.debug('NewGirviController.initialize error: $e');
    }
    notifyListeners();
  }

  Future<bool> initializeForEdit(int loanId) async {
    if (_initialized && _editingLoanId == loanId && _editingDetails != null) {
      return true;
    }

    _initialized = true;
    _isLoadingEdit = true;
    _isEditMode = true;
    _editingLoanId = loanId;
    _lastSavedLoanId = loanId;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _billingSettings = await _billingRepo.fetch();
      final details = await _detailsRepo.getLoanDetails(loanId);
      if (details == null) {
        _errorMessage = 'Selected Girvi ticket could not be found.';
        _isLoadingEdit = false;
        notifyListeners();
        return false;
      }

      final customer = await (_db.select(_db.customers)
            ..where((row) => row.id.equals(details.loan.customerId)))
          .getSingleOrNull();
      if (customer == null) {
        _errorMessage =
            'Customer details for this Girvi ticket could not be loaded.';
        _isLoadingEdit = false;
        notifyListeners();
        return false;
      }

      final loan = details.loan;
      _editingDetails = details;
      _selectedCustomer = customer;
      _ticketNo = loan.ticketNo;
      _itemCount = loan.itemCount.clamp(1, 99);
      _metalType = MetalType.fromDb(loan.metalType);
      _metalPurity = MetalPurity.fromDb(loan.metalPurity);
      _grossWeight = loan.grossWeight;
      _stoneWeight = loan.stoneWeight;
      _ratePerGram = loan.ratePerGram;
      _loanAmount = loan.loanAmount;
      _ltvPercent = loan.ltvPercent;
      _interestRate = loan.interestRate;
      _durationMonths = loan.durationMonths;
      _startDate = loan.startDate;
      _idProofType = loan.idProofType == null
          ? null
          : GirviIdProofType.fromDb(loan.idProofType!);
      if (details.disbursements.isNotEmpty) {
        _disbursementMode =
            GirviPaymentMode.fromDb(details.disbursements.first.mode);
      } else {
        _disbursementMode = GirviPaymentMode.fromDb(loan.disbursementMode);
      }

      _isLoadingEdit = false;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.debug('NewGirviController.initializeForEdit error: $e');
      _errorMessage = 'Girvi ticket could not be loaded for editing.';
      _isLoadingEdit = false;
      notifyListeners();
      return false;
    }
  }

  int _durationMonthsFromLabel(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return (int.tryParse(match?.group(0) ?? '') ?? 6).clamp(1, 120);
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
      return 'Loan cannot exceed item value (Rs ${totalValue.toStringAsFixed(0)})';
    }
    return null;
  }

  String? validateInterestRate(String? v) {
    if (v == null || v.isEmpty) return 'Enter interest rate';
    final d = double.tryParse(v);
    if (d == null || d < 0) return 'Rate must be at least 0';
    if (d > 30) return 'Rate seems too high (max 30%)';
    return null;
  }

  String? validateDuration(String? v) {
    if (v == null || v.isEmpty) return 'Enter duration';
    final i = int.tryParse(v);
    if (i == null || i < 1) return 'Duration must be at least 1 month';
    if (i > 120) return 'Max 120 months (10 years)';
    return null;
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────

  Future<bool> saveLoan({
    required List<GirviLoanItemInput> items,
    required List<GirviDisbursementInput> disbursements,
    required bool invoiceGenerated,
    required String? idProofNumber,
    required String? idProofImagePath,
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
    if (_ticketNo.trim().isEmpty || _ticketNo.contains('---')) {
      _errorMessage = 'Ticket number is not ready. Please reopen this screen.';
      notifyListeners();
      return false;
    }
    if (items.isEmpty) {
      _errorMessage = 'Please add at least one pledged item';
      notifyListeners();
      return false;
    }

    final totalItemValue =
        items.fold<double>(0.0, (sum, item) => sum + item.valuationAmount);
    if (totalItemValue <= 0) {
      _errorMessage = 'Pledged item valuation must be greater than zero';
      notifyListeners();
      return false;
    }
    if (_loanAmount - totalItemValue > 0.50) {
      _errorMessage = 'Loan amount cannot exceed pledged item valuation';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _lastSavedLoanId = _isEditMode ? _editingLoanId : null;
    notifyListeners();

    try {
      final totalPieces = items.fold<int>(0, (sum, item) => sum + item.pieces);
      final totalGross =
          items.fold<double>(0.0, (sum, item) => sum + item.grossWeight);
      final totalLess =
          items.fold<double>(0.0, (sum, item) => sum + item.lessWeight);
      final totalNet =
          items.fold<double>(0.0, (sum, item) => sum + item.netWeight);
      final weightedRate = totalNet > 0 ? totalItemValue / totalNet : 0.0;
      final metalTypes = items.map((item) => item.metalType).toSet();
      final purities = items.map((item) => item.purity).toSet();
      final combinedDescription = items.map((item) {
        final pieceLabel =
            item.pieces == 1 ? '1 piece' : '${item.pieces} pieces';
        return 'Serial Number ${item.serialNo} - ${item.itemName.trim()} | '
            '${item.metalType} | ${item.purity} | $pieceLabel | '
            'Net Weight ${item.netWeight.toStringAsFixed(3)} g';
      }).join('\n');
      final combinedHuid = items
          .map((item) => item.huidNumber?.trim() ?? '')
          .where((value) => value.isNotEmpty)
          .join(', ');
      final firstPhotoPath = items
          .expand((item) => item.photoPaths)
          .cast<String?>()
          .firstWhere((path) => path?.trim().isNotEmpty == true,
              orElse: () => null);
      final disbursementSummary = disbursements
          .map(
            (entry) =>
                '${entry.displayLabel} Rs ${entry.amount.toStringAsFixed(2)}',
          )
          .join(' + ');

      final companion = GirviLoansCompanion.insert(
        ticketNo: _ticketNo,
        customerId: _selectedCustomer!.id,
        itemDescription: combinedDescription,
        itemCount: drift.Value(totalPieces),
        huidNumber:
            drift.Value(combinedHuid.isEmpty ? null : combinedHuid.trim()),
        itemPhotoPath: drift.Value(firstPhotoPath?.trim().isEmpty == true
            ? null
            : firstPhotoPath?.trim()),
        metalType: drift.Value(
          metalTypes.length == 1 ? metalTypes.single : MetalType.mixed.dbValue,
        ),
        metalPurity: drift.Value(
          purities.length == 1 ? purities.single : 'Mixed',
        ),
        grossWeight: drift.Value(totalGross),
        stoneWeight: drift.Value(totalLess),
        netWeight: drift.Value(totalNet),
        ratePerGram: drift.Value(weightedRate),
        totalValue: drift.Value(totalItemValue),
        ltvPercent: drift.Value(
          totalItemValue > 0 ? (_loanAmount / totalItemValue) * 100 : 0,
        ),
        loanAmount: drift.Value(_loanAmount),
        interestRate: drift.Value(_interestRate),
        durationMonths: drift.Value(_durationMonths),
        disbursementMode: drift.Value(disbursementSummary),
        invoiceGenerated: drift.Value(
          invoiceGenerated || (_editingDetails?.loan.invoiceGenerated ?? false),
        ),
        startDate: drift.Value(_startDate),
        maturityDate: drift.Value(maturityDate),
        idProofType: drift.Value(_idProofType?.dbValue),
        idProofNumber: drift.Value(idProofNumber?.trim().isEmpty == true
            ? null
            : idProofNumber?.trim()),
        idProofImagePath: drift.Value(
          idProofImagePath?.trim().isEmpty == true
              ? null
              : idProofImagePath?.trim(),
        ),
        notes:
            drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      );

      if (_isEditMode && _editingLoanId != null) {
        final updated = await _detailsRepo.updateLoanWithDetails(
          loanId: _editingLoanId!,
          loan: companion,
          items: items,
          disbursements: disbursements,
          expectedLoanAmount: _loanAmount,
        );
        if (!updated) {
          throw StateError('No Girvi ticket was updated.');
        }
        _editingDetails = await _detailsRepo.getLoanDetails(_editingLoanId!);
        _lastSavedLoanId = _editingLoanId;
        _successMessage = 'Girvi ticket $_ticketNo updated successfully!';
      } else {
        final loanId = await _detailsRepo.createLoanWithDetails(
          loan: companion,
          items: items,
          disbursements: disbursements,
          expectedLoanAmount: _loanAmount,
        );
        _lastSavedLoanId = loanId;
        _successMessage = 'Girvi ticket $_ticketNo created successfully!';
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.debug('NewGirviController.saveLoan error: $e');
      _errorMessage = 'Failed to save girvi. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ── RESET ─────────────────────────────────────────────────────────────────

  Future<void> resetForm() async {
    _selectedCustomer = null;
    _itemCount = 1;
    _metalType = MetalType.gold;
    _metalPurity = MetalPurity.k22;
    _grossWeight = 0.0;
    _stoneWeight = 0.0;
    _ratePerGram = 0.0;
    _ltvPercent = 50.0;
    _loanAmount = 0.0;
    _editingLoanId = null;
    _lastSavedLoanId = null;
    _editingDetails = null;
    _isEditMode = false;
    _isLoadingEdit = false;
    _interestRate = _billingSettings.defaultInterestRate;
    _durationMonths =
        _durationMonthsFromLabel(_billingSettings.defaultDuration);
    _disbursementMode = GirviPaymentMode.cash;
    _startDate = DateTime.now();
    _idProofType = null;
    _errorMessage = null;
    _successMessage = null;
    _initialized = false;
    await initialize(); // regenerates ticket number
  }
}
