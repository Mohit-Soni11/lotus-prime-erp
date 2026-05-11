// =============================================================================
// FILE        : add_stock_controller.dart
// MODULE      : Stock & Inventory
// LAYER       : Logic / Controller
// DESCRIPTION : Shared Add Stock controller for Gold, Diamond, Platinum,
//               Antique, and Other metal categories.
//
// ⚠️  SILVER IS NOT HANDLED HERE.
//     Silver has its own fully isolated controller:
//     → lib/logic/stock/add_stock_silver/silver_stock_controller.dart
//
//     Passing StockCategory.silver to this controller will throw an
//     AssertionError at construction time.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/purchase/purchase_enums/purchase_enums.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';
import 'package:lotus_erp/models/stock/supplier_model/supplier_model.dart';
import 'package:lotus_erp/repositories/purchase/purchase_entry_repository.dart';
import 'package:lotus_erp/repositories/supplier/supplier_repository.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';

class StockRowEntry {
  final String id;

  String itemName = '';
  String description = '';
  StockSubCategory subCategory = StockSubCategory.ring;
  String huid = '';
  String hsnCode;

  double grossWeight = 0.0;
  double stoneWeight = 0.0;
  double stoneValue = 0.0;
  double touchPercent = 0.0;

  StoneType stoneType = StoneType.none;
  double stoneCarats = 0.0;
  int stonePieces = 0;

  double purchaseRate = 0.0;
  double makingCharges = 0.0;
  MakingChargesType makingChargesType = MakingChargesType.perGram;
  double mrp = 0.0;
  double gstRate = 3.0;

  int quantity = 1;
  String location = '';

  int? supplierId;
  String supplierName = '';

  StockRowEntry({required this.id, required this.hsnCode});

  double get netWeight =>
      (grossWeight - stoneWeight).clamp(0.0, double.infinity);

  double get lessWeight => stoneWeight;

  set lessWeight(double value) => stoneWeight = value;

  double resolveTouch(double fallbackTouch) {
    final value = touchPercent > 0 ? touchPercent : fallbackTouch;
    return value.clamp(0.0, 100.0);
  }

  double fineWeight(double fallbackTouch) =>
      netWeight * (resolveTouch(fallbackTouch) / 100.0);

  double labourAmount({
    required double metalAmount,
    required double fallbackTouch,
  }) {
    return switch (makingChargesType) {
      MakingChargesType.perGram => netWeight * makingCharges,
      MakingChargesType.flat => makingCharges,
      MakingChargesType.percent => metalAmount * makingCharges / 100.0,
    };
  }

  double get costPrice {
    final metalCost = netWeight * purchaseRate;
    final making = switch (makingChargesType) {
      MakingChargesType.perGram => netWeight * makingCharges,
      MakingChargesType.flat => makingCharges,
      MakingChargesType.percent => metalCost * makingCharges / 100.0,
    };
    return metalCost + stoneValue + making;
  }

  double get totalCostValue => costPrice * quantity;

  double get totalSellingValue => ((mrp > 0 ? mrp : costPrice) * quantity);

  bool get hasAnyInput {
    return itemName.trim().isNotEmpty ||
        description.trim().isNotEmpty ||
        huid.trim().isNotEmpty ||
        grossWeight > 0 ||
        stoneWeight > 0 ||
        stoneValue > 0 ||
        touchPercent > 0 ||
        stoneCarats > 0 ||
        stonePieces > 0 ||
        purchaseRate > 0 ||
        makingCharges > 0 ||
        mrp > 0 ||
        quantity != 1 ||
        location.trim().isNotEmpty ||
        supplierName.trim().isNotEmpty;
  }
}

enum AddStockStep { purity, items }

class AddStockController extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  late final SupplierRepository _supplierRepo;
  late final PurchaseEntryRepository _purchaseRepo;

  // Active row tracking — Delete key support (matches POS activeRowIndex behaviour).
  String? _activeRowId;
  String? get activeRowId => _activeRowId;

  void setActiveRow(String rowId) {
    _activeRowId = rowId;
  }

  /// Creates the shared Add Stock controller for Gold, Diamond, Platinum, Antique, Other.
  ///
  /// ⚠️  Do NOT pass [StockCategory.silver] here.
  ///     Silver has its own isolated controller:
  ///     → `lib/logic/stock/add_stock_silver/silver_stock_controller.dart`
  AddStockController({required StockCategory initialMetal}) {
    assert(
      initialMetal != StockCategory.silver,
      'AddStockController does not handle Silver. '
      'Use SilverStockController (lib/logic/stock/add_stock_silver/) instead.',
    );
    _supplierRepo = SupplierRepository(_db);
    _purchaseRepo = PurchaseEntryRepository(db: _db);
    _selectedMetal = initialMetal;
    _loadSuppliers();
    _loadPurityStockSummary();
    if (_selectedMetal == StockCategory.gold) {
      _loadGoldRateSnapshot();
    }
  }

  AddStockStep _step = AddStockStep.purity;
  AddStockStep get step => _step;

  late final StockCategory _selectedMetal;
  StockCategory get selectedMetal => _selectedMetal;

  String _purityDisplay = '';
  String get purityDisplay => _purityDisplay;

  bool _isCustomPurity = false;
  bool get isCustomPurity => _isCustomPurity;

  bool get canProceedFromPurity => _purityDisplay.trim().isNotEmpty;

  /// Purity preset options for the selected metal.
  /// Silver is NOT listed here — it is handled by SilverStockController.
  List<String> get purityOptions {
    switch (_selectedMetal) {
      case StockCategory.gold:
        return [
          '24K (999)',
          '22K (916)',
          '18K (750)',
          '14K (585)',
          '10K (417)',
          'Custom',
        ];
      case StockCategory.platinum:
        return ['950 Platinum', '900 Platinum', '850 Platinum', 'Custom'];
      case StockCategory.diamond:
        return ['Solitaire', 'Studded', 'Fancy', 'Custom'];
      case StockCategory.antique:
      case StockCategory.other:
        return ['Standard', 'Custom'];
      case StockCategory.silver:
        // Silver is handled by SilverStockController — should never reach here.
        assert(false, 'Silver purity options are in SilverStockController.');
        return [];
    }
  }

  /// Default HSN code for the selected metal.
  /// Silver HSN is managed inside SilverStockController.
  String get defaultHsnCode {
    switch (_selectedMetal) {
      case StockCategory.gold:
      case StockCategory.platinum:
        return JewelleryHsn.h7113.code;
      case StockCategory.diamond:
        return JewelleryHsn.h7116.code;
      case StockCategory.antique:
      case StockCategory.other:
        return JewelleryHsn.h7117.code;
      case StockCategory.silver:
        // Silver is handled by SilverStockController — should never reach here.
        return JewelleryHsn.h7113.code;
    }
  }

  String get batchCode {
    final now = DateTime.now();
    final prefix = _selectedMetal.label.length >= 3
        ? _selectedMetal.label.substring(0, 3).toUpperCase()
        : _selectedMetal.label.toUpperCase();
    return '$prefix-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  final List<StockRowEntry> _rows = [];
  List<StockRowEntry> get rows => List.unmodifiable(_rows);
  List<StockRowEntry> get enteredRows =>
      _rows.where((row) => row.hasAnyInput).toList(growable: false);
  int get rowCount => _rows.length;
  int get enteredRowCount => enteredRows.length;

  List<SupplierListItemModel> _suppliers = [];
  List<SupplierListItemModel> get suppliers => _suppliers;

  int? _sessionSupplierId;
  String _sessionSupplierName = '';
  bool _sameForAll = true;
  SupplierModel? _linkedSupplier;
  bool _isApplyingSupplierProfile = false;

  final TextEditingController supplierMobileCtrl = TextEditingController();
  final TextEditingController supplierNameCtrl = TextEditingController();
  final TextEditingController supplierRegionCtrl = TextEditingController();
  final TextEditingController supplierPanCtrl = TextEditingController();
  final TextEditingController supplierGstCtrl = TextEditingController();
  final TextEditingController gold24kManualCtrl = TextEditingController();

  /// Supplier's own invoice reference — stored per batch for B2B / GST traceability.
  /// Editable by the operator; not auto-generated. Persisted to Purchase records on save.
  final TextEditingController supplierInvoiceCtrl = TextEditingController();

  String get sessionSupplierName => _sessionSupplierName;
  bool get sameForAll => _sameForAll;
  SupplierModel? get linkedSupplier => _linkedSupplier;
  bool get hasLinkedSupplier => _sessionSupplierId != null;
  bool get isApplyingSupplierProfile => _isApplyingSupplierProfile;
  String get supplierDisplayName =>
      _linkedSupplier?.businessName.isNotEmpty == true
          ? _linkedSupplier!.businessName
          : _sessionSupplierName;

  bool _gstEnabled = false;
  bool get gstEnabled => _gstEnabled;
  double gstRate = 3.0;

  double _gold24kRatePer10g = 0.0;
  double _gold22kRatePer10g = 0.0;
  double _gold18kRatePer10g = 0.0;
  DateTime? _goldRateDate;
  bool _isLoadingGoldRates = false;

  bool get isLoadingGoldRates => _isLoadingGoldRates;
  DateTime? get goldRateDate => _goldRateDate;
  double get gold24kRatePer10g => _gold24kRatePer10g;
  double get gold22kRatePer10g => _gold22kRatePer10g;
  double get gold18kRatePer10g => _gold18kRatePer10g;

  String get selectedPurityShortLabel => _shortPurityLabel(_purityDisplay);

  double get selectedPurityBasePercent => _resolvePurityPercent(_purityDisplay);

  double get selectedPurityRatePer10g {
    if (_selectedMetal != StockCategory.gold) {
      return 0.0;
    }

    final basePercent = selectedPurityBasePercent;
    if (basePercent <= 0) {
      return 0.0;
    }

    if (_near(basePercent, 99.9) && _gold24kRatePer10g > 0) {
      return _gold24kRatePer10g;
    }
    if (_near(basePercent, 91.6) && _gold22kRatePer10g > 0) {
      return _gold22kRatePer10g;
    }
    if (_near(basePercent, 75.0) && _gold18kRatePer10g > 0) {
      return _gold18kRatePer10g;
    }
    if (_gold24kRatePer10g > 0) {
      return _gold24kRatePer10g * (basePercent / 100.0);
    }
    return 0.0;
  }

  double get pureGoldRatePerGram => _gold24kRatePer10g > 0
      ? _gold24kRatePer10g / 10.0
      : (selectedPurityRatePer10g > 0 && selectedPurityBasePercent > 0
          ? (selectedPurityRatePer10g / 10.0) /
              (selectedPurityBasePercent / 100)
          : 0.0);

  double get selectedPurityRatePerGram =>
      selectedPurityRatePer10g > 0 ? selectedPurityRatePer10g / 10.0 : 0.0;

  bool get hasActiveRateSnapshot =>
      pureGoldRatePerGram > 0 && selectedPurityRatePer10g > 0;

  void setManual24kRate(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    _gold24kRatePer10g = parsed;
    notifyListeners();
  }

  String? _pendingFocusRowId;

  int get totalQuantity =>
      enteredRows.fold<int>(0, (sum, row) => sum + row.quantity);

  double get totalGrossWeight => enteredRows.fold<double>(
        0,
        (sum, row) => sum + (row.grossWeight * row.quantity),
      );

  double get totalNetWeight => enteredRows.fold<double>(
        0,
        (sum, row) => sum + (row.netWeight * row.quantity),
      );

  double get totalEstimatedCost =>
      enteredRows.fold<double>(0, (sum, row) => sum + row.totalCostValue);

  double get totalEstimatedSelling =>
      enteredRows.fold<double>(0, (sum, row) => sum + row.totalSellingValue);

  double get totalFineGold =>
      enteredRows.fold<double>(0, (sum, row) => sum + fineWeightOf(row));

  double get totalTaxableAmount =>
      enteredRows.fold<double>(0, (sum, row) => sum + rowSubtotal(row));

  double get totalGstAmount => _gstEnabled
      ? enteredRows.fold<double>(0, (sum, row) => sum + rowGstAmount(row))
      : 0.0;

  double get cgstAmount => totalGstAmount / 2.0;
  double get sgstAmount => totalGstAmount / 2.0;
  double get totalBatchAmount => totalTaxableAmount + totalGstAmount;

  int get rowsWithErrorsCount =>
      enteredRows.where((row) => validateRow(row) != null).length;

  bool get hasAnyInput {
    return _purityDisplay.trim().isNotEmpty ||
        _sessionSupplierName.trim().isNotEmpty ||
        supplierMobileCtrl.text.trim().isNotEmpty ||
        enteredRows.isNotEmpty;
  }

  bool get isValid =>
      canProceedFromPurity &&
      enteredRows.isNotEmpty &&
      enteredRows.every((row) => validateRow(row) == null);

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Map<String, double> _purityStockSummary = {};
  Map<String, double> get purityStockSummary =>
      Map.unmodifiable(_purityStockSummary);

  bool _isLoadingStockSummary = false;
  bool get isLoadingStockSummary => _isLoadingStockSummary;

  Future<void> _loadSuppliers() async {
    await reloadSuppliers();
  }

  Future<void> _loadPurityStockSummary() async {
    _isLoadingStockSummary = true;
    notifyListeners();

    try {
      final items = await (_db.select(_db.stockItems)
            ..where(
              (t) =>
                  t.category.equals(_selectedMetal.label) &
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

  Future<void> _loadGoldRateSnapshot() async {
    _isLoadingGoldRates = true;
    notifyListeners();

    try {
      final latestRate = await (_db.select(_db.dailyRates)
            ..orderBy([(r) => drift.OrderingTerm.desc(r.rateDate)])
            ..limit(1))
          .getSingleOrNull();

      if (latestRate != null) {
        _gold24kRatePer10g = _parseRateText(latestRate.gold24k);
        _gold22kRatePer10g = _parseRateText(latestRate.gold22k);
        _gold18kRatePer10g = _parseRateText(latestRate.gold18k);
        _goldRateDate = latestRate.rateDate;
        if (gold24kManualCtrl.text.isEmpty && _gold24kRatePer10g > 0) {
          gold24kManualCtrl.text = _gold24kRatePer10g.toStringAsFixed(0);
        }
      } else {
        _gold24kRatePer10g = 0.0;
        _gold22kRatePer10g = 0.0;
        _gold18kRatePer10g = 0.0;
        _goldRateDate = null;
      }
    } catch (_) {
      _gold24kRatePer10g = 0.0;
      _gold22kRatePer10g = 0.0;
      _gold18kRatePer10g = 0.0;
      _goldRateDate = null;
    }

    _isLoadingGoldRates = false;
    notifyListeners();
  }

  Future<void> reloadSuppliers() async {
    _suppliers = await _supplierRepo.getAllSuppliers();
    notifyListeners();
  }

  void _emitChange({bool clearMessages = true}) {
    if (clearMessages) {
      _errorMessage = null;
      _successMessage = null;
    }
    notifyListeners();
  }

  StockRowEntry _buildEmptyRow() {
    final row = StockRowEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      hsnCode: defaultHsnCode,
    );

    if (_sameForAll) {
      row.supplierId = _sessionSupplierId;
      row.supplierName = _sessionSupplierName;
    }

    if (_selectedMetal == StockCategory.gold) {
      row.touchPercent = selectedPurityBasePercent;
      row.gstRate = _gstEnabled ? gstRate : 0.0;
      row.makingChargesType = MakingChargesType.perGram;
    }

    return row;
  }

  void nextStep() {
    if (!canProceedFromPurity) {
      _errorMessage = AddStockStrings.errPurityRequired;
      notifyListeners();
      return;
    }
    if (_step == AddStockStep.purity) {
      _step = AddStockStep.items;
      _emitChange(clearMessages: false);
    }
  }

  void prevStep() {
    if (_step == AddStockStep.items) {
      _step = AddStockStep.purity;
      _emitChange(clearMessages: false);
    }
  }

  void setPurity(String option) {
    final previousBase = selectedPurityBasePercent;
    _isCustomPurity = option == 'Custom';
    _purityDisplay = _isCustomPurity ? '' : option;
    _syncGoldRowDefaults(previousBase);
    _emitChange();
  }

  void setCustomPurity(String value) {
    final previousBase = selectedPurityBasePercent;
    _purityDisplay = value.trim();
    _syncGoldRowDefaults(previousBase);
    _emitChange();
  }

  void _syncGoldRowDefaults(double previousBaseTouch) {
    if (_selectedMetal != StockCategory.gold) {
      return;
    }

    final newBaseTouch = selectedPurityBasePercent;
    for (final row in _rows) {
      if (!row.hasAnyInput ||
          row.touchPercent == 0 ||
          _near(row.touchPercent, previousBaseTouch)) {
        row.touchPercent = newBaseTouch;
      }
      row.gstRate = _gstEnabled ? gstRate : 0.0;
    }
  }

  void setSessionSupplier(SupplierListItemModel? supplier) {
    _sessionSupplierId = supplier?.id;
    _sessionSupplierName = supplier?.displayName ?? '';
    _isApplyingSupplierProfile = true;
    supplierNameCtrl.text = _sessionSupplierName;
    supplierMobileCtrl.text = supplier?.mobile ?? '';
    supplierGstCtrl.text = supplier?.gstNumber ?? '';
    _isApplyingSupplierProfile = false;

    if (_sameForAll) {
      for (final row in _rows) {
        row.supplierId = _sessionSupplierId;
        row.supplierName = _sessionSupplierName;
      }
    }

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

  Future<void> _hydrateSelectedSupplier(int supplierId) async {
    final fullSupplier = await _supplierRepo.getById(supplierId);
    if (_sessionSupplierId != supplierId) {
      return;
    }

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

  void setSessionSupplierText(String value) {
    _sessionSupplierId = null;
    _sessionSupplierName = value.trimLeft();
    if (supplierNameCtrl.text != value) {
      supplierNameCtrl.text = value;
    }
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
      supplierMobileCtrl.clear();
      supplierNameCtrl.clear();
      supplierRegionCtrl.clear();
      supplierPanCtrl.clear();
      supplierGstCtrl.clear();
    }
    _applyBatchSupplierToRows();
    _emitChange();
  }

  void _applyBatchSupplierToRows() {
    if (!_sameForAll) {
      return;
    }
    for (final row in _rows) {
      row.supplierId = _sessionSupplierId;
      row.supplierName = _sessionSupplierName;
    }
  }

  void setSameForAll(bool value) {
    _sameForAll = value;
    if (value) {
      _applyBatchSupplierToRows();
    }
    _emitChange();
  }

  void setRowSupplier(String rowId, SupplierListItemModel? supplier) {
    final row = _rows.firstWhere((entry) => entry.id == rowId);
    row.supplierId = supplier?.id;
    row.supplierName = supplier?.displayName ?? '';
    _emitChange();
  }

  void setRowSupplierText(String rowId, String value) {
    final row = _rows.firstWhere((entry) => entry.id == rowId);
    row.supplierId = null;
    row.supplierName = value.trimLeft();
    _emitChange();
  }

  void toggleGst(bool value) {
    _gstEnabled = value;
    for (final row in _rows) {
      row.gstRate = value ? gstRate : 0.0;
    }
    _emitChange(clearMessages: false);
  }

  void addRow({bool requestFocus = false}) {
    final newRow = _buildEmptyRow();
    _rows.add(newRow);
    _activeRowId = newRow.id;
    if (requestFocus) {
      _pendingFocusRowId = newRow.id;
    }
    _emitChange();
  }

  void completeRowAndAdvance(String rowId) {
    final currentIndex = _rows.indexWhere((row) => row.id == rowId);
    if (currentIndex == -1) {
      return;
    }

    for (var index = currentIndex + 1; index < _rows.length; index++) {
      if (!_rows[index].hasAnyInput) {
        _pendingFocusRowId = _rows[index].id;
        _emitChange(clearMessages: false);
        return;
      }
    }

    final newRow = _buildEmptyRow();
    _rows.insert(currentIndex + 1, newRow);
    _pendingFocusRowId = newRow.id;
    _emitChange();
  }

  bool shouldRequestFocus(String rowId) => _pendingFocusRowId == rowId;

  void clearFocusRequest(String rowId) {
    if (_pendingFocusRowId == rowId) {
      _pendingFocusRowId = null;
    }
  }

  void removeRow(String rowId) {
    // Allows deleting any row including the last — empty state shows when list is empty.
    _rows.removeWhere((row) => row.id == rowId);
    if (_pendingFocusRowId == rowId) {
      _pendingFocusRowId = null;
    }
    if (_activeRowId == rowId) {
      _activeRowId = _rows.isNotEmpty ? _rows.last.id : null;
    }
    _emitChange();
  }

  // Delete key shortcut — removes the currently focused row (mirrors POS removeActiveItem).
  void removeActiveRow() {
    if (_activeRowId == null || _rows.isEmpty) return;
    final idToRemove = _activeRowId!;
    final removedIndex = _rows.indexWhere((r) => r.id == idToRemove);
    removeRow(idToRemove);
    // Focus previous row after delete
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_rows.isEmpty) return;
      final focusIndex =
          (removedIndex > 0 ? removedIndex - 1 : 0).clamp(0, _rows.length - 1);
      _pendingFocusRowId = _rows[focusIndex].id;
      _activeRowId = _rows[focusIndex].id;
      notifyListeners();
    });
  }

  void updateItemName(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).itemName = value;
    _emitChange();
  }

  void updateDescription(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).description = value;
    _emitChange();
  }

  void updateSubCategory(String rowId, StockSubCategory value) {
    _rows.firstWhere((row) => row.id == rowId).subCategory = value;
    _emitChange();
  }

  void updateHuid(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).huid =
        value.trim().toUpperCase();
    _emitChange();
  }

  void updateGrossWeight(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).grossWeight =
        double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateStoneWeight(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).stoneWeight =
        double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateLessWeight(String rowId, String value) {
    updateStoneWeight(rowId, value);
  }

  void updateTouchPercent(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).touchPercent =
        double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateStoneValue(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).stoneValue =
        double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateStoneType(String rowId, StoneType value) {
    _rows.firstWhere((row) => row.id == rowId).stoneType = value;
    _emitChange();
  }

  void updateStoneCarats(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).stoneCarats =
        double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateStonePieces(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).stonePieces =
        int.tryParse(value) ?? 0;
    _emitChange();
  }

  void updatePurchaseRate(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).purchaseRate =
        double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateMakingCharges(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).makingCharges =
        double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateMakingType(String rowId, MakingChargesType value) {
    _rows.firstWhere((row) => row.id == rowId).makingChargesType = value;
    _emitChange();
  }

  void updateMrp(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).mrp =
        double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateGstRate(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).gstRate =
        double.tryParse(value) ?? 0.0;
    _emitChange();
  }

  void updateQuantity(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).quantity =
        int.tryParse(value) ?? 0;
    _emitChange();
  }

  void updateLocation(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).location = value;
    _emitChange();
  }

  void updateHsnCode(String rowId, String value) {
    _rows.firstWhere((row) => row.id == rowId).hsnCode = value.trim();
    _emitChange();
  }

  void applyPresetHsn(String rowId, JewelleryHsn? hsn) {
    if (hsn == null) {
      return;
    }
    _rows.firstWhere((row) => row.id == rowId).hsnCode = hsn.code;
    _emitChange();
  }

  double touchOf(StockRowEntry row) =>
      row.resolveTouch(selectedPurityBasePercent);

  double fineWeightOf(StockRowEntry row) =>
      row.fineWeight(selectedPurityBasePercent);

  double metalAmount(StockRowEntry row) {
    if (_selectedMetal != StockCategory.gold) {
      return row.costPrice;
    }
    if (pureGoldRatePerGram <= 0) {
      return 0.0;
    }
    return fineWeightOf(row) * pureGoldRatePerGram;
  }

  double labourAmount(StockRowEntry row) {
    return row.labourAmount(
      metalAmount: metalAmount(row),
      fallbackTouch: selectedPurityBasePercent,
    );
  }

  double rowSubtotal(StockRowEntry row) => metalAmount(row) + labourAmount(row);

  double rowGstAmount(StockRowEntry row) {
    if (!_gstEnabled) {
      return 0.0;
    }
    final appliedRate = row.gstRate > 0 ? row.gstRate : gstRate;
    return rowSubtotal(row) * (appliedRate / 100.0);
  }

  double rowTotalAmount(StockRowEntry row) =>
      rowSubtotal(row) + rowGstAmount(row);

  double effectiveRatePerGram(StockRowEntry row) {
    if (row.netWeight <= 0) {
      return 0.0;
    }
    return metalAmount(row) / row.netWeight;
  }

  String composedPurityLabel(StockRowEntry row) {
    final shortLabel = selectedPurityShortLabel.isEmpty
        ? purityDisplay.trim()
        : selectedPurityShortLabel;
    final touch = touchOf(row);
    final touchLabel = touch == touch.roundToDouble()
        ? touch.round().toString()
        : touch.toStringAsFixed(2);

    if (shortLabel.isEmpty) {
      return '$touchLabel% Touch';
    }
    return '$shortLabel • $touchLabel% Touch';
  }

  String? validateRow(StockRowEntry row) {
    if (!row.hasAnyInput) {
      return null;
    }

    if (row.itemName.trim().isEmpty) {
      return AddStockStrings.errItemName;
    }
    if (row.itemName.trim().length < 2) {
      return AddStockStrings.errItemNameShort;
    }
    if (row.quantity < 1) {
      return AddStockStrings.errQtyMin;
    }
    if (row.grossWeight <= 0) {
      return AddStockStrings.errWeightInvalid;
    }
    if (row.grossWeight < 0 || row.stoneWeight < 0) {
      return AddStockStrings.errWeightNeg;
    }
    if (row.stoneWeight > row.grossWeight) {
      return AddStockStrings.errStoneWeightExceeds;
    }
    if (_selectedMetal == StockCategory.gold) {
      final touch = touchOf(row);
      if (touch <= 0 || touch > 100) {
        return 'Touch must be between 0 and 100';
      }
      if (row.makingCharges < 0) {
        return AddStockStrings.errPriceNeg;
      }
    } else if (row.purchaseRate < 0 ||
        row.makingCharges < 0 ||
        row.stoneValue < 0 ||
        row.mrp < 0) {
      return AddStockStrings.errPriceNeg;
    }
    if (row.gstRate < 0 || row.gstRate > 100) {
      return AddStockStrings.errGstRange;
    }
    if (row.huid.trim().isNotEmpty && row.huid.trim().length != 6) {
      return AddStockStrings.errHuidLength;
    }
    return null;
  }

  Future<String?> _validateBeforeSave() async {
    if (!canProceedFromPurity) {
      return AddStockStrings.errPurityRequired;
    }

    final rowsToSave = enteredRows;
    if (rowsToSave.isEmpty) {
      return AddStockStrings.errRowsMissing;
    }

    if (_selectedMetal == StockCategory.gold) {
      if (_sessionSupplierId == null) {
        return 'Select a saved supplier profile before saving this gold batch.';
      }
      if (!hasActiveRateSnapshot) {
        return 'Today\'s gold rate snapshot is missing. Set rates before saving this batch.';
      }
    }

    final seenBatchHuids = <String>{};
    for (int index = 0; index < rowsToSave.length; index++) {
      final row = rowsToSave[index];
      final error = validateRow(row);
      if (error != null) {
        return 'Row ${index + 1}: $error';
      }

      final huid = row.huid.trim().toUpperCase();
      if (huid.isNotEmpty && !seenBatchHuids.add(huid)) {
        return 'Row ${index + 1}: ${AddStockStrings.errDuplicateHuidInBatch}';
      }
    }

    final huidValues = rowsToSave
        .map((row) => row.huid.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (huidValues.isNotEmpty) {
      final existing = await (_db.select(
        _db.stockItems,
      )..where((table) => table.huid.isIn(huidValues)))
          .get();
      if (existing.isNotEmpty) {
        final duplicate = existing.first.huid ?? huidValues.first;
        return '${AddStockStrings.errDuplicateHuidInStock} ($duplicate)';
      }
    }

    return null;
  }

  String _generateSku(int index) {
    final prefix = _selectedMetal.label.length >= 4
        ? _selectedMetal.label.substring(0, 4).toUpperCase()
        : _selectedMetal.label.toUpperCase();
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final uniquePart = now.microsecondsSinceEpoch % 99999;
    return '$prefix-$datePart-${uniquePart + index}';
  }

  Future<bool> saveAll() async {
    if (_isSaving) {
      return false;
    }

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

      if (_selectedMetal == StockCategory.gold) {
        final saved = await _saveGoldBatch(rowsToSave);
        _isSaving = false;
        notifyListeners();
        return saved;
      }

      // Generic save path — Platinum, Diamond, Antique, Other.
      // Silver has its own save path in SilverStockController.saveAll().
      int saved = 0;
      for (int index = 0; index < rowsToSave.length; index++) {
        final row = rowsToSave[index];

        await _db.into(_db.stockItems).insert(
              StockItemsCompanion.insert(
                sku: _generateSku(index),
                itemName: row.itemName.trim(),
                description: drift.Value(
                  row.description.trim().isEmpty
                      ? null
                      : row.description.trim(),
                ),
                category: _selectedMetal.label,
                subCategory: row.subCategory.label,
                metalType: drift.Value(_selectedMetal.label),
                purity: drift.Value(
                  _purityDisplay.trim().isEmpty ? null : _purityDisplay.trim(),
                ),
                grossWeight: drift.Value(row.grossWeight),
                stoneWeight: drift.Value(row.stoneWeight),
                netWeight: drift.Value(row.netWeight),
                stoneType: drift.Value(row.stoneType.label),
                stoneCarats: drift.Value(row.stoneCarats),
                stonePieces: drift.Value(row.stonePieces),
                stoneValue: drift.Value(row.stoneValue),
                purchaseRate: drift.Value(row.purchaseRate),
                makingCharge: drift.Value(row.makingCharges),
                makingChargeType: drift.Value(row.makingChargesType.label),
                purchasePrice: drift.Value(row.costPrice),
                mrp: drift.Value(row.mrp),
                hsnCode: drift.Value(
                  row.hsnCode.trim().isEmpty
                      ? defaultHsnCode
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
          '$saved item${saved > 1 ? 's' : ''} saved to ${_selectedMetal.label} stock successfully!';
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

  Future<bool> _saveGoldBatch(List<StockRowEntry> rowsToSave) async {
    final linkedSupplier = _linkedSupplier;
    final sequenceNo = await _purchaseRepo.getNextSequence();
    final result = await _purchaseRepo.savePurchase(
      PurchaseVoucherDraft(
        sequenceNo: sequenceNo,
        voucherNo:
            'GSTOCK-${DateTime.now().year}-${sequenceNo.toString().padLeft(4, '0')}',
        source: PurchaseSource.fromSupplier,
        taxType: _gstEnabled ? PurchaseTaxType.gst : PurchaseTaxType.normal,
        discountType: PurchaseDiscountType.flatAmount,
        discountValue: 0.0,
        discountAmount: 0.0,
        grossAmount: totalTaxableAmount,
        taxableAmount: totalTaxableAmount,
        gstAmount: totalGstAmount,
        cgstAmount: cgstAmount,
        sgstAmount: sgstAmount,
        grandTotal: totalBatchAmount,
        cashPaid: 0.0,
        bankPaid: 0.0,
        cardPaid: 0.0,
        totalPaid: 0.0,
        balanceDue: totalBatchAmount,
        party: PurchaseVoucherPartyDraft(
          supplierId: _sessionSupplierId,
          name: supplierDisplayName,
          mobile: supplierMobileCtrl.text.trim().isEmpty
              ? null
              : supplierMobileCtrl.text.trim(),
          city: supplierRegionCtrl.text.trim().isEmpty
              ? null
              : supplierRegionCtrl.text.trim(),
          panNumber: supplierPanCtrl.text.trim().isEmpty
              ? null
              : supplierPanCtrl.text.trim(),
          gstNumber: supplierGstCtrl.text.trim().isEmpty
              ? null
              : supplierGstCtrl.text.trim(),
          contactName: linkedSupplier?.contactPersonName,
        ),
        items: rowsToSave
            .map(
              (row) => PurchaseVoucherItemDraft(
                metal: PurchaseMetalType.gold,
                description: row.itemName.trim(),
                grossWeight: row.grossWeight,
                lessWeight: row.lessWeight,
                netWeight: row.netWeight,
                purity: touchOf(row),
                fineWeight: fineWeightOf(row),
                rate: pureGoldRatePerGram,
                lineAmount: rowSubtotal(row),
                subCategory: row.subCategory.label,
                huid: row.huid.trim().isEmpty
                    ? null
                    : row.huid.trim().toUpperCase(),
                hsnCode: row.hsnCode.trim().isEmpty ? null : row.hsnCode.trim(),
                labourCharge: row.makingCharges,
                labourType: row.makingChargesType,
                purityLabel: composedPurityLabel(row),
                effectiveRatePerGram: effectiveRatePerGram(row),
                gstRate: _gstEnabled ? gstRate : 0.0,
              ),
            )
            .toList(),
      ),
    );

    if (result == null) {
      _errorMessage =
          'Gold stock batch could not be saved. Please review the rows and try again.';
      return false;
    }

    _successMessage =
        '${rowsToSave.length} gold item${rowsToSave.length > 1 ? 's' : ''} saved under voucher ${result.voucherNo}. Inventory has been routed into ${selectedPurityShortLabel.isEmpty ? purityDisplay : selectedPurityShortLabel} stock cards.';
    return true;
  }

  void resetAllRows() {
    _rows.clear();
    // ✅ FIX: Start empty after reset — user adds rows with F2 (like POS)
    _pendingFocusRowId = null;
    _activeRowId = null;
    _errorMessage = null;
    _successMessage = null;
    _step = _purityDisplay.trim().isEmpty
        ? AddStockStep.purity
        : AddStockStep.items;
    notifyListeners();
  }

  void resetForNewBatch() {
    _sessionSupplierId = null;
    _sessionSupplierName = '';
    _sameForAll = true;
    _linkedSupplier = null;
    supplierMobileCtrl.clear();
    supplierNameCtrl.clear();
    supplierRegionCtrl.clear();
    supplierPanCtrl.clear();
    supplierGstCtrl.clear();
    supplierInvoiceCtrl.clear();
    _gstEnabled = false;
    // ✅ FIX: Start empty after batch reset — user adds rows with F2 (like POS)
    _pendingFocusRowId = null;
    _activeRowId = null;
    _errorMessage = null;
    _successMessage = null;
    _step = AddStockStep.purity;
    notifyListeners();
  }

  double _parseRateText(String raw) {
    final normalized = raw.replaceAll(',', '').replaceAll('--', '0').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  String _shortPurityLabel(String value) {
    final match = RegExp(r'(\d{1,2}K)').firstMatch(value.toUpperCase());
    if (match != null) {
      return match.group(1)!;
    }
    if (value.contains('999')) {
      return '24K';
    }
    if (value.contains('916')) {
      return '22K';
    }
    if (value.contains('750')) {
      return '18K';
    }
    if (value.contains('585')) {
      return '14K';
    }
    if (value.contains('417')) {
      return '10K';
    }
    return value.trim();
  }

  double _resolvePurityPercent(String value) {
    final normalized = value.toUpperCase();

    final karatMatch = RegExp(r'(\d{1,2})K').firstMatch(normalized);
    if (karatMatch != null) {
      final karat = double.tryParse(karatMatch.group(1) ?? '');
      if (karat != null) {
        return (karat / 24.0) * 100.0;
      }
    }

    final hallmarkMatch = RegExp(
      r'\((\d{3}(?:\.\d+)?)\)',
    ).firstMatch(normalized);
    if (hallmarkMatch != null) {
      final hallmark = double.tryParse(hallmarkMatch.group(1) ?? '');
      if (hallmark != null) {
        return hallmark / 10.0;
      }
    }

    final directPercentMatch = RegExp(
      r'(\d{2,3}(?:\.\d+)?)\s*%',
    ).firstMatch(normalized);
    if (directPercentMatch != null) {
      return double.tryParse(directPercentMatch.group(1) ?? '') ?? 0.0;
    }

    final pureCodeMatch = RegExp(
      r'\b(999|925|800|700)\b',
    ).firstMatch(normalized);
    if (pureCodeMatch != null) {
      final code = double.tryParse(pureCodeMatch.group(1) ?? '');
      if (code != null) {
        return code / 10.0;
      }
    }

    return 0.0;
  }

  bool _near(double a, double b) => (a - b).abs() < 0.11;

  @override
  void dispose() {
    supplierMobileCtrl.dispose();
    supplierNameCtrl.dispose();
    supplierRegionCtrl.dispose();
    supplierPanCtrl.dispose();
    supplierGstCtrl.dispose();
    gold24kManualCtrl.dispose();
    supplierInvoiceCtrl.dispose();
    super.dispose();
  }
}
