// =============================================================================
// FILE        : silver_stock_controller.dart
// MODULE      : Stock & Inventory — Silver
// LAYER       : Logic / Controller
// DESCRIPTION : Main ChangeNotifier for the Silver Add Stock module.
//               ✅ 100% Isolated from AddStockController (Gold/Generic).
//               ✅ Composes SilverInvoiceLogic + SilverOverviewLogic.
//               ✅ Manages step routing, purity, rows, supplier session, save.
//               ✅ Silver-specific save path — direct to stockItems table.
//               ✅ No gold rate snapshot, no touch%, no fine-weight math.
//               ✅ Future-proof: add silver-specific fields freely here.
//
// ARCHITECTURE:
//   SilverStockController (ChangeNotifier — UI listens to this)
//     ├── SilverInvoiceLogic   → batch ID, supplier invoice ref, date stream
//     ├── SilverOverviewLogic  → GST toggle, all totals, stats snapshot
//     └── List<SilverRowEntry> → row data managed directly by this controller
//
// HOW UI ACCESSES SUB-LOGICS:
//   ctrl.invoice.batchCode
//   ctrl.invoice.supplierInvoiceCtrl
//   ctrl.overview.gstEnabled
//   ctrl.overview.buildStats(ctrl.enteredRows)
//   ctrl.toggleGst(bool)   ← delegates to overview, then notifies
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:lotus_erp/database/db/app_database.dart';
//import 'package:lotus_erp/models/purchase/purchase_enums/purchase_enums.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';
import 'package:lotus_erp/models/stock/supplier_model/supplier_model.dart';
import 'package:lotus_erp/repositories/supplier/supplier_repository.dart';

import 'silver_invoice_logic.dart';
import 'silver_overview_logic.dart';
import 'silver_row_entry.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STEP ENUM  (Silver only — no cross-module sharing)
// ─────────────────────────────────────────────────────────────────────────────
enum SilverAddStockStep { purity, items }

// ─────────────────────────────────────────────────────────────────────────────
// SILVER STOCK CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class SilverStockController extends ChangeNotifier {
  // ── DATABASE / REPOS ─────────────────────────────────────────
  final AppDatabase _db = AppDatabase();
  late final SupplierRepository _supplierRepo;

  // ── SUB-LOGICS (public — UI accesses via ctrl.invoice / ctrl.overview) ──
  final SilverInvoiceLogic invoice = SilverInvoiceLogic();
  final SilverOverviewLogic overview = SilverOverviewLogic();

  // ─────────────────────────────────────────────────────────────
  // CONSTRUCTOR
  // ─────────────────────────────────────────────────────────────
  SilverStockController() {
    _supplierRepo = SupplierRepository(_db);
    invoice.init();
    _loadSuppliers();
    _loadPurityStockSummary();
  }

  // ─────────────────────────────────────────────────────────────
  // STEP
  // ─────────────────────────────────────────────────────────────
  SilverAddStockStep _step = SilverAddStockStep.purity;
  SilverAddStockStep get step => _step;

  void nextStep() {
    if (!canProceedFromPurity) {
      _errorMessage = 'Please select a purity grade before proceeding.';
      notifyListeners();
      return;
    }
    if (_step == SilverAddStockStep.purity) {
      _step = SilverAddStockStep.items;
      _emitChange(clearMessages: false);
    }
  }

  void prevStep() {
    if (_step == SilverAddStockStep.items) {
      _step = SilverAddStockStep.purity;
      _emitChange(clearMessages: false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PURITY
  // ─────────────────────────────────────────────────────────────
  String _purityDisplay = '';
  String get purityDisplay => _purityDisplay;

  bool _isCustomPurity = false;
  bool get isCustomPurity => _isCustomPurity;

  bool get canProceedFromPurity => _purityDisplay.trim().isNotEmpty;

  /// Silver purity presets — isolated from Gold/Platinum purity lists.
  static const List<String> purityOptions = [
    '999 (Pure)',
    '925 (Sterling)',
    '800',
    '700',
    'Custom',
  ];

  void setPurity(String option) {
    _isCustomPurity = option == 'Custom';
    _purityDisplay = _isCustomPurity ? '' : option;
    _emitChange();
  }

  void setCustomPurity(String value) {
    _purityDisplay = value.trim();
    _emitChange();
  }

  // ─────────────────────────────────────────────────────────────
  // ROWS
  // ─────────────────────────────────────────────────────────────
  final List<SilverRowEntry> _rows = [];

  List<SilverRowEntry> get rows => List.unmodifiable(_rows);

  /// Only rows where the operator has entered at least one field.
  List<SilverRowEntry> get enteredRows =>
      _rows.where((row) => row.hasAnyInput).toList(growable: false);

  int get rowCount => _rows.length;
  int get enteredRowCount => enteredRows.length;

  // ── ACTIVE ROW (keyboard Delete key support) ──────────────────
  String? _activeRowId;
  String? get activeRowId => _activeRowId;

  void setActiveRow(String rowId) {
    _activeRowId = rowId;
  }

  // ── FOCUS MANAGEMENT ─────────────────────────────────────────
  String? _pendingFocusRowId;

  bool shouldRequestFocus(String rowId) => _pendingFocusRowId == rowId;

  void clearFocusRequest(String rowId) {
    if (_pendingFocusRowId == rowId) _pendingFocusRowId = null;
  }

  // ── ROW CRUD ─────────────────────────────────────────────────

  void addRow({bool requestFocus = false}) {
    final newRow = _buildEmptyRow();
    _rows.add(newRow);
    _activeRowId = newRow.id;
    if (requestFocus) _pendingFocusRowId = newRow.id;
    _emitChange();
  }

  void completeRowAndAdvance(String rowId) {
    final currentIndex = _rows.indexWhere((r) => r.id == rowId);
    if (currentIndex == -1) return;

    // Find next empty row
    for (var i = currentIndex + 1; i < _rows.length; i++) {
      if (!_rows[i].hasAnyInput) {
        _pendingFocusRowId = _rows[i].id;
        _emitChange(clearMessages: false);
        return;
      }
    }

    // No empty row found — insert one after current
    final newRow = _buildEmptyRow();
    _rows.insert(currentIndex + 1, newRow);
    _pendingFocusRowId = newRow.id;
    _emitChange();
  }

  void removeRow(String rowId) {
    _rows.removeWhere((row) => row.id == rowId);
    if (_pendingFocusRowId == rowId) _pendingFocusRowId = null;
    if (_activeRowId == rowId) {
      _activeRowId = _rows.isNotEmpty ? _rows.last.id : null;
    }
    _emitChange();
  }

  void removeActiveRow() {
    if (_activeRowId == null || _rows.isEmpty) return;
    final idToRemove = _activeRowId!;
    final removedIndex = _rows.indexWhere((r) => r.id == idToRemove);
    removeRow(idToRemove);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_rows.isEmpty) return;
      final focusIndex =
          (removedIndex > 0 ? removedIndex - 1 : 0).clamp(0, _rows.length - 1);
      _pendingFocusRowId = _rows[focusIndex].id;
      _activeRowId = _rows[focusIndex].id;
      notifyListeners();
    });
  }

  SilverRowEntry _buildEmptyRow() {
    final row = SilverRowEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      hsnCode: _defaultHsnCode,
    );
    // Pre-fill supplier if sameForAll is on
    if (_sameForAll) {
      row.supplierId = _sessionSupplierId;
      row.supplierName = _sessionSupplierName;
    }
    // Pre-fill GST rate
    row.gstRate = overview.gstEnabled ? overview.gstRate : 0.0;
    return row;
  }

  // ── DEFAULT HSN FOR SILVER ────────────────────────────────────
  String get _defaultHsnCode => JewelleryHsn.h7113.code;

  // ─────────────────────────────────────────────────────────────
  // ROW FIELD UPDATES
  // Each method updates a single field and calls _emitChange().
  // ─────────────────────────────────────────────────────────────

  void updateItemName(String rowId, String value) =>
      _rowById(rowId).itemName = value;

  void updateDescription(String rowId, String value) =>
      _rowById(rowId).description = value;

  void updateSubCategory(String rowId, StockSubCategory value) {
    _rowById(rowId).subCategory = value;
    _emitChange();
  }

  void updateHuid(String rowId, String value) {
    _rowById(rowId).huid = value.trim().toUpperCase();
    _emitChange();
  }

  void updateGrossWeight(String rowId, String value) {
    _rowById(rowId).grossWeight = double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateLessWeight(String rowId, String value) {
    _rowById(rowId).lessWeight = double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateStoneValue(String rowId, String value) {
    _rowById(rowId).stoneValue = double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateStoneType(String rowId, StoneType value) {
    _rowById(rowId).stoneType = value;
    _emitChange();
  }

  void updateStoneCarats(String rowId, String value) {
    _rowById(rowId).stoneCarats = double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateStonePieces(String rowId, String value) {
    _rowById(rowId).stonePieces = int.tryParse(value) ?? 0;
    _emitChange();
  }

  void updatePurchaseRatePerGram(String rowId, String value) {
    _rowById(rowId).purchaseRatePerGram = double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateMakingCharges(String rowId, String value) {
    _rowById(rowId).makingCharges = double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateMakingType(String rowId, MakingChargesType value) {
    _rowById(rowId).makingChargesType = value;
    _emitChange();
  }

  void updateMrp(String rowId, String value) {
    _rowById(rowId).mrp = double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateGstRate(String rowId, String value) {
    _rowById(rowId).gstRate = double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateQuantity(String rowId, String value) {
    _rowById(rowId).quantity = int.tryParse(value) ?? 1;
    _emitChange();
  }

  void updateLocation(String rowId, String value) {
    _rowById(rowId).location = value;
    _emitChange();
  }

  void updateHsnCode(String rowId, String value) {
    _rowById(rowId).hsnCode = value.trim();
    _emitChange();
  }

  void applyPresetHsn(String rowId, JewelleryHsn? hsn) {
    if (hsn == null) return;
    _rowById(rowId).hsnCode = hsn.code;
    _emitChange();
  }

  SilverRowEntry _rowById(String rowId) =>
      _rows.firstWhere((r) => r.id == rowId);

  // ─────────────────────────────────────────────────────────────
  // GST TOGGLE  (delegates to SilverOverviewLogic)
  // ─────────────────────────────────────────────────────────────

  void toggleGst(bool value) {
    overview.toggleGst(value, _rows);
    _emitChange(clearMessages: false);
  }

  // ─────────────────────────────────────────────────────────────
  // SUPPLIER SESSION
  // ─────────────────────────────────────────────────────────────
  List<SupplierListItemModel> _suppliers = [];
  List<SupplierListItemModel> get suppliers => _suppliers;

  int? _sessionSupplierId;
  String _sessionSupplierName = '';
  bool _sameForAll = true;
  SupplierModel? _linkedSupplier;
  bool _isApplyingSupplierProfile = false;

  String get sessionSupplierName => _sessionSupplierName;
  bool get sameForAll => _sameForAll;
  SupplierModel? get linkedSupplier => _linkedSupplier;
  bool get hasLinkedSupplier => _sessionSupplierId != null;
  bool get isApplyingSupplierProfile => _isApplyingSupplierProfile;

  String get supplierDisplayName =>
      _linkedSupplier?.businessName.isNotEmpty == true
          ? _linkedSupplier!.businessName
          : _sessionSupplierName;

  // ── TextEditingControllers for supplier fields ────────────────
  final TextEditingController supplierNameCtrl = TextEditingController();
  final TextEditingController supplierMobileCtrl = TextEditingController();
  final TextEditingController supplierRegionCtrl = TextEditingController();
  final TextEditingController supplierPanCtrl = TextEditingController();
  final TextEditingController supplierGstCtrl = TextEditingController();

  void setSessionSupplier(SupplierListItemModel? supplier) {
    _sessionSupplierId = supplier?.id;
    _sessionSupplierName = supplier?.displayName ?? '';
    _isApplyingSupplierProfile = true;
    supplierNameCtrl.text = _sessionSupplierName;
    supplierMobileCtrl.text = supplier?.mobile ?? '';
    supplierGstCtrl.text = supplier?.gstNumber ?? '';
    _isApplyingSupplierProfile = false;

    if (_sameForAll) _applyBatchSupplierToRows();

    if (supplier == null) {
      _linkedSupplier = null;
      supplierRegionCtrl.clear();
      supplierPanCtrl.clear();
      _emitChange();
      return;
    }
    _emitChange();
    _hydrateSelectedSupplier(supplier.id);
  }

  void setSessionSupplierText(String value) {
    _sessionSupplierId = null;
    _sessionSupplierName = value.trimLeft();
    if (supplierNameCtrl.text != value) supplierNameCtrl.text = value;
    _linkedSupplier = null;
    supplierRegionCtrl.clear();
    supplierPanCtrl.clear();
    supplierGstCtrl.clear();
    _applyBatchSupplierToRows();
    _emitChange();
  }

  void updateSupplierMobileText(String value) {
    if (_linkedSupplier != null && value.trim() != _linkedSupplier!.mobile) {
      _sessionSupplierId = null;
      _linkedSupplier = null;
      supplierRegionCtrl.clear();
      supplierPanCtrl.clear();
      supplierGstCtrl.clear();
      _applyBatchSupplierToRows();
    }
    _emitChange();
  }

  void clearSessionSupplier({bool clearFields = true}) {
    _sessionSupplierId = null;
    _sessionSupplierName = '';
    _linkedSupplier = null;
    if (clearFields) {
      supplierNameCtrl.clear();
      supplierMobileCtrl.clear();
      supplierRegionCtrl.clear();
      supplierPanCtrl.clear();
      supplierGstCtrl.clear();
    }
    _applyBatchSupplierToRows();
    _emitChange();
  }

  void setSameForAll(bool value) {
    _sameForAll = value;
    if (value) _applyBatchSupplierToRows();
    _emitChange();
  }

  void setRowSupplier(String rowId, SupplierListItemModel? supplier) {
    _rowById(rowId).supplierId = supplier?.id;
    _rowById(rowId).supplierName = supplier?.displayName ?? '';
    _emitChange();
  }

  void setRowSupplierText(String rowId, String value) {
    _rowById(rowId).supplierId = null;
    _rowById(rowId).supplierName = value.trimLeft();
    _emitChange();
  }

  void _applyBatchSupplierToRows() {
    if (!_sameForAll) return;
    for (final row in _rows) {
      row.supplierId = _sessionSupplierId;
      row.supplierName = _sessionSupplierName;
    }
  }

  Future<void> _hydrateSelectedSupplier(int supplierId) async {
    final fullSupplier = await _supplierRepo.getById(supplierId);
    if (_sessionSupplierId != supplierId) return;
    _linkedSupplier = fullSupplier;
    if (fullSupplier != null) {
      _isApplyingSupplierProfile = true;
      supplierNameCtrl.text = fullSupplier.businessName;
      supplierMobileCtrl.text = fullSupplier.mobile;
      supplierRegionCtrl.text = [
        fullSupplier.addressLine1 ?? '',
        fullSupplier.addressLine2 ?? '',
        fullSupplier.state ?? '',
      ].where((s) => s.isNotEmpty).join(', ');
      supplierPanCtrl.text = fullSupplier.panNumber ?? '';
      supplierGstCtrl.text = fullSupplier.gstNumber ?? '';
      _isApplyingSupplierProfile = false;
      _sessionSupplierName = fullSupplier.businessName;
      _applyBatchSupplierToRows();
    }
    notifyListeners();
  }

  Future<void> reloadSuppliers() async {
    _suppliers = await _supplierRepo.getAllSuppliers();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // STOCK SUMMARY (purity-wise existing stock)
  // ─────────────────────────────────────────────────────────────
  Map<String, double> _purityStockSummary = {};
  Map<String, double> get purityStockSummary =>
      Map.unmodifiable(_purityStockSummary);

  bool _isLoadingStockSummary = false;
  bool get isLoadingStockSummary => _isLoadingStockSummary;

  Future<void> _loadPurityStockSummary() async {
    _isLoadingStockSummary = true;
    notifyListeners();

    try {
      final items = await (_db.select(_db.stockItems)
            ..where(
              (t) =>
                  t.category.equals(StockCategory.silver.label) &
                  t.status.equals(StockStatus.available.label),
            ))
          .get();

      final Map<String, double> summary = {};
      for (final item in items) {
        final purity = (item.purity?.trim().isEmpty ?? true)
            ? 'Unspecified'
            : item.purity!;
        final netWt = item.netWeight * item.quantity;
        summary[purity] = (summary[purity] ?? 0) + netWt;
      }

      _purityStockSummary = Map.fromEntries(
        summary.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );
    } catch (_) {
      _purityStockSummary = {};
    }

    _isLoadingStockSummary = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // COMPUTED STATE HELPERS
  // ─────────────────────────────────────────────────────────────

  bool get hasAnyInput =>
      _purityDisplay.trim().isNotEmpty ||
      _sessionSupplierName.trim().isNotEmpty ||
      supplierMobileCtrl.text.trim().isNotEmpty ||
      enteredRows.isNotEmpty;

  bool get isValid =>
      canProceedFromPurity &&
      enteredRows.isNotEmpty &&
      enteredRows.every((row) => validateRow(row) == null);

  // ─────────────────────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────────────────────

  String? validateRow(SilverRowEntry row) {
    if (!row.hasAnyInput) return null;

    if (row.itemName.trim().isEmpty) {
      return 'Item name is required.';
    }
    if (row.itemName.trim().length < 2) {
      return 'Item name must be at least 2 characters.';
    }
    if (row.quantity < 1) {
      return 'Quantity must be at least 1.';
    }
    if (row.grossWeight <= 0) {
      return 'Gross weight must be greater than 0.';
    }
    if (row.lessWeight < 0 || row.grossWeight < 0) {
      return 'Weight values cannot be negative.';
    }
    if (row.lessWeight > row.grossWeight) {
      return 'Stone/less weight cannot exceed gross weight.';
    }
    if (row.purchaseRatePerGram < 0 ||
        row.makingCharges < 0 ||
        row.stoneValue < 0 ||
        row.mrp < 0) {
      return 'Price values cannot be negative.';
    }
    if (row.gstRate < 0 || row.gstRate > 100) {
      return 'GST rate must be between 0 and 100.';
    }
    if (row.huid.trim().isNotEmpty && row.huid.trim().length != 6) {
      return 'HUID must be exactly 6 characters.';
    }
    return null;
  }

  Future<String?> _validateBeforeSave() async {
    if (!canProceedFromPurity) return 'Please select a purity grade.';

    final rowsToSave = enteredRows;
    if (rowsToSave.isEmpty) return 'Add at least one item before saving.';

    final seenHuids = <String>{};
    for (int i = 0; i < rowsToSave.length; i++) {
      final row = rowsToSave[i];
      final error = validateRow(row);
      if (error != null) return 'Row ${i + 1}: $error';

      final huid = row.huid.trim().toUpperCase();
      if (huid.isNotEmpty && !seenHuids.add(huid)) {
        return 'Row ${i + 1}: Duplicate HUID found in this batch.';
      }
    }

    // DB-level HUID uniqueness check
    final huidValues = rowsToSave
        .map((r) => r.huid.trim().toUpperCase())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();

    if (huidValues.isNotEmpty) {
      final existing = await (_db.select(_db.stockItems)
            ..where((t) => t.huid.isIn(huidValues)))
          .get();
      if (existing.isNotEmpty) {
        final dup = existing.first.huid ?? huidValues.first;
        return 'HUID $dup already exists in stock. Duplicate not allowed.';
      }
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // SAVE  (Silver-specific path — direct to stockItems)
  // No purchase voucher created for silver. Only Gold creates a
  // PurchaseVoucher entry in the current flow.
  // ─────────────────────────────────────────────────────────────
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Future<bool> saveAll() async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final validationError = await _validateBeforeSave();
      if (validationError != null) {
        _errorMessage = validationError;
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final rowsToSave = enteredRows;
      int saved = 0;

      for (int i = 0; i < rowsToSave.length; i++) {
        final row = rowsToSave[i];

        await _db.into(_db.stockItems).insert(
              StockItemsCompanion.insert(
                sku: _generateSku(i),
                itemName: row.itemName.trim(),
                description: drift.Value(
                  row.description.trim().isEmpty
                      ? null
                      : row.description.trim(),
                ),
                category: StockCategory.silver.label,
                subCategory: row.subCategory.label,
                metalType: drift.Value(StockCategory.silver.label),
                purity: drift.Value(
                  _purityDisplay.trim().isEmpty ? null : _purityDisplay.trim(),
                ),
                grossWeight: drift.Value(row.grossWeight),
                stoneWeight: drift.Value(row.lessWeight),
                netWeight: drift.Value(row.netWeight),
                stoneType: drift.Value(row.stoneType.label),
                stoneCarats: drift.Value(row.stoneCarats),
                stonePieces: drift.Value(row.stonePieces),
                stoneValue: drift.Value(row.stoneValue),
                purchaseRate: drift.Value(row.purchaseRatePerGram),
                makingCharge: drift.Value(row.makingCharges),
                makingChargeType: drift.Value(row.makingChargesType.label),
                purchasePrice: drift.Value(row.costPrice),
                mrp: drift.Value(row.mrp),
                hsnCode: drift.Value(
                  row.hsnCode.trim().isEmpty
                      ? _defaultHsnCode
                      : row.hsnCode.trim(),
                ),
                huid: drift.Value(
                  row.huid.trim().isEmpty
                      ? null
                      : row.huid.trim().toUpperCase(),
                ),
                gstRate: drift.Value(row.gstRate),
                quantity: drift.Value(row.quantity),
                location: drift.Value(
                  row.location.trim().isEmpty ? null : row.location.trim(),
                ),
                supplierId: drift.Value(row.supplierId),
                supplierName: drift.Value(
                  row.supplierName.trim().isEmpty
                      ? null
                      : row.supplierName.trim(),
                ),
                status: drift.Value(StockStatus.available.label),
              ),
            );
        saved++;
      }

      _successMessage =
          '$saved silver item${saved > 1 ? 's' : ''} saved successfully under batch ${invoice.batchCode}.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = 'Save failed: $error';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // RESET
  // ─────────────────────────────────────────────────────────────

  /// Clears only the row list — keeps purity and supplier.
  /// Use when operator wants to add more items after a successful save.
  void resetAllRows() {
    _rows.clear();
    _pendingFocusRowId = null;
    _activeRowId = null;
    _errorMessage = null;
    _successMessage = null;
    _step = _purityDisplay.trim().isEmpty
        ? SilverAddStockStep.purity
        : SilverAddStockStep.items;
    notifyListeners();
  }

  /// Full reset — clears everything including supplier session.
  /// Use when starting a completely new batch.
  void resetForNewBatch() {
    _rows.clear();
    _purityDisplay = '';
    _isCustomPurity = false;
    _sessionSupplierId = null;
    _sessionSupplierName = '';
    _sameForAll = true;
    _linkedSupplier = null;
    supplierNameCtrl.clear();
    supplierMobileCtrl.clear();
    supplierRegionCtrl.clear();
    supplierPanCtrl.clear();
    supplierGstCtrl.clear();
    invoice.clearSupplierInvoice();
    overview.resetGst();
    _pendingFocusRowId = null;
    _activeRowId = null;
    _errorMessage = null;
    _successMessage = null;
    _step = SilverAddStockStep.purity;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────

  /// Generates a unique SKU for a silver stock item.
  /// Format: SILV-YYYYMMDD-XXXXX
  String _generateSku(int index) {
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final uniquePart = (now.microsecondsSinceEpoch % 99999) + index;
    return 'SILV-$datePart-$uniquePart';
  }

  void _emitChange({bool clearMessages = true}) {
    if (clearMessages) {
      _errorMessage = null;
      _successMessage = null;
    }
    notifyListeners();
  }

  Future<void> _loadSuppliers() async {
    await reloadSuppliers();
  }

  // ─────────────────────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    invoice.dispose();
    supplierNameCtrl.dispose();
    supplierMobileCtrl.dispose();
    supplierRegionCtrl.dispose();
    supplierPanCtrl.dispose();
    supplierGstCtrl.dispose();
    super.dispose();
  }
}
