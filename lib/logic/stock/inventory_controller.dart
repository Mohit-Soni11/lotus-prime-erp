// =============================================================================
// FILE        : inventory_controller.dart
// MODULE      : Stock & Inventory
// LAYER       : Logic / Controller
// DESCRIPTION : Business logic for Inventory Ledger screen.
//               Handles:
//               - Live stream of stock items (filtered by category)
//               - Opening stock calculation (items added before today)
//               - Closing stock calculation (currently Available items)
//               - Metal-wise breakdown (Gold, Silver, Diamond, Platinum)
//               - Refresh + loading state management
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/stock/stock_item_model/stock_enums.dart';
import '../../models/stock/inventory/inventory_stats_model.dart';

class InventoryController extends ChangeNotifier {
  final AppDatabase _db;

  InventoryController(this._db);

  // ── State ─────────────────────────────────────────────────────
  bool _isLoading = false;
  InventoryStats _stats = InventoryStats.empty();
  String _activeCategory = 'All';
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  InventoryStats get stats => _stats;
  String get activeCategory => _activeCategory;
  String? get errorMessage => _errorMessage;

  // ── Category filter options ───────────────────────────────────
  static const List<String> categories = [
    'All',
    'Gold',
    'Silver',
    'Diamond',
    'Platinum',
    'Antique',
    'Other',
  ];

  // ════════════════════════════════════════════════════════════════
  // LIVE STREAM — category-filtered items for the list view
  // ════════════════════════════════════════════════════════════════

  Stream<List<StockItem>> watchItems() {
    if (_activeCategory == 'All') {
      return (_db.select(_db.stockItems)
            ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
          .watch();
    }
    return (_db.select(_db.stockItems)
          ..where((t) => t.category.equals(_activeCategory))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  // ════════════════════════════════════════════════════════════════
  // LOAD STATS — called on init + refresh
  // ════════════════════════════════════════════════════════════════

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);

      // ── All items ───────────────────────────────────────────────
      final allItems = await _db.select(_db.stockItems).get();

      // ── Opening: added BEFORE today ────────────────────────────
      final opening = allItems
          .where(
            (i) => i.createdAt.isBefore(dayStart),
          )
          .toList();

      // ── Today's additions ──────────────────────────────────────
      final todayIn = allItems
          .where(
            (i) => !i.createdAt.isBefore(dayStart),
          )
          .toList();

      // ── Closing: currently Available ──────────────────────────
      final closing = allItems
          .where(
            (i) => i.status == StockStatus.available.label,
          )
          .toList();

      // ── Today's sold: Sold + updatedAt today ──────────────────
      final todaySold = allItems.where((i) {
        if (i.status != StockStatus.sold.label) return false;
        if (i.updatedAt == null) return false;
        return !i.updatedAt!.isBefore(dayStart);
      }).toList();

      // ── Metal breakdown (available items only) ─────────────────
      final avail = closing;

      final gold =
          avail.where((i) => i.category == StockCategory.gold.label).toList();
      final silver =
          avail.where((i) => i.category == StockCategory.silver.label).toList();
      final diamond = avail
          .where((i) => i.category == StockCategory.diamond.label)
          .toList();
      final platinum = avail
          .where((i) => i.category == StockCategory.platinum.label)
          .toList();

      _stats = InventoryStats(
        openingCount: opening.fold(0, (s, i) => s + i.quantity),
        openingWeight: opening.fold(0.0, (s, i) => s + _grossWeightOf(i)),
        openingValue:
            opening.fold(0.0, (s, i) => s + _valuationOf(i) * i.quantity),
        closingCount: closing.fold(0, (s, i) => s + i.quantity),
        closingWeight: closing.fold(0.0, (s, i) => s + _grossWeightOf(i)),
        closingValue:
            closing.fold(0.0, (s, i) => s + _valuationOf(i) * i.quantity),
        todayAdded: todayIn.fold(0, (s, i) => s + i.quantity),
        todaySold: todaySold.fold(0, (s, i) => s + i.quantity),
        goldCount: gold.fold(0, (s, i) => s + i.quantity),
        goldWeight: gold.fold(0.0, (s, i) => s + _grossWeightOf(i)),
        goldValue: gold.fold(0.0, (s, i) => s + _valuationOf(i) * i.quantity),
        silverCount: silver.fold(0, (s, i) => s + i.quantity),
        silverWeight: silver.fold(0.0, (s, i) => s + _grossWeightOf(i)),
        silverValue:
            silver.fold(0.0, (s, i) => s + _valuationOf(i) * i.quantity),
        diamondCount: diamond.fold(0, (s, i) => s + i.quantity),
        diamondValue:
            diamond.fold(0.0, (s, i) => s + _valuationOf(i) * i.quantity),
        platinumCount: platinum.fold(0, (s, i) => s + i.quantity),
        platinumWeight: platinum.fold(0.0, (s, i) => s + _grossWeightOf(i)),
      );
    } catch (e) {
      debugPrint('InventoryController.loadStats error: $e');
      _errorMessage = 'Could not load inventory data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CATEGORY FILTER
  // ════════════════════════════════════════════════════════════════

  void setCategory(String cat) {
    if (_activeCategory == cat) return;
    _activeCategory = cat;
    notifyListeners();
  }

  double _valuationOf(StockItem item) {
    if (item.mrp > 0) {
      return item.mrp;
    }
    return item.purchasePrice;
  }

  double _grossWeightOf(StockItem item) => item.grossWeight * item.quantity;
}
