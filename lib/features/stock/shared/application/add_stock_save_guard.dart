import 'package:drift/drift.dart' as drift;
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/add_stock_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';

typedef AddStockRowValidation = String? Function(StockRowEntry row);
typedef AddStockBatchValidation = Future<String?> Function(
  List<StockRowEntry> rowsToSave,
);

final class AddStockSaveGuard {
  const AddStockSaveGuard._();

  static Future<String?> validateBeforeSave({
    required AppDatabase db,
    required bool canProceedFromPurity,
    required List<StockRowEntry> rowsToSave,
    required StockCategory selectedMetal,
    required bool hasSessionSupplier,
    required bool hasActiveRateSnapshot,
    required AddStockRowValidation validateRow,
    required AddStockBatchValidation validateCustomBatch,
  }) async {
    if (!canProceedFromPurity) {
      return AddStockStrings.errPurityRequired;
    }

    if (rowsToSave.isEmpty) {
      return AddStockStrings.errRowsMissing;
    }

    if (selectedMetal == StockCategory.gold) {
      if (!hasSessionSupplier) {
        return 'Select a saved supplier profile before saving this gold batch.';
      }
      if (!hasActiveRateSnapshot) {
        return 'Today\'s gold rate snapshot is missing. Set rates before saving this batch.';
      }
    }

    final customValidation = await validateCustomBatch(rowsToSave);
    if (customValidation != null) {
      return customValidation;
    }

    final batchDuplicate = _validateRowsAndBatchHuids(
      rowsToSave: rowsToSave,
      validateRow: validateRow,
    );
    if (batchDuplicate != null) {
      return batchDuplicate;
    }

    final stockDuplicate = await _findExistingHuidDuplicate(
      db: db,
      huidValues: _collectHuids(rowsToSave),
    );
    if (stockDuplicate != null) {
      return '${AddStockStrings.errDuplicateHuidInStock} ($stockDuplicate)';
    }

    return null;
  }

  static String? _validateRowsAndBatchHuids({
    required List<StockRowEntry> rowsToSave,
    required AddStockRowValidation validateRow,
  }) {
    final seenBatchHuids = <String>{};
    for (var index = 0; index < rowsToSave.length; index++) {
      final row = rowsToSave[index];
      final error = validateRow(row);
      if (error != null) {
        return 'Row ${index + 1}: $error';
      }

      for (final huid in _rowHuids(row)) {
        if (!seenBatchHuids.add(huid)) {
          return 'Row ${index + 1}: ${AddStockStrings.errDuplicateHuidInBatch}';
        }
      }
    }
    return null;
  }

  static Future<String?> _findExistingHuidDuplicate({
    required AppDatabase db,
    required List<String> huidValues,
  }) async {
    if (huidValues.isEmpty) {
      return null;
    }

    final existing = await (db.select(
      db.stockItems,
    )..where((table) => table.huid.isIn(huidValues)))
        .get();
    if (existing.isNotEmpty) {
      return existing.first.huid ?? huidValues.first;
    }

    try {
      final placeholders = List.filled(huidValues.length, '?').join(', ');
      final serialRows = await db.customSelect(
        '''
        SELECT huid
        FROM purchase_item_huids
        WHERE huid IN ($placeholders)
        LIMIT 1
        ''',
        variables: huidValues.map(drift.Variable.withString).toList(),
      ).get();
      if (serialRows.isNotEmpty) {
        return serialRows.first.read<String>('huid');
      }
    } catch (_) {
      // Older databases may not have purchase_item_huids yet.
    }

    return null;
  }

  static List<String> _collectHuids(List<StockRowEntry> rows) {
    return rows.expand(_rowHuids).toSet().toList(growable: false);
  }

  static Iterable<String> _rowHuids(StockRowEntry row) sync* {
    final source = row.huids.isNotEmpty
        ? row.huids
        : [
            if (row.huid.trim().isNotEmpty) row.huid,
          ];
    for (final value in source) {
      final huid = value.trim().toUpperCase();
      if (huid.isNotEmpty) {
        yield huid;
      }
    }
  }
}
