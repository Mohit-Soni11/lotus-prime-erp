import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/reports/day_book/day_book_stock_movement.dart';

class DayBookStockMovementRepository {
  const DayBookStockMovementRepository(this._db);

  final AppDatabase _db;

  Future<List<DayBookStockMovement>> fetch(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);
    final rows = await _db.customSelect(
      '''SELECT id, occurred_at, movement_type, metal_type_snapshot,
                item_name_snapshot, purity_snapshot, source_type, source_id,
                source_line_no, source_number,
                quantity_delta, gross_weight_delta, net_weight_delta,
                fine_weight_delta
         FROM stock_movements
         WHERE (occurred_at >= ? AND occurred_at < ?)
            OR (occurred_at >= ? AND occurred_at < ?)
         ORDER BY occurred_at, id''',
      variables: [
        Variable.withInt(start.millisecondsSinceEpoch),
        Variable.withInt(end.millisecondsSinceEpoch),
        Variable.withInt(start.millisecondsSinceEpoch ~/ 1000),
        Variable.withInt(end.millisecondsSinceEpoch ~/ 1000),
      ],
      readsFrom: {_db.stockMovements},
    ).get();
    return List.unmodifiable(rows.map((row) {
      final timestamp = row.read<int>('occurred_at');
      final movement = DayBookStockMovement(
        id: row.read<int>('id'),
        occurredAt: DateTime.fromMillisecondsSinceEpoch(
          timestamp.abs() >= 100000000000 ? timestamp : timestamp * 1000,
        ),
        movementType: row.read<String>('movement_type'),
        metal: row.read<String>('metal_type_snapshot'),
        itemName: row.read<String>('item_name_snapshot'),
        puritySnapshot: row.readNullable<String>('purity_snapshot'),
        sourceType: row.read<String>('source_type'),
        sourceId: row.read<String>('source_id'),
        sourceLineNo: row.readNullable<int>('source_line_no'),
        sourceNumber: row.readNullable<String>('source_number'),
        quantityDelta: row.read<int>('quantity_delta'),
        grossWeightDelta: row.read<double>('gross_weight_delta'),
        netWeightDelta: row.read<double>('net_weight_delta'),
        fineWeightDelta: row.read<double>('fine_weight_delta'),
      );
      if (movement.sourceType.trim().isEmpty ||
          movement.sourceId.trim().isEmpty) {
        throw StateError(
            'Stock movement ${movement.id} has no source reference.');
      }
      return movement;
    }));
  }
}
