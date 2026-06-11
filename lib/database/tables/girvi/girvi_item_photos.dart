import 'package:drift/drift.dart';

import '../base_table.dart';
import 'girvi_loan_items.dart';

@DataClassName('GirviItemPhoto')
@TableIndex(name: 'idx_girvi_photo_item', columns: {#itemId})
@TableIndex(
  name: 'idx_girvi_photo_item_order',
  columns: {#itemId, #sortOrder},
  unique: true,
)
class GirviItemPhotos extends Table with BaseTable {
  IntColumn get itemId =>
      integer().references(GirviLoanItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get filePath => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(1))();
  TextColumn get caption => text().nullable()();
  BoolColumn get isLegacy => boolean().withDefault(const Constant(false))();
}
