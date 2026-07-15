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
      final openingUnits = await _unitStats(
        before: dayStart,
      );
      final closingUnits = await _unitStats(
        status: StockStatus.available.label,
      );
      final goldUnits = await _unitStats(
        metal: StockCategory.gold.label,
        status: StockStatus.available.label,
      );
      final silverUnits = await _unitStats(
        metal: StockCategory.silver.label,
        status: StockStatus.available.label,
      );
      final diamondUnits = await _unitStats(
        metal: StockCategory.diamond.label,
        status: StockStatus.available.label,
      );
      final platinumUnits = await _unitStats(
        metal: StockCategory.platinum.label,
        status: StockStatus.available.label,
      );

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
        openingCount:
            openingUnits.hasRows ? openingUnits.count : _quantityOf(opening),
        openingWeight: openingUnits.hasRows
            ? openingUnits.grossWeight
            : _grossWeightOfItems(opening),
        openingValue:
            openingUnits.hasRows ? openingUnits.value : _valueOfItems(opening),
        closingCount:
            closingUnits.hasRows ? closingUnits.count : _quantityOf(closing),
        closingWeight: closingUnits.hasRows
            ? closingUnits.grossWeight
            : _grossWeightOfItems(closing),
        closingValue:
            closingUnits.hasRows ? closingUnits.value : _valueOfItems(closing),
        todayAdded: todayAdded,
        todaySold: todaySold,
        goldCount: goldUnits.hasRows ? goldUnits.count : _quantityOf(gold),
        goldWeight: goldUnits.hasRows
            ? goldUnits.grossWeight
            : _grossWeightOfItems(gold),
        goldValue: goldUnits.hasRows ? goldUnits.value : _valueOfItems(gold),
        silverCount:
            silverUnits.hasRows ? silverUnits.count : _quantityOf(silver),
        silverWeight: silverUnits.hasRows
            ? silverUnits.grossWeight
            : _grossWeightOfItems(silver),
        silverValue:
            silverUnits.hasRows ? silverUnits.value : _valueOfItems(silver),
        diamondCount:
            diamondUnits.hasRows ? diamondUnits.count : _quantityOf(diamond),
        diamondValue:
            diamondUnits.hasRows ? diamondUnits.value : _valueOfItems(diamond),
        platinumCount:
            platinumUnits.hasRows ? platinumUnits.count : _quantityOf(platinum),
        platinumWeight: platinumUnits.hasRows
            ? platinumUnits.grossWeight
            : _grossWeightOfItems(platinum),
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

  Future<_InventoryUnitStats> _unitStats({
    String? metal,
    String? status,
    DateTime? before,
  }) async {
    final where = <String>['1 = 1'];
    final variables = <drift.Variable<Object>>[];

    final metalValue = metal?.trim().toLowerCase();
    if (metalValue != null && metalValue.isNotEmpty) {
      where.add('lower(metal_type) = ?');
      variables.add(drift.Variable.withString(metalValue));
    }

    final statusValue = status?.trim();
    if (statusValue != null && statusValue.isNotEmpty) {
      where.add('status = ?');
      variables.add(drift.Variable.withString(statusValue));
    }

    if (before != null) {
      where.add('created_at < ?');
      variables.add(drift.Variable.withInt(before.millisecondsSinceEpoch));
    }

    final row = await _db.customSelect(
      '''
      SELECT
        COUNT(*) AS unit_count,
        COALESCE(SUM(gross_weight), 0.0) AS gross_weight,
        COALESCE(SUM(unit_cost), 0.0) AS stock_value
      FROM stock_item_units
      WHERE ${where.join(' AND ')}
      ''',
      variables: variables,
    ).getSingle();

    final count = row.read<int>('unit_count');
    return _InventoryUnitStats(
      count: count,
      grossWeight: row.read<double>('gross_weight'),
      value: row.read<double>('stock_value'),
    );
  }

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

class _InventoryUnitStats {
  final int count;
  final double grossWeight;
  final double value;

  const _InventoryUnitStats({
    required this.count,
    required this.grossWeight,
    required this.value,
  });

  bool get hasRows => count > 0;
}
