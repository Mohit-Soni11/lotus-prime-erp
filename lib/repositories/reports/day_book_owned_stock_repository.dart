import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/reports/day_book/day_book_owned_stock_position.dart';
import '../../models/reports/day_book/day_book_stock_movement.dart';

/// Reconstructs selected-day owned stock from today's inventory snapshot and
/// the immutable dated movement journal. Customer Girvi custody is excluded.
class DayBookOwnedStockRepository {
  const DayBookOwnedStockRepository(this._db);

  final AppDatabase _db;

  Future<DayBookOwnedStockPosition> fetch(
    DateTime day,
    List<DayBookStockMovement> dayMovements,
  ) async {
    final end = DateTime(day.year, day.month, day.day + 1);
    final unitRows = await _db.customSelect('''
      SELECT LOWER(TRIM(metal_type)) AS metal,
        COALESCE(SUM(CASE WHEN LOWER(status) = 'available'
          THEN net_weight ELSE 0 END), 0.0) AS available_grams
      FROM stock_item_units
      WHERE LOWER(TRIM(metal_type)) IN ('gold', 'silver')
      GROUP BY LOWER(TRIM(metal_type))
    ''').get();
    final legacyRows = await _db.customSelect('''
      SELECT LOWER(TRIM(s.metal_type)) AS metal,
        COALESCE(SUM(CASE WHEN LOWER(s.status) = 'available' AND s.is_active = 1
          THEN s.net_weight ELSE 0 END), 0.0) AS available_grams
      FROM stock_items s
      WHERE LOWER(TRIM(s.metal_type)) IN ('gold', 'silver')
        AND s.created_at < ?
        AND NOT EXISTS (SELECT 1 FROM stock_item_units u
          WHERE u.stock_item_id = s.id)
      GROUP BY LOWER(TRIM(s.metal_type))
    ''',
        variables: [Variable.withDateTime(end)],
        readsFrom: {_db.stockItems}).get();
    final unitValues = {
      for (final row in unitRows)
        row.read<String>('metal'): row.read<double>('available_grams'),
    };
    final legacyValues = {
      for (final row in legacyRows)
        row.read<String>('metal'): row.read<double>('available_grams'),
    };
    final afterRows = await _db.customSelect('''
      SELECT LOWER(TRIM(metal_type_snapshot)) AS metal,
        COALESCE(SUM(net_weight_delta), 0.0) AS net_grams
      FROM stock_movements
      WHERE ((occurred_at >= ? AND occurred_at >= 100000000000)
          OR (occurred_at >= ? AND occurred_at < 100000000000))
        AND LOWER(TRIM(metal_type_snapshot)) IN ('gold', 'silver')
      GROUP BY LOWER(TRIM(metal_type_snapshot))
    ''', variables: [
      Variable.withInt(end.millisecondsSinceEpoch),
      Variable.withInt(end.millisecondsSinceEpoch ~/ 1000),
    ], readsFrom: {
      _db.stockMovements
    }).get();
    final after = {
      for (final row in afterRows)
        row.read<String>('metal'): row.read<double>('net_grams'),
    };

    DayBookOwnedMetalPosition metal(String name) =>
        DayBookOwnedMetalPosition.fromMovements(
          metal: name,
          currentAvailableGrams:
              (unitValues[name] ?? 0) + (legacyValues[name] ?? 0),
          movementAfterDayGrams: after[name] ?? 0,
          dayMovements: dayMovements,
        );

    return DayBookOwnedStockPosition(
      gold: metal('gold'),
      silver: metal('silver'),
    );
  }
}
