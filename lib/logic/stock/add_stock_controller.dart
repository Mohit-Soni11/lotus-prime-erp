// =============================================================================
// FILE        : add_stock_controller.dart
// MODULE      : Stock & Inventory
// LAYER       : Logic / Controller
// DESCRIPTION : Reworked stepped Add Stock wizard controller.
//               Step 1: Metal → Step 2: Purity → Step 3: Multi-item table
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

  String itemName          = '';
  StockSubCategory subCategory = StockSubCategory.values.first; // ✅ Safer enum access
  String huid              = '';

  double grossWeight       = 0.0;
  double stoneWeight       = 0.0;
  
  StoneType stoneType      = StoneType.none;
  double stoneCarats       = 0.0;
  int    stonePieces       = 0;

  double stoneValue        = 0.0;

  double purchaseRate      = 0.0;
  double makingCharges     = 0.0;
  MakingChargesType makingChargesType = MakingChargesType.perGram;

  int?   supplierId;
  String supplierName      = '';

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
// Wizard Steps
// ─────────────────────────────────────────────────────────────────────────────

enum AddStockStep { metal, purity, items }

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class AddStockController extends ChangeNotifier {
  late final AppDatabase        _db;
  late final SupplierRepository _supplierRepo;

  AddStockController() {
    _db           = AppDatabase();
    _supplierRepo = SupplierRepository(_db);
    _loadSuppliers();
    _addRow();
  }

  // ── Step ──────────────────────────────────────────────────────────────────
  AddStockStep _step = AddStockStep.metal;
  AddStockStep get step => _step;

  void nextStep() {
    if (_step == AddStockStep.metal)  _step = AddStockStep.purity;
    else if (_step == AddStockStep.purity) _step = AddStockStep.items;
    notifyListeners();
  }

  void prevStep() {
    if (_step == AddStockStep.purity) _step = AddStockStep.metal;
    else if (_step == AddStockStep.items) _step = AddStockStep.purity;
    notifyListeners();
  }

  // ── Metal / Purity ────────────────────────────────────────────────────────
  StockCategory _selectedMetal  = StockCategory.gold;
  String        _selectedPurity = '22K (916)';
  bool          _isCustomPurity = false;
  String        _customPurity   = '';

  StockCategory get selectedMetal   => _selectedMetal;
  bool          get isCustomPurity  => _isCustomPurity;
  String        get purityDisplay   => _isCustomPurity ? _customPurity : _selectedPurity;

  void setMetal(StockCategory metal) {
    _selectedMetal  = metal;
    _isCustomPurity = false;
    final opts = purityOptions;
    _selectedPurity = opts.isNotEmpty ? opts.first : '';
    notifyListeners();
  }

  void setPurity(String purity) {
    _isCustomPurity = (purity == 'Other');
    _selectedPurity = purity;
    notifyListeners();
  }

  void setCustomPurity(String val) {
    _customPurity = val;
    notifyListeners();
  }

  List<String> get purityOptions {
    switch (_selectedMetal) {
      case StockCategory.gold:
        return GoldPurity.values.map((e) => e.label).toList();
      case StockCategory.silver:
        return SilverPurity.values.map((e) => e.label).toList();
      case StockCategory.platinum:
        return PlatinumPurity.values.map((e) => e.label).toList();
      default:
        return ['Other'];
    }
  }

  bool get canProceedFromPurity =>
      !_isCustomPurity || _customPurity.trim().isNotEmpty;

  // ── Suppliers ─────────────────────────────────────────────────────────────
  List<SupplierListItemModel> _suppliers      = [];
  bool                        _loadingSuppliers = false;
  bool                        _sameForAll     = true;
  int?                        _sessionSupplierId;
  String                      _sessionSupplierName = '';

  List<SupplierListItemModel> get suppliers           => _suppliers;
  bool                        get loadingSuppliers    => _loadingSuppliers;
  bool                        get sameForAll          => _sameForAll;
  String                      get sessionSupplierName => _sessionSupplierName;

  Future<void> _loadSuppliers() async {
    _loadingSuppliers = true;
    notifyListeners();
    try {
      _suppliers = await _supplierRepo.getAllSuppliers();
    } catch (_) {}
    _loadingSuppliers = false;
    notifyListeners();
  }

  void setSameForAll(bool val) {
    _sameForAll = val;
    if (val) {
      for (final r in _rows) {
        r.supplierId   = _sessionSupplierId;
        r.supplierName = _sessionSupplierName;
      }
    }
    notifyListeners();
  }

  void setSessionSupplier(SupplierListItemModel? s) {
    _sessionSupplierId   = s?.id;
    _sessionSupplierName = s?.businessName ?? '';
    if (_sameForAll) {
      for (final r in _rows) {
        r.supplierId   = _sessionSupplierId;
        r.supplierName = _sessionSupplierName;
      }
    }
    notifyListeners();
  }

  void setSessionSupplierText(String name) {
    _sessionSupplierName = name;
    if (_sameForAll) {
      for (final r in _rows) { r.supplierName = name; }
    }
    notifyListeners();
  }

  void setRowSupplier(String rowId, SupplierListItemModel? s) {
    final r = _rowById(rowId);
    r.supplierId   = s?.id;
    r.supplierName = s?.businessName ?? '';
    notifyListeners();
  }

  // ── Rows ──────────────────────────────────────────────────────────────────
  final List<StockRowEntry> _rows = [];

  List<StockRowEntry> get rows     => List.unmodifiable(_rows);
  int                 get rowCount => _rows.length;

  void _addRow() {
    final r = StockRowEntry(id: 'row_${DateTime.now().microsecondsSinceEpoch}');
    if (_sameForAll) {
      r.supplierId   = _sessionSupplierId;
      r.supplierName = _sessionSupplierName;
    }
    _rows.add(r);
    notifyListeners();
  }

  void addRow() => _addRow();

  void removeRow(String rowId) {
    if (_rows.length <= 1) return;
    _rows.removeWhere((r) => r.id == rowId);
    notifyListeners();
  }

  // ── Row updaters ──────────────────────────────────────────────────────────
  void updateItemName(String id, String v)     { _rowById(id).itemName = v; notifyListeners(); }
  void updateSubCategory(String id, StockSubCategory v) { _rowById(id).subCategory = v; notifyListeners(); }
  void updateHuid(String id, String v)         { _rowById(id).huid = v; notifyListeners(); }
  void updateGrossWeight(String id, String v)  { _rowById(id).grossWeight = double.tryParse(v) ?? 0; notifyListeners(); }
  void updateStoneWeight(String id, String v)  { _rowById(id).stoneWeight = double.tryParse(v) ?? 0; notifyListeners(); }
  void updateStoneValue(String id, String v)   { _rowById(id).stoneValue = double.tryParse(v) ?? 0; notifyListeners(); }
  void updateStoneType(String id, StoneType v) { _rowById(id).stoneType = v; notifyListeners(); }
  void updateStoneCarats(String id, String v)  { _rowById(id).stoneCarats = double.tryParse(v) ?? 0; notifyListeners(); }
  void updateStonePieces(String id, String v)  { _rowById(id).stonePieces = int.tryParse(v) ?? 0; notifyListeners(); }
  void updatePurchaseRate(String id, String v) { _rowById(id).purchaseRate = double.tryParse(v) ?? 0; notifyListeners(); }
  void updateMakingCharges(String id, String v){ _rowById(id).makingCharges = double.tryParse(v) ?? 0; notifyListeners(); }
  void updateMakingType(String id, MakingChargesType v) { _rowById(id).makingChargesType = v; notifyListeners(); }

  StockRowEntry _rowById(String id) => _rows.firstWhere((r) => r.id == id);

  // ── Validation ────────────────────────────────────────────────────────────
  String? validateRow(StockRowEntry r) {
    if (r.itemName.trim().isEmpty) return 'Item name required';
    if (r.grossWeight <= 0)        return 'Gross weight must be > 0';
    if (r.stoneWeight > r.grossWeight) return 'Stone weight cannot exceed gross weight';
    return null;
  }

  bool get allRowsValid => _rows.every((r) => validateRow(r) == null);

  // ── SKU ───────────────────────────────────────────────────────────────────
  String _generateSku() {
    String cat = _selectedMetal.label.substring(0, _selectedMetal.label.length.clamp(0, 3)).toUpperCase();
    String pur = purityDisplay.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    pur = pur.substring(0, pur.length.clamp(0, 3));
    
    // ✅ FIX: Replaced simple sequence with a microsecond suffix to prevent UNIQUE constraint crashes
    String uniqueId = DateTime.now().microsecondsSinceEpoch.toString();
    uniqueId = uniqueId.substring(uniqueId.length - 4); 
    
    return '$cat-$pur-$uniqueId';
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  bool   _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  int    _savedCount = 0;

  bool    get isSaving      => _isSaving;
  String? get errorMessage  => _errorMessage;
  String? get successMessage=> _successMessage;
  int     get savedCount    => _savedCount;

  Future<bool> saveAll() async {
    if (!allRowsValid) {
      _errorMessage = 'Please fix errors before saving.';
      notifyListeners();
      return false;
    }

    _isSaving       = true;
    _errorMessage   = null;
    _successMessage = null;
    notifyListeners();

    int saved = 0;
    try {
      for (final row in _rows) {
        final sku = _generateSku();
        
        // Slight delay to ensure microseconds generate unique SKUs in rapid loop
        await Future.delayed(const Duration(milliseconds: 2)); 

        await _db.into(_db.stockItems).insert(StockItemsCompanion.insert(
          sku:               sku,
          itemName:          row.itemName.trim(),
          category:          _selectedMetal.label,
          subCategory:       row.subCategory.label,
          metalType:         drift.Value([StockCategory.diamond, StockCategory.antique, StockCategory.other]
              .contains(_selectedMetal) ? 'None / Other' : _selectedMetal.label),
          purity:            drift.Value(purityDisplay.isEmpty ? null : purityDisplay),
          grossWeight:       drift.Value(row.grossWeight),
          stoneWeight:       drift.Value(row.stoneWeight),
          netWeight:         drift.Value(row.netWeight),
          stoneType:         drift.Value(row.stoneType.label),
          stoneCarats:       drift.Value(row.stoneCarats),
          stonePieces:       drift.Value(row.stonePieces),
          stoneValue:        drift.Value(row.stoneValue),
          makingCharges:     drift.Value(row.makingCharges),
          makingChargesType: drift.Value(row.makingChargesType.label),
          purchaseRate:      drift.Value(row.purchaseRate),
          huid:              drift.Value(row.huid.trim().isEmpty ? null : row.huid.trim()),
          gstRate:           drift.Value(_selectedMetal == StockCategory.diamond ? 1.5 : 3.0),
          supplierId:        drift.Value(row.supplierId),
          supplierName:      drift.Value(row.supplierName.trim().isEmpty ? null : row.supplierName.trim()),
          status:            const drift.Value('Available'),
          
          // ✅ FIX: Added safe defaults for PC 1 missing fields to prevent DB crashes
          description:       const drift.Value(''),
          mrp:               const drift.Value(0.0),
          quantity:          const drift.Value(1),
          hsnCode:           drift.Value(_selectedMetal == StockCategory.silver ? '7114' : '7113'),
          rackLocation:      const drift.Value(''),
        ));
        saved++;
      }

      _savedCount     = saved;
      _successMessage = '$saved item${saved > 1 ? 's' : ''} added to stock!';
      return true;

    } catch (e) {
      debugPrint('AddStockController.saveAll: $e');
      _errorMessage = 'Error saving items. Database conflict or missing values.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void resetAllRows() {
    _rows.clear();
    _addRow();
    _errorMessage   = null;
    _successMessage = null;
    notifyListeners();
  }

  void resetForNewBatch() {
    _step             = AddStockStep.metal;
    _isCustomPurity   = false;
    _customPurity     = '';
    _rows.clear();
    _savedCount       = 0;
    _errorMessage     = null;
    _successMessage   = null;
    _addRow();
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage   = null;
    _successMessage = null;
    notifyListeners();
  }
}