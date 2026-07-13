import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/inventory/inventory_stats_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';

class InventoryController extends ChangeNotifier {
  final AppDatabase _db;

  InventoryController(this._db);

  bool _isLoading = false;
  InventoryStats _stats = InventoryStats.empty();
  String _activeCategory = 'All';
  String? _errorMessage;

  bool get isLoading => _isLoading;
  InventoryStats get stats => _stats;
  String get activeCategory => _activeCategory;
  String? get errorMessage => _errorMessage;

  static const List<String> categories = [
    'All',
    'Gold',
    'Silver',
    'Diamond',
    'Platinum',
    'Antique',
    'Other',
  ];

  Stream<List<StockItem>> watchItems() {
    final query = _db.select(_db.stockItems)
      ..orderBy([(table) => drift.OrderingTerm.desc(table.createdAt)]);

    if (_activeCategory != 'All') {
      query.where((table) => table.category.equals(_activeCategory));
    }

    return query.watch();
  }

  Stream<List<StockMovement>> watchRecentMovements({int limit = 12}) {
    final query = _db.select(_db.stockMovements)
      ..orderBy([(table) => drift.OrderingTerm.desc(table.occurredAt)])
      ..limit(limit);

    if (_activeCategory != 'All') {
      query.where((table) => table.metalTypeSnapshot.equals(_activeCategory));
    }

    return query.watch();
  }

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);

      final allItems = await _db.select(_db.stockItems).get();
      final todayAdded = await _todayAddedQuantity(dayStart);
      final todaySold = await _todaySoldQuantity(dayStart);

      final opening =
          allItems.where((item) => item.createdAt.isBefore(dayStart)).toList();

      final closing = allItems
          .where((item) => item.status == StockStatus.available.label)
          .toList();

      final gold = closing
          .where((item) => item.category == StockCategory.gold.label)
          .toList();
      final silver = closing
          .where((item) => item.category == StockCategory.silver.label)
          .toList();
      final diamond = closing
          .where((item) => item.category == StockCategory.diamond.label)
          .toList();
      final platinum = closing
          .where((item) => item.category == StockCategory.platinum.label)
          .toList();

      _stats = InventoryStats(
        openingCount: _quantityOf(opening),
        openingWeight: _grossWeightOfItems(opening),
        openingValue: _valueOfItems(opening),
        closingCount: _quantityOf(closing),
        closingWeight: _grossWeightOfItems(closing),
        closingValue: _valueOfItems(closing),
        todayAdded: todayAdded,
        todaySold: todaySold,
        goldCount: _quantityOf(gold),
        goldWeight: _grossWeightOfItems(gold),
        goldValue: _valueOfItems(gold),
        silverCount: _quantityOf(silver),
        silverWeight: _grossWeightOfItems(silver),
        silverValue: _valueOfItems(silver),
        diamondCount: _quantityOf(diamond),
        diamondValue: _valueOfItems(diamond),
        platinumCount: _quantityOf(platinum),
        platinumWeight: _grossWeightOfItems(platinum),
      );
    } catch (error, stackTrace) {
      AppLogger.debug(
        'InventoryController.loadStats error: $error\n$stackTrace',
      );
      _errorMessage = 'Could not load inventory data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (_activeCategory == category) return;
    _activeCategory = category;
    notifyListeners();
  }

  Future<int> _todayAddedQuantity(DateTime dayStart) async {
    final movements = await (_db.select(_db.stockMovements)
          ..where(
            (table) =>
                table.occurredAt.isBiggerOrEqualValue(dayStart) &
                table.movementType.equals('IN'),
          ))
        .get();

    return movements.fold<int>(
      0,
      (total, movement) => total + _positiveQuantity(movement.quantityDelta),
    );
  }

  Future<int> _todaySoldQuantity(DateTime dayStart) async {
    final movements = await (_db.select(_db.stockMovements)
          ..where(
            (table) =>
                table.occurredAt.isBiggerOrEqualValue(dayStart) &
                (table.movementType.equals('SALE') |
                    table.movementType.equals('SALE_RESTORE')),
          ))
        .get();

    final netQuantity = movements.fold<int>(
      0,
      (total, movement) => total + movement.quantityDelta,
    );

    return netQuantity < 0 ? netQuantity.abs() : 0;
  }

  int _positiveQuantity(int quantity) => quantity > 0 ? quantity : 0;

  int _quantityOf(List<StockItem> items) {
    return items.fold<int>(0, (total, item) => total + item.quantity);
  }

  double _grossWeightOfItems(List<StockItem> items) {
    return items.fold<double>(
      0,
      (total, item) => total + (item.grossWeight * item.quantity),
    );
  }

  double _valueOfItems(List<StockItem> items) {
    return items.fold<double>(
      0,
      (total, item) => total + (_valuationOf(item) * item.quantity),
    );
  }

  double _valuationOf(StockItem item) {
    if (item.mrp > 0) return item.mrp;
    return item.purchasePrice;
  }
}
