import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/repositories/purchase/purchase_entry_repository.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_repository.dart';
import 'package:lotus_erp/repositories/supplier/supplier_repository.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';

class StockRowEntry {
  final String id;

  String itemName = '';
  String description = '';
  StockSubCategory subCategory = StockSubCategory.ring;
  String subCategoryLabel = '';
  String segmentLabel = '';
  String huid = '';
  List<String> huids = [];
  String hsnCode;

  double grossWeight = 0.0;
  double stoneWeight = 0.0;
  double stoneValue = 0.0;
  double touchPercent = 0.0;
  String purityLabel = '';

  StoneType stoneType = StoneType.none;
  double stoneCarats = 0.0;
  int stonePieces = 0;

  double purchaseRate = 0.0;
  double purchasePriceOverride = 0.0;
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

  double get resolvedCostPrice =>
      purchasePriceOverride > 0 ? purchasePriceOverride : costPrice;

  double get totalCostValue => resolvedCostPrice * quantity;

  double get totalSellingValue =>
      ((mrp > 0 ? mrp : resolvedCostPrice) * quantity);

  bool get hasAnyInput {
    return itemName.trim().isNotEmpty ||
        description.trim().isNotEmpty ||
        segmentLabel.trim().isNotEmpty ||
        huid.trim().isNotEmpty ||
        huids.any((value) => value.trim().isNotEmpty) ||
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

  AddStockController({required StockCategory initialMetal}) {
    _supplierRepo = SupplierRepository(_db);
    _purchaseRepo = PurchaseEntryRepository(db: _db);
    _selectedMetal = initialMetal;
    _rows.add(_buildEmptyRow());
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

  List<String> get purityOptions {
    switch (_selectedMetal) {
      case StockCategory.gold:
        return [
          '24KT (999)',
          '22KT (916)',
          '18KT (750)',
          '14KT (585)',
          '9KT (375)',
          'Custom',
        ];
      case StockCategory.silver:
        return ['999 (Pure)', '925 (Sterling)', '800', '700', 'Custom'];
      case StockCategory.platinum:
        return ['950 Platinum', '900 Platinum', '850 Platinum', 'Custom'];
      case StockCategory.diamond:
        return ['Solitaire', 'Studded', 'Fancy', 'Custom'];
      case StockCategory.antique:
      case StockCategory.other:
        return ['Standard', 'Custom'];
    }
  }

  String get defaultHsnCode {
    switch (_selectedMetal) {
      case StockCategory.gold:
      case StockCategory.silver:
      case StockCategory.platinum:
        return JewelleryHsn.h7113.code;
      case StockCategory.diamond:
        return JewelleryHsn.h7116.code;
      case StockCategory.antique:
      case StockCategory.other:
        return JewelleryHsn.h7117.code;
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

  String get sessionSupplierName => _sessionSupplierName;
  int? get sessionSupplierId => _sessionSupplierId;
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
  double _gold14kRatePer10g = 0.0;
  double _gold9kRatePer10g = 0.0;
  double? _manualGold24kRatePer10g;
  DateTime? _goldRateDate;
  bool _isLoadingGoldRates = false;
  Map<String, double> _goldRateByPurityPer10g = {};

  bool get isLoadingGoldRates => _isLoadingGoldRates;
  DateTime? get goldRateDate => _goldRateDate;
  double get gold24kRatePer10g => _gold24kRatePer10g;
  double get gold22kRatePer10g => _gold22kRatePer10g;
  double get gold18kRatePer10g => _gold18kRatePer10g;
  double get gold14kRatePer10g => _gold14kRatePer10g;
  double get gold9kRatePer10g => _gold9kRatePer10g;

  String get selectedPurityShortLabel => _shortPurityLabel(_purityDisplay);

  double get selectedPurityBasePercent => _resolvePurityPercent(_purityDisplay);

  double get effectiveGold24kRatePer10g {
    if (_selectedMetal != StockCategory.gold) {
      return 0.0;
    }

    if (_manualGold24kRatePer10g != null && _manualGold24kRatePer10g! > 0) {
      return _manualGold24kRatePer10g!;
    }

    return _gold24kRatePer10g;
  }

  double get selectedPurityRatePer10g {
    if (_selectedMetal != StockCategory.gold) {
      return 0.0;
    }

    final masterRate = _goldRateByPurityPer10g[selectedPurityShortLabel] ?? 0.0;
    if (masterRate > 0) {
      return masterRate;
    }

    final basePercent = selectedPurityBasePercent;
    final pureRate = effectiveGold24kRatePer10g;
    if (basePercent <= 0 || pureRate <= 0) {
      return 0.0;
    }

    return pureRate * (basePercent / 100.0);
  }

  double get pureGoldRatePerGram =>
      effectiveGold24kRatePer10g > 0 ? effectiveGold24kRatePer10g / 10.0 : 0.0;

  double get selectedPurityRatePerGram =>
      selectedPurityRatePer10g > 0 ? selectedPurityRatePer10g / 10.0 : 0.0;

  bool get hasActiveRateSnapshot => selectedPurityRatePer10g > 0;

  String? _pendingFocusRowId;
  String? _activeRowId;

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
      final masterProfile =
          await MetalRateRepository().loadProfile(MetalRateMetal.gold);
      final masterRates = <String, double>{};
      for (final plan in masterProfile.purityPlans) {
        final key = _normaliseRateKey(plan.label);
        final rate = plan.manualDisplayRatePer10g > 0
            ? plan.manualDisplayRatePer10g
            : masterProfile.marketBaseRatePer10g * plan.purityFactor;
        if (key.isNotEmpty && rate > 0) {
          masterRates[key] = rate;
        }
      }

      final latestRate = await (_db.select(_db.dailyRates)
            ..orderBy([(r) => drift.OrderingTerm.desc(r.rateDate)])
            ..limit(1))
          .getSingleOrNull();

      if (latestRate != null) {
        masterRates.putIfAbsent(
            '24K', () => _parseRateText(latestRate.gold24k));
        masterRates.putIfAbsent(
            '22K', () => _parseRateText(latestRate.gold22k));
        masterRates.putIfAbsent(
            '18K', () => _parseRateText(latestRate.gold18k));
      }

      _goldRateByPurityPer10g = masterRates;
      _gold24kRatePer10g = masterRates['24K'] ?? 0.0;
      _gold22kRatePer10g = masterRates['22K'] ?? 0.0;
      _gold18kRatePer10g = masterRates['18K'] ?? 0.0;
      _gold14kRatePer10g = masterRates['14K'] ?? 0.0;
      _gold9kRatePer10g = masterRates['9K'] ?? 0.0;
      _goldRateDate = masterProfile.updatedAt
              .isAfter(DateTime.fromMillisecondsSinceEpoch(0))
          ? masterProfile.updatedAt
          : latestRate?.rateDate;
    } catch (_) {
      _gold24kRatePer10g = 0.0;
      _gold22kRatePer10g = 0.0;
      _gold18kRatePer10g = 0.0;
      _gold14kRatePer10g = 0.0;
      _gold9kRatePer10g = 0.0;
      _goldRateByPurityPer10g = {};
      _goldRateDate = null;
    }

    if (_manualGold24kRatePer10g == null || _manualGold24kRatePer10g! <= 0) {
      gold24kManualCtrl.text = _formatRateText(_gold24kRatePer10g);
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
      supplierRegionCtrl.text = fullSupplier.state ?? '';
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

  void setManual24kRate(String value) {
    final normalized = value.replaceAll(',', '').trim();

    if (normalized.isEmpty) {
      _manualGold24kRatePer10g = null;
      _emitChange(clearMessages: false);
      return;
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      _manualGold24kRatePer10g = null;
      _emitChange(clearMessages: false);
      return;
    }

    _manualGold24kRatePer10g = parsed;
    _emitChange(clearMessages: false);
  }

  void setActiveRow(String rowId) {
    _activeRowId = rowId;
  }

  void removeActiveRow() {
    if (_rows.length <= 1) {
      return;
    }

    final targetRowId =
        _activeRowId != null && _rows.any((row) => row.id == _activeRowId)
            ? _activeRowId!
            : _rows.last.id;

    removeRow(targetRowId);
  }

  void removeRow(String rowId) {
    if (_rows.length <= 1) {
      return;
    }
    _rows.removeWhere((row) => row.id == rowId);
    if (_rows.isEmpty) {
      final fallbackRow = _buildEmptyRow();
      _rows.add(fallbackRow);
      _activeRowId = fallbackRow.id;
    } else if (_activeRowId == rowId) {
      _activeRowId = _rows.last.id;
    }
    if (_pendingFocusRowId == rowId) {
      _pendingFocusRowId = null;
    }
    _emitChange();
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
      return selectedPurityRatePerGram > 0
          ? row.netWeight * selectedPurityRatePerGram
          : 0.0;
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

  String resolvedPurityStorageLabel(StockRowEntry row) {
    final baseLabel = row.purityLabel.trim().isNotEmpty
        ? row.purityLabel.trim()
        : _purityDisplay.trim();
    if (baseLabel.isEmpty) {
      return '';
    }

    if (_selectedMetal != StockCategory.silver) {
      return baseLabel;
    }

    final touch = row.resolveTouch(selectedPurityBasePercent);
    final basePercent = _resolvePurityPercent(baseLabel);
    if (basePercent <= 0 || _near(basePercent, touch)) {
      return baseLabel;
    }

    final touchLabel = touch == touch.roundToDouble()
        ? touch.round().toString()
        : touch.toStringAsFixed(2);
    return '$baseLabel • $touchLabel% Touch';
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
    if (_selectedMetal == StockCategory.silver &&
        row.subCategoryLabel.trim().isEmpty) {
      return 'Category is required';
    }
    if (_selectedMetal == StockCategory.silver) {
      final purityLabel = row.purityLabel.trim().isNotEmpty
          ? row.purityLabel.trim()
          : _purityDisplay.trim();
      if (purityLabel.isEmpty) {
        return 'Base purity is required';
      }

      final touch =
          row.touchPercent > 0 ? row.touchPercent : selectedPurityBasePercent;
      if (touch <= 0 || touch > 100) {
        return 'Total purity must be between 0 and 100';
      }

      if (row.purchaseRate <= 0) {
        return 'Silver daily rate is missing. Update silver jewellery rate before saving.';
      }
    }
    if (row.gstRate < 0 || row.gstRate > 100) {
      return AddStockStrings.errGstRange;
    }
    final rowHuids = row.huids.isNotEmpty
        ? row.huids
        : [
            if (row.huid.trim().isNotEmpty) row.huid.trim(),
          ];
    final invalidHuid = rowHuids
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .any((value) => value.length != 6);
    if (invalidHuid) {
      return AddStockStrings.errHuidLength;
    }
    if (_selectedMetal != StockCategory.gold &&
        row.huid.trim().isNotEmpty &&
        row.quantity != 1) {
      return 'HUID item must have quantity 1';
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

    final customValidation = await validateCustomBatch(rowsToSave);
    if (customValidation != null) {
      return customValidation;
    }

    final seenBatchHuids = <String>{};
    for (int index = 0; index < rowsToSave.length; index++) {
      final row = rowsToSave[index];
      final error = validateRow(row);
      if (error != null) {
        return 'Row ${index + 1}: $error';
      }

      final rowHuids = row.huids.isNotEmpty
          ? row.huids
          : [
              if (row.huid.trim().isNotEmpty) row.huid,
            ];
      for (final huidValue in rowHuids) {
        final huid = huidValue.trim().toUpperCase();
        if (huid.isNotEmpty && !seenBatchHuids.add(huid)) {
          return 'Row ${index + 1}: ${AddStockStrings.errDuplicateHuidInBatch}';
        }
      }
    }

    final huidValues = rowsToSave
        .expand(
          (row) => row.huids.isNotEmpty
              ? row.huids
              : [
                  if (row.huid.trim().isNotEmpty) row.huid,
                ],
        )
        .map((value) => value.trim().toUpperCase())
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

      try {
        final placeholders = List.filled(huidValues.length, '?').join(', ');
        final serialRows = await _db.customSelect(
          '''
          SELECT huid
          FROM purchase_item_huids
          WHERE huid IN ($placeholders)
          LIMIT 1
          ''',
          variables: huidValues.map(drift.Variable.withString).toList(),
        ).get();
        if (serialRows.isNotEmpty) {
          final duplicate = serialRows.first.read<String>('huid');
          return '${AddStockStrings.errDuplicateHuidInStock} ($duplicate)';
        }
      } catch (_) {}
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

  @protected
  Future<String?> validateCustomBatch(List<StockRowEntry> rowsToSave) async {
    return null;
  }

  @protected
  Future<int> getNextPurchaseSequence() => _purchaseRepo.getNextSequence();

  @protected
  Future<PurchaseVoucherDraft?> buildPurchaseVoucherDraft(
    List<StockRowEntry> rowsToSave,
  ) async {
    return null;
  }

  @protected
  String buildPurchaseSuccessMessage(
    PurchaseSaveResult result,
    List<StockRowEntry> rowsToSave,
  ) {
    return '${rowsToSave.length} ${_selectedMetal.label} item${rowsToSave.length > 1 ? 's' : ''} saved under voucher ${result.voucherNo}.';
  }

  String _purchaseSaveFailureMessage(String fallback) {
    final detail = _purchaseRepo.lastErrorMessage?.trim();
    if (detail == null || detail.isEmpty) {
      return fallback;
    }
    return '$fallback Detail: $detail';
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

      final purchaseDraft = await buildPurchaseVoucherDraft(rowsToSave);
      if (purchaseDraft != null) {
        final result = await _purchaseRepo.savePurchase(purchaseDraft);
        if (result == null) {
          _errorMessage = _purchaseSaveFailureMessage(
            '${_selectedMetal.label} stock batch could not be saved. Please review the rows and try again.',
          );
          _isSaving = false;
          notifyListeners();
          return false;
        }

        _successMessage = buildPurchaseSuccessMessage(result, rowsToSave);
        _isSaving = false;
        notifyListeners();
        return true;
      }

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
                subCategory: row.subCategoryLabel.trim().isEmpty
                    ? row.subCategory.label
                    : row.subCategoryLabel.trim(),
                metalType: drift.Value(_selectedMetal.label),
                purity: drift.Value(
                  resolvedPurityStorageLabel(row).isEmpty
                      ? null
                      : resolvedPurityStorageLabel(row),
                ),
                grossWeight: drift.Value(row.grossWeight),
                stoneWeight: drift.Value(row.stoneWeight),
                netWeight: drift.Value(row.netWeight),
                wastage: drift.Value(
                  row.resolveTouch(selectedPurityBasePercent),
                ),
                stoneType: drift.Value(row.stoneType.label),
                stoneCarats: drift.Value(row.stoneCarats),
                stonePieces: drift.Value(row.stonePieces),
                stoneValue: drift.Value(row.stoneValue),
                purchaseRate: drift.Value(row.purchaseRate),
                makingCharge: drift.Value(row.makingCharges),
                makingChargeType: drift.Value(row.makingChargesType.label),
                purchasePrice: drift.Value(row.resolvedCostPrice),
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

  void resetAllRows() {
    _rows
      ..clear()
      ..add(_buildEmptyRow());
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
    _gstEnabled = false;
    _purityDisplay = '';
    _isCustomPurity = false;
    _rows
      ..clear()
      ..add(_buildEmptyRow());
    _pendingFocusRowId = null;
    _activeRowId = null;
    _manualGold24kRatePer10g = null;
    gold24kManualCtrl.text = _formatRateText(_gold24kRatePer10g);
    _errorMessage = null;
    _successMessage = null;
    _step = AddStockStep.purity;
    notifyListeners();
  }

  String _formatRateText(double value) {
    if (value <= 0) {
      return '';
    }

    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  double _parseRateText(String raw) {
    final normalized = raw.replaceAll(',', '').replaceAll('--', '0').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  String _shortPurityLabel(String value) {
    final normalized = value.toUpperCase().replaceAll('KT', 'K');
    final match = RegExp(r'(\d{1,2}K)').firstMatch(normalized);
    if (match != null) {
      return match.group(1)!;
    }
    if (normalized.contains('999')) {
      return '24K';
    }
    if (normalized.contains('916')) {
      return '22K';
    }
    if (normalized.contains('750')) {
      return '18K';
    }
    if (normalized.contains('585')) {
      return '14K';
    }
    if (normalized.contains('375')) {
      return '9K';
    }
    if (normalized.contains('417')) {
      return '10K';
    }
    return value.trim();
  }

  String _normaliseRateKey(String value) {
    final normalized = value.trim().toUpperCase().replaceAll('KT', 'K');
    final karatMatch = RegExp(r'(\d{1,2}K)').firstMatch(normalized);
    if (karatMatch != null) {
      return karatMatch.group(1)!;
    }
    if (normalized.contains('999')) return '24K';
    if (normalized.contains('916')) return '22K';
    if (normalized.contains('750')) return '18K';
    if (normalized.contains('585')) return '14K';
    if (normalized.contains('375')) return '9K';
    return normalized;
  }

  double _resolvePurityPercent(String value) {
    final normalized = value.toUpperCase().replaceAll('KT', 'K');

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
    super.dispose();
  }
}
