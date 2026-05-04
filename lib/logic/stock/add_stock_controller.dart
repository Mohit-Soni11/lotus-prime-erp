// =============================================================================
// FILE        : add_stock_controller.dart
// MODULE      : Stock & Inventory
// LAYER       : Logic / Controller
// DESCRIPTION : Stepped Add Stock wizard controller.
//               ✅ v2: Accepts initialMetal from hub → skips metal step
//               Step 1: Purity → Step 2: Multi-item table
//
// WEIGHT LOGIC:
//   netWeight  = grossWeight − stoneWeight   (metal billing)
//   stoneValue = separate ₹ field            (NOT deducted — billed separately)
//   purchaseRate = rate/g at purchase        (🔒 owner-only — cost guard)
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/stock/stock_enums/stock_enums.dart';
import '../../../../../models/stock/supplier_model/supplier_model.dart';
import '../../repositories/supplier/supplier_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Single item row in the multi-item table
// ─────────────────────────────────────────────────────────────────────────────

class StockRowEntry {
  final String id;

  String itemName = '';
  StockSubCategory subCategory = StockSubCategory.values.first;
  String huid = '';

  double grossWeight = 0.0;
  double stoneWeight = 0.0;

  StoneType stoneType = StoneType.none;
  double stoneCarats = 0.0;
  int stonePieces = 0;

  double stoneValue = 0.0;

  double purchaseRate = 0.0;
  double makingCharges = 0.0;
  MakingChargesType makingChargesType = MakingChargesType.perGram;

  int? supplierId;
  String supplierName = '';

  StockRowEntry({required this.id});

  double get netWeight =>
      (grossWeight - stoneWeight).clamp(0.0, double.infinity);

  double get costPrice {
    final metalCost = netWeight * purchaseRate;
    double making;
    switch (makingChargesType) {
      case MakingChargesType.perGram:
        making = netWeight * makingCharges;
        break;
      case MakingChargesType.flat:
        making = makingCharges;
        break;
      case MakingChargesType.percent:
        making = metalCost * makingCharges / 100;
        break;
    }
    return metalCost + stoneValue + making;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wizard Steps  (Metal step removed — hub screen handles it)
// ─────────────────────────────────────────────────────────────────────────────

enum AddStockStep { purity, items }

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class AddStockController extends ChangeNotifier {
  late final AppDatabase _db;
  late final SupplierRepository _supplierRepo;

  /// ✅ v2: initialMetal is REQUIRED — passed from hub screen
  AddStockController({required StockCategory initialMetal}) {
    _db = AppDatabase();
    _supplierRepo = SupplierRepository(_db);
    _selectedMetal = initialMetal;
    _loadSuppliers();
    _addRow();
  }

  // ── Step ──────────────────────────────────────────────────────────────────
  AddStockStep _step = AddStockStep.purity;
  AddStockStep get step => _step;

  void nextStep() {
    if (_step == AddStockStep.purity) _step = AddStockStep.items;
    notifyListeners();
  }

  void prevStep() {
    if (_step == AddStockStep.items) _step = AddStockStep.purity;
    notifyListeners();
  }

  // ── Metal / Purity ────────────────────────────────────────────────────────
  late StockCategory _selectedMetal;
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
      default:
        return ['Standard', 'Custom'];
    }
  }

  void setPurity(String opt) {
    _isCustomPurity = opt == 'Custom';
    if (!_isCustomPurity) {
      _purityDisplay = opt;
    } else {
      _purityDisplay = '';
    }
    notifyListeners();
  }

  void setCustomPurity(String val) {
    _purityDisplay = val.trim();
    notifyListeners();
  }

  // ── Suppliers ─────────────────────────────────────────────────────────────
  List<SupplierListItemModel> _suppliers = [];
  List<SupplierListItemModel> get suppliers => _suppliers;

  Future<void> _loadSuppliers() async {
    _suppliers = await _supplierRepo.getAllSuppliers();
    notifyListeners();
  }

  // ── Session Supplier (same-for-all) ───────────────────────────────────────
  int? _sessionSupplierId;
  String _sessionSupplierName = '';
  bool _sameForAll = true;

  String get sessionSupplierName => _sessionSupplierName;
  bool get sameForAll => _sameForAll;

  void setSessionSupplier(SupplierListItemModel? s) {
    _sessionSupplierId = s?.id;
    _sessionSupplierName = s?.displayName ?? '';
    if (_sameForAll) {
      for (final r in _rows) {
        r.supplierId = _sessionSupplierId;
        r.supplierName = _sessionSupplierName;
      }
    }
    notifyListeners();
  }

  void setSessionSupplierText(String v) {
    _sessionSupplierName = v;
    notifyListeners();
  }

  void setSameForAll(bool val) {
    _sameForAll = val;
    if (val) {
      for (final r in _rows) {
        r.supplierId = _sessionSupplierId;
        r.supplierName = _sessionSupplierName;
      }
    }
    notifyListeners();
  }

  void setRowSupplier(String rowId, SupplierListItemModel? s) {
    final r = _rows.firstWhere((r) => r.id == rowId);
    r.supplierId = s?.id;
    r.supplierName = s?.displayName ?? '';
    notifyListeners();
  }

  // ── Rows ──────────────────────────────────────────────────────────────────
  final List<StockRowEntry> _rows = [];
  List<StockRowEntry> get rows => List.unmodifiable(_rows);
  int get rowCount => _rows.length;

  void _addRow() {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final row = StockRowEntry(id: id);
    if (_sameForAll) {
      row.supplierId = _sessionSupplierId;
      row.supplierName = _sessionSupplierName;
    }
    _rows.add(row);
    notifyListeners();
  }

  void addRow() => _addRow();

  void removeRow(String id) {
    if (_rows.length <= 1) return;
    _rows.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // ── Row Update Methods ────────────────────────────────────────────────────
  void updateItemName(String id, String v) {
    _rows.firstWhere((r) => r.id == id).itemName = v;
    notifyListeners();
  }

  void updateSubCategory(String id, StockSubCategory v) {
    _rows.firstWhere((r) => r.id == id).subCategory = v;
    notifyListeners();
  }

  void updateHuid(String id, String v) {
    _rows.firstWhere((r) => r.id == id).huid = v;
    notifyListeners();
  }

  void updateGrossWeight(String id, String v) {
    _rows.firstWhere((r) => r.id == id).grossWeight = double.tryParse(v) ?? 0.0;
    notifyListeners();
  }

  void updateStoneWeight(String id, String v) {
    _rows.firstWhere((r) => r.id == id).stoneWeight = double.tryParse(v) ?? 0.0;
    notifyListeners();
  }

  void updateStoneValue(String id, String v) {
    _rows.firstWhere((r) => r.id == id).stoneValue = double.tryParse(v) ?? 0.0;
    notifyListeners();
  }

  void updateStoneType(String id, StoneType v) {
    _rows.firstWhere((r) => r.id == id).stoneType = v;
    notifyListeners();
  }

  void updateStoneCarats(String id, String v) {
    _rows.firstWhere((r) => r.id == id).stoneCarats = double.tryParse(v) ?? 0.0;
    notifyListeners();
  }

  void updateStonePieces(String id, String v) {
    _rows.firstWhere((r) => r.id == id).stonePieces = int.tryParse(v) ?? 0;
    notifyListeners();
  }

  void updatePurchaseRate(String id, String v) {
    _rows.firstWhere((r) => r.id == id).purchaseRate =
        double.tryParse(v) ?? 0.0;
    notifyListeners();
  }

  void updateMakingCharges(String id, String v) {
    _rows.firstWhere((r) => r.id == id).makingCharges =
        double.tryParse(v) ?? 0.0;
    notifyListeners();
  }

  void updateMakingType(String id, MakingChargesType v) {
    _rows.firstWhere((r) => r.id == id).makingChargesType = v;
    notifyListeners();
  }

  // ── Validation ────────────────────────────────────────────────────────────
  String? validateRow(StockRowEntry row) {
    if (row.itemName.trim().isEmpty) return 'Item name required';
    if (row.grossWeight <= 0) return 'Gross weight required';
    return null;
  }

  bool get isValid =>
      _rows.isNotEmpty &&
      _rows.every((r) => validateRow(r) == null) &&
      canProceedFromPurity;

  // ── Save ──────────────────────────────────────────────────────────────────
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // ── SKU Generator ─────────────────────────────────────────────────────────
  String _generateSku(int index) {
    final prefix = _selectedMetal.label.substring(0, 4).toUpperCase();
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final uniq = now.microsecondsSinceEpoch % 99999;
    return '$prefix-$datePart-${uniq + index}';
  }

  Future<bool> saveAll() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      int saved = 0;
      for (int i = 0; i < _rows.length; i++) {
        final row = _rows[i];
        if (validateRow(row) != null) continue;

        await _db.into(_db.stockItems).insert(
              StockItemsCompanion.insert(
                // ✅ sku — required unique field
                sku: _generateSku(i),
                itemName: row.itemName,
                category: _selectedMetal.label,
                subCategory: row.subCategory.label,
                // ✅ purity is nullable in table
                purity:
                    drift.Value(_purityDisplay.isEmpty ? null : _purityDisplay),
                huid: drift.Value(row.huid.isEmpty ? null : row.huid),
                grossWeight: drift.Value(row.grossWeight),
                stoneWeight: drift.Value(row.stoneWeight),
                netWeight: drift.Value(row.netWeight),
                stoneType: drift.Value(row.stoneType.label),
                stoneCarats: drift.Value(row.stoneCarats),
                stonePieces: drift.Value(row.stonePieces),
                stoneValue: drift.Value(row.stoneValue),
                purchaseRate: drift.Value(row.purchaseRate),
                // ✅ makingCharge  (table column name — NOT makingCharges)
                makingCharge: drift.Value(row.makingCharges),
                // ✅ makingChargeType (table column name — NOT makingChargesType)
                makingChargeType: drift.Value(row.makingChargesType.label),
                // ✅ purchasePrice = costPrice calc  (no costPrice column in table)
                purchasePrice: drift.Value(row.costPrice),
                supplierId: drift.Value(row.supplierId),
                supplierName: drift.Value(
                    row.supplierName.isEmpty ? null : row.supplierName),
                // ✅ status (NOT stockStatus)
                status: drift.Value('Available'),
              ),
            );
        saved++;
      }

      _successMessage =
          '$saved item${saved > 1 ? 's' : ''} saved to ${_selectedMetal.label} stock successfully!';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Save failed: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void resetAllRows() {
    _rows.clear();
    _addRow();
    _purityDisplay = '';
    _isCustomPurity = false;
    _step = AddStockStep.purity;
    notifyListeners();
  }

  void resetForNewBatch() {
    _rows.clear();
    _addRow();
    _purityDisplay = '';
    _isCustomPurity = false;
    _step = AddStockStep.purity;
    notifyListeners();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }
}
