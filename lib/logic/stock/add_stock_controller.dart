import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/stock/stock_enums/stock_enums.dart';
import 'package:lotus_erp/models/stock/supplier_model/supplier_model.dart';
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

  double get costPrice {
    final metalCost = netWeight * purchaseRate;
    final making = switch (makingChargesType) {
      MakingChargesType.perGram => netWeight * makingCharges,
      MakingChargesType.flat => makingCharges,
      MakingChargesType.percent => metalCost * makingCharges / 100,
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

  AddStockController({required StockCategory initialMetal}) {
    _supplierRepo = SupplierRepository(_db);
    _selectedMetal = initialMetal;
    _rows.add(_buildEmptyRow());
    _loadSuppliers();
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
          '24K (999)',
          '22K (916)',
          '18K (750)',
          '14K (585)',
          '10K (417)',
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

  List<SupplierListItemModel> _suppliers = [];
  List<SupplierListItemModel> get suppliers => _suppliers;

  int? _sessionSupplierId;
  String _sessionSupplierName = '';
  bool _sameForAll = true;

  String get sessionSupplierName => _sessionSupplierName;
  bool get sameForAll => _sameForAll;

  final List<StockRowEntry> _rows = [];
  List<StockRowEntry> get rows => List.unmodifiable(_rows);
  int get rowCount => _rows.length;

  int get totalQuantity => _rows.fold<int>(0, (sum, row) => sum + row.quantity);

  double get totalGrossWeight => _rows.fold<double>(
        0,
        (sum, row) => sum + (row.grossWeight * row.quantity),
      );

  double get totalNetWeight =>
      _rows.fold<double>(0, (sum, row) => sum + (row.netWeight * row.quantity));

  double get totalEstimatedCost =>
      _rows.fold<double>(0, (sum, row) => sum + row.totalCostValue);

  double get totalEstimatedSelling =>
      _rows.fold<double>(0, (sum, row) => sum + row.totalSellingValue);

  int get rowsWithErrorsCount =>
      _rows.where((row) => validateRow(row) != null).length;

  bool get hasAnyInput {
    return _purityDisplay.trim().isNotEmpty ||
        _sessionSupplierName.trim().isNotEmpty ||
        _rows.any((row) => row.hasAnyInput);
  }

  bool get isValid =>
      canProceedFromPurity &&
      _rows.isNotEmpty &&
      _rows.every((row) => validateRow(row) == null);

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Future<void> _loadSuppliers() async {
    await reloadSuppliers();
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
    _isCustomPurity = option == 'Custom';
    _purityDisplay = _isCustomPurity ? '' : option;
    _emitChange();
  }

  void setCustomPurity(String value) {
    _purityDisplay = value.trim();
    _emitChange();
  }

  void setSessionSupplier(SupplierListItemModel? supplier) {
    _sessionSupplierId = supplier?.id;
    _sessionSupplierName = supplier?.displayName ?? '';
    if (_sameForAll) {
      for (final row in _rows) {
        row.supplierId = _sessionSupplierId;
        row.supplierName = _sessionSupplierName;
      }
    }
    _emitChange();
  }

  void setSessionSupplierText(String value) {
    _sessionSupplierId = null;
    _sessionSupplierName = value.trimLeft();
    if (_sameForAll) {
      for (final row in _rows) {
        row.supplierId = null;
        row.supplierName = _sessionSupplierName;
      }
    }
    _emitChange();
  }

  void setSameForAll(bool value) {
    _sameForAll = value;
    if (value) {
      for (final row in _rows) {
        row.supplierId = _sessionSupplierId;
        row.supplierName = _sessionSupplierName;
      }
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

  void addRow() {
    _rows.add(_buildEmptyRow());
    _emitChange();
  }

  void removeRow(String rowId) {
    if (_rows.length <= 1) {
      return;
    }
    _rows.removeWhere((row) => row.id == rowId);
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

  String? validateRow(StockRowEntry row) {
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
    if (row.purchaseRate < 0 ||
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
    if (_rows.isEmpty) {
      return AddStockStrings.errRowsMissing;
    }

    final seenBatchHuids = <String>{};
    for (int index = 0; index < _rows.length; index++) {
      final row = _rows[index];
      final error = validateRow(row);
      if (error != null) {
        return 'Row ${index + 1}: $error';
      }

      final huid = row.huid.trim().toUpperCase();
      if (huid.isNotEmpty && !seenBatchHuids.add(huid)) {
        return 'Row ${index + 1}: ${AddStockStrings.errDuplicateHuidInBatch}';
      }
    }

    final huidValues = _rows
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

      int saved = 0;
      for (int index = 0; index < _rows.length; index++) {
        final row = _rows[index];

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

  void resetAllRows() {
    _rows
      ..clear()
      ..add(_buildEmptyRow());
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
    _purityDisplay = '';
    _isCustomPurity = false;
    _rows
      ..clear()
      ..add(_buildEmptyRow());
    _errorMessage = null;
    _successMessage = null;
    _step = AddStockStep.purity;
    notifyListeners();
  }
}
