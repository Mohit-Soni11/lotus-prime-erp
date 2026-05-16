import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_payment_controller.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

import '../../../models/stock/stock_item_model/add_stock_silver/silver_item_model.dart';

class SilverStockController extends AddStockController {
  String _silverBatchCode;
  final AppDatabase _rateDb = AppDatabase();

  /// ✅ Payment controller — wired to this batch lifecycle
  final SilverPaymentController payment = SilverPaymentController();

  final TextEditingController supplierInvoiceNumberCtrl =
      TextEditingController();

  final List<SilverItemModel> _silverRows = [];

  String? _pendingSilverFocusId;
  String? _activeSilverRowId;
  double _silverRatePer10g = 0.0;
  DateTime? _silverRateDate;
  bool _isLoadingSilverRate = false;

  SilverStockController()
      : _silverBatchCode = _generateSilverBatchCode(),
        super(initialMetal: StockCategory.silver) {
    _loadSilverRateSnapshot();
  }

  @override
  String get batchCode => _silverBatchCode;

  List<SilverItemModel> get silverRows => List.unmodifiable(_silverRows);

  List<SilverItemModel> get enteredSilverRows =>
      _silverRows.where((row) => row.hasAnyInput).toList(growable: false);

  bool get isLoadingSilverRate => _isLoadingSilverRate;
  DateTime? get silverRateDate => _silverRateDate;
  double get silverRatePer10g => _silverRatePer10g;
  double get silverRatePerGram =>
      _silverRatePer10g > 0 ? _silverRatePer10g / 10.0 : 0.0;
  bool get hasSilverRateSnapshot => silverRatePerGram > 0;
  double get totalFineWeight =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.fineWeight);
  @override
  int get totalQuantity =>
      enteredSilverRows.fold(0, (sum, row) => sum + row.pieces);

  String get silverRateDisplay {
    if (_isLoadingSilverRate) {
      return 'Loading rate...';
    }
    if (!hasSilverRateSnapshot) {
      return 'Rate missing';
    }
    return 'Rs ${silverRatePerGram.toStringAsFixed(2)}/g';
  }

  @override
  List<StockRowEntry> get enteredRows {
    final supplierId = linkedSupplier?.id;
    final supplierName = supplierDisplayName;

    return enteredSilverRows.map((rowModel) {
      final pieces = rowModel.pieces;
      final lotDivisor = pieces > 0 ? pieces : 1;
      final row = StockRowEntry(id: rowModel.id, hsnCode: defaultHsnCode);
      row.itemName = rowModel.itemName;
      row.description = rowModel.categoryLabel;
      row.subCategory = _mapSilverSubCategory(rowModel.categoryLabel);
      row.subCategoryLabel = rowModel.categoryLabel;
      row.huid = rowModel.huid;
      row.grossWeight = rowModel.grossWeight / lotDivisor;
      row.stoneWeight = rowModel.lessWeight / lotDivisor;
      row.touchPercent = rowModel.totalPurityPercent;
      row.purityLabel = rowModel.purityLabel;
      row.purchaseRate = rowModel.purchaseRate;
      row.purchasePriceOverride = rowModel.totalAmount / lotDivisor;
      row.makingCharges = switch (rowModel.makingChargesType) {
        MakingChargesType.flat => rowModel.makingValue / lotDivisor,
        MakingChargesType.perGram ||
        MakingChargesType.percent =>
          rowModel.makingValue,
      };
      row.makingChargesType = rowModel.makingChargesType;
      row.gstRate = gstEnabled ? gstRate : 0.0;
      row.supplierId = supplierId;
      row.supplierName = supplierName;
      row.quantity = pieces;
      return row;
    }).toList(growable: false);
  }

  @override
  int get enteredRowCount => enteredSilverRows.length;

  @override
  int get rowCount => _silverRows.length;

  @override
  double get totalGrossWeight =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.grossWeight);

  @override
  double get totalNetWeight =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.netWeight);

  @override
  double get totalEstimatedCost =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.totalAmount);

  @override
  double get totalEstimatedSelling =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.totalAmount);

  @override
  double get totalTaxableAmount =>
      enteredSilverRows.fold(0.0, (sum, row) => sum + row.totalAmount);

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

  @override
  int get rowsWithErrorsCount =>
      enteredSilverRows.where((row) => validateSilverRow(row) != null).length;

  @override
  bool get hasAnyInput => super.hasAnyInput || enteredSilverRows.isNotEmpty;

  String? validateSilverRow(SilverItemModel row) {
    if (!row.hasAnyInput) {
      return null;
    }
    if (row.categoryLabel.isEmpty) {
      return 'Category is required';
    }
    if (row.itemName.isEmpty) {
      return 'Item name is required';
    }
    if (row.itemName.length < 2) {
      return 'Item name must be at least 2 characters';
    }
    if (row.pieces < 1) {
      return 'Pieces must be at least 1';
    }
    if (row.grossWeight <= 0) {
      return 'Gross weight must be greater than 0';
    }
    if (row.lessWeight < 0) {
      return 'Less weight cannot be negative';
    }
    if (row.lessWeight > row.grossWeight) {
      return 'Less weight cannot exceed gross weight';
    }
    if (row.purityLabel.isEmpty) {
      return 'Base purity is required';
    }
    if (row.totalPurityPercent <= 0 || row.totalPurityPercent > 100) {
      return 'Total purity must be between 0 and 100';
    }
    if (row.purchaseRate <= 0) {
      return 'Silver daily rate is missing. Update silver jewellery rate first.';
    }
    if (row.makingValue < 0) {
      return 'Making charge cannot be negative';
    }
    if (row.huid.isNotEmpty && row.huid.length != 6) {
      return 'HUID must be exactly 6 characters';
    }
    return null;
  }

  @override
  void addRow({bool requestFocus = false}) {
    _addSilverModel(requestFocus: requestFocus);
  }

  void _addSilverModel({bool requestFocus = false}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final model = SilverItemModel(
      id: id,
      initialPurityLabel: _defaultSilverPurityLabel(),
      initialWastagePercent: 0.0,
      initialPurchaseRate: silverRatePerGram,
      initialPieces: 1,
    );
    model.addListener(notifyListeners);
    _silverRows.add(model);
    if (requestFocus) {
      _pendingSilverFocusId = id;
    }
    notifyListeners();
  }

  @override
  void removeRow(String rowId) {
    final index = _silverRows.indexWhere((row) => row.id == rowId);
    if (index == -1) {
      return;
    }

    final model = _silverRows[index];
    model.removeListener(notifyListeners);
    _silverRows.removeAt(index);

    if (_activeSilverRowId == rowId) {
      _activeSilverRowId = _silverRows.isNotEmpty ? _silverRows.last.id : null;
    }
    if (_pendingSilverFocusId == rowId) {
      _pendingSilverFocusId = null;
    }

    model.disposeAll();
    notifyListeners();
  }

  @override
  void removeActiveRow() {
    if (_silverRows.isEmpty) {
      return;
    }
    final targetId = _activeSilverRowId != null &&
            _silverRows.any((row) => row.id == _activeSilverRowId)
        ? _activeSilverRowId!
        : _silverRows.last.id;
    removeRow(targetId);
  }

  void setSilverActiveRow(String id) => _activeSilverRowId = id;

  bool shouldRequestSilverFocus(String id) => _pendingSilverFocusId == id;

  void clearSilverFocusRequest(String id) {
    if (_pendingSilverFocusId == id) {
      _pendingSilverFocusId = null;
    }
  }

  void completeRowAndAdvanceSilver(String rowId) {
    final index = _silverRows.indexWhere((row) => row.id == rowId);
    if (index == -1) {
      return;
    }

    for (var i = index + 1; i < _silverRows.length; i++) {
      if (!_silverRows[i].hasAnyInput) {
        _pendingSilverFocusId = _silverRows[i].id;
        notifyListeners();
        return;
      }
    }

    _addSilverModel(requestFocus: true);
  }

  @override
  void resetAllRows() {
    _clearSilverRows();
    notifyListeners();
  }

  @override
  void resetForNewBatch() {
    _silverBatchCode = _generateSilverBatchCode();
    supplierInvoiceNumberCtrl.clear();
    payment.reset(); // ✅ payment fields bhi reset
    _clearSilverRows();
    super.resetForNewBatch();
    _loadSilverRateSnapshot();
  }

  void _clearSilverRows() {
    for (final row in _silverRows) {
      row.removeListener(notifyListeners);
      row.disposeAll();
    }
    _silverRows.clear();
    _pendingSilverFocusId = null;
    _activeSilverRowId = null;
  }

  @override
  void dispose() {
    supplierInvoiceNumberCtrl.dispose();
    payment.dispose(); // ✅ payment controller dispose
    for (final row in _silverRows) {
      row.removeListener(notifyListeners);
      row.disposeAll();
    }
    _silverRows.clear();
    super.dispose();
  }

  Future<void> _loadSilverRateSnapshot() async {
    _isLoadingSilverRate = true;
    notifyListeners();

    try {
      final latestRate = await (_rateDb.select(_rateDb.dailyRates)
            ..orderBy([(r) => drift.OrderingTerm.desc(r.rateDate)])
            ..limit(1))
          .getSingleOrNull();

      if (latestRate != null) {
        final jewelleryRate = _parseSilverRate(latestRate.silverJewellery);
        final kgRate = _parseSilverRate(latestRate.silverRateKg);
        _silverRatePer10g = jewelleryRate > 0 ? jewelleryRate : kgRate / 100.0;
        _silverRateDate = latestRate.rateDate;
      } else {
        _silverRatePer10g = 0.0;
        _silverRateDate = null;
      }

      for (final row in _silverRows) {
        row.applyPurchaseRate(silverRatePerGram);
      }
    } catch (_) {
      _silverRatePer10g = 0.0;
      _silverRateDate = null;
    }

    _isLoadingSilverRate = false;
    notifyListeners();
  }

  String _defaultSilverPurityLabel() {
    final trimmed = purityDisplay.trim().toUpperCase();
    final codeMatch = RegExp(r'\b(999|925|800|700)\b').firstMatch(trimmed);
    if (codeMatch != null) {
      return codeMatch.group(1)!;
    }
    return trimmed;
  }

  StockSubCategory _mapSilverSubCategory(String categoryLabel) {
    final normalized = categoryLabel.trim().toLowerCase();
    if (normalized.contains('anklet') || normalized.contains('payal')) {
      return StockSubCategory.anklet;
    }
    if (normalized.contains('chain')) {
      return StockSubCategory.chain;
    }
    if (normalized.contains('bracelet')) {
      return StockSubCategory.bracelet;
    }
    if (normalized.contains('bichhiya') || normalized.contains('toe ring')) {
      return StockSubCategory.ring;
    }
    if (normalized.contains('ring')) {
      return StockSubCategory.ring;
    }
    if (normalized.contains('bangle') || normalized.contains('kada')) {
      return StockSubCategory.bangle;
    }
    if (normalized.contains('pendant') || normalized.contains('locket')) {
      return StockSubCategory.pendant;
    }
    if (normalized.contains('necklace') || normalized.contains('set')) {
      return StockSubCategory.necklace;
    }
    if (normalized.contains('earring') || normalized.contains('jhumka')) {
      return StockSubCategory.earring;
    }
    return StockSubCategory.other;
  }

  double _parseSilverRate(String raw) {
    final normalized = raw.replaceAll(',', '').replaceAll('--', '0').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

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
