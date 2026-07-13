import 'package:drift/drift.dart';
import 'package:lotus_erp/database/tables/base_table.dart';
import 'package:lotus_erp/features/stock/shared/data/tables/stock_items.dart';

@DataClassName('StockMovement')
@TableIndex(name: 'idx_stock_movement_item', columns: {#stockItemId})
@TableIndex(
    name: 'idx_stock_movement_source', columns: {#sourceType, #sourceId})
@TableIndex(name: 'idx_stock_movement_occurred', columns: {#occurredAt})
class StockMovements extends Table with BaseTable {
  IntColumn get stockItemId =>
      integer().references(StockItems, #id, onDelete: KeyAction.restrict)();

  TextColumn get movementType => text()();
  TextColumn get sourceType => text()();
  TextColumn get sourceId => text()();
  IntColumn get sourceLineNo => integer().nullable()();
  TextColumn get sourceNumber => text().nullable()();
  TextColumn get skuSnapshot => text()();
  TextColumn get metalTypeSnapshot => text()();
  TextColumn get itemNameSnapshot => text()();
  IntColumn get quantityDelta => integer()();
  RealColumn get grossWeightDelta => real().withDefault(const Constant(0.0))();
  RealColumn get netWeightDelta => real().withDefault(const Constant(0.0))();
  RealColumn get fineWeightDelta => real().withDefault(const Constant(0.0))();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
}
