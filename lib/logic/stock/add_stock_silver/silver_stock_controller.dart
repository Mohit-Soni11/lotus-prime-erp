// =============================================================================
// silver_stock_controller.dart  —  SILVER STOCK CONTROLLER
// ✅ POS jaisa: starts EMPTY — koi initial row nahi
// ✅ F2 / ADD NEW ITEM se pehli row aati hai
// ✅ Sab rows delete ho sakti hain — empty state aa sakta hai
// ✅ SilverItemModel pattern (controllers + focus nodes model ke andar)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';
import '../../../models/stock/stock_item_model/add_stock_silver/silver_item_model.dart';

class SilverStockController extends AddStockController {
  // ── BATCH CODE ───────────────────────────────────────────────
  String _silverBatchCode;

  final TextEditingController supplierInvoiceNumberCtrl =
      TextEditingController();

  // ── SILVER ROW MODELS ────────────────────────────────────────
  final List<SilverItemModel> _silverRows = [];

  String? _pendingSilverFocusId;
  String? _activeSilverRowId;

  // ─────────────────────────────────────────────────────────────
  // CONSTRUCTOR — starts EMPTY, same as POS
  // ─────────────────────────────────────────────────────────────
  SilverStockController()
      : _silverBatchCode = _generateSilverBatchCode(),
        super(initialMetal: StockCategory.silver);
  // NOTE: NO _addSilverModel() here — cart starts empty like POS

  // ─────────────────────────────────────────────────────────────
  // BATCH CODE
  // ─────────────────────────────────────────────────────────────
  @override
  String get batchCode => _silverBatchCode;

  // ─────────────────────────────────────────────────────────────
  // SILVER ROW ACCESSORS
  // ─────────────────────────────────────────────────────────────
  List<SilverItemModel> get silverRows => List.unmodifiable(_silverRows);

  List<SilverItemModel> get enteredSilverRows =>
      _silverRows.where((m) => m.hasAnyInput).toList(growable: false);

  // ─────────────────────────────────────────────────────────────
  // OVERRIDE enteredRows — so super.saveAll() gets silver data
  // ─────────────────────────────────────────────────────────────
  @override
  List<StockRowEntry> get enteredRows {
    final supplierId = linkedSupplier?.id;
    final supplierName = supplierDisplayName;

    return enteredSilverRows.map((m) {
      final row = StockRowEntry(id: m.id, hsnCode: defaultHsnCode);
      row.itemName = m.itemName;
      row.huid = m.huid;
      row.grossWeight = m.grossWeight;
      row.stoneWeight = m.lessWeight;
      row.purchaseRate = m.purchaseRate;
      row.makingCharges = m.makingValue;
      row.makingChargesType = m.makingChargesType;
      row.gstRate = gstEnabled ? gstRate : 0.0;
      row.supplierId = supplierId;
      row.supplierName = supplierName;
      row.quantity = 1;
      return row;
    }).toList(growable: false);
  }

  // ─────────────────────────────────────────────────────────────
  // COUNTS
  // ─────────────────────────────────────────────────────────────
  @override
  int get enteredRowCount => enteredSilverRows.length;

  @override
  int get rowCount => _silverRows.length;

  // ─────────────────────────────────────────────────────────────
  // TOTALS
  // ─────────────────────────────────────────────────────────────
  @override
  double get totalGrossWeight =>
      enteredSilverRows.fold(0.0, (s, m) => s + m.grossWeight);

  @override
  double get totalNetWeight =>
      enteredSilverRows.fold(0.0, (s, m) => s + m.netWeight);

  @override
  double get totalEstimatedCost =>
      enteredSilverRows.fold(0.0, (s, m) => s + m.totalAmount);

  @override
  double get totalEstimatedSelling =>
      enteredSilverRows.fold(0.0, (s, m) => s + m.totalAmount);

  @override
  double get totalTaxableAmount =>
      enteredSilverRows.fold(0.0, (s, m) => s + m.totalAmount);

  @override
  double get totalGstAmount =>
      gstEnabled ? totalTaxableAmount * (gstRate / 100.0) : 0.0;

  @override
  double get cgstAmount => totalGstAmount / 2.0;

  @override
  double get sgstAmount => totalGstAmount / 2.0;

  @override
  double get totalBatchAmount => totalTaxableAmount + totalGstAmount;

  @override
  double get totalFineGold => 0.0;

  // ─────────────────────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────────────────────
  @override
  int get rowsWithErrorsCount =>
      enteredSilverRows.where((m) => validateSilverRow(m) != null).length;

  @override
  bool get hasAnyInput => super.hasAnyInput || enteredSilverRows.isNotEmpty;

  String? validateSilverRow(SilverItemModel m) {
    if (!m.hasAnyInput) return null;
    if (m.itemName.isEmpty) return 'Item name is required';
    if (m.itemName.length < 2) return 'Item name must be at least 2 characters';
    if (m.grossWeight <= 0) return 'Gross weight must be greater than 0';
    if (m.lessWeight < 0) return 'Less weight cannot be negative';
    if (m.lessWeight > m.grossWeight)
      return 'Less weight cannot exceed gross weight';
    if (m.purchaseRate < 0) return 'Purchase rate cannot be negative';
    if (m.makingValue < 0) return 'Making charge cannot be negative';
    if (m.huid.isNotEmpty && m.huid.length != 6)
      return 'HUID must be exactly 6 characters';
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // ROW MANAGEMENT — same as POS addNewSaleItem / removeSaleItem
  // ─────────────────────────────────────────────────────────────

  /// F2 / ADD NEW ITEM — adds a new empty row with focus
  @override
  void addRow({bool requestFocus = false}) {
    _addSilverModel(requestFocus: requestFocus);
  }

  void _addSilverModel({bool requestFocus = false}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final model = SilverItemModel(id: id);
    model.addListener(notifyListeners);
    _silverRows.add(model);
    if (requestFocus) _pendingSilverFocusId = id;
    notifyListeners();
  }

  /// Delete row — NO minimum row guard (same as POS removeSaleItem)
  @override
  void removeRow(String rowId) {
    final idx = _silverRows.indexWhere((m) => m.id == rowId);
    if (idx == -1) return;

    final model = _silverRows[idx];
    model.removeListener(notifyListeners);
    _silverRows.removeAt(idx);

    if (_activeSilverRowId == rowId)
      _activeSilverRowId = _silverRows.isNotEmpty ? _silverRows.last.id : null;
    if (_pendingSilverFocusId == rowId) _pendingSilverFocusId = null;

    model.disposeAll();
    notifyListeners();
  }

  /// Delete key shortcut — remove active row (or last row)
  @override
  void removeActiveRow() {
    if (_silverRows.isEmpty) return;
    final targetId = _activeSilverRowId != null &&
            _silverRows.any((m) => m.id == _activeSilverRowId)
        ? _activeSilverRowId!
        : _silverRows.last.id;
    removeRow(targetId);
  }

  // ─────────────────────────────────────────────────────────────
  // FOCUS MANAGEMENT
  // ─────────────────────────────────────────────────────────────
  void setSilverActiveRow(String id) => _activeSilverRowId = id;

  bool shouldRequestSilverFocus(String id) => _pendingSilverFocusId == id;

  void clearSilverFocusRequest(String id) {
    if (_pendingSilverFocusId == id) _pendingSilverFocusId = null;
  }

  /// Done key on last field → jump to next empty row, or add new row
  void completeRowAndAdvanceSilver(String rowId) {
    final idx = _silverRows.indexWhere((m) => m.id == rowId);
    if (idx == -1) return;

    for (var i = idx + 1; i < _silverRows.length; i++) {
      if (!_silverRows[i].hasAnyInput) {
        _pendingSilverFocusId = _silverRows[i].id;
        notifyListeners();
        return;
      }
    }

    _addSilverModel(requestFocus: true);
  }

  // ─────────────────────────────────────────────────────────────
  // RESET
  // ─────────────────────────────────────────────────────────────
  @override
  void resetAllRows() {
    _clearSilverRows();
    // No initial row — stays empty like POS
    notifyListeners();
  }

  @override
  void resetForNewBatch() {
    _silverBatchCode = _generateSilverBatchCode();
    supplierInvoiceNumberCtrl.clear();
    _clearSilverRows();
    super.resetForNewBatch();
  }

  void _clearSilverRows() {
    for (final model in _silverRows) {
      model.removeListener(notifyListeners);
      model.disposeAll();
    }
    _silverRows.clear();
    _pendingSilverFocusId = null;
    _activeSilverRowId = null;
  }

  // ─────────────────────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    supplierInvoiceNumberCtrl.dispose();
    for (final model in _silverRows) {
      model.removeListener(notifyListeners);
      model.disposeAll();
    }
    _silverRows.clear();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // BATCH CODE GENERATION
  // ─────────────────────────────────────────────────────────────
  static String _generateSilverBatchCode() {
    final now = DateTime.now();
    final datePart = '${now.year.toString().substring(2)}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final timePart = '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'SIL-$datePart-$timePart';
  }
}
