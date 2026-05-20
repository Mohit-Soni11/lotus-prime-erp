// =============================================================================
// FILE        : receive_karigar_controller.dart
// MODULE      : Karigar
// LAYER       : Logic / Controller
// DESCRIPTION : Business logic for the Receive from Karigar screen.
//               Manages issue selection, live wastage computation, making
//               charge calculation, payment tracking, and DB persistence.
//               Automatically marks the linked issue as Completed on save.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/karigar/karigar_enums/karigar_enums.dart';
import '../../models/karigar/karigar_issue_model.dart';
import '../../repositories/karigar/karigar_repository.dart';

class ReceiveKarigarController extends ChangeNotifier {
  final KarigarRepository _repo;

  ReceiveKarigarController(AppDatabase db) : _repo = KarigarRepository(db);

  // ── STATE ──────────────────────────────────────────────────────────────────

  bool _isSaving = false;
  bool _isLoadingIssues = false;
  String? _errorMessage;
  String? _successMessage;
  String _receiptNumber = '';

  // Pending issues available for selection
  List<KarigarIssueWithKarigar> _pendingIssues = [];
  KarigarIssueWithKarigar? _selectedIssue;

  // Dropdown selections
  KarigarMakingType _makingType = KarigarMakingType.perGram;
  KarigarPaymentStatus _paymentStatus = KarigarPaymentStatus.unpaid;

  // Live weight tracking
  double _grossReceived = 0.0;
  double _stoneWeight = 0.0;
  double _makingRate = 0.0;

  // ── GETTERS ────────────────────────────────────────────────────────────────

  bool get isSaving => _isSaving;
  bool get isLoadingIssues => _isLoadingIssues;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;
  String get receiptNumber => _receiptNumber;

  List<KarigarIssueWithKarigar> get pendingIssues => _pendingIssues;
  KarigarIssueWithKarigar? get selectedIssue => _selectedIssue;
  bool get hasIssue => _selectedIssue != null;

  KarigarMakingType get makingType => _makingType;
  KarigarPaymentStatus get paymentStatus => _paymentStatus;

  // Live computed values
  double get netWeightReceived =>
      (_grossReceived - _stoneWeight).clamp(0.0, double.infinity);

  double get wastageWeight {
    if (_selectedIssue == null) return 0.0;
    return (_selectedIssue!.netWeightIssued - netWeightReceived)
        .clamp(0.0, double.infinity);
  }

  double get wastagePercent {
    if (_selectedIssue == null || _selectedIssue!.netWeightIssued == 0) {
      return 0.0;
    }
    return (wastageWeight / _selectedIssue!.netWeightIssued) * 100;
  }

  bool get isHighWastage => wastagePercent > 2.0;
  bool get isCriticalWastage => wastagePercent > 5.0;

  double get computedMakingCharges {
    switch (_makingType) {
      case KarigarMakingType.perGram:
        return _makingRate * netWeightReceived;
      case KarigarMakingType.perPiece:
        return _makingRate * (_selectedIssue?.quantity ?? 1);
      case KarigarMakingType.percent:
        // Percentage of net weight in grams × rate (caller provides metal value context)
        return _makingRate;
    }
  }

  // ── INITIALIZATION ─────────────────────────────────────────────────────────

  Future<void> initialize({int? preSelectedIssueId}) async {
    _receiptNumber = await _repo.generateReceiptNumber();
    await _loadPendingIssues();

    if (preSelectedIssueId != null) {
      final match =
          _pendingIssues.where((i) => i.id == preSelectedIssueId).firstOrNull;
      if (match != null) selectIssue(match);
    }

    notifyListeners();
  }

  Future<void> _loadPendingIssues() async {
    _isLoadingIssues = true;
    notifyListeners();
    try {
      _pendingIssues = await _repo.getActiveIssuesWithKarigar();
    } catch (e) {
      debugPrint('ReceiveKarigarController._loadPendingIssues error: $e');
      _pendingIssues = [];
    } finally {
      _isLoadingIssues = false;
      notifyListeners();
    }
  }

  // ── SETTERS ─────────────────────────────────────────────────────────────────

  void selectIssue(KarigarIssueWithKarigar issue) {
    _selectedIssue = issue;
    // Pre-populate making rate from karigar's default rate (if per gram)
    _grossReceived = 0.0;
    _stoneWeight = 0.0;
    _makingRate = 0.0;
    notifyListeners();
  }

  void setMakingType(KarigarMakingType val) {
    _makingType = val;
    _makingRate = 0.0;
    notifyListeners();
  }

  void setPaymentStatus(KarigarPaymentStatus val) {
    _paymentStatus = val;
    notifyListeners();
  }

  void onGrossReceivedChanged(String val) {
    _grossReceived = double.tryParse(val) ?? 0.0;
    notifyListeners();
  }

  void onStoneWeightChanged(String val) {
    _stoneWeight = double.tryParse(val) ?? 0.0;
    notifyListeners();
  }

  void onMakingRateChanged(String val) {
    _makingRate = double.tryParse(val) ?? 0.0;
    notifyListeners();
  }

  // ── SAVE ───────────────────────────────────────────────────────────────────

  Future<bool> saveReceipt({
    required DateTime receiptDate,
    required int quantityReceived,
    required double grossWeightReceived,
    required double stoneWeight,
    required double makingChargesAmount,
    required double paidAmount,
    String? notes,
  }) async {
    if (_selectedIssue == null) {
      _errorMessage = 'Please select a pending issue before saving.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final netReceived =
          (grossWeightReceived - stoneWeight).clamp(0.0, double.infinity);
      final computed = _selectedIssue!.netWeightIssued;
      final wastage = (computed - netReceived).clamp(0.0, double.infinity);
      final wastageP = computed > 0 ? (wastage / computed) * 100 : 0.0;

      final cleanNotes = notes?.trim().isEmpty == true ? null : notes?.trim();

      final companion = KarigarReceiptsCompanion.insert(
        receiptNumber: _receiptNumber,
        issueId: _selectedIssue!.id,
        karigarId: _selectedIssue!.karigarId,
        receiptDate: receiptDate,
        quantityReceived: drift.Value(quantityReceived),
        grossWeightReceived: drift.Value(grossWeightReceived),
        stoneWeight: drift.Value(stoneWeight),
        netWeightReceived: drift.Value(netReceived),
        wastageWeight: drift.Value(wastage),
        wastagePercent: drift.Value(wastageP),
        makingChargesType: drift.Value(_makingType.label),
        makingChargeRate: drift.Value(_makingRate),
        makingChargesAmount: drift.Value(makingChargesAmount),
        paymentStatus: drift.Value(_paymentStatus.label),
        paidAmount: drift.Value(paidAmount),
        notes: drift.Value(cleanNotes),
      );

      await _repo.createReceipt(companion); // Also marks issue as Completed
      _successMessage =
          'Receipt #$_receiptNumber saved. Issue #${_selectedIssue!.issueNumber} marked as Completed.';
      return true;
    } catch (e) {
      debugPrint('ReceiveKarigarController.saveReceipt error: $e');
      _errorMessage = 'Could not save the receipt. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── RESET ──────────────────────────────────────────────────────────────────

  Future<void> resetForm() async {
    _selectedIssue = null;
    _makingType = KarigarMakingType.perGram;
    _paymentStatus = KarigarPaymentStatus.unpaid;
    _grossReceived = 0.0;
    _stoneWeight = 0.0;
    _makingRate = 0.0;
    _errorMessage = null;
    _successMessage = null;
    _receiptNumber = await _repo.generateReceiptNumber();
    await _loadPendingIssues();
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
